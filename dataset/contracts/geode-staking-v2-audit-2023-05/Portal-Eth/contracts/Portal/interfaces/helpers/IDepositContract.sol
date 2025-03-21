// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

/** This interface is designed to be compatible with the Vyper version.
 * @notice This is the Ethereum 2.0 deposit contract interface.
 * For more information see the Phase 0 specification under https://github.com/ethereum/eth2.0-specs
 */
interface IDepositContract {
  /**
   * @notice Submit a Phase 0 DepositData object.
   * @param pubkey A BLS12-381 public key.
   * @param withdrawal_credentials Commitment to a public key for withdrawals.
   * @param signature A BLS12-381 signature.
   * @param deposit_data_root The SHA-256 hash of the SSZ-encoded DepositData object.
   *Used as a protection against malformed input.
   */
  function deposit(
    bytes calldata pubkey,
    bytes calldata withdrawal_credentials,
    bytes calldata signature,
    bytes32 deposit_data_root
  ) external payable;
}
