// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IVault.sol";

import "hardhat/console.sol";

contract DepositApprover is Ownable {
    address public vault;
    address public asset;

    event SetVault(address vault);

    constructor(address _asset) {
        asset = _asset;
    }

    function deposit(uint256 amount) public {
        require(IERC20(asset).balanceOf(msg.sender) >= amount, "INSUFFICIENT_AMOUNT");
        require(IERC20(asset).allowance(msg.sender, address(this)) >= amount, "INSUFFICIENT_ALLOWANCE");

        IERC20(asset).transferFrom(msg.sender, vault, amount);
        IVault(vault).deposit(amount, msg.sender);
    }

    function setVault(address _vault) public onlyOwner {
        require(_vault != address(0), "ZERO_ADDRESS");

        vault = _vault;

        emit SetVault(vault);
    }
}
