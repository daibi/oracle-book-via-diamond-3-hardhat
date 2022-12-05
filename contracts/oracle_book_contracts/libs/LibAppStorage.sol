pragma solidity ^0.8.1;

import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";

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

    
}