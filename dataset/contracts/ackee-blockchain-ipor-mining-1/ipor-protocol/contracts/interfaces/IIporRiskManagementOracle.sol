// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "./types/IporTypes.sol";
import "./types/IporRiskManagementOracleTypes.sol";

interface IIporRiskManagementOracle {
    /// @notice event emitted when risk indicators are updated. Values and rates are not represented in 18 decimals.
    /// @param asset underlying / stablecoin address supported by IPOR Protocol
    /// @param maxNotionalPayFixed maximum notional value for pay fixed leg, 1 = 10k
    /// @param maxNotionalReceiveFixed maximum notional value for receive fixed leg, 1 = 10k
    /// @param maxCollateralRatioPayFixed maximum collateral ratio for pay fixed leg, 1 = 0.01%
    /// @param maxCollateralRatioReceiveFixed maximum collateral ratio for receive fixed leg, 1 = 0.01%
    /// @param maxCollateralRatio maximum collateral ratio for both legs, 1 = 0.01%
    /// @param demandSpreadFactor28 demand spread factor, value represents without decimals, used to calculate demand spread
    /// @param demandSpreadFactor60 demand spread factor, value represents without decimals, used to calculate demand spread
    /// @param demandSpreadFactor90 demand spread factor, value represents without decimals, used to calculate demand spread
    event RiskIndicatorsUpdated(
        address indexed asset,
        uint256 maxNotionalPayFixed,
        uint256 maxNotionalReceiveFixed,
        uint256 maxCollateralRatioPayFixed,
        uint256 maxCollateralRatioReceiveFixed,
        uint256 maxCollateralRatio,
        uint256 demandSpreadFactor28,
        uint256 demandSpreadFactor60,
        uint256 demandSpreadFactor90
    );

    /// @notice event emitted when base spreads are updated. Rates are represented in 18 decimals.
    /// @param asset underlying / stablecoin address supported by IPOR Protocol
    /// @param baseSpreads28dPayFixed spread for 28 days pay fixed swap
    /// @param baseSpreads28dReceiveFixed spread for 28 days receive fixed swap
    /// @param baseSpreads60dPayFixed spread for 60 days pay fixed swap
    /// @param baseSpreads60dReceiveFixed spread for 60 days receive fixed swap
    /// @param baseSpreads90dPayFixed spread for 90 days pay fixed swap
    /// @param baseSpreads90dReceiveFixed spread for 90 days receive fixed swap
    event BaseSpreadsUpdated(
        address indexed asset,
        int256 baseSpreads28dPayFixed,
        int256 baseSpreads28dReceiveFixed,
        int256 baseSpreads60dPayFixed,
        int256 baseSpreads60dReceiveFixed,
        int256 baseSpreads90dPayFixed,
        int256 baseSpreads90dReceiveFixed
    );

    /// @notice event emitted when base spreads are updated. Rates are represented in 18 decimals.
    /// @param asset underlying / stablecoin address supported by IPOR Protocol
    /// @param fixedRateCap28dPayFixed fixed rate cap for 28 days pay fixed swap
    /// @param fixedRateCap28dReceiveFixed fixed rate cap for 28 days receive fixed swap
    /// @param fixedRateCap60dPayFixed fixed rate cap for 60 days pay fixed swap
    /// @param fixedRateCap60dReceiveFixed fixed rate cap for 60 days receive fixed swap
    /// @param fixedRateCap90dPayFixed fixed rate cap for 90 days pay fixed swap
    /// @param fixedRateCap90dReceiveFixed fixed rate cap for 90 days receive fixed swap
    event FixedRateCapsUpdated(
        address indexed asset,
        uint256 fixedRateCap28dPayFixed,
        uint256 fixedRateCap28dReceiveFixed,
        uint256 fixedRateCap60dPayFixed,
        uint256 fixedRateCap60dReceiveFixed,
        uint256 fixedRateCap90dPayFixed,
        uint256 fixedRateCap90dReceiveFixed
    );

    /// @notice event emitted when new asset is added
    /// @param asset underlying / stablecoin address
    event IporRiskManagementOracleAssetAdded(address indexed asset);

    /// @notice event emitted when asset is removed
    /// @param asset underlying / stablecoin address
    event IporRiskManagementOracleAssetRemoved(address indexed asset);

    /// @notice event emitted when new updater is added
    /// @param updater address
    event IporRiskManagementOracleUpdaterAdded(address indexed updater);

    /// @notice event emitted when updater is removed
    /// @param updater address
    event IporRiskManagementOracleUpdaterRemoved(address indexed updater);

    /// @notice Returns current version of IIporRiskManagementOracle's
    /// @dev Increase number when implementation inside source code is different that implementation deployed on Mainnet
    /// @return current IIporRiskManagementOracle version
    function getVersion() external pure returns (uint256);

    /// @notice Gets risk indicators and base spread for a given asset, swap direction and tenor. Rates represented in 6 decimals. 1 = 0.0001%
    /// @param asset underlying / stablecoin address supported in Ipor Protocol
    /// @param direction swap direction, 0 = pay fixed, 1 = receive fixed
    /// @param tenor swap duration, 0 = 28 days, 1 = 60 days, 2 = 90 days
    /// @return maxNotionalPerLeg maximum notional value for given leg
    /// @return maxCollateralRatioPerLeg maximum collateral ratio for given leg
    /// @return maxCollateralRatio maximum collateral ratio for both legs
    /// @return baseSpreadPerLeg spread for given direction and tenor
    /// @return fixedRateCapPerLeg fixed rate cap for given direction and tenor
    /// @return demandSpreadFactor demand spread factor, value represents without decimals, used to calculate demand spread
    function getOpenSwapParameters(
        address asset,
        uint256 direction,
        IporTypes.SwapTenor tenor
    )
        external
        view
        returns (
            uint256 maxNotionalPerLeg,
            uint256 maxCollateralRatioPerLeg,
            uint256 maxCollateralRatio,
            int256 baseSpreadPerLeg,
            uint256 fixedRateCapPerLeg,
            uint256 demandSpreadFactor
        );

    /// @notice Gets risk indicators for a given asset. Amounts and rates represented in 18 decimals.
    /// @param asset underlying / stablecoin address supported in Ipor Protocol
    /// @return maxNotionalPayFixed maximum notional value for pay fixed leg
    /// @return maxNotionalReceiveFixed maximum notional value for receive fixed leg
    /// @return maxCollateralRatioPayFixed maximum collateral ratio for pay fixed leg
    /// @return maxCollateralRatioReceiveFixed maximum collateral ratio for receive fixed leg
    /// @return maxCollateralRatio maximum collateral ratio for both legs
    /// @return lastUpdateTimestamp Last risk indicators update done by off-chain service
    /// @return demandSpreadFactor demand spread factor, value represents without decimals, used to calculate demand spread
    function getRiskIndicators(
        address asset,
        IporTypes.SwapTenor tenor
    )
        external
        view
        returns (
            uint256 maxNotionalPayFixed,
            uint256 maxNotionalReceiveFixed,
            uint256 maxCollateralRatioPayFixed,
            uint256 maxCollateralRatioReceiveFixed,
            uint256 maxCollateralRatio,
            uint256 lastUpdateTimestamp,
            uint256 demandSpreadFactor
        );

    /// @notice Gets base spreads for a given asset. Rates represented in 18 decimals.
    /// @param asset underlying / stablecoin address supported in Ipor Protocol
    /// @return lastUpdateTimestamp Last base spreads update done by off-chain service
    /// @return spread28dPayFixed spread for 28 days pay fixed swap, value represented percentage in 18 decimals, example: 100% = 1e18, 50% = 5e17, 35% = 35e16, 0,1% = 1e15 = 1000 * 1e12
    /// @return spread28dReceiveFixed spread for 28 days receive fixed swap, value represented percentage in 18 decimals, example: 100% = 1e18, 50% = 5e17, 35% = 35e16, 0,1% = 1e15 = 1000 * 1e12
    /// @return spread60dPayFixed spread for 60 days pay fixed swap, value represented percentage in 18 decimals, example: 100% = 1e18, 50% = 5e17, 35% = 35e16, 0,1% = 1e15 = 1000 * 1e12
    /// @return spread60dReceiveFixed spread for 60 days receive fixed swap, value represented percentage in 18 decimals, example: 100% = 1e18, 50% = 5e17, 35% = 35e16, 0,1% = 1e15 = 1000 * 1e12
    /// @return spread90dPayFixed spread for 90 days pay fixed swap, value represented percentage in 18 decimals, example: 100% = 1e18, 50% = 5e17, 35% = 35e16, 0,1% = 1e15 = 1000 * 1e12
    /// @return spread90dReceiveFixed spread for 90 days receive fixed swap, value represented percentage in 18 decimals, example: 100% = 1e18, 50% = 5e17, 35% = 35e16, 0,1% = 1e15 = 1000 * 1e12
    function getBaseSpreads(
        address asset
    )
        external
        view
        returns (
            uint256 lastUpdateTimestamp,
            int256 spread28dPayFixed,
            int256 spread28dReceiveFixed,
            int256 spread60dPayFixed,
            int256 spread60dReceiveFixed,
            int256 spread90dPayFixed,
            int256 spread90dReceiveFixed
        );

    /// @notice Gets fixed rate cap for a given asset. Rates represented in 18 decimals.
    /// @param asset underlying / stablecoin address supported in Ipor Protocol
    /// @return lastUpdateTimestamp Last base spreads update done by off-chain service
    /// @return fixedRateCap28dPayFixed fixed rate cap for 28 days pay fixed swap, value represented percentage in 18 decimals, example: 100% = 1e18, 50% = 5e17, 35% = 35e16, 0,1% = 1e15 = 1000 * 1e12
    /// @return fixedRateCap28dReceiveFixed fixed rate cap for 28 days receive fixed swap, value represented percentage in 18 decimals, example: 100% = 1e18, 50% = 5e17, 35% = 35e16, 0,1% = 1e15 = 1000 * 1e12
    /// @return fixedRateCap60dPayFixed fixed rate cap for 60 days pay fixed swap, value represented percentage in 18 decimals, example: 100% = 1e18, 50% = 5e17, 35% = 35e16, 0,1% = 1e15 = 1000 * 1e12
    /// @return fixedRateCap60dReceiveFixed fixed rate cap for 60 days receive fixed swap, value represented percentage in 18 decimals, example: 100% = 1e18, 50% = 5e17, 35% = 35e16, 0,1% = 1e15 = 1000 * 1e12
    /// @return fixedRateCap90dPayFixed fixed rate cap for 90 days pay fixed swap, value represented percentage in 18 decimals, example: 100% = 1e18, 50% = 5e17, 35% = 35e16, 0,1% = 1e15 = 1000 * 1e12
    /// @return fixedRateCap90dReceiveFixed fixed rate cap for 90 days receive fixed swap, value represented percentage in 18 decimals, example: 100% = 1e18, 50% = 5e17, 35% = 35e16, 0,1% = 1e15 = 1000 * 1e12
    function getFixedRateCaps(
        address asset
    )
        external
        view
        returns (
            uint256 lastUpdateTimestamp,
            uint256 fixedRateCap28dPayFixed,
            uint256 fixedRateCap28dReceiveFixed,
            uint256 fixedRateCap60dPayFixed,
            uint256 fixedRateCap60dReceiveFixed,
            uint256 fixedRateCap90dPayFixed,
            uint256 fixedRateCap90dReceiveFixed
        );

    /// @notice Checks if given asset is supported by IPOR Protocol.
    /// @param asset underlying / stablecoin address
    function isAssetSupported(address asset) external view returns (bool);

    /// @notice Checks if given account is an Updater.
    /// @param account account for checking
    /// @return 0 if account is not updater, 1 if account is updater.
    function isUpdater(address account) external view returns (uint256);

    /// @notice Updates risk indicators for a given asset. Values and rates are not represented in 18 decimals.
    /// @dev Emmits {RiskIndicatorsUpdated} event.
    /// @param asset underlying / stablecoin address supported by IPOR Protocol
    /// @param maxNotionalPayFixed maximum notional value for pay fixed leg, 1 = 10k
    /// @param maxNotionalReceiveFixed maximum notional value for receive fixed leg, 1 = 10k
    /// @param maxCollateralRatioPayFixed maximum collateral ratio for pay fixed leg, 1 = 0.01%
    /// @param maxCollateralRatioReceiveFixed maximum collateral ratio for receive fixed leg, 1 = 0.01%
    /// @param maxCollateralRatio maximum collateral ratio for both legs, 1 = 0.01%
    /// @param demandSpreadFactor28 demand spread factor, value represents without decimals, used to calculate demand spread
    /// @param demandSpreadFactor60 demand spread factor, value represents without decimals, used to calculate demand spread
    /// @param demandSpreadFactor90 demand spread factor, value represents without decimals, used to calculate demand spread
    function updateRiskIndicators(
        address asset,
        uint256 maxNotionalPayFixed,
        uint256 maxNotionalReceiveFixed,
        uint256 maxCollateralRatioPayFixed,
        uint256 maxCollateralRatioReceiveFixed,
        uint256 maxCollateralRatio,
        uint256 demandSpreadFactor28,
        uint256 demandSpreadFactor60,
        uint256 demandSpreadFactor90
    ) external;

    /// @notice Updates base spreads and fixed rate caps for a given asset. Rates are not represented in 18 decimals
    /// @dev Emmits {BaseSpreadsUpdated} event.
    /// @param asset underlying / stablecoin address supported by IPOR Protocol
    /// @param baseSpreadsAndFixedRateCaps base spreads and fixed rate caps for a given asset
    function updateBaseSpreadsAndFixedRateCaps(
        address asset,
        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps calldata baseSpreadsAndFixedRateCaps
    ) external;

    /// @notice Adds asset which IPOR Protocol will support. Function available only for Owner.
    /// @param asset underlying / stablecoin address which will be supported by IPOR Protocol.
    /// @param riskIndicators risk indicators
    /// @param baseSpreadsAndFixedRateCaps base spread and fixed rate cap for each maturities and both legs
    function addAsset(
        address asset,
        IporRiskManagementOracleTypes.RiskIndicators calldata riskIndicators,
        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps calldata baseSpreadsAndFixedRateCaps
    ) external;

    /// @notice Removes asset which IPOR Protocol will not support. Function available only for Owner.
    /// @param asset  underlying / stablecoin address which current is supported by IPOR Protocol.
    function removeAsset(address asset) external;

    /// @notice Adds new Updater. Updater has right to update indicators. Function available only for Owner.
    /// @param newUpdater new updater address
    function addUpdater(address newUpdater) external;

    /// @notice Removes Updater. Function available only for Owner.
    /// @param updater updater address
    function removeUpdater(address updater) external;
}
