pragma solidity >=0.5.0 <0.6.0;

import "../../../interfaces/PrivateRangeInterface.sol";
import "./PrivateRangeABIEncoder.sol";

/**
 * @title Library to validate AZTEC zero-knowledge private range proofs
 * @author AZTEC
 * @dev Don't include this as an internal library. This contract uses a static memory table to cache
 * elliptic curve primitives and hashes.
 * Calling this internally from another function will lead to memory mutation and undefined behaviour.
 * The intended use case is to call this externally via `staticcall`.
 * External calls to OptimizedAZTEC can be treated as pure functions as this contract contains no
 * storage and makes no external calls (other than to precompiles)
 * Copyright Spilsbury Holdings Ltd 2019. All rights reserved.

 **/
contract PrivateRange {
    /**
     * @dev AZTEC will take any transaction sent to it and attempt to validate a zero knowledge proof.
     * If the proof is not valid, the transaction throws.
     * @notice See AZTECInterface for how method calls should be constructed.
     **/

    // solhint-disable payable-fallback
    function() external {
        assembly {
            // We don't check for function signatures,
            // there's only one function that ever gets called: validatePrivateRange()
            // We still assume calldata is offset by 4 bytes so that we can represent this contract
            // through a compatible ABI
            validatePrivateRange()

            // if we get to here, the proof is valid. We now 'fall through' the assembly block
            // and into PrviateRangeABIEncoder.validatePrivateRange()
            // reset the free memory pointer because we're touching Solidity code again
            mstore(0x40, 0x60)

            /**
             * New calldata map
             * 0x04:0x24      = calldata location of proofData byte array
             * 0x24:0x44      = message sender
             * 0x44:0x64      = h_x
             * 0x64:0x84      = h_y
             * 0x84:0xa4      = t2_x0
             * 0xa4:0xc4      = t2_x1
             * 0xc4:0xe4      = t2_y0
             * 0xe4:0x104     = t2_y1
             * 0x104:0x124    = length of proofData byte array
             * 0x124:0x144    = challenge
             * 0x144:0x164    = offset in byte array to notes
             * 0x164:0x184    = offset in byte array to inputOwners
             * 0x184:0x1a4    = offset in byte array to outputOwners
             * 0x1a4:0x1c4    = offset in byte array to metadata
             */
            function validatePrivateRange() {
                mstore(0x80, calldataload(0x44))
                mstore(0xa0, calldataload(0x64))
                let notes := add(0x104, calldataload(0x144))
                let m := 2
                let n := 3
                let gen_order := 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001
                let challenge := mod(calldataload(0x124), gen_order)

                // add sender, kPublic, publicOwner to final hash table
                mstore(0x2a0, calldataload(0x24)) // sender
                mstore(0x2c0, 0) // kPublic
                mstore(0x2e0, 0) // publicOwner
                hashCommitments(notes, n)
                let b := add(0x300, mul(n, 0x80))

                // Iterate over every note and calculate the blinding factor B_i = \gamma_i^{kBar}h^{aBar}\sigma_i^{-c}.
                // We use the AZTEC protocol pairing optimization to reduce the number of pairing comparisons to 1,
                //  which adds some minor alterations

                // Iterate over every note and calculate the blinding factor B_i = \gamma_i^{kBar}h^{aBar}\sigma_i^{-c}.
                // We use the AZTEC protocol pairing optimization to reduce the number of pairing comparisons to 1,
                //  which adds some minor alterations
                for { let i := 0 } lt(i, n) { i := add(i, 0x01) } {

                    // Get the calldata index of this note
                    let noteIndex := add(add(notes, 0x20), mul(i, 0xc0))

                    // Define variables k, a and c.
                    // If i <= m then
                    //   k = kBar_i
                    //   a = aBar_i
                    //   c = challenge
                    // If i > m then we add a modification for the pairing optimization
                    //   k = kBar_i * x_i
                    //   a = aBar_i * x_i
                    //   c = challenge * x_i
                    // Set j = i - (m + 1).
                    // x_0 = 1
                    // x_1 = keccak256(input string)
                    // all other x_{j} = keccak256(x_{j-1})
                    // The reason for doing this is that the point  \sigma_i^{-cx_j} can be re-used in the pairing check
                    // Instead of validating e(\gamma_i, t_2) == e(\sigma_i, g_2) for all i = [m+1,\ldots,n]
                    // We validate e(\Pi_{i=m+1}^{n}\gamma_i^{-cx_j}, t_2) == e(\Pi_{i=m+1}^{n}\sigma_i^{cx_j}, g_2).
                    // x_j is a pseudorandom variable whose entropy source is the input string, allowing for
                    // a sum of commitment points to be evaluated in one pairing comparison
                    let k := calldataload(noteIndex)
                    let a := calldataload(add(noteIndex, 0x20))
                    let c := challenge

                    switch gt(i, 1)
                    case 1 {

                        // k_3 = k_1 - k_2
                        k := addmod(
                                calldataload(sub(noteIndex, 0x180)), // k_1
                                sub(
                                    gen_order,
                                    calldataload(sub(noteIndex, 0xc0))), // k_2xÂ§
                                gen_order)
                    } 
                    case 0 {
                        k := calldataload(noteIndex)
                    }

                    // Check this commitment is well formed...
                    validateCommitment(noteIndex, k, a)

                    // Set k = kx_j, a = ax_j, c = cx_j, where j = i - (m+1)
                    if i {
                        let x := mod(mload(0x00), gen_order)
                        k := mulmod(k, x, gen_order)
                        a := mulmod(a, x, gen_order)
                        c := mulmod(challenge, x, gen_order)

                        // calculate x_{j+1}
                        mstore(0x00, keccak256(0x00, 0x20))
                    }

                    // Calculate the G1 element \gamma_i^{k}h^{a}\sigma_i^{-c} = B_i
                    // Memory map:
                    // 0x20: \gamma_iX
                    // 0x40: \gamma_iY
                    // 0x60: k_i
                    // 0x80: hX
                    // 0xa0: hY
                    // 0xc0: a_i
                    // 0xe0: \sigma_iX
                    // 0x100: \sigma_iY
                    // 0x120: -c
                    calldatacopy(0xe0, add(noteIndex, 0x80), 0x40)
                    calldatacopy(0x20, add(noteIndex, 0x40), 0x40)
                    mstore(0x120, sub(gen_order, c)) 
                    mstore(0x60, k)
                    mstore(0xc0, a)

                    // Call bn128 scalar multiplication precompiles
                    // Represent point + multiplication scalar in 3 consecutive blocks of memory
                    // Store \sigma_i^{-c} at 0x1a0:0x200
                    // Store \gamma_i^{k} at 0x120:0x160
                    // Store h^{a} at 0x160:0x1a0
                    let result := staticcall(gas, 7, 0xe0, 0x60, 0x1a0, 0x40)
                    result := and(result, staticcall(gas, 7, 0x20, 0x60, 0x120, 0x40))
                    result := and(result, staticcall(gas, 7, 0x80, 0x60, 0x160, 0x40))

                    // Call bn128 group addition precompiles
                    // \gamma_i^{k} and h^{a} in memory block 0x120:0x1a0
                    // Store result of addition at 0x160:0x1a0
                    result := and(result, staticcall(gas, 6, 0x120, 0x80, 0x160, 0x40))

                    // \gamma_i^{k}h^{a} and \sigma^{-c} in memory block 0x160:0x1e0
                    // Store resulting point B at memory index b
                    result := and(result, staticcall(gas, 6, 0x160, 0x80, b, 0x40))
                    
                    if eq(i, 0) { // m = 0
                        mstore(0x260, mload(0x20))
                        mstore(0x280, mload(0x40))
                        mstore(0x1e0, mload(0xe0))
                        mstore(
                            0x200,
                            sub(0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47, mload(0x100))
                            )
                    }

                    // If i > m + 1 (i.e. subsequent output notes)
                    // then we add \sigma^{-c} and \sigma_{acc} and store result at \sigma_{acc} (0x1e0:0x200)
                    // we then calculate \gamma^{cx} and add into \gamma_{acc}
                    if gt(i, 0) {  // performing bilinear pairing comparison on all notes
                        mstore(0x60, c)

                        result := and(
                            result,
                            and(
                                and(
                                    staticcall(gas, 6, 0x1a0, 0x80, 0x1e0, 0x40),
                                    staticcall(gas, 6, 0x220, 0x80, 0x260, 0x40)
                                ),
                                staticcall(gas, 7, 0x20, 0x60, 0x220, 0x40)
                            )
                        )
                    }

                    // throw transaction if any calls to precompiled contracts failed
                    if iszero(result) { mstore(0x00, 400) revert(0x00, 0x20) }
                    b := add(b, 0x40) // increase B pointer by 2 words
                }

                validatePairing(0x84)

                // We now have the note commitments and the calculated blinding factors in a block of memory
                // starting at 0x2a0, of size (b - 0x2a0).
                // Hash this block to reconstruct the initial challenge and validate that they match
                let expected := mod(keccak256(0x2a0, sub(b, 0x2a0)), gen_order)

                if iszero(eq(expected, challenge)) {

                    // No! Bad! No soup for you!
                    mstore(0x00, 404)
                    revert(0x00, 0x20)
                }

                // Great! All done. This is a valid proof, so fall through out of the assembly block
                // so that we can call `PrivateRangeABIEncoder.encodeAndExit`
            }

            /**        
             * @dev evaluate if e(P1, t2) . e(P2, g2) == 0.
             * @notice we don't hard-code t2 so that contracts that call this library can use
             * different trusted setups.
             **/
            function validatePairing(t2) {
                let field_order := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
                let t2_x_1 := calldataload(t2)
                let t2_x_2 := calldataload(add(t2, 0x20))
                let t2_y_1 := calldataload(add(t2, 0x40))
                let t2_y_2 := calldataload(add(t2, 0x60))

                // check provided setup pubkey is not zero or g2
                if or(or(or(or(or(or(or(
                    iszero(t2_x_1),
                    iszero(t2_x_2)),
                    iszero(t2_y_1)),
                    iszero(t2_y_2)),
                    eq(t2_x_1, 0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed)),
                    eq(t2_x_2, 0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2)),
                    eq(t2_y_1, 0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa)),
                    eq(t2_y_2, 0x90689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b))
                {
                    mstore(0x00, 400)
                    revert(0x00, 0x20)
                }

                // store coords in memory
                // indices are a bit off, scipr lab's libff limb ordering (c0, c1) is opposite
                // to what precompile expects
                // We can overwrite the memory we used previously as this function is called at the
                // end of the validation routine.
                mstore(0x20, mload(0x1e0)) // sigma accumulator x
                mstore(0x40, mload(0x200)) // sigma accumulator y
                mstore(0x80, 0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed)
                mstore(0x60, 0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2)
                mstore(0xc0, 0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa)
                mstore(0xa0, 0x90689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b)
                mstore(0xe0, mload(0x260)) // gamma accumulator x
                mstore(0x100, mload(0x280)) // gamma accumulator y
                mstore(0x140, t2_x_1)
                mstore(0x120, t2_x_2)
                mstore(0x180, t2_y_1)
                mstore(0x160, t2_y_2)

                let success := staticcall(gas, 8, 0x20, 0x180, 0x20, 0x20)

                if or(iszero(success), iszero(mload(0x20))) {
                    mstore(0x00, 400)
                    revert(0x00, 0x20)
                }
            }

            /**
             * @dev check that this note's points are on the altbn128 curve(y^2 = x^3 + 3)
             * and that signatures 'k' and 'a' are modulo the order of the curve.
             * Transaction throws if this is not the case.
             * @param note the calldata loation of the note
             **/
            function validateCommitment(note, k, a) {
                let gen_order := 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001
                let field_order := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
                let gammaX := calldataload(add(note, 0x40))
                let gammaY := calldataload(add(note, 0x60))
                let sigmaX := calldataload(add(note, 0x80))
                let sigmaY := calldataload(add(note, 0xa0))
                if iszero(
                    and(
                        and(
                        and(
                            eq(mod(a, gen_order), a), // a is modulo generator order?
                            gt(a, 1)                  // can't be 0 or 1 either!
                        ),
                        and(
                            eq(mod(k, gen_order), k), // k is modulo generator order?
                            gt(k, 1)                  // and not 0 or 1
                        )
                        ),
                        and(
                        eq( // y^2 ?= x^3 + 3
                            addmod(
                                mulmod(mulmod(sigmaX, sigmaX, field_order), sigmaX, field_order),
                                3,
                                field_order
                            ),
                            mulmod(sigmaY, sigmaY, field_order)
                        ),
                        eq( // y^2 ?= x^3 + 3
                            addmod(
                                mulmod(mulmod(gammaX, gammaX, field_order), gammaX, field_order),
                                3,
                                field_order
                            ),
                            mulmod(gammaY, gammaY, field_order)
                        )
                        )
                    )
                ) {
                    mstore(0x00, 400)
                    revert(0x00, 0x20)
                }
            }

            /**
             * @dev Calculate the keccak256 hash of the commitments for both input notes and output notes.
             * This is used both as an input to validate the challenge `c` and also to
             * generate pseudorandom relationships
             * between commitments for different outputNotes, so that we can combine them
             * into a single multi-exponentiation for the purposes of validating the bilinear pairing relationships.
             * @param notes calldata location notes
             * @param n number of notes
             **/
            function hashCommitments(notes, n) {
                for { let i := 0 } lt(i, n) { i := add(i, 0x01) } {
                let index := add(add(notes, mul(i, 0xc0)), 0x60)
                calldatacopy(add(0x300, mul(i, 0x80)), index, 0x80)
                }
                mstore(0x00, keccak256(0x300, mul(n, 0x80)))
            }
        }
    
        // if we've reached here, we've validated the private range proof and haven't thrown an error.
        // Encode the output according to the ACE standard and exit.
        PrivateRangeABIEncoder.encodeAndExit();
    }
}
