pragma solidity ^0.8.1;

import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {LibAppStorage, AppStorage} from "./LibAppStorage.sol";
import {LibERC721} from "../../shared/libraries/LibERC721.sol";
import {LibERC3525} from "../../shared/libraries/LibERC3525.sol";

/*
 * A 'Item' related library layer for common usage
 * Approval related work to be added
 *
 * @author: Xiaoyuan
 */
library LibItem {
    /**
     * Check if a tokenId exists
     */
    function _exists(uint256 _tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.itemOwner[_tokenId] != address(0);
    }

    /**
     * Generate a new tokenId from item Counter
     * TODO: concurrent issues?
     */
    function _getNewTokenId() internal returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 _lastTokenId = Counters.current(s.itemCounter);
        Counters.increment(s.itemCounter);
        return _lastTokenId + 1;
    }

    /**
     * Mint a zero value ERC3525 standard item
     */
    function _mint(
        address to_,
        uint256 tokenId_,
        uint256 slot_
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.ownerItems[to_].push(tokenId_);
        s.itemOwner[tokenId_] = to_;
        s.itemSlot[tokenId_] = slot_;
        emit LibERC3525.SlotChanged(tokenId_, 0, slot_);

        emit LibERC721.Transfer(address(0), to_, tokenId_);
    }

    /**
     * Burn a token
     */
    function _burn(uint256 tokenId_) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        address owner = s.itemOwner[tokenId_];

        uint256 slot = s.itemSlot[tokenId_];
        uint256 value = s.itemBalance[tokenId_];

        delete s.itemOwner[tokenId_];
        delete s.itemSlot[tokenId_];
        delete s.itemBalance[tokenId_];

        uint256 length = s.ownerItems[owner].length;
        for (uint256 i = 0; i < length - 1; i++) {
            if (s.ownerItems[owner][i] == tokenId_) {
                s.ownerItems[owner][i] = s.ownerItems[owner][length - 1];
                break;
            }
        }
        s.ownerItems[owner].pop();

        emit LibERC3525.TransferValue(tokenId_, 0, value);
        emit LibERC3525.SlotChanged(tokenId_, slot, 0);
    }

    /**
     * transfer value between two tokens
     */
    function _transfer(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) internal {
        require(_exists(fromTokenId_), "ERC35255: transfer from nonexistent token");
        require(_exists(toTokenId_), "ERC35255: transfer to nonexistent token");

        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.itemBalance[fromTokenId_] >= value_, "ERC3525: transfer amount exceeds balance");
        require(s.itemSlot[fromTokenId_] == s.itemSlot[toTokenId_], "ERC3535: transfer to token with different slot");

        s.itemBalance[fromTokenId_] -= value_;
        s.itemBalance[toTokenId_] += value_;

        emit LibERC3525.TransferValue(fromTokenId_, toTokenId_, value_);
    }
}
