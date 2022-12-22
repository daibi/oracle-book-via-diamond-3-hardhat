pragma solidity ^0.8.0;

import { LibFortuneCookie } from "../libs/LibFortuneCookie.sol";
import { Modifiers, FortuneCookie } from '../libs/LibAppStorage.sol';
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * The facet for fortune cookies with the following features:
 *
 * 1) query address's fortune cookie collections
    - firstly, query fortuneCookieBalance() first
    - secondly, for each index, query fortune coookie detail by getCookieByOwnerIndex()
 * 2) query if he/she can ask for a fortune cookie based on last interaction timestamp
 * 3) ask for a new fortune cookie, with a daily cooldown based on UTC
 *  - 
 * 4) reveal the fortune cookie, for now it doesn't have an easy password manager solution, only for the use of feature development
 */
contract FortuneCookieFacet is Modifiers {
    
    /***********************
     **** READ FUNCTIONS *** 
     ***********************/
    
    /**
     * balance of given _owner's fortune cookie
     * @param   _owner          owner's address
     * @return  balance         balance of given _owner's fortune cookie
     */
    function fortuneCookieBalance(address _owner) public view onlyFortuneCookieInitialized returns(uint256) {
        require(_owner != address(0), "FortuneCookieFacet#balance: invalid _owner address");

        return s.ownerToFortuneCookies[_owner].length;
    }

    /**
     * get fortune cookie details by owner's index
     * 
     * @param   _owner          owner's address
     * @param   _index          the index of owner's fortune cookie collection
     * @return  fortuneCookieId id of the fortune cookie
     * @return  generateTime    generate time of the fortune cookie
     * @return  encryptedData   encrypted data
     * @return  placeHolder     token uri place holder
     * @return  remainingTime   
     */
    function getCookieByOwnerIndex(address _owner, uint256 _index) public view onlyFortuneCookieInitialized returns(
        uint256 fortuneCookieId,
        uint256 generateTime,
        bytes memory encryptedData,
        string memory placeHolder,
        uint256 remainingTime
    ) {
        require(_owner != address(0), "FortuneCookieFacet#getByOwnerIndex: invalid _owner address");
        require(_index < this.fortuneCookieBalance(_owner), "FortuneCookieFacet#getByOwnerIndex: invalid _index");

        fortuneCookieId = s.ownerToFortuneCookies[_owner][_index];

        require(LibFortuneCookie._exists(fortuneCookieId), "FortuneCookieFacet#getByOwnerIndex: fortune cookie id not exist");

        generateTime = s.fortuneCookies[fortuneCookieId].generateTime;
        encryptedData = s.fortuneCookies[fortuneCookieId].encryptedData;
        remainingTime = LibFortuneCookie.remainingTimeForReveal(fortuneCookieId);

        placeHolder = LibFortuneCookie.fortuneCookiePlaceHolder();
    }

    /**
     * owner of given fortune cookie id
     * 
     * @param _fortuneCookieId  fortune cookie id
     * @return address          owner's address
     */
    function ownerOfFortuneCookie(uint256 _fortuneCookieId) public view onlyFortuneCookieInitialized returns (address){
        return LibFortuneCookie._ownerOf(_fortuneCookieId);
    }   

    /**
     * query the remaining time(ms) for given address's next fortune cookie query
     *
     * @param _owner            fortune cookie owner
     * @return remainingTime    remaining cooldown time for next fortune cookie query
     */
    function remainingTimeForNextQuery(address _owner) public view onlyFortuneCookieInitialized returns (uint256 remainingTime)  {
        require(_owner != address(0), "FortuneCookieFacet#remainingTimeForNextQuery: invalid _owner address");

        if (s.lastFortuneCookieQueryTime[_owner] == 0) {
            return 0;
        }

        return Math.max(s.fortuneCookieQueryCooldown - (block.timestamp - s.lastFortuneCookieQueryTime[_owner]), 0);
    }

    /**
     * check if given address can query new fortune cookie
     * @param _owner            target owner address
     * @return bool             true - this address can query for a new fortune cookie
     */
    function canQueryNewFortuneCookie(address _owner) onlyFortuneCookieInitialized public view returns (bool) {
        return remainingTimeForNextQuery(_owner) == 0;
    }

    
    /***********************
     *** WRITE FUNCTIONS *** 
     ***********************/

    /**
     * ask for new fortune cookies, should be success in a daily routine based on UTC time 
     * 
     * @param _encryptedData    encrypted for the fortune cookie      
     */
    function askForNewFortuneCookie(bytes calldata _encryptedData) public onlyFortuneCookieInitialized onlyFaithfulOwners {

        require(this.canQueryNewFortuneCookie(msg.sender), "FortuneCookie#askForNew: still in cooldown period");

        LibFortuneCookie.mint(msg.sender, _encryptedData);
    }

    /**
     * reveal the fortune cookie
     * 
     * @param _fortuneCookieId  fortune cookie id
     * @param _key              decryption key
     */
    function reveal(uint256 _fortuneCookieId, bytes calldata _key) public onlyFortuneCookieInitialized {
        
        require(ownerOfFortuneCookie(_fortuneCookieId) == msg.sender, "FortuneCookie#reveal: not the owner");

        LibFortuneCookie.reveal(_fortuneCookieId, _key);
    }
}