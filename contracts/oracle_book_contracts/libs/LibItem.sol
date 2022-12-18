// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import { LibAppStorage, AppStorage } from "./LibAppStorage.sol";

library LibItem {

    /**
     * mint new portions of given _itemType
     * 
     * @param _to           target address
     * @param _itemType     type of portion
     * @param _itemNum      num of items
     */
    function mintPortion(address _to, uint8 _itemType, uint8 _itemNum) internal {
        
        AppStorage storage s = LibAppStorage.diamondStorage();

        s.ownerItemBalance[_to][_itemType] += _itemNum;
        if (s.ownerItemIndices[_to][_itemType] == 0) {
            s.ownerItems[_to].push(_itemType);
            s.ownerItemIndices[_to][_itemType] = s.ownerItems[_to].length;
        }
    }
}   