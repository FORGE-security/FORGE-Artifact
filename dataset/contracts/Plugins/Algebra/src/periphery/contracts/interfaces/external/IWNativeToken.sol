// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.20;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title Interface for WNativeToken
interface IWNativeToken is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}
