// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../../../interfaces/types/IporTypes.sol";

/// @notice Structs used in the AmmStorage interface
library StorageInternalTypes {
    struct Swap {
        /// @notice Swap's ID
        uint32 id;
        /// @notice Address of swap's Buyer
        address buyer;
        /// @notice Starting EPOCH timestamp of this swap.
        uint32 openTimestamp;
        /// @notice Index position of this Swap in an array of swaps' identification associated to swap's buyer
        /// @dev Field used for gas optimization purposes, it allows for quick removal by id in the array.
        /// During removal the last item in the array is switched with the one that just has been removed.
        uint32 idsIndex;
        /// @notice Swap's collateral
        /// @dev value represented in 18 decimals
        uint128 collateral;
        /// @notice Swap's notional amount
        /// @dev value represented in 18 decimals
        uint128 notional;
        /// @notice Swap's notional amount denominated in the Interest Bearing Token (IBT)
        /// @dev value represented in 18 decimals
        uint128 ibtQuantity;
        /// @notice Fixed interest rate at which the position has been opened
        /// @dev value represented in 18 decimals
        uint64 fixedInterestRate;
        /// @notice Liquidation deposit amount
        /// @dev value represented WITHOUT decimals
        uint32 liquidationDepositAmount;
        /// @notice State of the swap
        /// @dev 0 - INACTIVE, 1 - ACTIVE
        IporTypes.SwapState state;
        /// @notice Swap's tenor, it is used to calculate the swap's end date, date when swap achieved maturity.
        /// @dev 0 - 28 days, 1 - 60 days, 2 - 90 days
        IporTypes.SwapTenor tenor;
    }

    /// @notice All active swaps available in AMM with information on swaps belong to the account.
    /// It describes swaps for a given leg.
    struct SwapContainer {
        /// @notice Swap details, key in the map is a swapId
        mapping(uint32 => Swap) swaps;
        /// @notice List of swap IDs for every account, key in the list is the account's address, and the value is a list of swap IDs
        mapping(address => uint32[]) ids;
    }

    /// @notice A struct containing balances that AMM keeps track of. It acts as a AMM's accounting book.
    /// Those balances are used in various calculations across the protocol.
    /// @dev All balances are in 18 decimals
    struct Balances {
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Fixed & Receive Floating leg.
        uint128 totalCollateralPayFixed;
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Floating & Receive Fixed leg.
        uint128 totalCollateralReceiveFixed;
        /// @notice Liquidity Pool Balance. This balance is where the liquidity from liquidity providers and the opening fee are accounted for,
        /// @dev Amount of opening fee accounted in this balance is defined by _OPENING_FEE_FOR_TREASURY_PORTION_RATE param.
        uint128 liquidityPool;
        /// @notice AssetManagement's current balance. It includes interest accrued until AssetManagement's most recent state change.
        uint128 vault;
        /// @notice This balance is used to track the funds accounted for IporOracle subsidization.
        uint128 iporPublicationFee;
        /// @notice Treasury is the balance that belongs to IPOR DAO and funds up to this amount can be transferred to the DAO-appointed multi-sig wallet.
        /// this ballance is fed by part of the opening fee appointed by the DAO. For more information refer to the documentation:
        /// https://ipor-labs.gitbook.io/ipor-labs/automated-market-maker/ipor-swaps#fees
        uint128 treasury;
    }

    /// @notice A struct with parameters required to calculate SOAP for pay fixed and receive fixed legs.
    /// @dev Saved to the databse.
    struct SoapIndicatorsStorage {
        /// @notice Value of interest accrued on a fixed leg of all derivatives for this particular type of swap.
        /// @dev  Is represented in 18 decimals.
        uint256 hypotheticalInterestCumulative;
        /// @notice Sum of all swaps' notional amounts for a given leg.
        /// @dev Is represented in 18 decimals.
        uint128 totalNotional;
        /// @notice Sum of all IBTs on a given leg.
        /// @dev Is represented in 18 decimals.
        uint128 totalIbtQuantity;
        /// @notice The notional-weighted average interest rate of all swaps on a given leg combined.
        /// @dev Is represented in 18 decimals.
        uint64 averageInterestRate;
        /// @notice EPOCH timestamp of when the most recent rebalancing took place
        uint32 rebalanceTimestamp;
    }
}
