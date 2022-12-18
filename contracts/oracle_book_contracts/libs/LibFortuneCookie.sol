// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import { LibAppStorage, AppStorage, FortuneCookie } from "./LibAppStorage.sol";
import { LibEncryption } from "./LibEncryption.sol";

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
     *  @param _fortuneCookieId     the fortune cookie id
     *  @return bool                this fortune cookie currently exists(not opened)
     */
    function _exists(uint256 _fortuneCookieId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.fortuneCookies[_fortuneCookieId].encryptedData.length > 0; 
    }

    /**
     * reveal a fortune cookie
     * 
     * @param _fortuneCookeId       the fortune cookie id
     * @param key                   the key used for decryption
     */
    function reveal(uint256 _fortuneCookeId, bytes calldata key) internal {

        require(mature(_fortuneCookeId), "FortuneCookie#reveal: fortune cookie check failed");

        // get the fortune Cookie instance
        AppStorage storage s = LibAppStorage.diamondStorage();

        // decrypt the fortune cookie data
        bytes memory decrypted = LibEncryption.encryptedDecrypt(
            s.fortuneCookies[_fortuneCookeId].encryptedData,
            key);

        // make the decrypted into uint256
        
    }
}