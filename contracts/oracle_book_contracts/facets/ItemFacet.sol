pragma solidity ^0.8.1;

import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {Modifiers} from "../libs/LibAppStorage.sol";
import {LibItem} from "../libs/LibItem.sol";
import {LibERC721} from "../../shared/libraries/LibERC721.sol";
import {LibERC3525} from "../../shared/libraries/LibERC3525.sol";

contract ItemFacet is Modifiers {
    /***********************
     *** WRITE FUNCTIONS ***
     ***********************/

    /**
     * Get balance of the token
     */
    function balanceOf(uint256 tokenId_) public view virtual returns (uint256) {
        require(LibItem._exists(tokenId_), "ERC3525: balance query for nonexistent token");
        return s.itemBalance[tokenId_];
    }

    /**
     * Get slot of the token
     */
    function slotOf(uint256 tokenId_) public view virtual returns (uint256) {
        require(LibItem._exists(tokenId_), "ERC3525: slot query for nonexistent token");
        return s.itemSlot[tokenId_];
    }

    /**
     * Mint an ERC3525 standard item with value
     */
    function mint(
        address to_,
        uint256 slot_,
        uint256 value_
    ) external payable {
        require(to_ != address(0), "ERC3525: mint to the zero address");

        uint256 tokenId_ = LibItem._getNewTokenId();
        LibItem._mint(to_, tokenId_, slot_);

        s.itemBalance[tokenId_] = value_;

        emit LibERC3525.TransferValue(0, tokenId_, value_);
    }

    /**
     * Transfer ERC3525 standard item to an address
     */
    // function transferFrom(
    //     uint256 fromTokenId_,
    //     address to_,
    //     uint256 value_
    // ) public payable virtual returns (uint256) {
    //     uint256 newTokenId = LibItem._getNewTokenId();

    //     LibItem._mint(to_, newTokenId, s.itemSlot[fromTokenId_]);
    //     LibItem._transfer(fromTokenId_, newTokenId, value_);

    //     return newTokenId;
    // }

    /**
     * Transfer ERC3525 standard item to another token
     */
    function transferFrom(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) public payable virtual {
        LibItem._transfer(fromTokenId_, toTokenId_, value_);
    }
}
