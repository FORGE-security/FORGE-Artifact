// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import { ERC20HelperContract } from './ERC20DSTestPlus.sol';

import 'src/ERC20Pool.sol';
import 'src/interfaces/pool/commons/IPoolEvents.sol';

contract ERC20PoolLiquidationsSettleTest is ERC20HelperContract {

    address internal _borrower;
    address internal _borrower2;
    address internal _lender;
    address internal _lender1;

    function setUp() external {
        _borrower  = makeAddr("borrower");
        _borrower2 = makeAddr("borrower2");
        _lender    = makeAddr("lender");
        _lender1   = makeAddr("lender1");

        _mintQuoteAndApproveTokens(_lender,  120_000 * 1e18);
        _mintQuoteAndApproveTokens(_lender1, 120_000 * 1e18);

        _mintCollateralAndApproveTokens(_borrower,  4 * 1e18);
        _mintCollateralAndApproveTokens(_borrower2, 1_000 * 1e18);
        _mintCollateralAndApproveTokens(_lender1,   4 * 1e18);

        // Lender adds Quote token accross 5 prices
        _addInitialLiquidity({
            from:   _lender,
            amount: 2_000 * 1e18,
            index:  _i9_91
        });
        _addInitialLiquidity({
            from:   _lender,
            amount: 5_000 * 1e18,
            index:  _i9_81
        });
        _addInitialLiquidity({
            from:   _lender,
            amount: 11_000 * 1e18,
            index:  _i9_72
        });
        _addInitialLiquidity({
            from:   _lender,
            amount: 25_000 * 1e18,
            index:  _i9_62
        });
        _addInitialLiquidity({
            from:   _lender,
            amount: 30_000 * 1e18,
            index:  _i9_52
        });

        // first borrower adds collateral token and borrows
        _pledgeCollateral({
            from:     _borrower,
            borrower: _borrower,
            amount:   2 * 1e18
        });
        _borrow({
            from:       _borrower,
            amount:     19.25 * 1e18,
            indexLimit: _i9_91,
            newLup:     9.917184843435912074 * 1e18
        });

        // second borrower adds collateral token and borrows
        _pledgeCollateral({
            from:     _borrower2,
            borrower: _borrower2,
            amount:   1_000 * 1e18
        });
        _borrow({
            from:       _borrower2,
            amount:     7_980 * 1e18,
            indexLimit: _i9_72,
            newLup:     9.721295865031779605 * 1e18
        });

        /*****************************/
        /*** Assert pre-kick state ***/
        /*****************************/

        _assertPool(
            PoolParams({
                htp:                  9.634254807692307697 * 1e18,
                lup:                  9.721295865031779605 * 1e18,
                poolSize:             73_000 * 1e18,
                pledgedCollateral:    1_002 * 1e18,
                encumberedCollateral: 823.649613971736296163 * 1e18,
                poolDebt:             8_006.941586538461542154 * 1e18,
                actualUtilization:    0,
                targetUtilization:    1e18,
                minDebtAmount:        400.347079326923077108 * 1e18,
                loans:                2,
                maxBorrower:          address(_borrower),
                interestRate:         0.05 * 1e18,
                interestRateUpdate:   _startTime
            })
        );
        _assertBorrower({
            borrower:                  _borrower,
            borrowerDebt:              19.268509615384615394 * 1e18,
            borrowerCollateral:        2 * 1e18,
            borrowert0Np:              10.115967548076923081 * 1e18,
            borrowerCollateralization: 1.009034539679184679 * 1e18
        });
        _assertBorrower({
            borrower:                  _borrower2,
            borrowerDebt:              7_987.673076923076926760 * 1e18,
            borrowerCollateral:        1_000 * 1e18,
            borrowert0Np:              8.471136974495192174 * 1e18,
            borrowerCollateralization: 1.217037273735858713 * 1e18
        });
        _assertReserveAuction({
            reserves:                   7.691586538461542154 * 1e18,
            claimableReserves :         0,
            claimableReservesRemaining: 0,
            auctionPrice:               0,
            timeRemaining:              0
        });

        assertEq(_quote.balanceOf(_lender), 47_000 * 1e18);

    }
    
    function testSettleOnAuctionKicked72HoursAgoAndPartiallyTaken() external tearDown {
        // Borrower2 borrows
        _borrow({
            from:       _borrower2,
            amount:     1_730 * 1e18,
            indexLimit: _i9_72,
            newLup:     9.721295865031779605 * 1e18
        });

        // Skip to make borrower undercollateralized
        skip(100 days);

        _assertAuction(
            AuctionParams({
                borrower:          _borrower2,
                active:            false,
                kicker:            address(0),
                bondSize:          0,
                bondFactor:        0,
                kickTime:          0,
                kickMomp:          0,
                totalBondEscrowed: 0,
                auctionPrice:      0,
                debtInAuction:     0,
                thresholdPrice:    9.853394241979221645 * 1e18,
                neutralPrice:      0
            })
        );
        _assertBorrower({
            borrower:                  _borrower2,
            borrowerDebt:              9_853.394241979221645666 * 1e18,
            borrowerCollateral:        1_000 * 1e18,
            borrowert0Np:              10.307611531622595991 * 1e18,
            borrowerCollateralization: 0.986593617011217057 * 1e18
        });

        _kick({
            from:           _lender,
            borrower:       _borrower2,
            debt:           9_976.561670003961916237 * 1e18,
            collateral:     1_000 * 1e18,
            bond:           98.533942419792216457 * 1e18,
            transferAmount: 98.533942419792216457 * 1e18
        });

        _assertAuction(
            AuctionParams({
                borrower:          _borrower2,
                active:            true,
                kicker:            _lender,
                bondSize:          98.533942419792216457 * 1e18,
                bondFactor:        0.01 * 1e18,
                kickTime:          _startTime + 100 days,
                kickMomp:          9.818751856078723036 * 1e18,
                totalBondEscrowed: 98.533942419792216457 * 1e18,
                auctionPrice:      334.393063846970122880 * 1e18,
                debtInAuction:     9_976.561670003961916237 * 1e18,
                thresholdPrice:    9.976561670003961916 * 1e18,
                neutralPrice:      10.449783245217816340 * 1e18
            })
        );
        _assertBorrower({
            borrower:                  _borrower2,
            borrowerDebt:              9_976.561670003961916237 * 1e18,
            borrowerCollateral:        1_000 * 1e18,
            borrowert0Np:              10.307611531622595991 * 1e18,
            borrowerCollateralization: 0.974413448899967463 * 1e18
        });
        _assertBucket({
            index:        _i9_91,
            lpBalance:    2_000 * 1e18,
            collateral:   0,
            deposit:      2_114.174951097528962000 * 1e18,
            exchangeRate: 1.057087475548764481 * 1e18
        });
        _assertBucket({
            index:        _i9_81,
            lpBalance:    5_000 * 1e18,
            collateral:   0,
            deposit:      5_000 * 1e18,
            exchangeRate: 1 * 1e18
        });
        _assertBucket({
            index:        _i9_72,
            lpBalance:    11_000 * 1e18,
            collateral:   0,
            deposit:      11_000 * 1e18,
            exchangeRate: 1 * 1e18
        });
        _assertBucket({
            index:        _i9_62,
            lpBalance:    25_000 * 1e18,
            collateral:   0,
            deposit:      25_000 * 1e18,
            exchangeRate: 1 * 1e18
        });

        // skip ahead so take can be called on the loan
        skip(10 hours);

        _assertAuction(
            AuctionParams({
                borrower:          _borrower2,
                active:            true,
                kicker:            _lender,
                bondSize:          98.533942419792216457 * 1e18,
                bondFactor:        0.01 * 1e18,
                kickTime:          _startTime + 100 days,
                kickMomp:          9.818751856078723036 * 1e18,
                totalBondEscrowed: 98.533942419792216457 * 1e18,
                auctionPrice:      0.653111452826113536 * 1e18,
                debtInAuction:     9_976.561670003961916237 * 1e18,
                thresholdPrice:    9.977074177773911990 * 1e18,
                neutralPrice:      10.449783245217816340 * 1e18
            })
        );
        _assertBorrower({
            borrower:                  _borrower2,
            borrowerDebt:              9_977.074177773911990381 * 1e18,
            borrowerCollateral:        1_000 * 1e18,
            borrowert0Np:              10.307611531622595991 * 1e18,
            borrowerCollateralization: 0.974363394700228467 * 1e18
        });

        // take partial 800 collateral
        _take({
            from:            _lender,
            borrower:        _borrower2,
            maxCollateral:   800 * 1e18,
            bondChange:      5.224891622608908288 * 1e18,
            givenAmount:     522.489162260890828800 * 1e18,
            collateralTaken: 800 * 1e18,
            isReward:        true
        });

        _assertAuction(
            AuctionParams({
                borrower:          _borrower2,
                active:            true,
                kicker:            _lender,
                bondSize:          103.758834042401124745 * 1e18,
                bondFactor:        0.01 * 1e18,
                kickTime:          _startTime + 100 days,
                kickMomp:          9.818751856078723036 * 1e18,
                totalBondEscrowed: 103.758834042401124745 * 1e18,
                auctionPrice:      0.653111452826113536 * 1e18,
                debtInAuction:     10_158.205099579803908908 * 1e18,
                thresholdPrice:    50.791025497899019544 * 1e18,
                neutralPrice:      10.449783245217816340 * 1e18
            })
        );
        _assertBorrower({
            borrower:                  _borrower2,
            borrowerDebt:              10_158.205099579803908908 * 1e18,
            borrowerCollateral:        200 * 1e18,
            borrowert0Np:              10.307611531622595991 * 1e18,
            borrowerCollateralization: 0.191397904841159446 * 1e18
        });
        _assertBucket({
            index:        _i9_91,
            lpBalance:    2_000 * 1e18,
            collateral:   0,
            deposit:      2_114.310083596998856000 * 1e18,
            exchangeRate: 1.057155041798499428 * 1e18
        });
        _assertBucket({
            index:        _i9_81,
            lpBalance:    5_000 * 1e18,
            collateral:   0,
            deposit:      5_000.319586842611445000 * 1e18,
            exchangeRate: 1.000063917368522289 * 1e18
        });
        _assertBucket({
            index:        _i9_72,
            lpBalance:    11_000 * 1e18,
            collateral:   0,
            deposit:      11_000 * 1e18,
            exchangeRate: 1 * 1e18
        });
        _assertBucket({
            index:        _i9_62,
            lpBalance:    25_000 * 1e18,
            collateral:   0,
            deposit:      25_000 * 1e18,
            exchangeRate: 1 * 1e18
        });

        // settle should affect first 3 buckets, reducing deposit and incrementing collateral
        skip(73 hours);

        _assertBorrower({
            borrower:                  _borrower2,
            borrowerDebt:              10_162.015140830231868753 * 1e18,
            borrowerCollateral:        200 * 1e18,
            borrowert0Np:              10.307611531622595991 * 1e18,
            borrowerCollateralization: 0.191326144082827145 * 1e18
        });
        _assertBucket({
            index:        _i9_91,
            lpBalance:    2_000 * 1e18,
            collateral:   0,
            deposit:      2_114.310083596998856000 * 1e18,
            exchangeRate: 1.057155041798499428 * 1e18
        });

        _settle({
            from:        _lender,
            borrower:    _borrower2,
            maxDepth:    10,
            settledDebt: 10_019.485661146575724663 * 1e18
        });

        _assertAuction(
            AuctionParams({
                borrower:          _borrower2,
                active:            false,
                kicker:            address(0),
                bondSize:          0,
                bondFactor:        0,
                kickTime:          0,
                kickMomp:          0,
                totalBondEscrowed: 103.758834042401124745 * 1e18,
                auctionPrice:      0,
                debtInAuction:     0,
                thresholdPrice:    0,
                neutralPrice:      0
            })
        );
        _assertBorrower({
            borrower:                  _borrower2,
            borrowerDebt:              0,
            borrowerCollateral:        0,
            borrowert0Np:              10.307611531622595991 * 1e18,
            borrowerCollateralization: 1 * 1e18
        });
        _assertBucket({
            index:        _i9_91,
            lpBalance:    2_000 * 1e18,
            collateral:   200 * 1e18,
            deposit:      0,
            exchangeRate: 0.991718484343591207 * 1e18
        });
        _assertBucket({
            index:        _i9_81,
            lpBalance:    0,
            collateral:   0,
            deposit:      0,
            exchangeRate: 1 * 1e18
        });
        _assertBucket({
            index:        _i9_72,
            lpBalance:    11_000 * 1e18,
            collateral:   0,
            deposit:      8_807.241482463513273501 * 1e18,
            exchangeRate: 0.800658316587592116 * 1e18
        });
        _assertBucket({
            index:        _i9_62,
            lpBalance:    25_000 * 1e18,
            collateral:   0,
            deposit:      25_000 * 1e18,
            exchangeRate: 1 * 1e18
        });
        _assertPool(
            PoolParams({
                htp:                  9.771304290202671377 * 1e18,
                lup:                  9.721295865031779605 * 1e18,
                poolSize:             63_807.241482463513273501 * 1e18,
                pledgedCollateral:    2 * 1e18,
                encumberedCollateral: 2.010288427770370775 * 1e18,
                poolDebt:             19.542608580405342754 * 1e18,
                actualUtilization:    68.294962938223935750 * 1e18, // check why
                targetUtilization:    2.940996143103583563 * 1e18,
                minDebtAmount:        1.954260858040534275 * 1e18,
                loans:                1,
                maxBorrower:          address(_borrower),
                interestRate:         0.0495 * 1e18,
                interestRateUpdate:   _startTime + 83 hours + 100 days
            })
        );
    }

    function testSettleOnAuctionKicked72HoursAgo() external tearDown {
        // Borrower2 borrows
        _borrow({
            from:       _borrower2,
            amount:     1_730 * 1e18,
            indexLimit: _i9_72,
            newLup:     9.721295865031779605 * 1e18
        });

        // Skip to make borrower undercollateralized
        skip(100 days);

        _assertAuction(
            AuctionParams({
                borrower:          _borrower2,
                active:            false,
                kicker:            address(0),
                bondSize:          0,
                bondFactor:        0,
                kickTime:          0,
                kickMomp:          0,
                totalBondEscrowed: 0,
                auctionPrice:      0,
                debtInAuction:     0,
                thresholdPrice:    9.853394241979221645 * 1e18,
                neutralPrice:      0
            })
        );
        _assertBorrower({
            borrower:                  _borrower2,
            borrowerDebt:              9_853.394241979221645666 * 1e18,
            borrowerCollateral:        1_000 * 1e18,
            borrowert0Np:              10.307611531622595991 * 1e18,
            borrowerCollateralization: 0.986593617011217057 * 1e18
        });

        _kick({
            from:           _lender,
            borrower:       _borrower2,
            debt:           9_976.561670003961916237 * 1e18,
            collateral:     1_000 * 1e18,
            bond:           98.533942419792216457 * 1e18,
            transferAmount: 98.533942419792216457 * 1e18
        });

        _assertAuction(
            AuctionParams({
                borrower:          _borrower2,
                active:            true,
                kicker:            _lender,
                bondSize:          98.533942419792216457 * 1e18,
                bondFactor:        0.01 * 1e18,
                kickTime:          _startTime + 100 days,
                kickMomp:          9.818751856078723036 * 1e18,
                totalBondEscrowed: 98.533942419792216457 * 1e18,
                auctionPrice:      334.393063846970122880 * 1e18,
                debtInAuction:     9_976.561670003961916237 * 1e18,
                thresholdPrice:    9.976561670003961916 * 1e18,
                neutralPrice:      10.449783245217816340 * 1e18
            })
        );
        _assertBorrower({
            borrower:                  _borrower2,
            borrowerDebt:              9_976.561670003961916237 * 1e18,
            borrowerCollateral:        1_000 * 1e18,
            borrowert0Np:              10.307611531622595991 * 1e18,
            borrowerCollateralization: 0.974413448899967463 * 1e18
        });
        _assertBucket({
            index:        _i9_91,
            lpBalance:    2_000 * 1e18,
            collateral:   0,
            deposit:      2_114.174951097528962000 * 1e18,
            exchangeRate: 1.057087475548764481 * 1e18
        });
        _assertBucket({
            index:        _i9_81,
            lpBalance:    5_000 * 1e18,
            collateral:   0,
            deposit:      5_000 * 1e18,
            exchangeRate: 1 * 1e18
        });
        _assertBucket({
            index:        _i9_72,
            lpBalance:    11_000 * 1e18,
            collateral:   0,
            deposit:      11_000 * 1e18,
            exchangeRate: 1 * 1e18
        });
        _assertBucket({
            index:        _i9_62,
            lpBalance:    25_000 * 1e18,
            collateral:   0,
            deposit:      25_000 * 1e18,
            exchangeRate: 1 * 1e18
        });

        // settle should work on an kicked auction if 72 hours passed from kick time
        // settle should affect first 3 buckets, reducing deposit and incrementing collateral
        skip(73 hours);

        _assertAuction(
            AuctionParams({
                borrower:          _borrower2,
                active:            true,
                kicker:            _lender,
                bondSize:          98.533942419792216457 * 1e18,
                bondFactor:        0.01 * 1e18,
                kickTime:          block.timestamp - 73 hours,
                kickMomp:          9.818751856078723036 * 1e18,
                totalBondEscrowed: 98.533942419792216457 * 1e18,
                auctionPrice:      0,
                debtInAuction:     9_976.561670003961916237 * 1e18,
                thresholdPrice:    9.980303582194898667 * 1e18,
                neutralPrice:      10.449783245217816340 * 1e18
            })
        );
        _assertBorrower({
            borrower:                  _borrower2,
            borrowerDebt:              9_980.303582194898667001 * 1e18,
            borrowerCollateral:        1_000 * 1e18,
            borrowert0Np:              10.307611531622595991 * 1e18,
            borrowerCollateralization: 0.974048112361512224 * 1e18
        });

        _settle({
            from:        _lender,
            borrower:    _borrower2,
            maxDepth:    10,
            settledDebt: 9_840.828245192307696845 * 1e18
        });

        _assertAuction(
            AuctionParams({
                borrower:          _borrower2,
                active:            false,
                kicker:            address(0),
                bondSize:          0,
                bondFactor:        0,
                kickTime:          0,
                kickMomp:          0,
                totalBondEscrowed: 98.533942419792216457 * 1e18,
                auctionPrice:      0,
                debtInAuction:     0,
                thresholdPrice:    0,
                neutralPrice:      0
            })
        );
        _assertBorrower({
            borrower:                  _borrower2,
            borrowerDebt:              0,
            borrowerCollateral:        0,
            borrowert0Np:              10.307611531622595991 * 1e18,
            borrowerCollateralization: 1 * 1e18
        });
        _assertBucket({
            index:        _i9_91,
            lpBalance:    2_000 * 1e18,
            collateral:   213.282459829062995573 * 1e18,
            deposit:      0,
            exchangeRate: 1.057580788993756155 * 1e18
        });
        _assertBucket({
            index:        _i9_81,
            lpBalance:    5_000 * 1e18,
            collateral:   509.467337074016313187 * 1e18,
            deposit:      0,
            exchangeRate: 1.000466672301396420 * 1e18
        });
        _assertBucket({
            index:        _i9_72,
            lpBalance:    11_000 * 1e18,
            collateral:   277.250203096920691240 * 1e18,
            deposit:      8_289.317326783984381999 * 1e18,
            exchangeRate: 0.998595325429936418 * 1e18
        });
        _assertBucket({
            index:        _i9_62,
            lpBalance:    25_000 * 1e18,
            collateral:   0,
            deposit:      25_000 * 1e18,
            exchangeRate: 1 * 1e18
        });
    }

    function testSettleAuctionReverts() external tearDown {
        // Borrower2 borrows
        _borrow({
            from:       _borrower2,
            amount:     1_730 * 1e18,
            indexLimit: _i9_72,
            newLup:     9.721295865031779605 * 1e18
        });

        // Skip to make borrower undercollateralized
        skip(100 days);
        // settle should revert on a borrower that is not auctioned
        _assertSettleOnNotKickedAuctionRevert({
            from:     _lender,
            borrower: _borrower2
        });

        uint256 kickTime = _startTime + 100 days;

        _kick({
            from:           _lender,
            borrower:       _borrower2,
            debt:           9_976.561670003961916237 * 1e18,
            collateral:     1_000 * 1e18,
            bond:           98.533942419792216457 * 1e18,
            transferAmount: 98.533942419792216457 * 1e18
        });

        _assertAuction(
            AuctionParams({
                borrower:          _borrower2,
                active:            true,
                kicker:            _lender,
                bondSize:          98.533942419792216457 * 1e18,
                bondFactor:        0.01 * 1e18,
                kickTime:          kickTime,
                kickMomp:          9.818751856078723036 * 1e18,
                totalBondEscrowed: 98.533942419792216457 * 1e18,
                auctionPrice:      334.393063846970122880 * 1e18,
                debtInAuction:     9_976.561670003961916237 * 1e18,
                thresholdPrice:    9.976561670003961916 * 1e18,
                neutralPrice:      10.449783245217816340 * 1e18
            })
        );
        _assertBorrower({
            borrower:                  _borrower2,
            borrowerDebt:              9_976.561670003961916237 * 1e18,
            borrowerCollateral:        1_000 * 1e18,
            borrowert0Np:              10.307611531622595991 * 1e18,
            borrowerCollateralization: 0.974413448899967463 * 1e18
        });

        // settle should revert on an kicked auction but 72 hours not passed (there's still debt to settle and collateral to be auctioned)
        _assertSettleOnNotClearableAuctionRevert({
            from:     _lender,
            borrower: _borrower2
        });

        // skip ahead so take can be called on the loan
        skip(10 hours);

        _assertAuction(
            AuctionParams({
                borrower:          _borrower2,
                active:            true,
                kicker:            _lender,
                bondSize:          98.533942419792216457 * 1e18,
                bondFactor:        0.01 * 1e18,
                kickTime:          kickTime,
                kickMomp:          9.818751856078723036 * 1e18,
                totalBondEscrowed: 98.533942419792216457 * 1e18,
                auctionPrice:      0.653111452826113536 * 1e18,
                debtInAuction:     9_976.561670003961916237 * 1e18,
                thresholdPrice:    9.977074177773911990 * 1e18,
                neutralPrice:      10.449783245217816340 * 1e18
            })
        );
        _assertBorrower({
            borrower:                  _borrower2,
            borrowerDebt:              9_977.074177773911990381 * 1e18,
            borrowerCollateral:        1_000 * 1e18,
            borrowert0Np:              10.307611531622595991 * 1e18,
            borrowerCollateralization: 0.974363394700228467 * 1e18
        });

        // take entire collateral
        _take({
            from:            _lender,
            borrower:        _borrower2,
            maxCollateral:   1_000 * 1e18,
            bondChange:      6.531114528261135360 * 1e18,
            givenAmount:     653.111452826113536000 * 1e18,
            collateralTaken: 1_000 * 1e18,
            isReward:        true
        });

        // remove quote tokens should fail since auction head is clearable
        _assertRemoveLiquidityAuctionNotClearedRevert({
            from:   _lender,
            amount: 1_000 * 1e18,
            index:  _i9_52
        });

        _assertRemoveAllLiquidityAuctionNotClearedRevert({
            from:   _lender,
            index:  _i9_52
        });

        // remove collateral should fail since auction head is clearable
        _assertRemoveCollateralAuctionNotClearedRevert({
            from:   _lender,
            amount: 10 * 1e18,
            index:  _i9_52
        });

        // remove all collateral should fail since auction head is clearable
        _assertRemoveAllCollateralAuctionNotClearedRevert({
            from:   _lender,
            index:  _i9_52
        });

        // add liquidity in same block should be possible as debt was not yet settled / bucket is not yet insolvent
        _addLiquidity({
            from:    _lender1,
            amount:  100 * 1e18,
            index:   _i9_91,
            lpAward: 94.593504307441637520 * 1e18,
            newLup:  9.721295865031779605 * 1e18
        });

        _assertLenderLpBalance({
            lender:      _lender1,
            index:       _i9_91,
            lpBalance:   94.593504307441637520 * 1e18,
            depositTime: _startTime + 100 days + 10 hours
        });

        // adding to a different bucket for testing move in same block with bucket bankruptcy
        _addLiquidityWithPenalty({
            from:        _lender1,
            amount:      100 * 1e18,
            amountAdded: 99.987671232876712300 * 1e18,
            index:       _i9_52,
            lpAward:     99.987671232876712300 * 1e18,
            newLup:      9.721295865031779605 * 1e18
        });

        // settle to make buckets insolvent
        // settle should work because there is still debt to settle but no collateral left to auction (even if 72 hours didn't pass from kick)
        _assertBorrower({
            borrower:                  _borrower2,
            borrowerDebt:              10_028.889031920233428707 * 1e18,
            borrowerCollateral:        0,
            borrowert0Np:              10.307611531622595991 * 1e18,
            borrowerCollateralization: 0
        });
        
        assertTrue(block.timestamp - kickTime < 72 hours); // assert auction was kicked less than 72 hours ago

        _settle({
            from:        _lender,
            borrower:    _borrower2,
            maxDepth:    10,
            settledDebt: 9_891.935520844277346922 * 1e18
        });

        // bucket is insolvent, balances are resetted
        _assertBucket({
            index:        _i9_91,
            lpBalance:    0, // bucket is bankrupt
            collateral:   0,
            deposit:      0,
            exchangeRate: 1 * 1e18
        });
        // after bucket bankruptcy lenders balance is zero
        _assertLenderLpBalance({
            lender:      _lender,
            index:       _i9_91,
            lpBalance:   0,
            depositTime: _startTime
        });
        _assertLenderLpBalance({
            lender:      _lender1,
            index:       _i9_91,
            lpBalance:   0,
            depositTime: _startTime + 100 days + 10 hours
        });

        // cannot add liquidity in same block when bucket marked insolvent
        _assertAddLiquidityBankruptcyBlockRevert({
            from:   _lender1,
            amount: 1_000 * 1e18,
            index:  _i9_91
        });

        // cannot add collateral in same block when bucket marked insolvent
        _assertAddCollateralBankruptcyBlockRevert({
            from:   _lender1,
            amount: 10 * 1e18,
            index:  _i9_91
        });

        // cannot move LPs in same block when bucket marked insolvent
        _assertMoveLiquidityBankruptcyBlockRevert({
            from:      _lender1,
            amount:    10 * 1e18,
            fromIndex: _i9_52,
            toIndex:   _i9_91
        });

        // all operations should work if not in same block
        skip(1 hours);

        // move quote token in a bankrupt bucket should set deposit time to time of bankruptcy + 1 to prevent losing deposit
        _pool.moveQuoteToken(10 * 1e18, _i9_52, _i9_91, block.timestamp + 1 minutes);
        (, , uint256 bankruptcyTime, , ) = _pool.bucketInfo(_i9_91);
        _assertLenderLpBalance({
            lender:      _lender1,
            index:       _i9_91,
            lpBalance:   10 * 1e18,
            depositTime: bankruptcyTime + 1
        });

        _pool.addQuoteToken(100 * 1e18, _i9_91, block.timestamp + 1 minutes);
        ERC20Pool(address(_pool)).addCollateral(4 * 1e18, _i9_91, block.timestamp + 1 minutes);

        _assertLenderLpBalance({
            lender:      _lender1,
            index:       _i9_91,
            lpBalance:   149.668739373743648296 * 1e18,
            depositTime: _startTime + 100 days + 10 hours + 1 hours
        });
        // bucket is healthy again
        _assertBucket({
            index:        _i9_91,
            lpBalance:    149.668739373743648296 * 1e18,
            collateral:   4 * 1e18,
            deposit:      110 * 1e18,
            exchangeRate: 1 * 1e18
        });

        // when moving to a bucket that was marked insolvent, the deposit time should be the greater between from bucket deposit time and insolvency time + 1
        changePrank(_lender);
        _assertLenderLpBalance({
            lender:      _lender,
            index:       _i9_91,
            lpBalance:   0,
            depositTime: _startTime
        });

        _pool.moveQuoteToken(1_000 * 1e18, _i9_52, _i9_91, block.timestamp + 1 minutes);

        _assertLenderLpBalance({
            lender:      _lender,
            index:       _i9_91,
            lpBalance:   1_000 * 1e18,
            depositTime: _startTime + 100 days + 10 hours + 1 // _i9_91 bucket insolvency time + 1 (since deposit in _i9_52 from bucket was done before _i9_91 target bucket become insolvent)
        });

        _pool.addQuoteToken(1_000 * 1e18, _i9_52, block.timestamp + 1 minutes);
        _pool.moveQuoteToken(1_000 * 1e18, _i9_52, _i9_91, block.timestamp + 1 minutes);

        _assertLenderLpBalance({
            lender:      _lender,
            index:       _i9_91,
            lpBalance:   2_000 * 1e18,
            depositTime: _startTime + 100 days + 10 hours + 1 hours // time of deposit in _i9_52 from bucket (since deposit in _i9_52 from bucket was done after _i9_91 target bucket become insolvent)
        });

        // ensure bucket bankruptcy when moving amounts from an unbalanced bucket leave bucket healthy
        _assertBucket({
            index:        _i9_72,
            lpBalance:    11_000 * 1e18,
            collateral:   0 * 1e18,
            deposit:      9_036.356565003188009087 * 1e18,
            exchangeRate: 0.821486960454835274 * 1e18
        });

        vm.expectEmit(true, true, false, true);
        emit BucketBankruptcy(_i9_72, 5981);
        _pool.moveQuoteToken(10000000000 * 1e18, _i9_72, _i9_91, type(uint256).max);

        _assertBucket({
            index:        _i9_72,
            lpBalance:    0,
            collateral:   0 * 1e18,
            deposit:      0,
            exchangeRate: 1 * 1e18
        });
    }
}

contract ERC20PoolLiquidationsSettleRegressionTest is ERC20HelperContract {

    function testSettleAndBankruptcyOnHPBWithTinyDeposit() external {
        address actor1 = makeAddr("actor1");
        _mintQuoteAndApproveTokens(actor1, type(uint256).max);
        _mintCollateralAndApproveTokens(actor1, type(uint256).max);

        address actor2 = makeAddr("actor2");
        _mintQuoteAndApproveTokens(actor2,  type(uint256).max);
        _mintCollateralAndApproveTokens(actor2, type(uint256).max);

        address actor3 = makeAddr("actor1");
        _mintQuoteAndApproveTokens(actor3, type(uint256).max);
        _mintCollateralAndApproveTokens(actor3, type(uint256).max);

        address actor6 = makeAddr("actor6");
        _mintQuoteAndApproveTokens(actor6, type(uint256).max);
        _mintCollateralAndApproveTokens(actor6, type(uint256).max);

        address actor8 = makeAddr("actor8");
        _mintQuoteAndApproveTokens(actor8, type(uint256).max);
        _mintCollateralAndApproveTokens(actor8, type(uint256).max);

        changePrank(actor6);
        _pool.addQuoteToken(2_000_000 * 1e18, 2572, block.timestamp + 100);
        skip(100 days);
        ERC20Pool(address(_pool)).drawDebt(actor6, 1000000 * 1e18, 7388, 372.489032271806320214 * 1e18);
        skip(100 days);

        changePrank(actor1);
        _pool.updateInterest();
        _pool.kick(actor6, 7388);
        skip(100 hours);
        ERC20Pool(address(_pool)).drawDebt(actor1, 1000000 * 1e18, 7388, 10066231386838.450530455239517417 * 1e18);
        skip(100 days);

        changePrank(actor2);
        _pool.updateInterest();
        _pool.kick(actor1, 7388);
        skip(10 days);

        changePrank(actor3);
        _pool.addQuoteToken(2, 2571, block.timestamp + 100);

        (uint256 bucketLps, uint256 collateral, , uint256 deposit, ) = _pool.bucketInfo(2571);
        assertEq(bucketLps, 2);
        assertEq(collateral, 0);
        assertEq(deposit, 2);
        (uint256 borrowerDebt, uint256 borrowerCollateral, ) = _pool.borrowerInfo(actor1);
        assertEq(borrowerDebt, 987909.179343464530923023 * 1e18);
        assertEq(borrowerCollateral, 10066231386838.450530455239517417 * 1e18);

        changePrank(actor8);
        _pool.updateInterest();
        vm.expectEmit(true, true, false, true);
        emit BucketBankruptcy(2571, 2);
        ERC20Pool(address(_pool)).settle(actor1, 1);

        (bucketLps, collateral, , deposit, ) = _pool.bucketInfo(2571);
        assertEq(bucketLps, 0); // entire LPs removed from bucket 2571
        assertEq(collateral, 0); // no collateral added in bucket 2571
        assertEq(deposit, 0); // entire deposit from bucket 2571 used to settle
        (borrowerDebt, borrowerCollateral, ) = _pool.borrowerInfo(actor1);
        assertEq(borrowerDebt, 987909.179343464530923021 * 1e18); // decreased with 2
        assertEq(borrowerCollateral, 10066231386838.450530455239517417 * 1e18); // same as before settle
    }
}
