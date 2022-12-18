// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import { LibAppStorage, AppStorage, FortuneCookie } from "./LibAppStorage.sol";
import { LibEncryption } from "./LibEncryption.sol";
import { BytesLib } from "solidity-bytes-utils/contracts/BytesLib.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { LibItem } from "./LibItem.sol";

library LibFortuneCookie {

    /**
     * check if given _fortuneCookieId is mature
     * 
     *  @param _fortuneCookieId     the fortune cookie id
     *
     *  @return bool                true: the fortune cookie is ready for revealing
     */
    function mature(uint256 _fortuneCookieId) internal view returns (bool) {
        
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_exists(_fortuneCookieId), "FortuneCookie#timeUp: fortuneCookie doesn't exist");

        return block.timestamp - s.fortuneCookies[_fortuneCookieId].generateTime >= s.fortuneCookieMatureTime;
    }

    /**
     * check if given _fortuneCookieId exists
     * 
     *  @param _fortuneCookieId     the fortune cookie id
     *  @return bool                this fortune cookie currently exists(not opened)
     */
    function _exists(uint256 _fortuneCookieId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.fortuneCookies[_fortuneCookieId].encryptedData.length > 0; 
    }

    /**
     * owner of given fortune cookie id 
     * 
     * @param _fortuneCookieId      the fortune cookie id 
     * @return owner                the owner of this fortune cookie
     */
    function _ownerOf(uint256 _fortuneCookieId) internal view returns (address owner) {
        require(_exists(_fortuneCookieId), "LibFortuneCookie#_ownerOf: fortune cookie doesn't exist");
        
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.fortuneCookieOwner[_fortuneCookieId];
    }

    /**
     * reveal a fortune cookie
     * 
     * @param _fortuneCookieId      the fortune cookie id
     * @param key                   the key used for decryption
     */
    function reveal(uint256 _fortuneCookieId, bytes calldata key) internal {

        require(mature(_fortuneCookieId), "FortuneCookie#reveal: fortune cookie check failed");

        // get the fortune Cookie instance
        AppStorage storage s = LibAppStorage.diamondStorage();

        // decrypt the fortune cookie data
        bytes memory decrypted = LibEncryption.encryptedDecrypt(
            s.fortuneCookies[_fortuneCookieId].encryptedData,
            key);

        // make the decrypted into uint256
        uint256 decryptedNum = BytesLib.toUint256(decrypted, 0);

        // render the fortune cookie
        renderFortuneCookie(decryptedNum, _ownerOf(_fortuneCookieId));

        // burn this cookie
        burn(_fortuneCookieId);
        
    }

    /**
     * render the fortune cookie with the initial num decrypted
     * 
     * Given a number(denoted as N), the principle of rendering this fortune cookie into item is:
     *  
     * 1) N % EFFECTIVE_TRAIT_SLOTS: the item type index
     * 2) (N / 100) % 10 : number of items
     * 
     * @param _decryptedNum      the decrypted number from fortune cookie
     * @param _to                the target address for the result of fortune cookie rendering
     */
    function renderFortuneCookie(uint256 _decryptedNum, address _to) internal {
        unchecked {
            // 1. render the item type behind the fortune cookie
            uint8 _itemType = uint8(_decryptedNum % 10);
            // 2. number of items
            uint8 _itemNum = uint8((_decryptedNum / 10) % 10);

            // 3. mint portions to this address
            LibItem.mintPortion(_to, _itemType, _itemNum);
        }
    }

    /**
     * burn the fortune cookie
     *
     * @param _fortuneCookieId      fortune cookie id
     */
    function burn(uint256 _fortuneCookieId) internal {
        
        // fortune cookie ownership data structure:
        // 1. fortuneCookies
        // 2. fortuneCookieOwner
        // 3. ownerToFortuneCookies
        // 4. ownerFortuneCookieIdIndices

        AppStorage storage s = LibAppStorage.diamondStorage();
        // clear fortuneCookie definition
        delete s.fortuneCookies[_fortuneCookieId];

        // get owner of this fortune cookie
        address _owner = _ownerOf(_fortuneCookieId);

        // clear owner by fortune index
        uint256 _fortuneCookieIndex = s.ownerFortuneCookieIdIndices[_owner][_fortuneCookieId];

        if (_fortuneCookieIndex != s.ownerToFortuneCookies[_owner].length - 1) {

            // swap the last fortune cookie with the removed one
            uint256 _lastFortuneCookieId = s.ownerToFortuneCookies[_owner][s.ownerToFortuneCookies[_owner].length - 1];
            s.ownerToFortuneCookies[_owner][_fortuneCookieIndex] = _lastFortuneCookieId;

            // update the last fortune cookie's index
            s.ownerFortuneCookieIdIndices[_owner][_lastFortuneCookieId] = _fortuneCookieIndex;

            // remove the last index
            delete s.ownerFortuneCookieIdIndices[_owner][_fortuneCookieId];

            // remove this fortune cookie from user's collection
            delete s.ownerToFortuneCookies[_owner][s.ownerToFortuneCookies[_owner].length - 1];
        }

        // delete owner record
        delete s.fortuneCookieOwner[_fortuneCookieId];

    }
}