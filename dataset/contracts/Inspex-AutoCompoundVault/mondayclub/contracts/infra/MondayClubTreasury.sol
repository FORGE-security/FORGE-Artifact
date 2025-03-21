// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MondayClubTreasury is Ownable {
    using SafeERC20 for IERC20;

    function withdrawTokens(address _token, address _to, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function withdrawNative(address payable _to, uint256 _amount) external onlyOwner {
        _to.transfer(_amount);
    }

    receive () external payable {}
}