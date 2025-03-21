// SPDX-License-Identifier: MIT

/* This is the data availabilty part of zkEscrow. It stores encrypted user data, given by the zk-escrow npm package.
 * It allows for statements of the form "I have stored properly-encrypted data to this contract, and the commitment to my data is X"
 * Then, users can do arbitrary proofs of the data by opening the commitment in a zksnark.
 * Neither the ciphertext and the commitment stored here can be broken by quantum computers, nor lost in a data breach of a single master key.
 */

import "./daEncrypt.verifier.sol";
pragma solidity ^0.8.9;

struct Point {
    uint x;
    uint y;
}

struct ElGamalCiphertext {
    Point c1;
    Point c2;
}

// A tag is given in the proof of correct encryption, as the public signals. It is all the information that will be needed to recover the plaintext.
// Notably, it has a Pedersen commitment to the plaintext data. That way, once data is stored in this contract, a user can open the commitment in another
// zksnark to prove facts about it.
struct Tag {
    // points to a contract that will have to the has access interface
    // function hasAccess(byte32 tagId, address auditor): reutrns (boolean)
    address accessControlLogic;
    // Pedersen commitment (Quantum Resistant Commitment)
    Point commitment;
    ElGamalCiphertext ciphertext;
    uint prfIn;
}

struct PublicSignal {
    uint x;
    uint y;
}

contract DataAvail {
    event TagAdded(bytes32 tagId, Tag tag);
    Verifier verifier;
    mapping(bytes32 => Tag) tags;

    constructor() {
        verifier = new Verifier();
    }

    function getTagId(Tag memory tag) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    tag.accessControlLogic,
                    tag.commitment.x,
                    tag.commitment.y
                )
            );
    }
    // Override
    function getTagId(Point memory commitment, address accessControlLogic) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    accessControlLogic,
                    commitment.x,
                    commitment.y
                )
            );
    }

    /**
     * Stores tags in the contract, given a (zk) proof of correct encryption.
     * the contract will have a verifyer contract that will verify the proof.
     * data that's generated by the npm package (zk-escrow)
     */
    function storeData(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[8] memory input
    ) public returns (bool) {
        require(
            verifier.verifyProof(a,b,c,input),
            "failed to verify proof of correct encryption"
        );

        Tag memory tag = Tag(
            address(uint160(input[6])),
            Point(input[4], input[5]),
            ElGamalCiphertext(
                Point(input[0], input[1]),
                Point(input[2], input[3])
            ),
            input[7]
        );
        bytes32 tagId = getTagId(tag);
        // Checks that tag hasn't been used before (commitment.x has negligible probability to be 0 if it is used)
        require(tags[tagId].commitment.x == 0, "This data already exists");

        tags[tagId] = tag;
        emit TagAdded(tagId, tag);
        return true;
    }

    // Checks a tag has been stored:
    function checkDataAvailability(
        Point memory dataCommitment,
        address accessControlLogic
    ) public view returns (bool available) {
        bytes32 id = getTagId(dataCommitment, accessControlLogic);
        // This line works because if tags[id] is uninitialized, the accessControlLogic will be the zero address
        return
            (tags[id].accessControlLogic == accessControlLogic) &&
            (accessControlLogic != address(0));
    }
}
