// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import { InterestRateModel } from "../InterestRateModel.sol";

contract InterestRateModelHarness is InterestRateModel {
  constructor(
    uint256 _curveParameterA,
    int256 _curveParameterB,
    uint256 _maxUtilizationRate,
    uint256 _fullUtilizationRate,
    uint256 _spFeeRate
  ) InterestRateModel(_curveParameterA, _curveParameterB, _maxUtilizationRate, _fullUtilizationRate, _spFeeRate) {} // solhint-disable-line no-empty-blocks, max-line-length

  function internalGetPointInCurve(uint256 utilizationRate) external view returns (uint256) {
    return getPointInCurve(utilizationRate);
  }

  function internalSimpsonIntegrator(uint256 ut, uint256 ut1) external view returns (uint256) {
    return simpsonIntegrator(ut, ut1);
  }

  function internalTrapezoidIntegrator(uint256 ut, uint256 ut1) external view returns (uint256) {
    return trapezoidIntegrator(ut, ut1);
  }

  function internalMidpointIntegrator(uint256 ut, uint256 ut1) external view returns (uint256) {
    return midpointIntegrator(ut, ut1);
  }
}
