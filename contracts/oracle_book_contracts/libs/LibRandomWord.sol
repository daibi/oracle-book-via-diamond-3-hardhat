// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibAppStorage, AppStorage, RequestStatus } from "./LibAppStorage.sol";
import { LibFaithful } from './LibFaithful.sol';

library LibRandomWord {

    uint8 constant STATUS_INVALID = 0;
    uint8 constant STATUS_VRF_PENDING = 1;
    uint8 constant STATUS_RUNNING = 2;

    /**
     * process the random word received, will route into the execute via the recorded RequestStatus
     * 
     * @param requestId         chainlink VRF request id
     * @param randomWords       generated random words result from chainlink VRF
     */
    function processRandomWord(uint256 requestId, uint256[] memory randomWords) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        // 1. retrieve RequestStatus from s_requests record
        RequestStatus storage requestStatus = s.s_requests[requestId];
        require(requestStatus.exists, "processRandomWord: requestId not exists");

        // 2. route into execute function via <scene>
        if (requestStatus.scene == 0) {
            LibFaithful.renderFaithful(requestId, randomWords);
        }
    }    
}