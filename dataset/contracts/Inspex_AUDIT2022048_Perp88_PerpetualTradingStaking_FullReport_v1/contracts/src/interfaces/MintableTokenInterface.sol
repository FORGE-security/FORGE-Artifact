// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface MintableTokenInterface is IERC20 {
  function isMinter(address _minter) external view returns (bool);

  function setMinter(address minter, bool allow) external;

  function mint(address to, uint256 amount) external;

  function burn(address to, uint256 amount) external;
}
