// SPDX-License-Identifier: MIT
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.8.13;

/// @title FakeDeltaWorker : A fake worker used for unit testing
contract FakeDeltaWorker {
  // totalLpWorker();
  uint256 public totalLpBalance;
  // lpToken();
  address public lpToken;

  address public baseToken;

  address public farmingToken;

  constructor(address _lpToken) {
    lpToken = _lpToken;
  }

  function setTotalLpBalance(uint256 _lpBalance) external {
    totalLpBalance = _lpBalance;
  }

  function setBaseToken(address _baseToken) external {
    baseToken = _baseToken;
  }

  function setFarmingToken(address _farmingToken) external {
    farmingToken = _farmingToken;
  }
}
