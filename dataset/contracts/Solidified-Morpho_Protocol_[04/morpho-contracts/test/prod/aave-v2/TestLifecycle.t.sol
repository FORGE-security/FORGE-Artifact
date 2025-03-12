// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/TestSetup.sol";

contract TestLifecycle is TestSetup {
    using WadRayMath for uint256;

    function _beforeSupply(MarketSideTest memory supply) internal virtual {}

    function _beforeBorrow(MarketSideTest memory borrow) internal virtual {}

    struct MorphoPosition {
        uint256 p2p;
        uint256 pool;
        uint256 total;
    }

    struct MarketSideTest {
        TestMarket market;
        uint256 amount;
        //
        bool p2pDisabled;
        uint256 p2pSupplyDelta;
        uint256 p2pBorrowDelta;
        //
        uint256 morphoPoolSupplyBefore;
        uint256 morphoPoolBorrowBefore;
        uint256 morphoUnderlyingBalanceBefore;
        //
        uint256 p2pSupplyIndex;
        uint256 p2pBorrowIndex;
        uint256 poolSupplyIndex;
        uint256 poolBorrowIndex;
        //
        uint256 scaledP2PBalance;
        uint256 scaledPoolBalance;
        //
        MorphoPosition position;
    }

    function _initMarketSideTest(TestMarket memory _market, uint256 _amount)
        internal
        view
        virtual
        returns (MarketSideTest memory test)
    {
        test.market = _market;

        (, , , , , , test.p2pDisabled) = morpho.market(_market.poolToken);
        (test.p2pSupplyDelta, test.p2pBorrowDelta, , ) = morpho.deltas(_market.poolToken);

        test.morphoPoolSupplyBefore = ERC20(_market.poolToken).balanceOf(address(morpho));
        test.morphoPoolBorrowBefore = ERC20(_market.debtToken).balanceOf(address(morpho));
        test.morphoUnderlyingBalanceBefore = ERC20(_market.underlying).balanceOf(address(morpho));

        test.amount = _amount;
    }

    function _supply(TestMarket memory _market, uint256 _amount)
        internal
        virtual
        returns (MarketSideTest memory supply)
    {
        supply = _initMarketSideTest(_market, _amount);

        _beforeSupply(supply);

        _tip(_market.underlying, address(user), supply.amount);

        user.approve(_market.underlying, supply.amount);
        user.supply(_market.poolToken, address(user), supply.amount);

        supply.p2pSupplyIndex = morpho.p2pSupplyIndex(_market.poolToken);
        supply.p2pBorrowIndex = morpho.p2pBorrowIndex(_market.poolToken);
        (, supply.poolSupplyIndex, supply.poolBorrowIndex) = morpho.poolIndexes(_market.poolToken);

        (supply.scaledP2PBalance, supply.scaledPoolBalance) = morpho.supplyBalanceInOf(
            _market.poolToken,
            address(user)
        );

        supply.position.p2p = supply.scaledP2PBalance.rayMul(supply.p2pSupplyIndex);
        supply.position.pool = supply.scaledPoolBalance.rayMul(supply.poolSupplyIndex);
        supply.position.total = supply.position.p2p + supply.position.pool;
    }

    function _testSupply(MarketSideTest memory supply) internal virtual {
        assertEq(
            ERC20(supply.market.underlying).balanceOf(address(user)),
            0,
            string.concat(supply.market.symbol, " balance after supply")
        );
        assertApproxEqAbs(
            supply.position.total,
            supply.amount,
            2,
            string.concat(supply.market.symbol, " total supply")
        );
        if (supply.p2pDisabled)
            assertEq(
                supply.scaledP2PBalance,
                0,
                string.concat(supply.market.symbol, " borrow delta matched")
            );
        else {
            uint256 underlyingBorrowDelta = supply.p2pBorrowDelta.rayMul(supply.poolBorrowIndex);
            if (underlyingBorrowDelta <= supply.amount)
                assertGe(
                    supply.position.p2p,
                    underlyingBorrowDelta,
                    string.concat(supply.market.symbol, " borrow delta minimum match")
                );
            else
                assertApproxEqAbs(
                    supply.position.p2p,
                    supply.amount,
                    1,
                    string.concat(supply.market.symbol, " borrow delta full match")
                );
        }

        assertEq(
            ERC20(supply.market.underlying).balanceOf(address(morpho)),
            supply.morphoUnderlyingBalanceBefore,
            string.concat(supply.market.symbol, " morpho balance")
        );
        assertApproxEqAbs(
            ERC20(supply.market.poolToken).balanceOf(address(morpho)),
            supply.morphoPoolSupplyBefore + supply.position.pool,
            10,
            string.concat(supply.market.symbol, " morpho pool supply")
        );
        assertApproxEqAbs(
            ERC20(supply.market.debtToken).balanceOf(address(morpho)) + supply.position.p2p,
            supply.morphoPoolBorrowBefore,
            10,
            string.concat(supply.market.symbol, " morpho pool borrow")
        );

        _forward(100_000);

        (supply.position.p2p, supply.position.pool, supply.position.total) = lens
        .getCurrentSupplyBalanceInOf(supply.market.poolToken, address(user));
    }

    function _borrow(TestMarket memory _market, uint256 _amount)
        internal
        virtual
        returns (MarketSideTest memory borrow)
    {
        borrow = _initMarketSideTest(_market, _amount);

        _beforeBorrow(borrow);

        user.borrow(_market.poolToken, borrow.amount);

        borrow.p2pSupplyIndex = morpho.p2pSupplyIndex(_market.poolToken);
        borrow.p2pBorrowIndex = morpho.p2pBorrowIndex(_market.poolToken);
        (, borrow.poolSupplyIndex, borrow.poolBorrowIndex) = morpho.poolIndexes(_market.poolToken);

        (borrow.scaledP2PBalance, borrow.scaledPoolBalance) = morpho.borrowBalanceInOf(
            _market.poolToken,
            address(user)
        );

        borrow.position.p2p = borrow.scaledP2PBalance.rayMul(borrow.p2pBorrowIndex);
        borrow.position.pool = borrow.scaledPoolBalance.rayMul(borrow.poolBorrowIndex);
        borrow.position.total = borrow.position.p2p + borrow.position.pool;
    }

    function _testBorrow(MarketSideTest memory borrow) internal virtual {
        assertEq(
            ERC20(borrow.market.underlying).balanceOf(address(user)),
            borrow.amount,
            string.concat(borrow.market.symbol, " balance after borrow")
        );
        assertApproxEqAbs(
            borrow.position.total,
            borrow.amount,
            2,
            string.concat(borrow.market.symbol, " total borrow")
        );
        if (borrow.p2pDisabled)
            assertEq(
                borrow.scaledP2PBalance,
                0,
                string.concat(borrow.market.symbol, " supply delta matched")
            );
        else {
            uint256 underlyingSupplyDelta = borrow.p2pSupplyDelta.rayMul(borrow.poolSupplyIndex);
            if (underlyingSupplyDelta <= borrow.amount)
                assertGe(
                    borrow.position.p2p,
                    underlyingSupplyDelta,
                    string.concat(borrow.market.symbol, " supply delta minimum match")
                );
            else
                assertApproxEqAbs(
                    borrow.position.p2p,
                    borrow.amount,
                    1,
                    string.concat(borrow.market.symbol, " supply delta full match")
                );
        }

        assertEq(
            ERC20(borrow.market.underlying).balanceOf(address(morpho)),
            borrow.morphoUnderlyingBalanceBefore,
            string.concat(borrow.market.symbol, " morpho borrowed balance")
        );
        assertApproxEqAbs(
            ERC20(borrow.market.poolToken).balanceOf(address(morpho)) + borrow.position.p2p,
            borrow.morphoPoolSupplyBefore,
            2,
            string.concat(borrow.market.symbol, " morpho borrowed pool supply")
        );
        assertApproxEqAbs(
            ERC20(borrow.market.debtToken).balanceOf(address(morpho)),
            borrow.morphoPoolBorrowBefore + borrow.position.pool,
            1,
            string.concat(borrow.market.symbol, " morpho borrowed pool borrow")
        );

        _forward(100_000);

        (borrow.position.p2p, borrow.position.pool, borrow.position.total) = lens
        .getCurrentBorrowBalanceInOf(borrow.market.poolToken, address(user));
    }

    function _repay(MarketSideTest memory borrow) internal virtual {
        (borrow.position.p2p, borrow.position.pool, borrow.position.total) = lens
        .getCurrentBorrowBalanceInOf(borrow.market.poolToken, address(user));

        _tip(
            borrow.market.underlying,
            address(user),
            Math.zeroFloorSub(
                borrow.position.total,
                ERC20(borrow.market.underlying).balanceOf(address(user))
            )
        );
        user.approve(borrow.market.underlying, borrow.position.total);
        user.repay(borrow.market.poolToken, address(user), type(uint256).max);
    }

    function _testRepay(MarketSideTest memory borrow) internal virtual {
        assertApproxEqAbs(
            ERC20(borrow.market.underlying).balanceOf(address(user)),
            0,
            10**(borrow.market.decimals / 2),
            string.concat(borrow.market.symbol, " borrow after repay")
        );

        (borrow.position.p2p, borrow.position.pool, borrow.position.total) = lens
        .getCurrentBorrowBalanceInOf(borrow.market.poolToken, address(user));

        assertEq(
            borrow.position.p2p,
            0,
            string.concat(borrow.market.symbol, " p2p borrow after repay")
        );
        assertEq(
            borrow.position.pool,
            0,
            string.concat(borrow.market.symbol, " pool borrow after repay")
        );
        assertEq(
            borrow.position.total,
            0,
            string.concat(borrow.market.symbol, " total borrow after repay")
        );
    }

    function _withdraw(MarketSideTest memory supply) internal virtual {
        (supply.position.p2p, supply.position.pool, supply.position.total) = lens
        .getCurrentSupplyBalanceInOf(supply.market.poolToken, address(user));

        user.withdraw(supply.market.poolToken, type(uint256).max);
    }

    function _testWithdraw(MarketSideTest memory supply) internal virtual {
        assertApproxEqAbs(
            ERC20(supply.market.underlying).balanceOf(address(user)),
            supply.position.total,
            10**(supply.market.decimals / 2),
            string.concat(supply.market.symbol, " supply after withdraw")
        );

        (supply.position.p2p, supply.position.pool, supply.position.total) = lens
        .getCurrentSupplyBalanceInOf(supply.market.poolToken, address(user));

        assertEq(
            supply.position.p2p,
            0,
            string.concat(supply.market.symbol, " p2p supply after withdraw")
        );
        assertEq(
            supply.position.pool,
            0,
            string.concat(supply.market.symbol, " pool supply after withdraw")
        );
        assertEq(
            supply.position.total,
            0,
            string.concat(supply.market.symbol, " total supply after withdraw")
        );
    }

    function testShouldSupplyBorrowRepayWithdrawAllMarkets(uint96 _amount) public {
        for (
            uint256 supplyMarketIndex;
            supplyMarketIndex < collateralMarkets.length;
            ++supplyMarketIndex
        ) {
            TestMarket memory supplyMarket = collateralMarkets[supplyMarketIndex];

            if (supplyMarket.status.isSupplyPaused) continue;

            for (
                uint256 borrowMarketIndex;
                borrowMarketIndex < borrowableMarkets.length;
                ++borrowMarketIndex
            ) {
                _revert();

                TestMarket memory borrowMarket = borrowableMarkets[borrowMarketIndex];

                uint256 borrowedPrice = oracle.getAssetPrice(borrowMarket.underlying);
                uint256 borrowAmount = _boundBorrowAmount(borrowMarket, _amount, borrowedPrice);
                uint256 supplyAmount = _getMinimumCollateralAmount(
                    borrowAmount,
                    borrowedPrice,
                    borrowMarket.decimals,
                    oracle.getAssetPrice(supplyMarket.underlying),
                    supplyMarket.decimals,
                    supplyMarket.ltv
                ).wadMul(1.01 ether);

                MarketSideTest memory supply = _supply(supplyMarket, supplyAmount);
                _testSupply(supply);

                if (!borrowMarket.status.isBorrowPaused) {
                    MarketSideTest memory borrow = _borrow(borrowMarket, borrowAmount);
                    _testBorrow(borrow);

                    if (!borrowMarket.status.isRepayPaused) {
                        _repay(borrow);
                        _testRepay(borrow);
                    }
                }

                if (supplyMarket.status.isWithdrawPaused) continue;

                _withdraw(supply);
                _testWithdraw(supply);
            }
        }
    }

    function testShouldNotBorrowWithoutEnoughCollateral(uint96 _amount) public {
        for (
            uint256 supplyMarketIndex;
            supplyMarketIndex < collateralMarkets.length;
            ++supplyMarketIndex
        ) {
            TestMarket memory supplyMarket = collateralMarkets[supplyMarketIndex];

            if (supplyMarket.status.isSupplyPaused) continue;

            for (
                uint256 borrowMarketIndex;
                borrowMarketIndex < borrowableMarkets.length;
                ++borrowMarketIndex
            ) {
                _revert();

                TestMarket memory borrowMarket = borrowableMarkets[borrowMarketIndex];

                if (borrowMarket.status.isBorrowPaused) continue;

                uint256 borrowedPrice = oracle.getAssetPrice(borrowMarket.underlying);
                uint256 borrowAmount = _boundBorrowAmount(borrowMarket, _amount, borrowedPrice);
                uint256 supplyAmount = _getMinimumCollateralAmount(
                    borrowAmount,
                    borrowedPrice,
                    borrowMarket.decimals,
                    oracle.getAssetPrice(supplyMarket.underlying),
                    supplyMarket.decimals,
                    supplyMarket.ltv
                ).wadMul(0.95 ether);

                _supply(supplyMarket, supplyAmount);

                vm.expectRevert(EntryPositionsManager.UnauthorisedBorrow.selector);
                user.borrow(borrowMarket.poolToken, borrowAmount);
            }
        }
    }

    function testShouldNotSupplyZeroAmount() public {
        for (uint256 marketIndex; marketIndex < activeMarkets.length; ++marketIndex) {
            vm.expectRevert(PositionsManagerUtils.AmountIsZero.selector);
            user.supply(activeMarkets[marketIndex].poolToken, address(user), 0);
        }
    }

    function testShouldNotSupplyOnBehalfAddressZero(uint96 _amount) public {
        vm.assume(_amount > 0);

        for (uint256 marketIndex; marketIndex < activeMarkets.length; ++marketIndex) {
            vm.expectRevert(PositionsManagerUtils.AddressIsZero.selector);
            user.supply(activeMarkets[marketIndex].poolToken, address(0), _amount);
        }
    }

    function testShouldNotBorrowZeroAmount() public {
        for (uint256 marketIndex; marketIndex < activeMarkets.length; ++marketIndex) {
            vm.expectRevert(PositionsManagerUtils.AmountIsZero.selector);
            user.borrow(activeMarkets[marketIndex].poolToken, 0);
        }
    }

    function testShouldNotRepayZeroAmount() public {
        for (uint256 marketIndex; marketIndex < unpausedMarkets.length; ++marketIndex) {
            vm.expectRevert(PositionsManagerUtils.AmountIsZero.selector);
            user.repay(unpausedMarkets[marketIndex].poolToken, address(user), 0);
        }
    }

    function testShouldNotWithdrawZeroAmount() public {
        for (uint256 marketIndex; marketIndex < activeMarkets.length; ++marketIndex) {
            vm.expectRevert(PositionsManagerUtils.AmountIsZero.selector);
            user.withdraw(activeMarkets[marketIndex].poolToken, 0);
        }
    }

    function testShouldNotWithdrawFromUnenteredMarket(uint96 _amount) public {
        vm.assume(_amount > 0);

        for (uint256 marketIndex; marketIndex < activeMarkets.length; ++marketIndex) {
            TestMarket memory market = activeMarkets[marketIndex];
            if (market.status.isWithdrawPaused) continue; // isWithdrawPaused check is before user-market membership check

            vm.expectRevert(ExitPositionsManager.UserNotMemberOfMarket.selector);
            user.withdraw(market.poolToken, _amount);
        }
    }

    function testShouldNotSupplyWhenPaused(uint96 _amount) public {
        vm.assume(_amount > 0);

        for (uint256 marketIndex; marketIndex < activeMarkets.length; ++marketIndex) {
            TestMarket memory market = activeMarkets[marketIndex];
            if (!market.status.isSupplyPaused) continue;

            vm.expectRevert(EntryPositionsManager.SupplyIsPaused.selector);
            user.supply(market.poolToken, _amount);
        }
    }

    function testShouldNotBorrowWhenPaused(uint96 _amount) public {
        vm.assume(_amount > 0);

        for (uint256 marketIndex; marketIndex < activeMarkets.length; ++marketIndex) {
            TestMarket memory market = activeMarkets[marketIndex];
            if (!market.status.isBorrowPaused) continue;

            vm.expectRevert(EntryPositionsManager.BorrowIsPaused.selector);
            user.borrow(market.poolToken, _amount);
        }
    }

    function testShouldNotRepayWhenPaused(uint96 _amount) public {
        vm.assume(_amount > 0);

        for (uint256 marketIndex; marketIndex < activeMarkets.length; ++marketIndex) {
            TestMarket memory market = activeMarkets[marketIndex];
            if (!market.status.isRepayPaused) continue;

            vm.expectRevert(ExitPositionsManager.RepayIsPaused.selector);
            user.repay(market.poolToken, type(uint256).max);
        }
    }

    function testShouldNotWithdrawWhenPaused(uint96 _amount) public {
        vm.assume(_amount > 0);

        for (uint256 marketIndex; marketIndex < activeMarkets.length; ++marketIndex) {
            TestMarket memory market = activeMarkets[marketIndex];
            if (!market.status.isWithdrawPaused) continue;

            vm.expectRevert(ExitPositionsManager.WithdrawIsPaused.selector);
            user.withdraw(market.poolToken, type(uint256).max);
        }
    }
}
