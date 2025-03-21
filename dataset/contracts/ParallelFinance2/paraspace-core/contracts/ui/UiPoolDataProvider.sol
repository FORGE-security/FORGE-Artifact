// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import {IERC20Detailed} from "../dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import {IERC721Metadata} from "../dependencies/openzeppelin/contracts/IERC721Metadata.sol";
import {IERC721} from "../dependencies/openzeppelin/contracts/IERC721.sol";
import {IPoolAddressesProvider} from "../interfaces/IPoolAddressesProvider.sol";
import {IUiPoolDataProvider} from "./interfaces/IUiPoolDataProvider.sol";
import {IPool} from "../interfaces/IPool.sol";
import {IParaSpaceOracle} from "../interfaces/IParaSpaceOracle.sol";
import {IPToken} from "../interfaces/IPToken.sol";
import {ICollaterizableERC721} from "../interfaces/ICollaterizableERC721.sol";
import {IAuctionableERC721} from "../interfaces/IAuctionableERC721.sol";
import {INToken} from "../interfaces/INToken.sol";
import {IVariableDebtToken} from "../interfaces/IVariableDebtToken.sol";
import {IStableDebtToken} from "../interfaces/IStableDebtToken.sol";
import {WadRayMath} from "../protocol/libraries/math/WadRayMath.sol";
import {ReserveConfiguration} from "../protocol/libraries/configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "../protocol/libraries/configuration/UserConfiguration.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";
import {DefaultReserveInterestRateStrategy} from "../protocol/pool/DefaultReserveInterestRateStrategy.sol";
import {IEACAggregatorProxy} from "./interfaces/IEACAggregatorProxy.sol";
import {IERC20DetailedBytes} from "./interfaces/IERC20DetailedBytes.sol";
import {ProtocolDataProvider} from "../misc/ProtocolDataProvider.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";
import {IUniswapV3OracleWrapper} from "../interfaces/IUniswapV3OracleWrapper.sol";
import {UinswapV3PositionData} from "../interfaces/IUniswapV3PositionInfoProvider.sol";
import {IDynamicConfigsStrategy} from "../interfaces/IDynamicConfigsStrategy.sol";

contract UiPoolDataProvider is IUiPoolDataProvider {
    using WadRayMath for uint256;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    IEACAggregatorProxy
        public immutable networkBaseTokenPriceInUsdProxyAggregator;
    IEACAggregatorProxy
        public immutable marketReferenceCurrencyPriceInUsdProxyAggregator;
    uint256 public constant ETH_CURRENCY_UNIT = 1 ether;
    address public constant MKR_ADDRESS =
        0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;

    constructor(
        IEACAggregatorProxy _networkBaseTokenPriceInUsdProxyAggregator,
        IEACAggregatorProxy _marketReferenceCurrencyPriceInUsdProxyAggregator
    ) {
        networkBaseTokenPriceInUsdProxyAggregator = _networkBaseTokenPriceInUsdProxyAggregator;
        marketReferenceCurrencyPriceInUsdProxyAggregator = _marketReferenceCurrencyPriceInUsdProxyAggregator;
    }

    function getInterestRateStrategySlopes(
        DefaultReserveInterestRateStrategy interestRateStrategy
    ) internal view returns (InterestRates memory) {
        InterestRates memory interestRates;
        interestRates.variableRateSlope1 = interestRateStrategy
            .getVariableRateSlope1();
        interestRates.variableRateSlope2 = interestRateStrategy
            .getVariableRateSlope2();
        interestRates.stableRateSlope1 = interestRateStrategy
            .getStableRateSlope1();
        interestRates.stableRateSlope2 = interestRateStrategy
            .getStableRateSlope2();
        interestRates.baseStableBorrowRate = interestRateStrategy
            .getBaseStableBorrowRate();
        interestRates.baseVariableBorrowRate = interestRateStrategy
            .getBaseVariableBorrowRate();
        interestRates.optimalUsageRatio = interestRateStrategy
            .OPTIMAL_USAGE_RATIO();

        return interestRates;
    }

    function getReservesList(IPoolAddressesProvider provider)
        public
        view
        override
        returns (address[] memory)
    {
        IPool pool = IPool(provider.getPool());
        return pool.getReservesList();
    }

    function getReservesData(IPoolAddressesProvider provider)
        public
        view
        override
        returns (AggregatedReserveData[] memory, BaseCurrencyInfo memory)
    {
        IParaSpaceOracle oracle = IParaSpaceOracle(provider.getPriceOracle());
        IPool pool = IPool(provider.getPool());

        address[] memory reserves = pool.getReservesList();
        AggregatedReserveData[]
            memory reservesData = new AggregatedReserveData[](reserves.length);

        for (uint256 i = 0; i < reserves.length; i++) {
            AggregatedReserveData memory reserveData = reservesData[i];
            reserveData.underlyingAsset = reserves[i];

            // reserve current state
            DataTypes.ReserveData memory baseData = pool.getReserveData(
                reserveData.underlyingAsset
            );
            //the liquidity index. Expressed in ray
            reserveData.liquidityIndex = baseData.liquidityIndex;
            //variable borrow index. Expressed in ray
            reserveData.variableBorrowIndex = baseData.variableBorrowIndex;
            //the current supply rate. Expressed in ray
            reserveData.liquidityRate = baseData.currentLiquidityRate;
            //the current variable borrow rate. Expressed in ray
            reserveData.variableBorrowRate = baseData.currentVariableBorrowRate;
            //the current stable borrow rate. Expressed in ray
            reserveData.stableBorrowRate = baseData.currentStableBorrowRate;
            reserveData.lastUpdateTimestamp = baseData.lastUpdateTimestamp;
            reserveData.xTokenAddress = baseData.xTokenAddress;
            reserveData.stableDebtTokenAddress = baseData
                .stableDebtTokenAddress;
            reserveData.variableDebtTokenAddress = baseData
                .variableDebtTokenAddress;
            //address of the interest rate strategy
            reserveData.interestRateStrategyAddress = baseData
                .interestRateStrategyAddress;
            try oracle.getAssetPrice(reserveData.underlyingAsset) returns (
                uint256 price
            ) {
                reserveData.priceInMarketReferenceCurrency = price;
            } catch {}
            // reserveData.priceOracle = oracle.getSourceOfAsset(
            //     reserveData.underlyingAsset
            // );

            (
                reserveData.totalPrincipalStableDebt,
                ,
                reserveData.averageStableRate,
                reserveData.stableDebtLastUpdateTimestamp
            ) = IStableDebtToken(reserveData.stableDebtTokenAddress)
                .getSupplyData();
            reserveData.totalScaledVariableDebt = IVariableDebtToken(
                reserveData.variableDebtTokenAddress
            ).scaledTotalSupply();
            DataTypes.ReserveConfigurationMap
                memory reserveConfigurationMap = baseData.configuration;
            bool isPaused;
            DataTypes.AssetType assetType;
            (
                reserveData.isActive,
                reserveData.isFrozen,
                reserveData.borrowingEnabled,
                reserveData.stableBorrowRateEnabled,
                isPaused,
                assetType
            ) = reserveConfigurationMap.getFlags();

            if (assetType == DataTypes.AssetType.ERC20) {
                // Due we take the symbol from underlying token we need a special case for $MKR as symbol() returns bytes32
                if (
                    address(reserveData.underlyingAsset) == address(MKR_ADDRESS)
                ) {
                    bytes32 symbol = IERC20DetailedBytes(
                        reserveData.underlyingAsset
                    ).symbol();
                    reserveData.symbol = bytes32ToString(symbol);
                } else {
                    reserveData.symbol = IERC20Detailed(
                        reserveData.underlyingAsset
                    ).symbol();
                }

                reserveData.availableLiquidity = IERC20Detailed(
                    reserveData.underlyingAsset
                ).balanceOf(reserveData.xTokenAddress);
            } else {
                reserveData.symbol = IERC721Metadata(
                    reserveData.underlyingAsset
                ).symbol();

                reserveData.availableLiquidity = IERC721(
                    reserveData.underlyingAsset
                ).balanceOf(reserveData.xTokenAddress);
            }

            //uint256 eModeCategoryId;
            (
                reserveData.baseLTVasCollateral,
                reserveData.reserveLiquidationThreshold,
                reserveData.reserveLiquidationBonus,
                reserveData.decimals,
                reserveData.reserveFactor,
                // eModeCategoryId

            ) = reserveConfigurationMap.getParams();
            reserveData.usageAsCollateralEnabled =
                reserveData.baseLTVasCollateral != 0;

            InterestRates memory interestRates = getInterestRateStrategySlopes(
                DefaultReserveInterestRateStrategy(
                    reserveData.interestRateStrategyAddress
                )
            );

            reserveData.variableRateSlope1 = interestRates.variableRateSlope1;
            reserveData.variableRateSlope2 = interestRates.variableRateSlope2;
            reserveData.stableRateSlope1 = interestRates.stableRateSlope1;
            reserveData.stableRateSlope2 = interestRates.stableRateSlope2;
            reserveData.baseStableBorrowRate = interestRates
                .baseStableBorrowRate;
            reserveData.baseVariableBorrowRate = interestRates
                .baseVariableBorrowRate;
            reserveData.optimalUsageRatio = interestRates.optimalUsageRatio;

            // v3 only
            reserveData.eModeCategoryId = 0;
            // reserveData.debtCeiling = reserveConfigurationMap.getDebtCeiling();
            // reserveData.debtCeilingDecimals = poolDataProvider
            //     .getDebtCeilingDecimals();
            (
                reserveData.borrowCap,
                reserveData.supplyCap
            ) = reserveConfigurationMap.getCaps();

            reserveData.isPaused = isPaused;
            reserveData.unbacked = 0;
            reserveData.isolationModeTotalDebt = 0;
            reserveData.accruedToTreasury = baseData.accruedToTreasury;

            //DataTypes.EModeCategory memory categoryData = pool.getEModeCategoryData(reserveData.eModeCategoryId);
            reserveData.eModeLtv = 0;
            reserveData.eModeLiquidationThreshold = 0;
            reserveData.eModeLiquidationBonus = 0;
            // each eMode category may or may not have a custom oracle to override the individual assets price oracles
            reserveData.eModePriceSource = address(0);
            reserveData.eModeLabel = "";

            reserveData.borrowableInIsolation = false; // reserveConfigurationMap.getBorrowableInIsolation();
        }

        BaseCurrencyInfo memory baseCurrencyInfo;
        baseCurrencyInfo
            .networkBaseTokenPriceInUsd = networkBaseTokenPriceInUsdProxyAggregator
            .latestAnswer();
        baseCurrencyInfo
            .networkBaseTokenPriceDecimals = networkBaseTokenPriceInUsdProxyAggregator
            .decimals();

        try oracle.BASE_CURRENCY_UNIT() returns (uint256 baseCurrencyUnit) {
            if (ETH_CURRENCY_UNIT == baseCurrencyUnit) {
                baseCurrencyInfo
                    .marketReferenceCurrencyUnit = ETH_CURRENCY_UNIT;
                baseCurrencyInfo
                    .marketReferenceCurrencyPriceInUsd = marketReferenceCurrencyPriceInUsdProxyAggregator
                    .latestAnswer();
            } else {
                baseCurrencyInfo.marketReferenceCurrencyUnit = baseCurrencyUnit;
                baseCurrencyInfo.marketReferenceCurrencyPriceInUsd = int256(
                    baseCurrencyUnit
                );
            }
        } catch (
            bytes memory /*lowLevelData*/
        ) {
            baseCurrencyInfo.marketReferenceCurrencyUnit = ETH_CURRENCY_UNIT;
            baseCurrencyInfo
                .marketReferenceCurrencyPriceInUsd = marketReferenceCurrencyPriceInUsdProxyAggregator
                .latestAnswer();
        }

        return (reservesData, baseCurrencyInfo);
    }

    function getAuctionData(
        IPoolAddressesProvider provider,
        address,
        address[] memory nTokenAddresses,
        uint256[][] memory tokenIds
    ) external view override returns (DataTypes.AuctionData[][] memory) {
        DataTypes.AuctionData[][]
            memory tokenData = new DataTypes.AuctionData[][](
                nTokenAddresses.length
            );
        IPool pool = IPool(provider.getPool());

        for (uint256 i = 0; i < nTokenAddresses.length; i++) {
            address asset = nTokenAddresses[i];
            uint256 size = tokenIds[i].length;
            tokenData[i] = new DataTypes.AuctionData[](size);

            for (uint256 j = 0; j < size; j++) {
                tokenData[i][j] = pool.getAuctionData(asset, tokenIds[i][j]);
            }
        }

        return (tokenData);
    }

    function getNTokenData(
        address,
        address[] memory nTokenAddresses,
        uint256[][] memory tokenIds
    ) external view override returns (DataTypes.NTokenData[][] memory) {
        DataTypes.NTokenData[][]
            memory tokenData = new DataTypes.NTokenData[][](
                nTokenAddresses.length
            );

        for (uint256 i = 0; i < nTokenAddresses.length; i++) {
            address asset = nTokenAddresses[i];
            uint256 size = tokenIds[i].length;
            tokenData[i] = new DataTypes.NTokenData[](size);

            for (uint256 j = 0; j < size; j++) {
                tokenData[i][j].tokenId = tokenIds[i][j];
                tokenData[i][j].useAsCollateral = ICollaterizableERC721(asset)
                    .isUsedAsCollateral(tokenIds[i][j]);
                tokenData[i][j].isAuctioned = IAuctionableERC721(asset)
                    .isAuctioned(tokenIds[i][j]);
            }
        }

        return (tokenData);
    }

    function getUniswapV3LpTokenData(
        IPoolAddressesProvider provider,
        address lpTokenAddress,
        uint256 tokenId
    ) external view override returns (UniswapV3LpTokenInfo memory) {
        UniswapV3LpTokenInfo memory lpTokenInfo;

        IUniswapV3OracleWrapper source;
        IDynamicConfigsStrategy dynamicConfigsStrategy;
        //avoid stack too deep
        {
            IParaSpaceOracle oracle = IParaSpaceOracle(
                provider.getPriceOracle()
            );
            address sourceAddress = oracle.getSourceOfAsset(lpTokenAddress);
            if (sourceAddress == address(0)) {
                return lpTokenInfo;
            }
            source = IUniswapV3OracleWrapper(sourceAddress);

            IPool pool = IPool(provider.getPool());
            DataTypes.ReserveData memory reserveData = pool.getReserveData(
                lpTokenAddress
            );
            address dynamicConfigsStrategyAddress = reserveData
                .dynamicConfigsStrategyAddress;
            if (dynamicConfigsStrategyAddress == address(0)) {
                return lpTokenInfo;
            }
            dynamicConfigsStrategy = IDynamicConfigsStrategy(
                dynamicConfigsStrategyAddress
            );
        }

        //try to catch invalid tokenId
        try source.getTokenPrice(tokenId) returns (uint256 tokenPrice) {
            lpTokenInfo.tokenPrice = tokenPrice;

            UinswapV3PositionData memory positionData = source
                .getOnchainPositionData(tokenId);
            lpTokenInfo.token0 = positionData.token0;
            lpTokenInfo.token1 = positionData.token1;
            lpTokenInfo.feeRate = positionData.fee;
            lpTokenInfo.liquidity = positionData.liquidity;
            lpTokenInfo.positionTickLower = positionData.tickLower;
            lpTokenInfo.positionTickUpper = positionData.tickUpper;
            lpTokenInfo.currentTick = positionData.currentTick;

            (
                lpTokenInfo.liquidityToken0Amount,
                lpTokenInfo.liquidityToken1Amount
            ) = source.getLiquidityAmountFromPositionData(positionData);

            (
                lpTokenInfo.lpFeeToken0Amount,
                lpTokenInfo.lpFeeToken1Amount
            ) = source.getLpFeeAmountFromPositionData(positionData);

            (
                lpTokenInfo.baseLTVasCollateral,
                lpTokenInfo.reserveLiquidationThreshold
            ) = dynamicConfigsStrategy.getConfigParams(tokenId);
        } catch {}

        return lpTokenInfo;
    }

    function getUserReservesData(IPoolAddressesProvider provider, address user)
        external
        view
        override
        returns (UserReserveData[] memory, uint8)
    {
        IPool pool = IPool(provider.getPool());
        address[] memory reserves = pool.getReservesList();
        DataTypes.UserConfigurationMap memory userConfig = pool
            .getUserConfiguration(user);

        uint8 userEmodeCategoryId = 0;

        UserReserveData[] memory userReservesData = new UserReserveData[](
            user != address(0) ? reserves.length : 0
        );

        for (uint256 i = 0; i < reserves.length; i++) {
            DataTypes.ReserveData memory baseData = pool.getReserveData(
                reserves[i]
            );

            // user reserve data
            userReservesData[i].underlyingAsset = reserves[i];

            if (
                baseData.configuration.getAssetType() ==
                DataTypes.AssetType.ERC20
            ) {
                userReservesData[i].scaledXTokenBalance = IPToken(
                    baseData.xTokenAddress
                ).scaledBalanceOf(user);
            } else {
                userReservesData[i].scaledXTokenBalance = INToken(
                    baseData.xTokenAddress
                ).balanceOf(user);
                userReservesData[i].collaterizedBalance = ICollaterizableERC721(
                    baseData.xTokenAddress
                ).collaterizedBalanceOf(user);
            }

            userReservesData[i].usageAsCollateralEnabledOnUser = userConfig
                .isUsingAsCollateral(i);

            if (userConfig.isBorrowing(i)) {
                userReservesData[i].scaledVariableDebt = IVariableDebtToken(
                    baseData.variableDebtTokenAddress
                ).scaledBalanceOf(user);
                userReservesData[i].principalStableDebt = IStableDebtToken(
                    baseData.stableDebtTokenAddress
                ).principalBalanceOf(user);
                if (userReservesData[i].principalStableDebt != 0) {
                    userReservesData[i].stableBorrowRate = IStableDebtToken(
                        baseData.stableDebtTokenAddress
                    ).getUserStableRate(user);
                    userReservesData[i]
                        .stableBorrowLastUpdateTimestamp = IStableDebtToken(
                        baseData.stableDebtTokenAddress
                    ).getUserLastUpdated(user);
                }
            }
        }

        return (userReservesData, userEmodeCategoryId);
    }

    function bytes32ToString(bytes32 _bytes32)
        public
        pure
        returns (string memory)
    {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}
