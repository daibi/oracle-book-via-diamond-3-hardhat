// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Modifiers } from '../libs/LibAppStorage.sol';
import { LibRandomWord } from '../libs/LibRandomWord.sol';
import { console } from 'hardhat/console.sol';

contract VRFFacet is Modifiers  {

    /**
     * Initialize VRF subscriber config
     */
    function initializeSubscriber(uint64 s_subscriptionId, 
                                    address vrfCoordinator, 
                                    bytes32 keyHash,
                                    uint32 callbackGasLimit, 
                                    uint16 requestConfirmations,
                                    uint32 numWords) external {
        s.s_subscriptionId = s_subscriptionId;
        s.vrfCoordinator = vrfCoordinator;
        s.keyHash = keyHash;
        s.callbackGasLimit = callbackGasLimit;
        s.requestConfirmations = requestConfirmations;
        s.numWords = numWords;
        
        s.chainlinkInitialized = true;
        console.logBool(this.chainlinkInitialized());
    }

    /**
     * query VRF subscription configs
     */
    function getSubscriberConfig() view external returns (uint64 s_subscriptionId, 
                                    address vrfCoordinator, 
                                    bytes32 keyHash,
                                    uint32 callbackGasLimit, 
                                    uint16 requestConfirmations,
                                    uint32 numWords) {
        s_subscriptionId = s.s_subscriptionId;
        vrfCoordinator = s.vrfCoordinator;
        keyHash = s.keyHash;
        callbackGasLimit = s.callbackGasLimit;
        requestConfirmations = s.requestConfirmations;
        numWords = s.numWords;
    }

    /**
     * VRF callback function
     */
    function rawFulfillRandomWords(uint256 requestId, 
			uint256[] memory randomWords) external {
        LibRandomWord.processRandomWord(requestId, randomWords);
    }

    /**
     * check if chainlink subscription has been initialiized
     */
    function chainlinkInitialized() view external returns (bool initialized) {
        initialized = s.chainlinkInitialized;
    }
}