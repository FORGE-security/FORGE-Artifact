// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title MerkleProofCalldata
 * @notice This library is adjusted from the work of OpenZeppelin.
 *         It is based on the 4.7.0 (utils/cryptography/MerkleProof.sol).
 * @author OpenZeppelin (adjusted)
 */
library MerkleProofCalldata {
    /**
     * @notice This returns true if a `leaf` can be proved to be a part of a Merkle tree defined by `root`.
     * For this, a `proof` must be provided, containing sibling hashes on the branch from the leaf to the root of the tree.
     * Each pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @notice This returns the rebuilt hash obtained by traversing a Merkle tree up from `leaf` using `proof`.
     * A `proof` is valid if and only if the rebuilt hash matches the root of the tree.
     * When processing the proof, the pairs of leafs & pre-images are assumed to be sorted.
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}
