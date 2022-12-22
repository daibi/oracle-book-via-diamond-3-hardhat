// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { VRFCoordinatorV2Interface } from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

/* 
 * Storage Slot Defination In a Human Readable Format
 * For an upgradable smart contract, 
 *  it is never TOO cautious on the storage slot distribution
 * This implementation follows the 'AppStorage Pattern' to come up with a more humanreadable storage allocation
 * For detailed information, please refer to 
 * https://eip2535diamonds.substack.com/p/appstorage-pattern-for-state-variables?s=w
 * 
 * For every NEWLY introduced storage, developers should design the storage pattern in AppStorage to have a better accessing performance.
*/ 

uint256 constant MAX_FORTUNE_COOKIE_NUM = 3;
uint256 constant NUMERIC_TRAITS_NUM = 16;

/**
 * chianlink VRF request status recorder
 */
struct RequestStatus {
    bool fulfilled; // whether the request has been successfully fulfilled
    bool exists; // whether a requestId exists
    uint8 scene; // Usage for this requestId: 0-mainNFT; 1-fortuneCookie
    uint256 tokenId; // request random number result used for certain tokenId
    uint256[] randomWords;
}

/**
 * NFT main character: Faithful
 */
struct Faithful {

    /** owner of this faithful */
    address owner;

    /** the hexagram record this faithful has made */
    uint256[] hexagrams;

    /** the random number received when this **Faithful** is mint */
    uint256 randomNumber;

    /** numeric traits - current only the first three of the slots are effective */
    uint8[NUMERIC_TRAITS_NUM] numericTraits;

    /** temporary trait boosts */
    uint8[NUMERIC_TRAITS_NUM] temporaryTraitBoosts;

    /** last boost time for every itemId -- it is refreshable */
    mapping (uint8 => uint40) lastBoostTime;

    /** the timestamp of this Faithful minted */
    uint256 mintTime;

    /** current status 0=NOT valid, 1=VRF Rending, 2=running */
    uint8 status;
    
}

/**
 * chainlink VRF request status
 */
struct VRFRequestStatus {
    /** whether the request has been successfully fulfilled */
    bool fulfilled; 
    /** whether a requestId exists */
    bool exists; // 
    /** For this implementation, 
      * we only consume the first randomNumber returned from Chainlink, 
      * therefore, we only record one randomNumber for each request status */
    uint256 randomNumber;
}

/**
 * Fortune cookie
 */
struct FortuneCookie {
    
    /** the generation time of this fortune cookie */
    uint256 generateTime;

    /** encrypted data */
    bytes encryptedData;

}

/**
 * Hexagram generated from the Oracal Book
 * May the Hexagram guide you!
 */
struct Hexagram {
    
    /** 
     * the integer representation of the hexagram result, which can be interpreted as the last 6 binary digits of number 
     * For example, for the hexagram:
     * -----
     * -- --
     * -----
     * -----
     * -----
     * -----
     * the integer representation of this hexagram is '0b101111' --> 47
    */
    uint8 hexagram;

    /** the timestamp this hexagram has generated */
    uint40 generateTime;

    /** original query this faithful has made */
    string query;

}

/**
 * Item type enumeration, id of certain item type is reflect in the ItemType[] list field in the common AppStorage layout
 * Current configuration of ItemType includes:
 * - `ItemType[1]`: fortune cookie
 * - `ItemType[2]`: has boost in Attack point
 * - `ItemType[3]`: has boost in Defense point
 * - `ItemType[4]`: has boost in Fortune point
 */
struct ItemType {
    /** the name of this item */
    string name;

    /** description of this item */
    string description;

    /** boost slot */
    int[NUMERIC_TRAITS_NUM] boostSlot;
}



/**
 * Common storage for diamond project
 */
struct AppStorage {

    /** Counter for Faithful */
    Counters.Counter faithfulCounter;

    /** Counter for Fortune Cookie */
    Counters.Counter fortuneCookieCounter;

    /** chainlink subscription initialization flag */
    bool chainlinkInitialized;

    /** Fortune cookie initilization flag */
    bool fortuneCookieInitialized;
    
    /** Faithful indices */
    mapping(uint256 => Faithful) faithfuls;

    /** owner address -> owned Faithful token ids */
    mapping(address => uint256[]) ownerToFaithfulTokenIds;

    /** owner address -> tokenId -> tokenId index */
    mapping(address => mapping(uint256 => uint256)) ownerTokenIdIndices;

    /** Faithful operational priviledge */
    mapping(uint256 => address) approved;

    /** Hexagram indices */
    mapping(uint256 => Hexagram) hexagramRecords;

    /** hexagram record ids belonging to Faithful _tokenId */
    mapping(uint256 => uint256[]) faithfulToHexagramRecords;

    /** Item type enumeration recorder */
    ItemType[] itemType;

    /** Fortune cookie indices */
    mapping(uint256 => FortuneCookie) fortuneCookies;

    /** Fortune cookie owner address */
    mapping(uint256 => address) fortuneCookieOwner;

    /** owner address to fortune cookie collections */
    mapping(address => uint256[]) ownerToFortuneCookies;

    /** owner address -> fortune cookie id -> index */
    mapping(address => mapping(uint256 => uint256)) ownerFortuneCookieIdIndices;

    /** time for fortune cookie becomes revealable (ms)*/
    uint64 fortuneCookieMatureTime;

    /** the cycle between address's every fortune cookie query  */
    uint64 fortuneCookieQueryCooldown;

    /** last fortune cookie query time for every address */
    mapping(address => uint256) lastFortuneCookieQueryTime;

    /** owner address -> itemIds */
    mapping(address => uint8[]) ownerItems;

    /** owner address -> itemsId -> balance */
    mapping(address => mapping(uint8 => uint256)) ownerItemBalance;

    /** owner address -> item id -> item id index */
    mapping(address => mapping(uint8 => uint256)) ownerItemIndices;

    mapping(uint256 => RequestStatus) s_requests; /* requestId --> requestStatus */

    /** Version2 VRF coordinator */
    VRFCoordinatorV2Interface COORDINATOR;

    /** VRF subscription ID. */
    uint64 s_subscriptionId;

    /** VRF Coordinator address - it varies from different blockchain network */
    address vrfCoordinator;

    /** VRF keyhash - it varies from different blockchain network */
    bytes32 keyHash;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations;

    // number of rundom number retrieved from chainlink
    uint32 numWords;

}

/**
 * AppStorage pattern library, this will ensure every facet will interact with the RIGHT storage address inside the diamond contract
 * For detailed information, please refer to: https://eip2535diamonds.substack.com/p/appstorage-pattern-for-state-variables?s=w
 */
library LibAppStorage {

    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

contract Modifiers {

    AppStorage internal s;

    /**
     * Decoration: should check if fortune cookie config has been initialized 
     */
    modifier onlyFortuneCookieInitialized() {
        require(s.fortuneCookieInitialized, "fortune cookie config should be initialized first!");
        _;
    }

    /**
     * Decoration: should check if the msg.sender is the contract owner
     */
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    /**
     * Decoration: only faithful owners 
     */
    modifier onlyFaithfulOwners() {
        require(s.ownerToFaithfulTokenIds[msg.sender].length > 0, "please get a Faithful first");
        _;
    }

}