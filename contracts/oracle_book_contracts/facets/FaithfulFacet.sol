// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { Modifiers, RequestStatus } from '../libs/LibAppStorage.sol';
import { LibFaithful } from '../libs/LibFaithful.sol';
import { LibConstant } from '../libs/LibConstant.sol';
import { VRFCoordinatorV2Interface } from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract FaithfulFacet is Modifiers {

    uint8 REQUEST_SCENE_MAIN_NFT = 0;

    /***********************
     *** READ FUNCTIONS **** 
     ***********************/

    /**
     * total supply of currently minted Faithfuls
     */
    function totalSupply() external view returns (uint256 totalSupply_) {
        totalSupply_ = Counters.current(s.faithfulCounter);
    }

    /**
     * get Faithful NFT via _tokenId
     */
    function getByTokenId(uint256 _tokenId) external view returns (
                uint256 randomNumber,
                uint8 status,
                uint8 attack,
                uint8 defense,
                uint8 fortune) 
    {
        require(_tokenId < this.totalSupply(), "getByTokenId: tokenId not exist!");
        randomNumber = s.faithfuls[_tokenId].randomNumber;
        status = s.faithfuls[_tokenId].status;
        attack = s.faithfuls[_tokenId].numericTraits[LibConstant.ATTACK_SLOT];
        defense = s.faithfuls[_tokenId].numericTraits[LibConstant.DEFENSE_SLOT];
        fortune = s.faithfuls[_tokenId].numericTraits[LibConstant.FORTUNE_SLOT];
    }

    /***********************
     *** WRITE FUNCTIONS *** 
     ***********************/

    /**
     * mint a new Faithful
     */
    function mint(address _to) external payable {
        require(_to != address(0), "FaithfulFacet: mint to zero address!");
        require(s.chainlinkInitialized, "FaithfulFacet: chainlink subscription config is not initialized!");
        uint256 _newTokenId = this.totalSupply();

        // mint execution
        LibFaithful.mint(_to, _newTokenId);

        // request random number from chainlink
        requestRandomWordForMainNFT(_newTokenId);

        // increment counter
        Counters.increment(s.faithfulCounter);
    }

    /**
     * trigger VRF requesting process for _newTokenId Faithful NFT
     */
    function requestRandomWordForMainNFT(uint256 _newTokenId) internal returns (uint256 requestId) {
        requestId = VRFCoordinatorV2Interface(s.vrfCoordinator).requestRandomWords(
            s.keyHash,
            s.s_subscriptionId,
            s.requestConfirmations,
            s.callbackGasLimit,
            s.numWords
        );

        // record this request Id for the newly generated _newTokenId
        s.s_requests[requestId] = RequestStatus({
            exists: true,
            fulfilled: false,
            randomWords: new uint256[](0),
            tokenId: _newTokenId,
            scene: REQUEST_SCENE_MAIN_NFT
        });
    }
}