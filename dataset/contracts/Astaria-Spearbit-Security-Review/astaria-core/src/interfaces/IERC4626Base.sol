pragma solidity ^0.8.16;

import {ITokenBase} from "core/interfaces/ITokenBase.sol";

interface IERC4626Base is ITokenBase {
  function asset() external view returns (address);
}
