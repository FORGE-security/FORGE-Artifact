// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

import { TestBase } from "../contracts/utilities/TestBase.sol";

import { Address, console  } from "../modules/contract-test-utils/contracts/test.sol";
import { MapleLoan as Loan } from "../modules/loan/contracts/MapleLoan.sol";

contract BalanceOfAssetsTests is TestBase {

    address lp1;
    address lp2;

    function setUp() public override {
        super.setUp();

        lp1 = address(new Address());
        lp2 = address(new Address());
    }

    function test_balanceOfAssets() external {
        depositLiquidity({
            lp:        lp1,
            liquidity: 1_000e6
        });

        assertEq(pool.balanceOfAssets(lp1), 1_000e6);
        assertEq(pool.balanceOfAssets(lp2), 0);

        depositLiquidity({
            lp:        lp2,
            liquidity: 3_000e6
        });

        assertEq(pool.balanceOfAssets(lp1), 1_000e6);
        assertEq(pool.balanceOfAssets(lp2), 3_000e6);

        fundsAsset.mint(address(pool), 4_000e6);  // Double totalAssets

        assertEq(pool.balanceOfAssets(lp1), 2_000e6);
        assertEq(pool.balanceOfAssets(lp2), 6_000e6);
    }

    function testFuzz_balanceOfAssets(uint256 depositAmount1, uint256 depositAmount2, uint256 additionalAmount) external {
        depositAmount1   = constrictToRange(depositAmount1,   1, 1e29);
        depositAmount2   = constrictToRange(depositAmount2,   1, 1e29);
        additionalAmount = constrictToRange(additionalAmount, 1, 1e29);

        uint256 totalDeposits = depositAmount1 + depositAmount2;

        depositLiquidity({
            lp:        lp1,
            liquidity: depositAmount1
        });

        assertEq(pool.balanceOfAssets(lp1), depositAmount1);
        assertEq(pool.balanceOfAssets(lp2), 0);

        depositLiquidity({
            lp:        lp2,
            liquidity: depositAmount2
        });

        assertEq(pool.balanceOfAssets(lp1), depositAmount1);
        assertEq(pool.balanceOfAssets(lp2), depositAmount2);

        fundsAsset.mint(address(pool), additionalAmount);

        assertEq(pool.balanceOfAssets(lp1), depositAmount1 + additionalAmount * depositAmount1 / totalDeposits);
        assertEq(pool.balanceOfAssets(lp2), depositAmount2 + additionalAmount * depositAmount2 / totalDeposits);
    }

}

// TODO: Add fuzz tests for all view function success cases.

contract MaxDepositTests is TestBase {

    address lp1;
    address lp2;

    function setUp() public override {
        _createAccounts();
        _createAssets();
        _createGlobals();
        _createFactories();
        _createAndConfigurePool(1 weeks, 2 days);

        lp1 = address(new Address());
        lp2 = address(new Address());
    }

    function test_maxDeposit_closedPool() external {
        vm.prank(poolDelegate);
        poolManager.setLiquidityCap(1_000e6);

        assertEq(pool.maxDeposit(lp1), 0);
        assertEq(pool.maxDeposit(lp2), 0);

        vm.prank(poolDelegate);
        poolManager.setAllowedLender(lp1, true);

        assertEq(pool.maxDeposit(lp1), 1_000e6);
        assertEq(pool.maxDeposit(lp2), 0);

        vm.prank(poolDelegate);
        poolManager.setOpenToPublic();

        assertEq(pool.maxDeposit(lp1), 1_000e6);
        assertEq(pool.maxDeposit(lp2), 1_000e6);
    }

    function test_maxDeposit_totalAssetsIncrease() external {
        vm.prank(poolDelegate);
        poolManager.setLiquidityCap(1_000e6);

        vm.prank(poolDelegate);
        poolManager.setOpenToPublic();

        assertEq(pool.maxDeposit(lp1), 1_000e6);
        assertEq(pool.maxDeposit(lp2), 1_000e6);

        fundsAsset.mint(address(pool), 400e6);

        assertEq(pool.maxDeposit(lp1), 600e6);
        assertEq(pool.maxDeposit(lp2), 600e6);
    }

    function testFuzz_maxDeposit_totalAssetsIncrease(uint256 liquidityCap, uint256 totalAssets) external {
        liquidityCap = constrictToRange(liquidityCap, 1, 1e29);
        totalAssets  = constrictToRange(totalAssets,  1, 1e29);

        uint256 availableDeposit = liquidityCap > totalAssets ? liquidityCap - totalAssets : 0;

        vm.startPrank(poolDelegate);
        poolManager.setLiquidityCap(liquidityCap);
        poolManager.setOpenToPublic();

        assertEq(pool.maxDeposit(lp1), liquidityCap);
        assertEq(pool.maxDeposit(lp2), liquidityCap);

        fundsAsset.mint(address(pool), totalAssets);

        assertEq(pool.maxDeposit(lp1), availableDeposit);
        assertEq(pool.maxDeposit(lp2), availableDeposit);
    }
}

contract MaxMintTests is TestBase {

    address lp1;
    address lp2;

    function setUp() public override {
        _createAccounts();
        _createAssets();
        _createGlobals();
        _createFactories();
        _createAndConfigurePool(1 weeks, 2 days);

        lp1 = address(new Address());
        lp2 = address(new Address());
    }

    function test_maxMint_closedPool() external {
        vm.prank(poolDelegate);
        poolManager.setLiquidityCap(1_000e6);

        assertEq(pool.maxMint(lp1), 0);
        assertEq(pool.maxMint(lp2), 0);

        vm.prank(poolDelegate);
        poolManager.setAllowedLender(lp1, true);

        assertEq(pool.maxMint(lp1), 1_000e6);
        assertEq(pool.maxMint(lp2), 0);

        vm.prank(poolDelegate);
        poolManager.setOpenToPublic();

        assertEq(pool.maxMint(lp1), 1_000e6);
        assertEq(pool.maxMint(lp2), 1_000e6);
    }

    function test_maxMint_totalAssetsIncrease() external {
        vm.prank(poolDelegate);
        poolManager.setLiquidityCap(1_000e6);

        vm.prank(poolDelegate);
        poolManager.setOpenToPublic();

        assertEq(pool.maxMint(lp1), 1_000e6);
        assertEq(pool.maxMint(lp2), 1_000e6);

        fundsAsset.mint(address(pool), 400e6);

        assertEq(pool.maxMint(lp1), 600e6);
        assertEq(pool.maxMint(lp2), 600e6);
    }

    function testFuzz_maxMint_totalAssetsIncrease(uint256 liquidityCap, uint256 totalAssets) external {
        liquidityCap = constrictToRange(liquidityCap, 1, 1e29);
        totalAssets  = constrictToRange(totalAssets,  1, 1e29);

        uint256 availableDeposit = liquidityCap > totalAssets ? liquidityCap - totalAssets : 0;

        vm.startPrank(poolDelegate);
        poolManager.setLiquidityCap(liquidityCap);
        poolManager.setOpenToPublic();

        assertEq(pool.maxMint(lp1), liquidityCap);
        assertEq(pool.maxMint(lp2), liquidityCap);

        fundsAsset.mint(address(pool), totalAssets);

        assertEq(pool.maxMint(lp1), availableDeposit);
        assertEq(pool.maxMint(lp2), availableDeposit);
    }

    function test_maxMint_exchangeRateGtOne() external {
        vm.startPrank(poolDelegate);
        poolManager.setLiquidityCap(10_000e6);
        poolManager.setOpenToPublic();
        vm.stopPrank();

        depositLiquidity({
            lp:        lp1,
            liquidity: 1_000e6
        });

        assertEq(pool.maxMint(lp1), 9_000e6);
        assertEq(pool.maxMint(lp2), 9_000e6);

        fundsAsset.mint(address(pool), 1_000e6);  // Double totalAssets.

        assertEq(pool.maxMint(lp1), 4_000e6);  // totalAssets = 2000, 8000 of room at 2:1
        assertEq(pool.maxMint(lp2), 4_000e6);
    }

    function testFuzz_maxMint_exchangeRateGtOne(uint256 liquidityCap, uint256 depositAmount, uint256 transferAmount) external {
        liquidityCap   = constrictToRange(liquidityCap,   1, 1e29);
        depositAmount  = constrictToRange(depositAmount,  1, liquidityCap);
        transferAmount = constrictToRange(transferAmount, 1, 1e29);

        vm.startPrank(poolDelegate);
        poolManager.setLiquidityCap(liquidityCap);
        poolManager.setOpenToPublic();
        vm.stopPrank();

        // TODO: Change all depositLiquidity calls to use depositLiquidity(lp1, 1_000e6) pattern.
        depositLiquidity({
            lp:        lp1,
            liquidity: depositAmount
        });

        uint256 availableDeposit = liquidityCap > depositAmount ? liquidityCap - depositAmount : 0;

        assertEq(pool.maxMint(lp1), availableDeposit);
        assertEq(pool.maxMint(lp2), availableDeposit);

        fundsAsset.mint(address(pool), transferAmount);

        uint256 totalAssets = depositAmount + transferAmount;

        availableDeposit = liquidityCap > totalAssets ? liquidityCap - totalAssets : 0;

        assertEq(pool.maxMint(lp1), availableDeposit * depositAmount / totalAssets);
        assertEq(pool.maxMint(lp2), availableDeposit * depositAmount / totalAssets);
    }
}

contract MaxRedeemTests is TestBase {

    address lp1;

    function setUp() public override {
        super.setUp();

        lp1 = address(new Address());
    }

    function test_maxRedeem_noLockedShares_notInExitWindow() external {
        depositLiquidity(lp1, 1_000e6);

        assertEq(pool.balanceOf(lp1), 1_000e6);

        assertTrue(!withdrawalManager.isInExitWindow(lp1));

        assertEq(pool.maxRedeem(lp1), 0);
    }

    function test_maxRedeem_lockedShares_notInExitWindow() external {
        depositLiquidity(lp1, 1_000e6);

        assertEq(pool.balanceOf(lp1), 1_000e6);

        vm.prank(lp1);
        pool.requestRedeem(1_000e6, lp1);

        vm.warp(start + 2 weeks - 1);

        assertTrue(!withdrawalManager.isInExitWindow(lp1));

        assertEq(pool.maxRedeem(lp1), 0);
    }

    function test_maxRedeem_lockedShares_inExitWindow() external {
        depositLiquidity(lp1, 1_000e6);

        assertEq(pool.balanceOf(lp1), 1_000e6);

        vm.prank(lp1);
        uint256 shares = pool.requestRedeem(1_000e6, lp1);

        assertEq(shares, 1_000e6);
        assertEq(pool.maxRedeem(lp1), 0);

        vm.warp(start + 2 weeks);

        assertTrue(withdrawalManager.isInExitWindow(lp1));

        assertEq(pool.maxRedeem(lp1), shares);
    }

}

contract MaxWithdrawTests is TestBase {

    address lp1;

    function setUp() public override {
        super.setUp();

        lp1 = address(new Address());
    }

    function test_maxWithdraw_noLockedShares_notInExitWindow() external {
        depositLiquidity(lp1, 1_000e6);

        assertEq(pool.balanceOf(lp1), 1_000e6);

        assertTrue(!withdrawalManager.isInExitWindow(lp1));

        assertEq(pool.maxWithdraw(lp1), 0);
    }

    function test_maxWithdraw_lockedShares_notInExitWindow() external {
        depositLiquidity(lp1, 1_000e6);

        assertEq(pool.balanceOf(lp1), 1_000e6);

        vm.prank(lp1);
        pool.requestWithdraw(1_000e6, lp1);

        vm.warp(start + 2 weeks - 1);

        assertTrue(!withdrawalManager.isInExitWindow(lp1));

        assertEq(pool.maxWithdraw(lp1), 0);
    }

    function test_maxWithdraw_lockedShares_inExitWindow() external {
        depositLiquidity(lp1, 1_000e6);

        assertEq(pool.balanceOf(lp1), 1_000e6);

        vm.prank(lp1);
        pool.requestWithdraw(1_000e6, lp1);

        assertEq(pool.maxWithdraw(lp1), 0);

        vm.warp(start + 2 weeks);

        assertTrue(withdrawalManager.isInExitWindow(lp1));

        assertEq(pool.maxWithdraw(lp1), 1_000e6);
    }

}

contract PreviewRedeemTests is TestBase {

    address lp1;

    function setUp() public override {
        super.setUp();

        lp1 = address(new Address());
    }

    function test_previewRedeem_invalidShares() external {
        depositLiquidity(lp1, 1_000e6);

        vm.startPrank(lp1);
        pool.requestRedeem(1_000e6, lp1);

        vm.expectRevert("WM:PR:INVALID_SHARES");
        pool.previewRedeem(1);
    }

    function test_previewRedeem_noLockedShares_notInExitWindow() external {
        vm.prank(lp1);
        vm.expectRevert("WM:PR:NO_REQUEST");
        pool.previewRedeem(0);
    }

    function test_previewRedeem_lockedShares_notInExitWindow() external {
        depositLiquidity(lp1, 1_000e6);

        vm.startPrank(lp1);
        pool.requestRedeem(1_000e6, lp1);

        vm.warp(start + 2 weeks - 1);

        vm.expectRevert("WM:PR:NOT_IN_WINDOW");
        pool.previewRedeem(1_000e6);
    }

    function test_previewRedeem_lockedShares_inExitWindow() external {
        depositLiquidity(lp1, 1_000e6);

        vm.startPrank(lp1);
        pool.requestRedeem(1_000e6, lp1);

        vm.warp(start + 2 weeks);

        assertEq(pool.previewRedeem(1_000e6), 1_000e6);
    }

}

contract PreviewWithdrawTests is TestBase {

    address lp1;

    function setUp() public override {
        super.setUp();

        lp1 = address(new Address());
    }

    function test_previewWithdraw_invalidShares_notEnabled() external {
        depositLiquidity(lp1, 1_000e6);

        vm.startPrank(lp1);
        pool.requestWithdraw(1_000e6, lp1);

        vm.expectRevert("WM:PW:NOT_ENABLED");
        pool.previewWithdraw(1);
    }

    function test_previewWithdraw_noLockedShares_notInExitWindow_notEnabled() external {
        depositLiquidity(lp1, 1_000e6);

        vm.prank(lp1);
        vm.expectRevert("WM:PW:NOT_ENABLED");
        pool.previewWithdraw(0);
    }

    function test_previewWithdraw_lockedShares_notInExitWindow_notEnabled() external {
        depositLiquidity(lp1, 1_000e6);

        vm.startPrank(lp1);
        pool.requestWithdraw(1_000e6, lp1);

        vm.warp(start + 2 weeks - 1);

        vm.expectRevert("WM:PW:NOT_ENABLED");
        pool.previewWithdraw(1_000e6);
    }

    function test_previewWithdraw_lockedShares_inExitWindow_notEnabled() external {
        depositLiquidity(lp1, 1_000e6);

        vm.startPrank(lp1);
        pool.requestWithdraw(1_000e6, lp1);

        vm.warp(start + 2 weeks);

        vm.expectRevert("WM:PW:NOT_ENABLED");
        pool.previewWithdraw(1_000e6);
    }

}

contract ConvertToAssetsTests is TestBase {

    address lp1;
    address lp2;
    address lp3;

    function setUp() public override {
        super.setUp();

        lp1 = address(new Address());
        lp2 = address(new Address());
        lp3 = address(new Address());
    }

    function test_convertToAssets_zeroTotalSupply() external {
        assertEq(pool.convertToAssets(1),       1);
        assertEq(pool.convertToAssets(2),       2);
        assertEq(pool.convertToAssets(1_000e6), 1_000e6);
    }

    function test_convertToAssets_singleUser() external {
        depositLiquidity(lp1, 1_000e6);

        assertEq(pool.convertToAssets(1),       1);
        assertEq(pool.convertToAssets(2),       2);
        assertEq(pool.convertToAssets(1_000e6), 1_000e6);
    }

    function test_convertToAssets_multipleUsers() external {
        depositLiquidity(lp1, 1_000e6);
        depositLiquidity(lp2, 1_000e6);
        depositLiquidity(lp3, 1_000e6);

        assertEq(pool.convertToAssets(1),       1);
        assertEq(pool.convertToAssets(2),       2);
        assertEq(pool.convertToAssets(1_000e6), 1_000e6);
    }

    function test_convertToAssets_multipleUsers_changeTotalAssets() external {
        depositLiquidity(lp1, 1_000e6);
        depositLiquidity(lp2, 1_000e6);
        depositLiquidity(lp3, 1_000e6);

        vm.prank(address(pool));
        fundsAsset.transfer(address(0), 1_500e6);  // Simulate loss of 50% of funds

        assertEq(pool.convertToAssets(1),       0);  // Rounds down as expected
        assertEq(pool.convertToAssets(2),       1);
        assertEq(pool.convertToAssets(1_000e6), 500e6);
    }

}

contract ConvertToSharesTests is TestBase {

    address lp1;
    address lp2;
    address lp3;

    function setUp() public override {
        super.setUp();

        lp1 = address(new Address());
        lp2 = address(new Address());
        lp3 = address(new Address());
    }

    function test_convertToShares_zeroTotalSupply() external {
        assertEq(pool.convertToShares(1),       1);
        assertEq(pool.convertToShares(2),       2);
        assertEq(pool.convertToShares(1_000e6), 1_000e6);
    }

    function test_convertToShares_singleUser() external {
        depositLiquidity(lp1, 1_000e6);

        assertEq(pool.convertToShares(1),       1);
        assertEq(pool.convertToShares(2),       2);
        assertEq(pool.convertToShares(1_000e6), 1_000e6);
    }

    function test_convertToShares_multipleUsers() external {
        depositLiquidity(lp1, 1_000e6);
        depositLiquidity(lp2, 1_000e6);
        depositLiquidity(lp3, 1_000e6);

        assertEq(pool.convertToShares(1),       1);
        assertEq(pool.convertToShares(2),       2);
        assertEq(pool.convertToShares(1_000e6), 1_000e6);
    }

    function test_convertToShares_multipleUsers_changeTotalAssets() external {
        depositLiquidity(lp1, 1_000e6);
        depositLiquidity(lp2, 1_000e6);
        depositLiquidity(lp3, 1_000e6);

        vm.prank(address(pool));
        fundsAsset.transfer(address(0), 1_500e6);  // Simulate loss of 50% of funds

        assertEq(pool.convertToShares(1),       2);
        assertEq(pool.convertToShares(2),       4);
        assertEq(pool.convertToShares(1_000e6), 2_000e6);
    }

}

contract PreviewDepositTests is TestBase {

    address lp1;
    address lp2;
    address lp3;

    function setUp() public override {
        super.setUp();

        lp1 = address(new Address());
        lp2 = address(new Address());
        lp3 = address(new Address());
    }

    function test_previewDeposit_zeroTotalSupply() external {
        assertEq(pool.previewDeposit(1),       1);
        assertEq(pool.previewDeposit(2),       2);
        assertEq(pool.previewDeposit(1_000e6), 1_000e6);
    }

    function test_previewDeposit_nonZeroTotalSupply() external {
        depositLiquidity(lp1, 1_000e6);

        assertEq(pool.previewDeposit(1),       1);
        assertEq(pool.previewDeposit(2),       2);
        assertEq(pool.previewDeposit(1_000e6), 1_000e6);
    }

    function test_previewDeposit_multipleUsers() external {
        depositLiquidity(lp1, 1_000e6);
        depositLiquidity(lp2, 1_000e6);
        depositLiquidity(lp3, 1_000e6);

        assertEq(pool.previewDeposit(1),       1);
        assertEq(pool.previewDeposit(2),       2);
        assertEq(pool.previewDeposit(1_000e6), 1_000e6);
    }

    function test_previewDeposit_multipleUsers_changeTotalAssets() external {
        depositLiquidity(lp1, 1_000e6);
        depositLiquidity(lp2, 1_000e6);
        depositLiquidity(lp3, 1_000e6);

        vm.prank(address(pool));
        fundsAsset.transfer(address(0), 1_500e6);  // Simulate loss of 50% of funds

        assertEq(pool.previewDeposit(1),       2);
        assertEq(pool.previewDeposit(2),       4);
        assertEq(pool.previewDeposit(1_000e6), 2_000e6);
    }

}

contract PreviewMintTests is TestBase {

    address lp1;
    address lp2;
    address lp3;

    function setUp() public override {
        super.setUp();

        lp1 = address(new Address());
        lp2 = address(new Address());
        lp3 = address(new Address());
    }

    function test_previewMint_zeroTotalSupply() external {
        assertEq(pool.previewMint(1),       1);
        assertEq(pool.previewMint(2),       2);
        assertEq(pool.previewMint(1_000e6), 1_000e6);
    }

    function test_previewMint_nonZeroTotalSupply() external {
        depositLiquidity(lp1, 1_000e6);

        assertEq(pool.previewMint(1),       1);
        assertEq(pool.previewMint(2),       2);
        assertEq(pool.previewMint(1_000e6), 1_000e6);
    }

    function test_previewMint_multipleUsers() external {
        depositLiquidity(lp1, 1_000e6);
        depositLiquidity(lp2, 1_000e6);
        depositLiquidity(lp3, 1_000e6);

        assertEq(pool.previewMint(1),       1);
        assertEq(pool.previewMint(2),       2);
        assertEq(pool.previewMint(1_000e6), 1_000e6);
    }

    function test_previewMint_multipleUsers_changeTotalAssets() external {
        depositLiquidity(lp1, 1_000e6);
        depositLiquidity(lp2, 1_000e6);
        depositLiquidity(lp3, 1_000e6);

        vm.prank(address(pool));
        fundsAsset.transfer(address(0), 1_500e6);  // Simulate loss of 50% of funds

        assertEq(pool.previewMint(1),       1);  // Rounds up the asset token amount
        assertEq(pool.previewMint(2),       1);
        assertEq(pool.previewMint(1_000e6), 500e6);
    }

}

contract TotalAssetsTests is TestBase {

    address lp1;
    address borrower;
    Loan loan;

    function setUp() public override {
        super.setUp();

        lp1      = address(new Address());
        borrower = address(new Address());

        vm.prank(governor);
        globals.setValidBorrower(borrower, true);

        setupFees({
            delegateOriginationFee:     500e6,
            delegateServiceFee:         300e6,
            delegateManagementFeeRate:  0.02e6,
            platformOriginationFeeRate: 0.001e6,
            platformServiceFeeRate:     0.31536e6,  // 10k after 1m seconds
            platformManagementFeeRate:  0.08e6
        });
    }

    function test_totalAssets_zeroTotalSupply() external {
        assertEq(pool.totalAssets(), 0);
    }

    function test_totalAssets_singleDeposit() external {
        depositLiquidity(lp1, 1_000e6);

        assertEq(pool.totalAssets(), 1_000e6);
    }

    function test_totalAssets_singleLoanFunded() external {
        depositLiquidity(lp1, 1_500_000e6);

        loan = fundAndDrawdownLoan({
            borrower:    borrower,
            termDetails: [uint256(5 days), uint256(ONE_MONTH), uint256(3)],
            amounts:     [uint256(0), uint256(1_500_000e6), uint256(1_000_000e6)],
            rates:       [uint256(0.075e18), uint256(0), uint256(0), uint256(0)]
        });

        assertEq(fundsAsset.balanceOf(address(pool)), 0);  // Funds moved out of pool
        assertEq(pool.totalAssets(),                  1_500_000e6);
    }

    function test_totalAssets_singleLoanFundedWithInterest() external {
        depositLiquidity(lp1, 1_500_000e6);

        loan = fundAndDrawdownLoan({
            borrower:    borrower,
            termDetails: [uint256(5 days), uint256(ONE_MONTH), uint256(3)],
            amounts:     [uint256(0), uint256(1_000_000e6), uint256(1_000_000e6)],
            rates:       [uint256(0.075e18), uint256(0), uint256(0), uint256(0)]
        });

        assertEq(fundsAsset.balanceOf(address(pool)), 500_000e6);  // Funds moved out of pool
        assertEq(pool.totalAssets(),                  1_500_000e6);

        vm.warp(start + ONE_MONTH);

        // +------------+--------+--------+
        // |    POOL    |   PD   |   MT   |
        // +------------+--------+--------+
        // |   500,000  |   500  |    250 |
        // | +   6,250  | + 275  | +  550 | Interest and service fees paid
        // | -     625  | + 125  | +  500 | Management fee distribution
        // | = 505,625  | = 900  | = 1300 |
        // +------------+--------+--------+
        assertEq(pool.totalAssets(), 1_505_624_999999);  // Note: Rounding
    }

    function test_totalAssets_singleLoanFundedWithPayment() external {
        depositLiquidity(lp1, 1_500_000e6);

        loan = fundAndDrawdownLoan({
            borrower:    borrower,
            termDetails: [uint256(5 days), uint256(ONE_MONTH), uint256(3)],
            amounts:     [uint256(0), uint256(1_000_000e6), uint256(1_000_000e6)],
            rates:       [uint256(0.075e18), uint256(0), uint256(0), uint256(0)]
        });

        assertEq(fundsAsset.balanceOf(address(pool)), 500_000e6);  // Funds moved out of pool
        assertEq(pool.totalAssets(),                  1_500_000e6);

        /************************/
        /*** Make 1st Payment ***/
        /************************/

        vm.warp(start + ONE_MONTH);
        makePayment(loan);

        // +------------+--------+--------+
        // |    POOL    |   PD   |   MT   |
        // +------------+--------+--------+
        // |   500,000  |   500  |    250 |
        // | +   6,250  | + 275  | +  550 | Interest and service fees paid
        // | -     625  | + 125  | +  500 | Management fee distribution
        // | = 505,625  | = 900  | = 1300 |
        // +------------+--------+--------+
        assertEq(pool.totalAssets(),                  1_505_625e6);
        assertEq(fundsAsset.balanceOf(address(pool)), 505_625e6);
    }

}
