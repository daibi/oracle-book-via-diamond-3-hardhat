pragma solidity ^0.8.1;

import {LibAppStorage, AppStorage, Faithful, RequestStatus} from "./LibAppStorage.sol";
import {LibMath} from "./LibMath.sol";
import {LibERC721} from "../../shared/libraries/LibERC721.sol";
import {LibConstant} from "./LibConstant.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

/*
 * A 'Faithful' related library layer for common usage
 *
 * @author: Ruofan
 */
library LibFaithful {
    event FaithfulRendered(address indexed owner, uint256 indexed tokenId, uint256 indexed requestId);

    /**
     * Mint a NEW Faithful.
     * Once minted, this faithful is at VRF-pending status waiting for the VRF received from chainlink
     * ONLY core implementations, facets should implement the prerequisites check & onERC721ReceivedCheck itself
     */
    function mint(address _to, uint256 _tokenId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        // init a new Faithful
        initNewFaithful(_to, _tokenId);
        // init Faithful indices
        s.ownerToFaithfulTokenIds[_to].push(_tokenId);
        s.ownerTokenIdIndices[_to][_tokenId] = s.ownerToFaithfulTokenIds[_to].length;

        emit LibERC721.Transfer(address(0), _to, _tokenId);
    }

    /**
     * Init a new Faithful
     */
    function initNewFaithful(address _to, uint256 _tokenId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Faithful storage faithful = s.faithfuls[_tokenId];
        faithful.owner = _to;
        faithful.mintTime = block.timestamp;
        // For Faithful's initialization, it should be waiting for the VRF determination
        faithful.status = LibConstant.STATUS_VRF_PENDING;
    }

    /**
     * Transfer Faithful of <_tokenId> from address <_from> to address <_to>
     * ONLY logic implementations, facets should implement the prerequisites check & onERC721ReceivedCheck itself
     */
    function transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // remove _from
        uint256 index = s.ownerTokenIdIndices[_from][_tokenId];
        uint256 lastIndex = s.ownerToFaithfulTokenIds[_from].length - 1;
        if (index != lastIndex) {
            uint256 lastTokenId = s.ownerTokenIdIndices[_from][lastIndex];
            s.ownerToFaithfulTokenIds[_from][index] = lastTokenId;
            s.ownerTokenIdIndices[_from][lastTokenId] = index;
        }
        s.ownerToFaithfulTokenIds[_from].pop();
        delete s.ownerTokenIdIndices[_from][_tokenId];

        // delete operational priviledges
        if (s.approved[_tokenId] != address(0)) {
            delete s.approved[_tokenId];
            emit LibERC721.Approval(_from, address(0), _tokenId);
        }

        // add _tokenId to _to Address's collection
        s.faithfuls[_tokenId].owner = _to;
        s.ownerTokenIdIndices[_to][_tokenId] = s.ownerToFaithfulTokenIds[_to].length;
        s.ownerToFaithfulTokenIds[_to].push(_tokenId);

        emit LibERC721.Transfer(_from, _to, _tokenId);
    }

    /**
     * Render this faithful's born attributes
     *
     * A faithful's born attributes are rendered in the following process:
     *
     * 0）PRE: A Faithful has the following attributes, as recorded in numericTraits, currently only the first three slots are effective
     *      - SLOT 0: Attack
     *      - SLOT 1: Defense
     *      - SLOT 2: Fortune
     * 1) A random word is received from chainlink subscription(VRF)
     * 2）Once received the random word(denoted as R), this function can render faithful's born attributes as follow:
     *      - SLOT 0(Attack): R % 10
     *      - SLOT 1(Defense): (R / 10) % 10
     *      - SLOT 2(Fortune): (R / (10^2)) % 10
     */
    function renderFaithful(uint256 requestId, uint256[] memory randomWords) internal {
        require(randomWords.length >= 1, "updateMainNFT: insufficient randomWords length");
        AppStorage storage s = LibAppStorage.diamondStorage();

        RequestStatus storage requestStatus = s.s_requests[requestId];

        require(requestStatus.exists, "processRandomWord: requestId not exists");

        uint256 _tokenId = requestStatus.tokenId;
        s.faithfuls[_tokenId].status = LibConstant.STATUS_RUNNING;
        s.faithfuls[_tokenId].randomNumber = randomWords[0];

        for (uint256 slotIdx; slotIdx < LibConstant.EFFECTIVE_TRAIT_SLOTS; slotIdx++) {
            s.faithfuls[_tokenId].numericTraits[slotIdx] = uint8(SafeMath.mod(SafeMath.div(randomWords[0], LibMath.power(10, slotIdx)), 10));
        }

        emit FaithfulRendered(s.faithfuls[_tokenId].owner, _tokenId, requestId);
    }
}
