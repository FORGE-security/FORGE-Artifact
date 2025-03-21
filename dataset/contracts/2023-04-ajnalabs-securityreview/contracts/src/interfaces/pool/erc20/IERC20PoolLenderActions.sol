// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

/**
 * @title ERC20 Pool Lender Actions
 */
interface IERC20PoolLenderActions {

    /**
     *  @notice Deposit claimable collateral into a specified bucket.
     *  @param  amount    Amount of collateral to deposit.
     *  @param  index     The bucket index to which collateral will be deposited.
     *  @param  expiry    Timestamp after which this TX will revert, preventing inclusion in a block with unfavorable price.
     *  @return lpbChange The amount of LPs changed for the added collateral.
     */
    function addCollateral(
        uint256 amount,
        uint256 index,
        uint256 expiry
    ) external returns (uint256 lpbChange);
}