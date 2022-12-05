pragma solidity ^0.8.1;

import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { Modifiers } from '../libs/LibAppStorage.sol';
import { LibFaithful } from '../libs/LibFaithful.sol';
import { console } from 'hardhat/console.sol';

contract FaithfulFacet is Modifiers {

    /**
     * total supply of currently minted Faithfuls
     */
    function totalSupply() external view returns (uint256 totalSupply_) {
        totalSupply_ = Counters.current(s.faithfulCounter);
    }

    /***********************
     *** WRITE FUNCTIONS *** 
     ***********************/

    /**
     * mint a new Faithful
     */
    function mint(address _to) external payable {
        require(_to != address(0), "FaithfulFacet: mint to zero address!");
        uint256 _newTokenId = this.totalSupply();

        // mint execution
        LibFaithful.mint(_to, _newTokenId);
        // increment counter
        console.logUint(Counters.current(s.faithfulCounter));
        Counters.increment(s.faithfulCounter);
        console.logUint(Counters.current(s.faithfulCounter));
    }
}