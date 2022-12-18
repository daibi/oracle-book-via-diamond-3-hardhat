// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import { LibAppStorage, AppStorage, FortuneCookie } from "./LibAppStorage.sol";

library LibFortuneCookie {

    /**
     * check if given _fortuneCookieId is mature
     */
    function mature(uint256 _fortuneCookieId) internal view returns (bool) {
        
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_exists(_fortuneCookieId), "FortuneCookie#timeUp: fortuneCookie doesn't exist");

        return block.timestamp - s.fortuneCookies[_fortuneCookieId].generateTime >= s.fortuneCookieMatureTime;
    }

    /**
     * check if given _fortuneCookieId exists
     */
    function _exists(uint256 _fortuneCookieId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.fortuneCookies[_fortuneCookieId].encryptedData.length > 0; 
    }
}