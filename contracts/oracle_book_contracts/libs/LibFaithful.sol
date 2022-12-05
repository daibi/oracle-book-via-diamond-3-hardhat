pragma solidity ^0.8.1;

import { LibAppStorage, AppStorage, Faithful } from "./LibAppStorage.sol";
import { LibERC721 } from "../../shared/libraries/LibERC721.sol";

/*
 * A 'Faithful' related library layer for common usage
 * 
 * @author: Ruofan
 */
library LibFaithful {

    uint8 constant STATUS_INVALID = 0;
    uint8 constant STATUS_VRF_PENDING = 1;
    uint8 constant STATUS_RUNNING = 2;

    /**
     * Mint a NEW Faithful.
     * Once minted, this faithful is at VRF-pending status waiting for the VRF received from chainlink
     * ONLY core implementations, facets should implement the prerequisites check & onERC721ReceivedCheck itself
     */
    function mint(
        address _to,
        uint256 _tokenId
    ) internal {
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
        faithful.status = STATUS_VRF_PENDING;
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
}