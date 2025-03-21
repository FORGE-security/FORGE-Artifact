// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import { VaultAIP25_BaseTest, VaultAip25, IERC20 } from "@tests/forks/aip-25/VaultAIP25_BaseTest.t.sol";
import { IERC20 } from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

contract VaultAIP25_WithdrawTest is VaultAIP25_BaseTest {
  function testCorrectness_whenAlreadyMigratedAndWithdraw_ShouldWork() external {
    uint256 _aliceShares = 2 ether;
    deal(address(VAULT_BTCB), ALICE, _aliceShares);

    // set vault debt to 0
    setVaultDebtShare(address(VAULT_BTCB), 0);

    // withdraw remaining reserve pool
    vm.startPrank(deployer);
    uint256 _reservePool = VAULT_BTCB.reservePool();
    VAULT_BTCB.withdrawReserve(deployer, _reservePool);
    vm.stopPrank();
    // migrate to moneymarket
    vm.prank(deployer);
    VAULT_BTCB.migrate();

    uint256 totalSupplyBefore = VAULT_BTCB.totalSupply();
    uint256 totalTokenBefore = VAULT_BTCB.totalToken();
    uint256 aliceBTCBBefore = IERC20(VAULT_BTCB.token()).balanceOf(ALICE);

    vm.prank(ALICE);
    VAULT_BTCB.withdraw(_aliceShares);

    uint256 aliceBTCBAfter = IERC20(VAULT_BTCB.token()).balanceOf(ALICE);

    uint256 receivedBTC = aliceBTCBAfter - aliceBTCBBefore;
    uint256 expectedBTC = (_aliceShares * totalTokenBefore) / totalSupplyBefore;
    assertApproxEqAbs(receivedBTC, expectedBTC, 1);
  }

  function testRevert_whenWithdrawBeforeMigrate_ShouldRevert() external {
    // set vault debt to 0
    setVaultDebtShare(address(VAULT_BTCB), 0);

    uint256 _aliceShares = 2 ether;
    deal(address(VAULT_BTCB), ALICE, _aliceShares);

    vm.prank(ALICE);
    vm.expectRevert("!allow");
    VAULT_BTCB.withdraw(_aliceShares);
  }
}
