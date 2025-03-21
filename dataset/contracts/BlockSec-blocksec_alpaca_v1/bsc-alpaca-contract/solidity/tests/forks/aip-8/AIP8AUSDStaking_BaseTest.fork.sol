// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import { BaseTest, console } from "@tests/base/BaseTest.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { AIP8AUSDStakingLike, UserInfo } from "@tests/interfaces/AIP8AUSDStakingLike.sol";

// solhint-disable contract-name-camelcase
contract AIP8AUSDStaking_BaseForkTest is BaseTest {
  uint256 internal constant WEEK = 7 days;
  uint256 internal constant PID = 25;

  address internal constant FAIR_LAUNCH_ADDRESS = 0xA625AB01B08ce023B2a342Dbb12a16f2C8489A8F;
  address internal constant _ALICE = 0x52Af1571D431842cc16073021bAF700aeAAa8146;
  address internal constant _BOB = 0x7a33e32547602e8bafc6392F4cb8f48918415522;
  address internal constant _CHARLIE = 0x62d51Fa08B15411D9429133aE5F224abf3867729;
  address internal constant _DAVID = 0x922c1a5007E8B091b2a5B12caff5cEFbc9133540;
  address internal constant AUSD3EPS = 0xae70E3f6050d6AB05E03A50c655309C2148615bE;
  address internal constant ALPACA = 0x8F0528cE5eF7B51152A59745bEfDD91D97091d2F;

  AIP8AUSDStakingLike internal aip8AUSDStaking;

  function setUp() external {
    vm.createSelectFork(vm.envString("BSC_MAINNET_RPC"), 18878744);
    aip8AUSDStaking = _setUpAIP8AUSDStaking(FAIR_LAUNCH_ADDRESS, PID);
  }

  function _setUpAIP8AUSDStaking(address _fairlaunch, uint256 _pid) internal returns (AIP8AUSDStakingLike) {
    bytes memory _logicBytecode = abi.encodePacked(vm.getCode("./out/AIP8AUSDStaking.sol/AIP8AUSDStaking.json"));
    bytes memory _initializer = abi.encodeWithSelector(
      bytes4(keccak256("initialize(address,uint256)")),
      _fairlaunch,
      _pid
    );
    address _proxy = _setupUpgradeable(_logicBytecode, _initializer);
    return AIP8AUSDStakingLike(payable(_proxy));
  }

  function _lockFor(address _actor, uint256 _expectedStakingAmount, uint256 _expectedLockUntil) internal {
    vm.startPrank(_actor);
    IERC20Upgradeable(AUSD3EPS).approve(address(aip8AUSDStaking), type(uint256).max);
    aip8AUSDStaking.lock(_expectedStakingAmount, _expectedLockUntil);
    vm.stopPrank();
  }

  function _unlockFor(address _actor) internal {
    vm.startPrank(_actor);
    aip8AUSDStaking.unlock();
    vm.stopPrank();
  }

  function _harvestFor(address _actor) internal {
    vm.startPrank(_actor);
    aip8AUSDStaking.harvest();
    vm.stopPrank();
  }

  function _emergencyWithdrawFor(address _actor) internal {
    vm.startPrank(_actor);
    aip8AUSDStaking.emergencyWithdraw();
    vm.stopPrank();
  }
}
