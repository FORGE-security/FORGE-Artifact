// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Swap/MesonSwap.sol";
import "./Pools/MesonPools.sol";

contract Meson is MesonSwap, MesonPools {
  constructor(address[] memory supportedTokens) {
    for (uint8 i = 0; i < supportedTokens.length; i++) {
      _addSupportToken(supportedTokens[i], i + 1);
    }
  }
}
