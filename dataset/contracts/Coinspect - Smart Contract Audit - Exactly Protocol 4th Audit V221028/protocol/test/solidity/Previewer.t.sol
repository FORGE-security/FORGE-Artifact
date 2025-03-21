// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import { Vm } from "forge-std/Vm.sol";
import { Test } from "forge-std/Test.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { MockERC20 } from "solmate/src/test/utils/mocks/MockERC20.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { FixedPointMathLib } from "solmate/src/utils/FixedPointMathLib.sol";
import { Market, InsufficientProtocolLiquidity } from "../../contracts/Market.sol";
import { InterestRateModel, UtilizationExceeded, AlreadyMatured } from "../../contracts/InterestRateModel.sol";
import { ExactlyOracle, AggregatorV2V3Interface } from "../../contracts/ExactlyOracle.sol";
import { Auditor, InsufficientAccountLiquidity } from "../../contracts/Auditor.sol";
import { MockPriceFeed } from "../../contracts/mocks/MockPriceFeed.sol";
import { Previewer } from "../../contracts/periphery/Previewer.sol";
import { FixedLib } from "../../contracts/utils/FixedLib.sol";

contract PreviewerTest is Test {
  using FixedPointMathLib for uint256;
  using FixedPointMathLib for int256;

  address internal constant BOB = address(69);
  address internal constant ALICE = address(70);

  Market internal market;
  Auditor internal auditor;
  MockERC20 internal asset;
  Previewer internal previewer;
  ExactlyOracle internal oracle;
  InterestRateModel internal irm;

  function setUp() external {
    asset = new MockERC20("DAI", "DAI", 18);
    oracle = new ExactlyOracle();

    auditor = Auditor(address(new ERC1967Proxy(address(new Auditor()), "")));
    auditor.initialize(ExactlyOracle(address(oracle)), Auditor.LiquidationIncentive(0.09e18, 0.01e18));

    irm = new InterestRateModel(0.72e18, -0.22e18, 1.1e18, 0.72e18, -0.22e18, 1.1e18);

    market = Market(address(new ERC1967Proxy(address(new Market(asset, auditor)), "")));
    market.initialize(12, 1e18, irm, 0.02e18 / uint256(1 days), 0.1e18, 0, 0.0046e18, 0.42e18);
    auditor.enableMarket(market, 0.8e18, 18);
    oracle.setPriceFeed(market, AggregatorV2V3Interface(address(new MockPriceFeed(1e8))));

    vm.label(BOB, "Bob");
    vm.label(ALICE, "Alice");
    asset.mint(BOB, 50_000 ether);
    asset.mint(ALICE, 50_000 ether);
    asset.mint(address(this), 50_000 ether);
    asset.approve(address(market), 50_000 ether);
    vm.prank(BOB);
    asset.approve(address(market), 50_000 ether);
    vm.prank(ALICE);
    asset.approve(address(market), 50_000 ether);

    previewer = new Previewer(auditor);
  }

  function testPreviewDepositAtMaturityReturningAccurateAmount() external {
    uint256 maturity = FixedLib.INTERVAL;
    market.deposit(10 ether, address(this));
    vm.warp(200 seconds);
    market.borrowAtMaturity(maturity, 1 ether, 2 ether, address(this), address(this));

    vm.warp(3 days);
    Previewer.FixedPreview memory preview;
    preview = previewer.previewDepositAtMaturity(market, maturity, 1 ether);
    market.depositAtMaturity(maturity, 1 ether, 1 ether, address(this));
    (uint256 principalAfterDeposit, uint256 earningsAfterDeposit) = market.fixedDepositPositions(
      maturity,
      address(this)
    );

    assertEq(preview.assets, principalAfterDeposit + earningsAfterDeposit);
  }

  function testPreviewDepositAtAllMaturitiesReturningAccurateAmounts() external {
    uint256 firstMaturity = FixedLib.INTERVAL;
    uint256 secondMaturity = FixedLib.INTERVAL * 2;
    uint256 thirdMaturity = FixedLib.INTERVAL * 3;
    market.deposit(10 ether, address(this));
    vm.warp(200 seconds);
    market.borrowAtMaturity(firstMaturity, 1 ether, 2 ether, address(this), address(this));

    vm.warp(500 seconds);
    market.borrowAtMaturity(secondMaturity, 0.389 ether, 1 ether, address(this), address(this));

    vm.warp(1 days);
    market.borrowAtMaturity(thirdMaturity, 2.31 ether, 3 ether, address(this), address(this));

    vm.warp(2 days + 3 hours);
    market.depositAtMaturity(thirdMaturity, 1.1 ether, 1.1 ether, BOB);

    vm.warp(3 days);
    Previewer.FixedPreview[] memory positionAssetsMaturities = previewer.previewDepositAtAllMaturities(market, 1 ether);

    market.depositAtMaturity(firstMaturity, 1 ether, 1 ether, address(this));
    (uint256 principalAfterDeposit, uint256 earningsAfterDeposit) = market.fixedDepositPositions(
      firstMaturity,
      address(this)
    );
    assertEq(positionAssetsMaturities[0].maturity, firstMaturity);
    assertEq(positionAssetsMaturities[0].assets, principalAfterDeposit + earningsAfterDeposit);

    market.depositAtMaturity(secondMaturity, 1 ether, 1 ether, address(this));
    (principalAfterDeposit, earningsAfterDeposit) = market.fixedDepositPositions(secondMaturity, address(this));
    assertEq(positionAssetsMaturities[1].maturity, secondMaturity);
    assertEq(positionAssetsMaturities[1].assets, principalAfterDeposit + earningsAfterDeposit);

    positionAssetsMaturities = previewer.previewDepositAtAllMaturities(market, 0.18239 ether);
    market.depositAtMaturity(thirdMaturity, 0.18239 ether, 0.18239 ether, address(this));
    (principalAfterDeposit, earningsAfterDeposit) = market.fixedDepositPositions(thirdMaturity, address(this));
    assertEq(positionAssetsMaturities[2].maturity, thirdMaturity);
    assertEq(positionAssetsMaturities[2].assets, principalAfterDeposit + earningsAfterDeposit);
  }

  function testPreviewDepositAtMaturityWithZeroAmount() external {
    uint256 maturity = FixedLib.INTERVAL;
    market.deposit(10 ether, address(this));
    vm.warp(120 seconds);
    market.borrowAtMaturity(maturity, 1 ether, 2 ether, address(this), address(this));

    vm.warp(3 days);
    Previewer.FixedPreview memory preview;
    preview = previewer.previewDepositAtMaturity(market, maturity, 0);

    assertEq(preview.assets, 0);
  }

  function testPreviewDepositAtMaturityWithOneUnit() external {
    uint256 maturity = FixedLib.INTERVAL;
    market.deposit(10 ether, address(this));
    vm.warp(120 seconds);
    market.borrowAtMaturity(maturity, 1 ether, 2 ether, address(this), address(this));

    vm.warp(3 days);
    Previewer.FixedPreview memory preview;
    preview = previewer.previewDepositAtMaturity(market, maturity, 1);

    assertEq(preview.assets, 1);
  }

  function testPreviewDepositAtMaturityReturningAccurateAmountWithIntermediateOperations() external {
    uint256 maturity = FixedLib.INTERVAL;
    market.deposit(10 ether, address(this));
    vm.warp(150 seconds);
    market.borrowAtMaturity(maturity, 1 ether, 2 ether, address(this), address(this));

    vm.warp(2 days);
    market.borrowAtMaturity(maturity, 2.3 ether, 3 ether, address(this), address(this));

    vm.warp(3 days);
    Previewer.FixedPreview memory preview;
    preview = previewer.previewDepositAtMaturity(market, maturity, 0.47 ether);
    market.depositAtMaturity(maturity, 0.47 ether, 0.47 ether, address(this));
    (uint256 principalAfterDeposit, uint256 earningsAfterDeposit) = market.fixedDepositPositions(
      maturity,
      address(this)
    );
    assertEq(preview.assets, principalAfterDeposit + earningsAfterDeposit);

    vm.warp(5 days);
    preview = previewer.previewDepositAtMaturity(market, maturity, 1 ether);
    market.depositAtMaturity(maturity, 1 ether, 1 ether, BOB);
    (principalAfterDeposit, earningsAfterDeposit) = market.fixedDepositPositions(maturity, BOB);
    assertEq(preview.assets, principalAfterDeposit + earningsAfterDeposit);

    vm.warp(6 days);
    preview = previewer.previewDepositAtMaturity(market, maturity, 20 ether);
    market.depositAtMaturity(maturity, 20 ether, 20 ether, ALICE);
    (principalAfterDeposit, earningsAfterDeposit) = market.fixedDepositPositions(maturity, ALICE);
    assertEq(preview.assets, principalAfterDeposit + earningsAfterDeposit);
  }

  function testPreviewDepositAtMaturityWithEmptyMaturity() external {
    Previewer.FixedPreview memory preview;
    preview = previewer.previewDepositAtMaturity(market, FixedLib.INTERVAL, 1 ether);
    assertEq(preview.assets, 1 ether);
  }

  function testPreviewDepositAtMaturityWithEmptyMaturityAndZeroAmount() external {
    Previewer.FixedPreview memory preview;
    preview = previewer.previewDepositAtMaturity(market, FixedLib.INTERVAL, 0);
    assertEq(preview.assets, 0);
  }

  function testPreviewDepositAtMaturityWithInvalidMaturity() external {
    Previewer.FixedPreview memory preview;
    preview = previewer.previewDepositAtMaturity(market, 376 seconds, 1 ether);
    assertEq(preview.assets, 1 ether);
  }

  function testPreviewDepositAtMaturityWithSameTimestamp() external {
    uint256 maturity = FixedLib.INTERVAL;
    vm.warp(maturity);
    Previewer.FixedPreview memory preview;
    preview = previewer.previewDepositAtMaturity(market, maturity, 1 ether);
    assertEq(preview.assets, 1 ether);
  }

  function testPreviewDepositAtMaturityWithMaturedMaturity() external {
    uint256 maturity = FixedLib.INTERVAL;
    vm.warp(maturity + 1);
    vm.expectRevert(AlreadyMatured.selector);
    previewer.previewDepositAtMaturity(market, maturity, 1 ether);
  }

  function testPreviewBorrowAtMaturityReturningAccurateAmount() external {
    uint256 maturity = FixedLib.INTERVAL;
    market.deposit(10 ether, address(this));
    vm.warp(180 seconds);
    Previewer.FixedPreview memory preview;
    preview = previewer.previewBorrowAtMaturity(market, maturity, 1 ether);
    market.borrowAtMaturity(maturity, 1 ether, 2 ether, address(this), address(this));
    (uint256 principalAfterBorrow, uint256 feesAfterBorrow) = market.fixedBorrowPositions(maturity, address(this));

    assertEq(preview.assets, principalAfterBorrow + feesAfterBorrow);
  }

  function testPreviewBorrowAtMaturityReturningAccurateUtilization() external {
    uint256 maturity = FixedLib.INTERVAL;
    market.deposit(10 ether, address(this));
    vm.warp(180 seconds);
    Previewer.FixedPreview memory preview;
    preview = previewer.previewBorrowAtMaturity(market, maturity, 1 ether);
    assertEq(preview.utilization, uint256(1 ether).divWadUp(previewFloatingAssetsAverage()));

    market.depositAtMaturity(maturity, 1.47 ether, 1.47 ether, address(this));
    vm.warp(5301 seconds);
    preview = previewer.previewBorrowAtMaturity(market, maturity, 2.33 ether);

    assertEq(preview.utilization, uint256(2.33 ether).divWadUp(1.47 ether + previewFloatingAssetsAverage()));
  }

  function testPreviewBorrowAtMaturityWithZeroAmount() external {
    market.deposit(10 ether, address(this));
    vm.warp(5 seconds);
    Previewer.FixedPreview memory preview;
    preview = previewer.previewBorrowAtMaturity(market, FixedLib.INTERVAL, 0);
    assertEq(preview.assets, 0);
  }

  function testPreviewBorrowAtMaturityWithOneUnit() external {
    market.deposit(5 ether, address(this));
    vm.warp(100 seconds);
    market.deposit(5 ether, address(this));
    Previewer.FixedPreview memory preview;
    preview = previewer.previewBorrowAtMaturity(market, FixedLib.INTERVAL, 1);
    assertEq(preview.assets, 1);
  }

  function testPreviewBorrowAtMaturityWithFiveUnits() external {
    market.deposit(5 ether, address(this));
    vm.warp(100 seconds);
    market.deposit(5 ether, address(this));
    Previewer.FixedPreview memory preview;
    preview = previewer.previewBorrowAtMaturity(market, FixedLib.INTERVAL, 5);
    assertEq(preview.assets, 5);
  }

  function testPreviewBorrowAtMaturityReturningAccurateAmountWithIntermediateOperations() external {
    uint256 maturity = FixedLib.INTERVAL;
    market.deposit(10 ether, address(this));
    market.deposit(10 ether, BOB);
    market.deposit(50 ether, ALICE);

    vm.warp(2 days);
    Previewer.FixedPreview memory preview;
    preview = previewer.previewBorrowAtMaturity(market, maturity, 2.3 ether);
    market.borrowAtMaturity(maturity, 2.3 ether, 3 ether, address(this), address(this));
    (uint256 principalAfterBorrow, uint256 feesAfterBorrow) = market.fixedBorrowPositions(maturity, address(this));
    assertEq(preview.assets, principalAfterBorrow + feesAfterBorrow);

    vm.warp(3 days);
    market.depositAtMaturity(maturity, 1.47 ether, 1.47 ether, address(this));

    vm.warp(5 days);
    preview = previewer.previewBorrowAtMaturity(market, maturity, 1 ether);
    vm.prank(BOB);
    market.borrowAtMaturity(maturity, 1 ether, 2 ether, BOB, BOB);
    (principalAfterBorrow, feesAfterBorrow) = market.fixedBorrowPositions(maturity, BOB);
    assertEq(preview.assets, principalAfterBorrow + feesAfterBorrow);

    vm.warp(6 days);
    preview = previewer.previewBorrowAtMaturity(market, maturity, 20 ether);
    vm.prank(ALICE);
    market.borrowAtMaturity(maturity, 20 ether, 30 ether, ALICE, ALICE);
    (principalAfterBorrow, feesAfterBorrow) = market.fixedBorrowPositions(maturity, ALICE);
    assertEq(preview.assets, principalAfterBorrow + feesAfterBorrow);
  }

  function testPreviewBorrowAtMaturityWithInvalidMaturity() external {
    market.deposit(10 ether, address(this));
    vm.warp(100 seconds);
    Previewer.FixedPreview memory preview;
    preview = previewer.previewBorrowAtMaturity(market, 376 seconds, 1 ether);
    assertGe(preview.assets, 1 ether);
  }

  function testPreviewBorrowAtMaturityWithSameTimestamp() external {
    uint256 maturity = FixedLib.INTERVAL;
    vm.warp(maturity);
    vm.expectRevert(AlreadyMatured.selector);
    previewer.previewBorrowAtMaturity(market, maturity, 1 ether);
  }

  function testPreviewBorrowAtMaturityWithMaturedMaturity() external {
    uint256 maturity = FixedLib.INTERVAL;
    vm.warp(maturity + 1);
    vm.expectRevert(AlreadyMatured.selector);
    previewer.previewBorrowAtMaturity(market, maturity, 1 ether);
  }

  function testPreviewRepayAtMaturityReturningAccurateAmount() external {
    uint256 maturity = FixedLib.INTERVAL;
    market.deposit(10 ether, address(this));
    market.deposit(10 ether, BOB);
    vm.warp(300 seconds);
    market.borrowAtMaturity(maturity, 1 ether, 2 ether, address(this), address(this));

    vm.prank(BOB);
    market.borrowAtMaturity(maturity, 2 ether, 3 ether, BOB, BOB);

    vm.warp(3 days);
    uint256 repayAssetsPreviewed = previewer.previewRepayAtMaturity(market, maturity, 1 ether, address(this));
    uint256 balanceBeforeRepay = asset.balanceOf(address(this));
    market.repayAtMaturity(maturity, 1 ether, 1 ether, address(this));
    uint256 discountAfterRepay = 1 ether - (balanceBeforeRepay - asset.balanceOf(address(this)));

    assertEq(repayAssetsPreviewed, 1 ether - discountAfterRepay);
  }

  function testPreviewRepayAtMaturityWithZeroAmount() external {
    uint256 maturity = FixedLib.INTERVAL;
    market.deposit(10 ether, address(this));
    vm.warp(100 seconds);
    market.borrowAtMaturity(maturity, 1 ether, 2 ether, address(this), address(this));

    vm.warp(3 days);
    uint256 repayAssetsPreviewed = previewer.previewRepayAtMaturity(market, maturity, 0, address(this));

    assertEq(repayAssetsPreviewed, 0);
  }

  function testPreviewRepayAtMaturityWithOneUnit() external {
    uint256 maturity = FixedLib.INTERVAL;
    market.deposit(10 ether, address(this));
    vm.warp(100 seconds);
    market.borrowAtMaturity(maturity, 1 ether, 2 ether, address(this), address(this));
    vm.warp(3 days);

    assertEq(previewer.previewRepayAtMaturity(market, maturity, 1, address(this)), 1);
  }

  function testPreviewRepayAtMaturityReturningAccurateAmountWithIntermediateOperations() external {
    uint256 maturity = FixedLib.INTERVAL;
    market.deposit(10 ether, address(this));
    market.deposit(10 ether, BOB);
    vm.warp(200 seconds);
    market.borrowAtMaturity(maturity, 3 ether, 4 ether, address(this), address(this));

    vm.warp(2 days);
    vm.prank(BOB);
    market.borrowAtMaturity(maturity, 2.3 ether, 3 ether, BOB, BOB);

    vm.warp(3 days);
    uint256 repayAssetsPreviewed = previewer.previewRepayAtMaturity(market, maturity, 0.47 ether, address(this));
    uint256 balanceBeforeRepay = asset.balanceOf(address(this));
    market.repayAtMaturity(maturity, 0.47 ether, 0.47 ether, address(this));
    uint256 discountAfterRepay = 0.47 ether - (balanceBeforeRepay - asset.balanceOf(address(this)));
    assertEq(repayAssetsPreviewed, 0.47 ether - discountAfterRepay);

    vm.warp(5 days);
    repayAssetsPreviewed = previewer.previewRepayAtMaturity(market, maturity, 1.1 ether, address(this));
    balanceBeforeRepay = asset.balanceOf(address(this));
    market.repayAtMaturity(maturity, 1.1 ether, 1.1 ether, address(this));
    discountAfterRepay = 1.1 ether - (balanceBeforeRepay - asset.balanceOf(address(this)));
    assertEq(repayAssetsPreviewed, 1.1 ether - discountAfterRepay);

    vm.warp(6 days);
    (uint256 bobOwedPrincipal, uint256 bobOwedFee) = market.fixedBorrowPositions(maturity, BOB);
    uint256 totalOwedBob = bobOwedPrincipal + bobOwedFee;
    repayAssetsPreviewed = previewer.previewRepayAtMaturity(market, maturity, totalOwedBob, BOB);
    balanceBeforeRepay = asset.balanceOf(BOB);
    vm.prank(BOB);
    market.repayAtMaturity(maturity, totalOwedBob, totalOwedBob, BOB);
    discountAfterRepay = totalOwedBob - (balanceBeforeRepay - asset.balanceOf(BOB));
    (bobOwedPrincipal, ) = market.fixedBorrowPositions(maturity, BOB);
    assertEq(repayAssetsPreviewed, totalOwedBob - discountAfterRepay);
    assertEq(bobOwedPrincipal, 0);
  }

  function testFixedPoolsA() external {
    uint256 maxFuturePools = market.maxFuturePools();
    MockERC20 weth = new MockERC20("WETH", "WETH", 18);
    Market marketWETH = Market(address(new ERC1967Proxy(address(new Market(weth, auditor)), "")));
    marketWETH.initialize(12, 1e18, irm, 0.02e18 / uint256(1 days), 0.1e18, 0, 0.0046e18, 0.42e18);
    oracle.setPriceFeed(marketWETH, AggregatorV2V3Interface(address(new MockPriceFeed(2800e8))));
    auditor.enableMarket(marketWETH, 0.7e18, 18);
    weth.mint(address(this), 50_000 ether);
    weth.approve(address(marketWETH), 50_000 ether);
    marketWETH.deposit(50_000 ether, address(this));
    auditor.enterMarket(marketWETH);

    // supply 100 to the smart pool
    market.deposit(100 ether, address(this));
    // let 9011 seconds go by so floatingAssetsAverage is equal to floatingDepositAssets
    vm.warp(9012 seconds);

    // borrow 10 from the first maturity
    market.borrowAtMaturity(FixedLib.INTERVAL, 10 ether, 15 ether, address(this), address(this));
    Previewer.MarketAccount[] memory data = previewer.exactly(address(this));
    for (uint256 i = 0; i < maxFuturePools; i++) {
      // MarketDAI
      assertEq(data[0].fixedPools[i].maturity, FixedLib.INTERVAL + FixedLib.INTERVAL * i);
      assertEq(data[0].fixedPools[i].available, 90 ether);
      // MarketWETH
      assertEq(data[1].fixedPools[i].maturity, FixedLib.INTERVAL + FixedLib.INTERVAL * i);
      assertEq(data[1].fixedPools[i].available, 50_000 ether);
    }

    // deposit 50 ether in the first maturity
    market.depositAtMaturity(FixedLib.INTERVAL, 50 ether, 50 ether, address(this));
    data = previewer.exactly(address(this));
    for (uint256 i = 0; i < maxFuturePools; i++) {
      if (i == 0) assertEq(data[0].fixedPools[i].available, 140 ether);
      else assertEq(data[0].fixedPools[i].available, 100 ether);
    }

    // deposit 100 ether in the second maturity
    market.depositAtMaturity(FixedLib.INTERVAL * 2, 100 ether, 100 ether, address(this));
    data = previewer.exactly(address(this));
    for (uint256 i = 0; i < maxFuturePools; i++) {
      if (i == 0) assertEq(data[0].fixedPools[i].available, 140 ether);
      else if (i == 1) assertEq(data[0].fixedPools[i].available, 200 ether);
      else assertEq(data[0].fixedPools[i].available, 100 ether);
    }
    // try to borrow 140 ether + 1 (ONE UNIT) from first maturity and it should fail
    vm.expectRevert(UtilizationExceeded.selector);
    market.borrowAtMaturity(FixedLib.INTERVAL, 140 ether + 1, 250 ether, address(this), address(this));
    // try to borrow 200 ether + 1 (ONE UNIT) from second maturity and it should fail
    vm.expectRevert(UtilizationExceeded.selector);
    market.borrowAtMaturity(FixedLib.INTERVAL * 2, 200 ether + 1, 250 ether, address(this), address(this));
    // try to borrow 100 ether + 1 (ONE UNIT) from any other maturity and it should fail
    vm.expectRevert(UtilizationExceeded.selector);
    market.borrowAtMaturity(FixedLib.INTERVAL * 7, 100 ether + 1, 250 ether, address(this), address(this));

    // finally borrow 200 ether from second maturity and it doesn't fail
    market.borrowAtMaturity(FixedLib.INTERVAL * 2, 200 ether, 250 ether, address(this), address(this));

    // repay back the 10 borrowed from the first maturity
    uint256 totalBorrowed = data[0].fixedBorrowPositions[0].position.principal +
      data[0].fixedBorrowPositions[0].position.fee;
    market.repayAtMaturity(FixedLib.INTERVAL, totalBorrowed, totalBorrowed, address(this));
    data = previewer.exactly(address(this));
    for (uint256 i = 0; i < maxFuturePools; i++) {
      if (i == 0) assertEq(data[0].fixedPools[i].available, 50 ether);
      else assertEq(data[0].fixedPools[i].available, 0 ether);
    }

    // supply 100 more to the smart pool
    market.deposit(100 ether, address(this));
    uint256 distributedEarnings = 6452799156053692;
    // set the smart pool reserve in 10%
    // since smart pool supply is 200 then 10% is 20
    market.setReserveFactor(0.1e18);
    data = previewer.exactly(address(this));
    for (uint256 i = 0; i < maxFuturePools; i++) {
      if (i == 0) assertEq(data[0].fixedPools[i].available, 80 ether + 50 ether + distributedEarnings);
      else assertEq(data[0].fixedPools[i].available, 80 ether + distributedEarnings);
    }

    // borrow 20 from the flexible borrow pool
    market.borrow(20 ether, address(this), address(this));
    data = previewer.exactly(address(this));
    for (uint256 i = 0; i < maxFuturePools; i++) {
      if (i == 0) assertEq(data[0].fixedPools[i].available, 130 ether + distributedEarnings - 20 ether);
      else assertEq(data[0].fixedPools[i].available, 80 ether + distributedEarnings - 20 ether);
    }
  }

  function testFlexibleAvailableLiquidity() external {
    MockERC20 weth = new MockERC20("WETH", "WETH", 18);
    Market marketWETH = Market(address(new ERC1967Proxy(address(new Market(weth, auditor)), "")));
    marketWETH.initialize(12, 1e18, irm, 0.02e18 / uint256(1 days), 0.1e18, 0, 0.0046e18, 0.42e18);
    oracle.setPriceFeed(marketWETH, AggregatorV2V3Interface(address(new MockPriceFeed(2800e8))));
    auditor.enableMarket(marketWETH, 0.7e18, 18);
    weth.mint(address(this), 50_000 ether);
    weth.approve(address(marketWETH), 50_000 ether);
    marketWETH.deposit(50_000 ether, address(this));
    auditor.enterMarket(marketWETH);

    // supply 100 to the smart pool
    market.deposit(100 ether, address(this));

    // let 9011 seconds go by so floatingAssetsAverage is equal to floatingDepositAssets
    vm.warp(9012 seconds);

    // borrow 10 from the first maturity
    market.borrowAtMaturity(FixedLib.INTERVAL, 10 ether, 15 ether, address(this), address(this));
    Previewer.MarketAccount[] memory data = previewer.exactly(address(this));
    assertEq(data[0].floatingAvailableAssets, 90 ether);

    // deposit 50 ether in the first maturity
    market.depositAtMaturity(FixedLib.INTERVAL, 50 ether, 50 ether, address(this));
    data = previewer.exactly(address(this));
    assertEq(data[0].floatingAvailableAssets, 100 ether);

    // deposit 100 ether in the second maturity
    market.depositAtMaturity(FixedLib.INTERVAL * 2, 100 ether, 100 ether, address(this));
    data = previewer.exactly(address(this));
    assertEq(data[0].floatingAvailableAssets, 100 ether);
    // try to borrow 100 ether + 1 (ONE UNIT) from flexible borrow pool and it should fail
    vm.expectRevert(InsufficientProtocolLiquidity.selector);
    market.borrow(100 ether + 1, address(this), address(this));

    // borrow 100 ether from flexible borrow pool and it doesn't fail
    market.borrow(100 ether, address(this), address(this));

    // repay back the 10 borrowed from the first maturity but liquidity is still 0
    uint256 totalBorrowed = data[0].fixedBorrowPositions[0].position.principal +
      data[0].fixedBorrowPositions[0].position.fee;
    market.repayAtMaturity(FixedLib.INTERVAL, totalBorrowed, totalBorrowed, address(this));
    data = previewer.exactly(address(this));
    assertEq(data[0].floatingAvailableAssets, 0 ether);

    // supply 100 more to the smart pool
    market.deposit(100 ether, address(this));
    uint256 distributedEarnings = 9951196284910;
    // set the smart pool reserve to 10%
    // since smart pool supply is 200 then 10% is 20
    market.setReserveFactor(0.1e18);
    data = previewer.exactly(address(this));
    assertEq(data[0].floatingAvailableAssets, 80 ether + distributedEarnings);
  }

  function testFloatingAvailableLiquidityProjectingNewFloatingDebt() external {
    MockERC20 weth = new MockERC20("WETH", "WETH", 18);
    Market marketWETH = Market(address(new ERC1967Proxy(address(new Market(weth, auditor)), "")));
    marketWETH.initialize(12, 1e18, irm, 0.02e18 / uint256(1 days), 0.1e18, 0, 0.0046e18, 0.42e18);
    oracle.setPriceFeed(marketWETH, AggregatorV2V3Interface(address(new MockPriceFeed(2800e8))));
    auditor.enableMarket(marketWETH, 0.7e18, 18);
    weth.mint(address(this), 50_000 ether);
    weth.approve(address(marketWETH), 50_000 ether);
    marketWETH.deposit(50_000 ether, address(this));
    auditor.enterMarket(marketWETH);
    market.setReserveFactor(0.1e18);

    // supply 100 to the floating pool
    market.deposit(100 ether, address(this));

    // borrow 50 from the floating pool
    market.borrow(50 ether, address(this), address(this));

    Previewer.MarketAccount[] memory data = previewer.exactly(address(this));
    assertEq(data[0].floatingAvailableAssets, 40 ether);

    vm.warp(5 days);
    data = previewer.exactly(address(this));
    // borrowing the available from the floating pool shouldn't fail
    market.borrow(data[0].floatingAvailableAssets, address(this), address(this));
  }

  function testFixedAvailableLiquidityProjectingNewFloatingDebt() external {
    MockERC20 weth = new MockERC20("WETH", "WETH", 18);
    Market marketWETH = Market(address(new ERC1967Proxy(address(new Market(weth, auditor)), "")));
    marketWETH.initialize(12, 1e18, irm, 0.02e18 / uint256(1 days), 0.1e18, 0, 0.0046e18, 0.42e18);
    oracle.setPriceFeed(marketWETH, AggregatorV2V3Interface(address(new MockPriceFeed(2800e8))));
    auditor.enableMarket(marketWETH, 0.7e18, 18);
    weth.mint(address(this), 50_000 ether);
    weth.approve(address(marketWETH), 50_000 ether);
    marketWETH.deposit(50_000 ether, address(this));
    auditor.enterMarket(marketWETH);
    market.setReserveFactor(0.1e18);

    // supply 100 to the floating pool
    market.deposit(100 ether, address(this));

    // let 9012 seconds go by so floatingAssetsAverage is equal to floatingDepositAssets
    vm.warp(9012 seconds);

    // borrow 50 from the floating pool
    market.borrow(50 ether, address(this), address(this));

    // borrow 10 from the first maturity
    market.borrowAtMaturity(FixedLib.INTERVAL, 10 ether, 15 ether, address(this), address(this));
    Previewer.MarketAccount[] memory data = previewer.exactly(address(this));
    assertEq(data[0].floatingAvailableAssets, 30 ether);

    vm.warp(5 days);
    data = previewer.exactly(address(this));
    // borrowing the available from a fixed pool shouldn't fail
    market.borrowAtMaturity(
      FixedLib.INTERVAL,
      data[0].fixedPools[0].available,
      type(uint256).max,
      address(this),
      address(this)
    );
  }

  function testFixedPoolsWithFloatingAssetsAverage() external {
    uint256 maxFuturePools = market.maxFuturePools();
    MockERC20 weth = new MockERC20("WETH", "WETH", 18);
    Market marketWETH = Market(address(new ERC1967Proxy(address(new Market(weth, auditor)), "")));
    marketWETH.initialize(12, 1e18, irm, 0.02e18 / uint256(1 days), 0.1e18, 0, 0.0046e18, 0.42e18);
    oracle.setPriceFeed(marketWETH, AggregatorV2V3Interface(address(new MockPriceFeed(2800e8))));
    auditor.enableMarket(marketWETH, 0.7e18, 18);
    weth.mint(address(this), 50_000 ether);
    weth.approve(address(marketWETH), 50_000 ether);
    marketWETH.deposit(50_000 ether, address(this));
    auditor.enterMarket(marketWETH);

    // supply 100 to the smart pool
    market.deposit(100 ether, address(this));
    // let only 10 seconds go by
    vm.warp(10 seconds);
    uint256 floatingAssetsAverage = previewFloatingAssetsAverage();
    Previewer.MarketAccount[] memory data = previewer.exactly(address(this));
    for (uint256 i = 0; i < maxFuturePools; i++) {
      assertEq(data[0].fixedPools[i].available, floatingAssetsAverage);
    }
    vm.expectRevert(UtilizationExceeded.selector);
    market.borrowAtMaturity(FixedLib.INTERVAL, floatingAssetsAverage + 1, 15 ether, address(this), address(this));

    // borrowing exactly floatingAssetsAverage doesn't revert
    market.borrowAtMaturity(FixedLib.INTERVAL, floatingAssetsAverage, 15 ether, address(this), address(this));

    // after 200 seconds pass there's more available liquidity
    vm.warp(200 seconds);
    floatingAssetsAverage = previewFloatingAssetsAverage();
    data = previewer.exactly(address(this));
    for (uint256 i = 0; i < maxFuturePools; i++) {
      assertEq(data[0].fixedPools[i].available, floatingAssetsAverage);
    }

    // after 1000 seconds the floatingDepositAssets minus the already borrowed is lower than the floatingAssetsAverage
    vm.warp(1000 seconds);
    floatingAssetsAverage = previewFloatingAssetsAverage();
    data = previewer.exactly(address(this));
    uint256 borrowed = data[0].fixedBorrowPositions[0].position.principal;
    for (uint256 i = 0; i < maxFuturePools; i++) {
      assertEq(data[0].fixedPools[i].available, Math.min(market.floatingAssets() - borrowed, floatingAssetsAverage));
    }

    // once floatingAssetsAverage = floatingDepositAssets, withdraw all liquidity available
    borrowed += data[0].fixedBorrowPositions[0].position.fee;
    market.repayAtMaturity(FixedLib.INTERVAL, borrowed, borrowed, address(this));
    uint256 accumulatorBefore = market.earningsAccumulator();
    vm.warp(9012 seconds);
    market.withdraw(market.floatingAssets(), address(this), address(this));

    // one second later floatingAssetsAverage STILL has big positive value but floatingDepositAssets is 0
    // actually the available liquidity is an extra dust distributed by the accumulator
    vm.warp(9013 seconds);
    data = previewer.exactly(address(this));
    for (uint256 i = 0; i < maxFuturePools; i++) {
      assertEq(data[0].fixedPools[i].available, accumulatorBefore - market.earningsAccumulator());
    }
  }

  function testMaxBorrowAssetsCapacity() external {
    market.deposit(100 ether, address(this));
    auditor.enterMarket(market);

    Previewer.MarketAccount[] memory data = previewer.exactly(address(this));
    assertEq(data[0].maxBorrowAssets, 64 ether);
    // try to borrow max assets + 1 unit should revert
    vm.expectRevert(InsufficientAccountLiquidity.selector);
    market.borrow(64 ether + 1, address(this), address(this));

    // once borrowing max assets, capacity should be 0
    market.borrow(64 ether, address(this), address(this));
    data = previewer.exactly(address(this));
    assertEq(data[0].maxBorrowAssets, 0);

    // max borrow assets for BOB should be 0
    data = previewer.exactly(BOB);
    assertEq(data[0].maxBorrowAssets, 0);
  }

  function testMaxBorrowAssetsCapacityForAccountWithShortfall() external {
    MockERC20 weth = new MockERC20("WETH", "WETH", 18);
    Market marketWETH = Market(address(new ERC1967Proxy(address(new Market(weth, auditor)), "")));
    marketWETH.initialize(12, 1e18, irm, 0.02e18 / uint256(1 days), 0.1e18, 0, 0.0046e18, 0.42e18);
    MockPriceFeed wethPriceFeed = new MockPriceFeed(1000e8);
    oracle.setPriceFeed(marketWETH, AggregatorV2V3Interface(address(wethPriceFeed)));
    auditor.enableMarket(marketWETH, 0.7e18, 18);
    weth.mint(address(this), 1 ether);
    weth.approve(address(marketWETH), 1 ether);
    marketWETH.deposit(1 ether, address(this));
    market.deposit(1000 ether, address(this));
    auditor.enterMarket(marketWETH);
    auditor.enterMarket(market);

    market.borrow(1000 ether, address(this), address(this));
    wethPriceFeed.setPrice(100e8);

    // if account has shortfall then max borrow assets should be 0
    (uint256 collateral, uint256 debt) = auditor.accountLiquidity(address(this), Market(address(0)), 0);
    Previewer.MarketAccount[] memory data = previewer.exactly(address(this));
    assertEq(data[0].maxBorrowAssets, 0);
    assertGt(debt, collateral);
  }

  function testMaxBorrowAssetsCapacityPerMarket() external {
    MockERC20 weth = new MockERC20("WETH", "WETH", 18);
    Market marketWETH = Market(address(new ERC1967Proxy(address(new Market(weth, auditor)), "")));
    marketWETH.initialize(12, 1e18, irm, 0.02e18 / uint256(1 days), 0.1e18, 0, 0.0046e18, 0.42e18);
    oracle.setPriceFeed(marketWETH, AggregatorV2V3Interface(address(new MockPriceFeed(1000e8))));
    auditor.enableMarket(marketWETH, 0.7e18, 18);
    weth.mint(address(this), 1 ether);
    weth.approve(address(marketWETH), 1 ether);
    marketWETH.deposit(1 ether, address(this));
    market.deposit(1000 ether, address(this));
    auditor.enterMarket(marketWETH);
    auditor.enterMarket(market);

    // add liquidity as bob
    weth.mint(BOB, 10 ether);
    vm.prank(BOB);
    weth.approve(address(marketWETH), 1_000 ether);
    vm.prank(BOB);
    marketWETH.deposit(10 ether, BOB);
    vm.prank(BOB);
    market.deposit(5000 ether, BOB);

    // dai collateral (1000) * 0.8 = 800
    // eth collateral (1000) * 0.7 = 700
    // 1500 * 0.8 = 1200 (dai)
    // 1500 * 0.7 = 1050 / 1000 = 1.05 (eth)
    Previewer.MarketAccount[] memory data = previewer.exactly(address(this));
    assertEq(data[0].maxBorrowAssets, 1200 ether);
    assertEq(data[1].maxBorrowAssets, 1.05 ether);
    // try to borrow dai max assets + 1 unit should revert
    vm.expectRevert(InsufficientAccountLiquidity.selector);
    market.borrow(1200 ether + 1, address(this), address(this));
    // try to borrow weth max assets + 1 unit should revert
    vm.expectRevert(InsufficientAccountLiquidity.selector);
    marketWETH.borrow(1.05 ether + 1, address(this), address(this));

    // once borrowing max assets, capacity should be 0
    marketWETH.borrow(1.05 ether, address(this), address(this));
    data = previewer.exactly(address(this));
    assertEq(data[0].maxBorrowAssets, 0);
  }

  function testFixedPoolsChangingMaturityInTime() external {
    Previewer.MarketAccount[] memory data = previewer.exactly(address(this));
    assertEq(data[0].fixedPools[0].maturity, FixedLib.INTERVAL);

    // now first maturity is FixedLib.INTERVAL * 2
    vm.warp(FixedLib.INTERVAL);
    data = previewer.exactly(address(this));
    assertEq(data[0].fixedPools[0].maturity, FixedLib.INTERVAL * 2);

    // now first maturity is FixedLib.INTERVAL * 3
    vm.warp(FixedLib.INTERVAL * 2 + 3000);
    data = previewer.exactly(address(this));
    assertEq(data[0].fixedPools[0].maturity, FixedLib.INTERVAL * 3);
  }

  function testPreviewFixedWithUsdAmount() external {
    MockERC20 weth = new MockERC20("WETH", "WETH", 18);
    Market marketWETH = Market(address(new ERC1967Proxy(address(new Market(weth, auditor)), "")));
    marketWETH.initialize(12, 1e18, irm, 0.02e18 / uint256(1 days), 0.1e18, 0, 0.0046e18, 0.42e18);
    oracle.setPriceFeed(marketWETH, AggregatorV2V3Interface(address(new MockPriceFeed(1000e8))));
    auditor.enableMarket(marketWETH, 0.7e18, 18);
    weth.mint(address(this), 1_000 ether);
    weth.approve(address(marketWETH), 1_000 ether);
    marketWETH.deposit(1_000 ether, address(this));
    auditor.enterMarket(marketWETH);
    market.deposit(1_000 ether, address(this));
    vm.warp(200);

    Previewer.FixedMarket[] memory data = previewer.previewFixed(100e18);
    assertEq(address(data[0].market), address(market));
    assertEq(data[0].decimals, asset.decimals());
    assertEq(data[0].assets, 100e18);
    assertEq(data[0].deposits[0].maturity, FixedLib.INTERVAL);
    assertEq(data[0].deposits[0].assets, 100e18);
    assertEq(data[0].borrows[0].maturity, FixedLib.INTERVAL);
    assertGt(data[0].borrows[0].assets, 100e18);
    assertEq(data[0].borrows[1].maturity, FixedLib.INTERVAL * 2);
    assertGt(data[0].borrows[1].assets, 100.5e18);
    assertEq(data[1].decimals, weth.decimals());
    assertEq(data[1].assets, 0.1e18);
    assertEq(data[1].deposits[0].maturity, FixedLib.INTERVAL);
    assertEq(data[1].deposits[0].assets, 0.1e18);
    assertEq(data[1].borrows[0].maturity, FixedLib.INTERVAL);
    assertGt(data[1].borrows[0].assets, 0.1e18);
    assertEq(data[1].borrows[1].maturity, FixedLib.INTERVAL * 2);
    assertGt(data[1].borrows[1].assets, 0.1003e18);
  }

  function testFlexibleBorrowSharesAndAssets() external {
    Previewer.MarketAccount[] memory data = previewer.exactly(address(this));
    assertEq(data[0].floatingBorrowAssets, 0);
    assertEq(data[0].floatingBorrowShares, 0);

    market.deposit(100 ether, address(this));
    market.borrow(10 ether, address(this), address(this));

    data = previewer.exactly(address(this));
    assertEq(data[0].floatingBorrowAssets, 10 ether);
    assertEq(data[0].floatingBorrowShares, 10 ether);

    vm.warp(365 days);
    data = previewer.exactly(address(this));
    assertGt(data[0].floatingBorrowAssets, 10.25 ether);
    assertEq(data[0].floatingBorrowAssets, market.previewDebt(address(this)));
    assertEq(data[0].floatingBorrowShares, 10 ether);

    vm.warp(365 days + 80 days);
    vm.prank(BOB);
    market.deposit(100 ether, BOB);
    vm.prank(BOB);
    market.borrow(10 ether, BOB, BOB);

    vm.warp(365 days + 120 days);
    data = previewer.exactly(address(this));
    assertEq(data[0].floatingBorrowAssets, market.previewDebt(address(this)));
    assertEq(data[0].floatingBorrowShares, 10 ether);

    vm.warp(365 days + 123 days + 7 seconds);
    data = previewer.exactly(BOB);
    (, , uint256 floatingBorrowShares) = market.accounts(BOB);
    assertEq(data[0].floatingBorrowAssets, market.previewDebt(BOB));
    assertEq(data[0].floatingBorrowShares, floatingBorrowShares);
  }

  function testPreviewRepayAtMaturityWithEmptyMaturity() external {
    vm.expectRevert(bytes(""));
    previewer.previewRepayAtMaturity(market, FixedLib.INTERVAL, 1 ether, address(this));
  }

  function testPreviewRepayAtMaturityWithEmptyMaturityAndZeroAmount() external {
    vm.expectRevert(bytes(""));
    previewer.previewRepayAtMaturity(market, FixedLib.INTERVAL, 0, address(this));
  }

  function testPreviewRepayAtMaturityWithInvalidMaturity() external {
    vm.expectRevert(bytes(""));
    previewer.previewRepayAtMaturity(market, 376 seconds, 1 ether, address(this));
  }

  function testPreviewRepayAtMaturityWithSameTimestamp() external {
    uint256 maturity = FixedLib.INTERVAL;
    vm.warp(maturity);

    assertEq(previewer.previewRepayAtMaturity(market, maturity, 1 ether, address(this)), 1 ether);
  }

  function testPreviewRepayAtMaturityWithMaturedMaturity() external {
    uint256 maturity = FixedLib.INTERVAL;
    vm.warp(maturity + 100);
    uint256 penalties = uint256(1 ether).mulWadDown(100 * market.penaltyRate());

    assertEq(previewer.previewRepayAtMaturity(market, maturity, 1 ether, address(this)), 1 ether + penalties);
  }

  function testPreviewWithdrawAtMaturityReturningAccurateAmount() external {
    uint256 maturity = FixedLib.INTERVAL;
    market.depositAtMaturity(maturity, 10 ether, 10 ether, address(this));

    vm.warp(3 days);
    uint256 withdrawAssetsPreviewed = previewer.previewWithdrawAtMaturity(market, maturity, 10 ether);
    uint256 balanceBeforeWithdraw = asset.balanceOf(address(this));
    market.withdrawAtMaturity(maturity, 10 ether, 0.9 ether, address(this), address(this));
    uint256 feeAfterWithdraw = 10 ether - (asset.balanceOf(address(this)) - balanceBeforeWithdraw);

    assertEq(withdrawAssetsPreviewed, 10 ether - feeAfterWithdraw);
  }

  function testPreviewWithdrawAtMaturityWithZeroAmount() external {
    uint256 maturity = FixedLib.INTERVAL;
    market.depositAtMaturity(maturity, 1 ether, 1 ether, address(this));

    vm.warp(3 days);
    assertEq(previewer.previewWithdrawAtMaturity(market, maturity, 0), 0);
  }

  function testPreviewWithdrawAtMaturityWithOneUnit() external {
    uint256 maturity = FixedLib.INTERVAL;
    market.depositAtMaturity(maturity, 1 ether, 1 ether, address(this));

    vm.warp(3 days);
    uint256 feesPreviewed = previewer.previewWithdrawAtMaturity(market, maturity, 1);

    assertEq(feesPreviewed, 1 - 1);
  }

  function testPreviewWithdrawAtMaturityWithFiveUnits() external {
    uint256 maturity = FixedLib.INTERVAL;
    market.depositAtMaturity(maturity, 1 ether, 1 ether, address(this));

    vm.warp(3 days);
    uint256 feesPreviewed = previewer.previewWithdrawAtMaturity(market, maturity, 5);

    assertEq(feesPreviewed, 5 - 1);
  }

  function testPreviewWithdrawAtMaturityReturningAccurateAmountWithIntermediateOperations() external {
    uint256 maturity = FixedLib.INTERVAL;
    market.deposit(10 ether, address(this));
    market.deposit(10 ether, BOB);
    market.depositAtMaturity(maturity, 5 ether, 5 ether, address(this));

    vm.warp(2 days);
    vm.prank(BOB);
    market.borrowAtMaturity(maturity, 2.3 ether, 3 ether, BOB, BOB);

    vm.warp(3 days);
    uint256 withdrawAssetsPreviewed = previewer.previewWithdrawAtMaturity(market, maturity, 0.47 ether);
    uint256 balanceBeforeWithdraw = asset.balanceOf(address(this));
    market.withdrawAtMaturity(maturity, 0.47 ether, 0.4 ether, address(this), address(this));
    uint256 feeAfterWithdraw = 0.47 ether - (asset.balanceOf(address(this)) - balanceBeforeWithdraw);
    assertEq(withdrawAssetsPreviewed, 0.47 ether - feeAfterWithdraw);

    vm.warp(5 days);
    withdrawAssetsPreviewed = previewer.previewWithdrawAtMaturity(market, maturity, 1.1 ether);
    balanceBeforeWithdraw = asset.balanceOf(address(this));
    market.withdrawAtMaturity(maturity, 1.1 ether, 1 ether, address(this), address(this));
    feeAfterWithdraw = 1.1 ether - (asset.balanceOf(address(this)) - balanceBeforeWithdraw);
    assertEq(withdrawAssetsPreviewed, 1.1 ether - feeAfterWithdraw);

    vm.warp(6 days);
    (uint256 contractPositionPrincipal, uint256 contractPositionEarnings) = market.fixedDepositPositions(
      maturity,
      address(this)
    );
    uint256 contractPosition = contractPositionPrincipal + contractPositionEarnings;
    withdrawAssetsPreviewed = previewer.previewWithdrawAtMaturity(market, maturity, contractPosition);
    balanceBeforeWithdraw = asset.balanceOf(address(this));
    market.withdrawAtMaturity(maturity, contractPosition, contractPosition - 1 ether, address(this), address(this));
    feeAfterWithdraw = contractPosition - (asset.balanceOf(address(this)) - balanceBeforeWithdraw);
    (contractPositionPrincipal, ) = market.fixedDepositPositions(maturity, address(this));

    assertEq(withdrawAssetsPreviewed, contractPosition - feeAfterWithdraw);
  }

  function testPreviewWithdrawAtMaturityWithEmptyMaturity() external {
    vm.expectRevert(bytes(""));
    previewer.previewWithdrawAtMaturity(market, FixedLib.INTERVAL, 1 ether);
  }

  function testPreviewWithdrawAtMaturityWithEmptyMaturityAndZeroAmount() external {
    vm.expectRevert(bytes(""));
    previewer.previewWithdrawAtMaturity(market, FixedLib.INTERVAL, 0);
  }

  function testPreviewWithdrawAtMaturityWithInvalidMaturity() external {
    vm.expectRevert(bytes(""));
    previewer.previewWithdrawAtMaturity(market, 376 seconds, 1 ether);
  }

  function testPreviewWithdrawAtMaturityWithSameTimestamp() external {
    uint256 maturity = FixedLib.INTERVAL;
    vm.warp(maturity);

    assertEq(previewer.previewWithdrawAtMaturity(market, maturity, 1 ether), 1 ether);
  }

  function testPreviewWithdrawAtMaturityWithMaturedMaturity() external {
    uint256 maturity = FixedLib.INTERVAL;
    vm.warp(maturity + 1);
    assertEq(previewer.previewWithdrawAtMaturity(market, maturity, 1 ether), 1 ether);
  }

  function testAccountsReturningAccurateAmounts() external {
    market.deposit(10 ether, address(this));
    vm.warp(100 seconds);
    market.borrowAtMaturity(FixedLib.INTERVAL, 1 ether, 2 ether, address(this), address(this));

    Previewer.MarketAccount[] memory data = previewer.exactly(address(this));

    // sum all the collateral prices
    uint256 sumCollateral = data[0]
      .floatingDepositAssets
      .mulDivDown(data[0].oraclePrice, 10**data[0].decimals)
      .mulWadDown(data[0].adjustFactor);

    // sum all the debt
    uint256 sumDebt = (data[0].fixedBorrowPositions[0].position.principal +
      data[0].fixedBorrowPositions[0].position.fee).mulDivDown(data[0].oraclePrice, 10**data[0].decimals).divWadUp(
        data[0].adjustFactor
      );

    (uint256 realCollateral, uint256 realDebt) = auditor.accountLiquidity(address(this), Market(address(0)), 0);

    assertEq(sumCollateral, realCollateral);
    assertEq(sumDebt, realDebt);
  }

  function testAccountsWithIntermediateOperationsReturningAccurateAmounts() external {
    // deploy a new asset for more liquidity combinations
    MockERC20 weth = new MockERC20("WETH", "WETH", 18);
    Market marketWETH = Market(address(new ERC1967Proxy(address(new Market(weth, auditor)), "")));
    marketWETH.initialize(12, 1e18, irm, 0.02e18 / uint256(1 days), 0.1e18, 0, 0.0046e18, 0.42e18);
    oracle.setPriceFeed(marketWETH, AggregatorV2V3Interface(address(new MockPriceFeed(2800e8))));
    auditor.enableMarket(marketWETH, 0.7e18, 18);
    weth.mint(address(this), 50_000 ether);
    weth.approve(address(marketWETH), 50_000 ether);

    market.deposit(10 ether, address(this));
    vm.warp(100 seconds);
    market.borrowAtMaturity(FixedLib.INTERVAL, 1 ether, 2 ether, address(this), address(this));
    market.borrowAtMaturity(FixedLib.INTERVAL, 1.321 ether, 2 ether, address(this), address(this));
    market.deposit(2 ether, address(this));

    Previewer.MarketAccount[] memory data = previewer.exactly(address(this));

    // sum all the collateral prices
    uint256 sumCollateral = data[0]
      .floatingDepositAssets
      .mulDivDown(data[0].oraclePrice, 10**data[0].decimals)
      .mulWadDown(data[0].adjustFactor);

    // sum all the debt
    uint256 sumDebt = (data[0].fixedBorrowPositions[0].position.principal +
      data[0].fixedBorrowPositions[0].position.fee).mulDivUp(data[0].oraclePrice, 10**data[0].decimals).divWadUp(
        data[0].adjustFactor
      );

    (uint256 realCollateral, uint256 realDebt) = auditor.accountLiquidity(address(this), Market(address(0)), 0);
    assertEq(sumCollateral - sumDebt, realCollateral - realDebt);
    assertEq(data[0].isCollateral, true);

    marketWETH.deposit(100 ether, address(this));
    data = previewer.exactly(address(this));
    assertEq(data[1].floatingDepositAssets, 100 ether);
    assertEq(data[1].isCollateral, false);
    assertEq(data.length, 2);

    auditor.enterMarket(marketWETH);
    data = previewer.exactly(address(this));
    sumCollateral += data[1].floatingDepositAssets.mulDivDown(data[1].oraclePrice, 10**data[1].decimals).mulWadDown(
      data[1].adjustFactor
    );
    (realCollateral, realDebt) = auditor.accountLiquidity(address(this), Market(address(0)), 0);
    assertEq(sumCollateral - sumDebt, realCollateral - realDebt);
    assertEq(data[1].isCollateral, true);

    oracle.setPriceFeed(marketWETH, AggregatorV2V3Interface(address(new MockPriceFeed(2800e8))));
    vm.warp(200 seconds);
    marketWETH.borrowAtMaturity(FixedLib.INTERVAL * 2, 33 ether, 40 ether, address(this), address(this));
    data = previewer.exactly(address(this));

    sumCollateral =
      data[0].floatingDepositAssets.mulDivDown(data[0].oraclePrice, 10**data[0].decimals).mulWadDown(
        data[0].adjustFactor
      ) +
      data[1].floatingDepositAssets.mulDivDown(data[1].oraclePrice, 10**data[1].decimals).mulWadDown(
        data[1].adjustFactor
      );

    sumDebt += (data[1].fixedBorrowPositions[0].position.principal + data[1].fixedBorrowPositions[0].position.fee)
      .mulDivDown(data[1].oraclePrice, 10**data[1].decimals)
      .divWadDown(data[1].adjustFactor);

    (realCollateral, realDebt) = auditor.accountLiquidity(address(this), Market(address(0)), 0);
    assertEq(sumCollateral - sumDebt, realCollateral - realDebt);

    oracle.setPriceFeed(marketWETH, AggregatorV2V3Interface(address(new MockPriceFeed(1831e8))));
    data = previewer.exactly(address(this));
    assertEq(data[1].oraclePrice, 1831e18);
  }

  function testAccountsWithAccountThatHasBalances() external {
    market.deposit(10 ether, address(this));
    vm.warp(400 seconds);
    market.borrowAtMaturity(FixedLib.INTERVAL, 1 ether, 2 ether, address(this), address(this));
    market.depositAtMaturity(FixedLib.INTERVAL, 1 ether, 1 ether, address(this));
    market.borrowAtMaturity(FixedLib.INTERVAL * 2, 2.33 ether, 3 ether, address(this), address(this));
    market.depositAtMaturity(FixedLib.INTERVAL * 2, 1.19 ether, 1.19 ether, address(this));
    (uint256 firstMaturitySupplyPrincipal, uint256 firstMaturitySupplyFee) = market.fixedDepositPositions(
      FixedLib.INTERVAL,
      address(this)
    );
    (uint256 secondMaturitySupplyPrincipal, uint256 secondMaturitySupplyFee) = market.fixedDepositPositions(
      FixedLib.INTERVAL * 2,
      address(this)
    );
    (uint256 firstMaturityBorrowPrincipal, uint256 firstMaturityBorrowFee) = market.fixedBorrowPositions(
      FixedLib.INTERVAL,
      address(this)
    );
    (uint256 secondMaturityBorrowPrincipal, uint256 secondMaturityBorrowFee) = market.fixedBorrowPositions(
      FixedLib.INTERVAL * 2,
      address(this)
    );

    Previewer.MarketAccount[] memory data = previewer.exactly(address(this));

    assertEq(data[0].assetSymbol, "DAI");
    assertEq(data[0].floatingDepositAssets, market.convertToAssets(market.balanceOf(address(this))));
    assertEq(data[0].floatingDepositShares, market.balanceOf(address(this)));

    assertEq(data[0].fixedDepositPositions[0].maturity, FixedLib.INTERVAL);
    assertEq(data[0].fixedDepositPositions[0].position.principal, firstMaturitySupplyPrincipal);
    assertEq(data[0].fixedDepositPositions[0].position.fee, firstMaturitySupplyFee);
    assertEq(data[0].fixedDepositPositions[1].maturity, FixedLib.INTERVAL * 2);
    assertEq(data[0].fixedDepositPositions[1].position.principal, secondMaturitySupplyPrincipal);
    assertEq(data[0].fixedDepositPositions[1].position.fee, secondMaturitySupplyFee);
    assertEq(data[0].fixedDepositPositions.length, 2);
    assertEq(data[0].fixedBorrowPositions[0].maturity, FixedLib.INTERVAL);
    assertEq(data[0].fixedBorrowPositions[0].position.principal, firstMaturityBorrowPrincipal);
    assertEq(data[0].fixedBorrowPositions[0].position.fee, firstMaturityBorrowFee);
    assertEq(data[0].fixedBorrowPositions[1].maturity, FixedLib.INTERVAL * 2);
    assertEq(data[0].fixedBorrowPositions[1].position.principal, secondMaturityBorrowPrincipal);
    assertEq(data[0].fixedBorrowPositions[1].position.fee, secondMaturityBorrowFee);
    assertEq(data[0].fixedBorrowPositions.length, 2);

    assertEq(data[0].oraclePrice, 1e18);
    assertEq(data[0].adjustFactor, 0.8e18);
    assertEq(data[0].penaltyRate, market.penaltyRate());
    assertEq(data[0].decimals, 18);
    assertEq(data[0].maxFuturePools, 12);
    assertEq(data[0].isCollateral, true);
  }

  function testAccountsWithAccountOnlyDeposit() external {
    market.deposit(10 ether, address(this));
    Previewer.MarketAccount[] memory data = previewer.exactly(address(this));

    assertEq(data[0].assetSymbol, "DAI");
    assertEq(data[0].floatingDepositAssets, 10 ether);
    assertEq(data[0].floatingDepositShares, market.convertToShares(10 ether));
    assertEq(data[0].fixedDepositPositions.length, 0);
    assertEq(data[0].fixedBorrowPositions.length, 0);
    assertEq(data[0].oraclePrice, 1e18);
    assertEq(data[0].adjustFactor, 0.8e18);
    assertEq(data[0].decimals, 18);
    assertEq(data[0].maxFuturePools, 12);
    assertEq(data[0].isCollateral, false);
  }

  function testAccountsReturningUtilizationForDifferentMaturities() external {
    market.deposit(10 ether, address(this));

    vm.warp(2113);
    Previewer.MarketAccount[] memory data = previewer.exactly(address(this));

    assertEq(data[0].fixedPools.length, 12);
    assertEq(data[0].fixedPools[0].maturity, FixedLib.INTERVAL);
    assertEq(data[0].fixedPools[0].utilization, 0);
    assertEq(data[0].fixedPools[1].maturity, FixedLib.INTERVAL * 2);
    assertEq(data[0].fixedPools[1].utilization, 0);
    assertEq(data[0].fixedPools[2].maturity, FixedLib.INTERVAL * 3);
    assertEq(data[0].fixedPools[2].utilization, 0);

    vm.warp(3490);
    market.borrowAtMaturity(FixedLib.INTERVAL, 1 ether, 2 ether, address(this), address(this));
    data = previewer.exactly(address(this));

    assertEq(data[0].fixedPools[0].utilization, uint256(1 ether).divWadUp(previewFloatingAssetsAverage()));
    assertEq(data[0].fixedPools[1].utilization, 0);
    assertEq(data[0].fixedPools[2].utilization, 0);

    vm.warp(8491);
    market.borrowAtMaturity(FixedLib.INTERVAL * 2, 0.172 ether, 1 ether, address(this), address(this));
    data = previewer.exactly(address(this));

    assertEq(data[0].fixedPools[0].utilization, uint256(1 ether).divWadUp(previewFloatingAssetsAverage()));
    assertEq(data[0].fixedPools[1].utilization, uint256(0.172 ether).divWadUp(previewFloatingAssetsAverage()));
    assertEq(data[0].fixedPools[2].utilization, 0);

    vm.warp(8999);
    market.borrowAtMaturity(FixedLib.INTERVAL * 3, 1.929 ether, 3 ether, address(this), address(this));
    data = previewer.exactly(address(this));

    assertEq(data[0].fixedPools[0].utilization, uint256(1 ether).divWadUp(previewFloatingAssetsAverage()));
    assertEq(data[0].fixedPools[1].utilization, uint256(0.172 ether).divWadUp(previewFloatingAssetsAverage()));
    assertEq(data[0].fixedPools[2].utilization, uint256(1.929 ether).divWadUp(previewFloatingAssetsAverage()));
  }

  function testAccountsWithEmptyAccount() external {
    Previewer.MarketAccount[] memory data = previewer.exactly(address(this));

    assertEq(data[0].assetSymbol, "DAI");
    assertEq(data[0].floatingDepositAssets, 0);
    assertEq(data[0].floatingDepositShares, 0);
    assertEq(data[0].fixedDepositPositions.length, 0);
    assertEq(data[0].fixedBorrowPositions.length, 0);
    assertEq(data[0].oraclePrice, 1e18);
    assertEq(data[0].adjustFactor, 0.8e18);
    assertEq(data[0].decimals, 18);
    assertEq(data[0].maxFuturePools, 12);
    assertEq(data[0].penaltyRate, market.penaltyRate());
    assertEq(data[0].isCollateral, false);
  }

  function previewFloatingAssetsAverage() internal view returns (uint256) {
    uint256 floatingDepositAssets = market.floatingAssets();
    uint256 floatingAssetsAverage = market.floatingAssetsAverage();
    uint256 dampSpeedFactor = floatingDepositAssets < floatingAssetsAverage
      ? market.dampSpeedDown()
      : market.dampSpeedUp();
    uint256 averageFactor = uint256(
      1e18 - (-int256(dampSpeedFactor * (block.timestamp - market.lastAverageUpdate()))).expWad()
    );

    return floatingAssetsAverage.mulWadDown(1e18 - averageFactor) + averageFactor.mulWadDown(floatingDepositAssets);
  }
}
