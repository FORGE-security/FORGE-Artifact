// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./HoldefiOwnable.sol";

/// @notice File: contracts/Holdefi.sol
interface HoldefiInterface {
	struct Market {
		uint256 totalSupply;
		uint256 supplyIndex;
		uint256 supplyIndexUpdateTime;

		uint256 totalBorrow;
		uint256 borrowIndex;
		uint256 borrowIndexUpdateTime;

		uint256 promotionReserveScaled;
		uint256 promotionReserveLastUpdateTime;
		uint256 promotionDebtScaled;
		uint256 promotionDebtLastUpdateTime;
	}

	function marketAssets(address market) external view returns (Market memory);
	function holdefiSettings() external view returns (address contractAddress);
	function beforeChangeSupplyRate (address market) external;
	function beforeChangeBorrowRate (address market) external;
	function reserveSettlement (address market) external;
}

/// @title HoldefiSettings contract
/// @author Holdefi Team
/// @notice This contract is for Holdefi settings implementation
/// @dev Error codes description: 
/// 	SE01: Market is not exist
/// 	SE02: Collateral is not exist
/// 	SE03: Conflict with Holdefi contract
/// 	SE04: The contract should be set once
/// 	SE05: Rate should be in the allowed range
/// 	SE06: Sender should be Holdefi contract
/// 	SE07: Collateral is exist
/// 	SE08: Market is exist
/// 	SE09: Market list is full
/// 	SE10: Total borrow is not zero
/// 	SE11: Changing rate is not allowed at this time
/// 	SE12: Changing rate should be less than Max allowed
contract HoldefiSettings is HoldefiOwnable {

	using SafeMath for uint256;

	/// @notice Markets Features
	struct MarketSettings {
		bool isExist;		// Market is exist or not
		bool isActive;		// Market is open for deposit or not

		uint256 borrowRate;
		uint256 borrowRateUpdateTime;

		uint256 suppliersShareRate;
		uint256 suppliersShareRateUpdateTime;

		uint256 promotionRate;
	}

	/// @notice Collateral Features
	struct CollateralSettings {
		bool isExist;		// Collateral is exist or not
		bool isActive;		// Collateral is open for deposit or not

		uint256 valueToLoanRate;
		uint256 VTLUpdateTime;

		uint256 penaltyRate;
		uint256 penaltyUpdateTime;

		uint256 bonusRate;
	}

	uint256 constant private rateDecimals = 10 ** 4;

	address constant private ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

	uint256 constant private periodBetweenUpdates = 604800;      	// seconds per week

	uint256 constant private maxBorrowRate = 4000;      			// 40%

	uint256 constant private borrowRateMaxIncrease = 500;      		// 5%

	uint256 constant private minSuppliersShareRate = 5000;      	// 50%

	uint256 constant private suppliersShareRateMaxDecrease = 500;	// 5%

	uint256 constant private maxValueToLoanRate = 20000;      		// 200%

	uint256 constant private valueToLoanRateMaxIncrease = 500;      // 5%

	uint256 constant private maxPenaltyRate = 13000;      			// 130%

	uint256 constant private penaltyRateMaxIncrease = 500;      	// 5%

	uint256 constant private maxPromotionRate = 10000;				// 100%

	uint256 constant private maxListsLength = 50;

	/// @dev Used for calculating liquidation threshold 
	/// There is 5% gap between value to loan rate and liquidation rate
	uint256 constant private fivePercentLiquidationGap = 500;

	mapping (address => MarketSettings) public marketAssets;
	address[] public marketsList;

	mapping (address => CollateralSettings) public collateralAssets;

	HoldefiInterface public holdefiContract;

	/// @notice Event emitted when market activation status is changed
	event MarketActivationChanged(address indexed market, bool status);

	/// @notice Event emitted when collateral activation status is changed
	event CollateralActivationChanged(address indexed collateral, bool status);

	/// @notice Event emitted when market existence status is changed
	event MarketExistenceChanged(address indexed market, bool status);

	/// @notice Event emitted when collateral existence status is changed
	event CollateralExistenceChanged(address indexed collateral, bool status);

	/// @notice Event emitted when market borrow rate is changed
	event BorrowRateChanged(address indexed market, uint256 newRate, uint256 oldRate);

	/// @notice Event emitted when market suppliers share rate is changed
	event SuppliersShareRateChanged(address indexed market, uint256 newRate, uint256 oldRate);

	/// @notice Event emitted when market promotion rate is changed
	event PromotionRateChanged(address indexed market, uint256 newRate, uint256 oldRate);

	/// @notice Event emitted when collateral value to loan rate is changed
	event ValueToLoanRateChanged(address indexed collateral, uint256 newRate, uint256 oldRate);

	/// @notice Event emitted when collateral penalty rate is changed
	event PenaltyRateChanged(address indexed collateral, uint256 newRate, uint256 oldRate);

	/// @notice Event emitted when collateral bonus rate is changed
	event BonusRateChanged(address indexed collateral, uint256 newRate, uint256 oldRate);


	/// @dev Modifier to make a function callable only when the market is exist
	/// @param market Address of the given market
    modifier marketIsExist(address market) {
        require (marketAssets[market].isExist, "SE01");
        _;
    }

	/// @dev Modifier to make a function callable only when the collateral is exist
	/// @param collateral Address of the given collateral
    modifier collateralIsExist(address collateral) {
        require (collateralAssets[collateral].isExist, "SE02");
        _;
    }


	/// @notice you cannot send ETH to this contract
    receive() external payable {
        revert();
    }

 	/// @notice Activate a market asset
	/// @dev Can only be called by the owner
	/// @param market Address of the given market
	function activateMarket (address market) external onlyOwner marketIsExist(market) {
		activateMarketInternal(market);
	}

	/// @notice Deactivate a market asset
	/// @dev Can only be called by the owner
	/// @param market Address of the given market
	function deactivateMarket (address market) external onlyOwner marketIsExist(market) {
		marketAssets[market].isActive = false;
		emit MarketActivationChanged(market, false);
	}

	/// @notice Activate a collateral asset
	/// @dev Can only be called by the owner
	/// @param collateral Address the given collateral
	function activateCollateral (address collateral) external onlyOwner collateralIsExist(collateral) {
		activateCollateralInternal(collateral);
	}

	/// @notice Deactivate a collateral asset
	/// @dev Can only be called by the owner
	/// @param collateral Address of the given collateral
	function deactivateCollateral (address collateral) external onlyOwner collateralIsExist(collateral) {
		collateralAssets[collateral].isActive = false;
		emit CollateralActivationChanged(collateral, false);
	}

	/// @notice Returns the list of markets
	/// @return res List of markets
	function getMarketsList() external view returns (address[] memory res) {
		res = marketsList;
	}

	/// @notice Disposable function to interact with Holdefi contract
	/// @dev Can only be called by the owner
	/// @param holdefiContractAddress Address of the Holdefi contract
	function setHoldefiContract(HoldefiInterface holdefiContractAddress) external onlyOwner {
		require (holdefiContractAddress.holdefiSettings() == address(this), "SE03");
		require (address(holdefiContract) == address(0), "SE04");
		holdefiContract = holdefiContractAddress;
	}

	/// @notice Returns supply, borrow and promotion rate of the given market
	/// @dev supplyRate = (totalBorrow * borrowRate) * suppliersShareRate / totalSupply
	/// @param market Address of the given market
	/// @return borrowRate Borrow rate of the given market
	/// @return supplyRateBase Supply rate base of the given market
	/// @return promotionRate Promotion rate of the given market
	function getInterests (address market)
		external
		view
		returns (uint256 borrowRate, uint256 supplyRateBase, uint256 promotionRate)
	{
		uint256 totalBorrow = holdefiContract.marketAssets(market).totalBorrow;
		uint256 totalSupply = holdefiContract.marketAssets(market).totalSupply;
		borrowRate = marketAssets[market].borrowRate;

		if (totalSupply == 0) {
			supplyRateBase = 0;
		}
		else {
			uint256 totalInterestFromBorrow = totalBorrow.mul(borrowRate);
			uint256 suppliersShare = totalInterestFromBorrow.mul(marketAssets[market].suppliersShareRate).div(rateDecimals);
			supplyRateBase = suppliersShare.div(totalSupply);
		}
		promotionRate = marketAssets[market].promotionRate;
	}


	/// @notice Set promotion rate for a market
	/// @dev Can only be called by the owner
	/// @param market Address of the given market
	/// @param newPromotionRate New promotion rate
	function setPromotionRate (address market, uint256 newPromotionRate) external onlyOwner {
		require (newPromotionRate <= maxPromotionRate, "SE05");

		holdefiContract.reserveSettlement(market);

		emit PromotionRateChanged(market, newPromotionRate, marketAssets[market].promotionRate);
		marketAssets[market].promotionRate = newPromotionRate;
	}

	/// @notice Reset promotion rate of the market to zero
	/// @dev Can only be called by holdefi contract
	/// @param market Address of the given market
	function resetPromotionRate (address market) external {
		require (msg.sender == address(holdefiContract), "SE06");

		emit PromotionRateChanged(market, 0, marketAssets[market].promotionRate);
		marketAssets[market].promotionRate = 0;
	}

	/// @notice Set borrow rate for a market
	/// @dev Can only be called by the owner
	/// @param market Address of the given market
	/// @param newBorrowRate New borrow rate
	function setBorrowRate (address market, uint256 newBorrowRate)
		external 
		onlyOwner
		marketIsExist(market)
	{
		setBorrowRateInternal(market, newBorrowRate);
	}

	/// @notice Set suppliers share rate for a market
	/// @dev Can only be called by the owner
	/// @param market Address of the given market
	/// @param newSuppliersShareRate New suppliers share rate
	function setSuppliersShareRate (address market, uint256 newSuppliersShareRate)
		external
		onlyOwner
		marketIsExist(market)
	{
		setSuppliersShareRateInternal(market, newSuppliersShareRate);
	}

	/// @notice Set value to loan rate for a collateral
	/// @dev Can only be called by the owner
	/// @param collateral Address of the given collateral
	/// @param newValueToLoanRate New value to loan rate
	function setValueToLoanRate (address collateral, uint256 newValueToLoanRate)
		external
		onlyOwner
		collateralIsExist(collateral)
	{
		setValueToLoanRateInternal(collateral, newValueToLoanRate);
	}

	/// @notice Set penalty rate for a collateral
	/// @dev Can only be called by the owner
	/// @param collateral Address of the given collateral
	/// @param newPenaltyRate New penalty rate
	function setPenaltyRate (address collateral, uint256 newPenaltyRate)
		external
		onlyOwner
		collateralIsExist(collateral)
	{
		setPenaltyRateInternal(collateral, newPenaltyRate);
	}

	/// @notice Set bonus rate for a collateral
	/// @dev Can only be called by the owner
	/// @param collateral Address of the given collateral
	/// @param newBonusRate New bonus rate
	function setBonusRate (address collateral, uint256 newBonusRate)
		external
		onlyOwner
		collateralIsExist(collateral)
	{
		setBonusRateInternal(collateral, newBonusRate); 
	}

	/// @notice Add a new asset as a market
	/// @dev Can only be called by the owner
	/// @param market Address of the new market
	/// @param borrowRate BorrowRate of the new market
	/// @param suppliersShareRate SuppliersShareRate of the new market
	function addMarket (address market, uint256 borrowRate, uint256 suppliersShareRate)
		external
		onlyOwner
	{
		require (!marketAssets[market].isExist, "SE08");
		require (marketsList.length < maxListsLength, "SE09");

		if (market != ethAddress) {
			IERC20(market);
		}

		marketsList.push(market);
		marketAssets[market].isExist = true;
		emit MarketExistenceChanged(market, true);

		setBorrowRateInternal(market, borrowRate);
		setSuppliersShareRateInternal(market, suppliersShareRate);
		
		activateMarketInternal(market);		
	}

	/// @notice Remove a market asset
	/// @dev Can only be called by the owner
	/// @param market Address of the given market
	function removeMarket (address market) external onlyOwner marketIsExist(market) {
		require (holdefiContract.marketAssets(market).totalBorrow == 0, "SE10");
		
		holdefiContract.beforeChangeBorrowRate(market);

		uint256 i;
		uint256 index;
		uint256 marketListLength = marketsList.length;
		for (i = 0 ; i < marketListLength ; i++) {
			if (marketsList[i] == market) {
				index = i;
			}
		}

		if (index != marketListLength-1) {
			for (i = index ; i < marketListLength-1 ; i++) {
				marketsList[i] = marketsList[i+1];
			}
		}

		marketsList.pop();
		delete marketAssets[market];
		emit MarketExistenceChanged(market, false);
	}

	/// @notice Add a new asset as a collateral
	/// @dev Can only be called by the owner
	/// @param collateral Address of the new collateral
	/// @param valueToLoanRate ValueToLoanRate of the new collateral
	/// @param penaltyRate PenaltyRate of the new collateral
	/// @param bonusRate BonusRate of the new collateral
	function addCollateral (
		address collateral,
		uint256 valueToLoanRate,
		uint256 penaltyRate,
		uint256 bonusRate
	)
		external
		onlyOwner
	{
		require (!collateralAssets[collateral].isExist, "SE07");

		if (collateral != ethAddress) {
			IERC20(collateral);
		}

		collateralAssets[collateral].isExist = true;
		emit CollateralExistenceChanged(collateral, true);

		setValueToLoanRateInternal(collateral, valueToLoanRate);
		setPenaltyRateInternal(collateral, penaltyRate);
		setBonusRateInternal(collateral, bonusRate);

		activateCollateralInternal(collateral);
	}

	/// @notice Activate the market
	function activateMarketInternal (address market) internal {
		marketAssets[market].isActive = true;
		emit MarketActivationChanged(market, true);
	}

	/// @notice Activate the collateral
	function activateCollateralInternal (address collateral) internal {
		collateralAssets[collateral].isActive = true;
		emit CollateralActivationChanged(collateral, true);
	}

	/// @notice Set borrow rate operation
	function setBorrowRateInternal (address market, uint256 newBorrowRate) internal {
		require (newBorrowRate <= maxBorrowRate, "SE05");
		uint256 currentTime = block.timestamp;

		if (marketAssets[market].borrowRateUpdateTime != 0) {
			if (newBorrowRate > marketAssets[market].borrowRate) {
				uint256 deltaTime = currentTime.sub(marketAssets[market].borrowRateUpdateTime);
				require (deltaTime >= periodBetweenUpdates, "SE11");

				uint256 maxIncrease = marketAssets[market].borrowRate.add(borrowRateMaxIncrease);
				require (newBorrowRate <= maxIncrease, "SE12");
			}

			holdefiContract.beforeChangeBorrowRate(market);
		}

		emit BorrowRateChanged(market, newBorrowRate, marketAssets[market].borrowRate);

		marketAssets[market].borrowRate = newBorrowRate;
		marketAssets[market].borrowRateUpdateTime = currentTime;
	}

	/// @notice Set suppliers share rate operation
	function setSuppliersShareRateInternal (address market, uint256 newSuppliersShareRate) internal {
		require (
			newSuppliersShareRate >= minSuppliersShareRate && newSuppliersShareRate <= rateDecimals,
			"SE05"
		);
		uint256 currentTime = block.timestamp;

		if (marketAssets[market].suppliersShareRateUpdateTime != 0) {
			if (newSuppliersShareRate < marketAssets[market].suppliersShareRate) {
				uint256 deltaTime = currentTime.sub(marketAssets[market].suppliersShareRateUpdateTime);
				require (deltaTime >= periodBetweenUpdates, "SE11");

				uint256 decreasedAllowed = newSuppliersShareRate.add(suppliersShareRateMaxDecrease);
				require (
					marketAssets[market].suppliersShareRate <= decreasedAllowed,
					"SE12"
				);
			}

			holdefiContract.beforeChangeSupplyRate(market);
		}

		emit SuppliersShareRateChanged(
			market,
			newSuppliersShareRate,
			marketAssets[market].suppliersShareRate
		);

		marketAssets[market].suppliersShareRate = newSuppliersShareRate;
		marketAssets[market].suppliersShareRateUpdateTime = currentTime;
	}

	/// @notice Set value to loan rate operation
	function setValueToLoanRateInternal (address collateral, uint256 newValueToLoanRate) internal {
		require (
			newValueToLoanRate <= maxValueToLoanRate &&
			collateralAssets[collateral].penaltyRate.add(fivePercentLiquidationGap) <= newValueToLoanRate,
			"SE05"
		);
		
		uint256 currentTime = block.timestamp;
		if (
			collateralAssets[collateral].VTLUpdateTime != 0 &&
			newValueToLoanRate > collateralAssets[collateral].valueToLoanRate
		) {
			uint256 deltaTime = currentTime.sub(collateralAssets[collateral].VTLUpdateTime);
			require (deltaTime >= periodBetweenUpdates,"SE11");
			uint256 maxIncrease = collateralAssets[collateral].valueToLoanRate.add(
				valueToLoanRateMaxIncrease
			);
			require (newValueToLoanRate <= maxIncrease,"SE12");
		}
		emit ValueToLoanRateChanged(
			collateral,
			newValueToLoanRate,
			collateralAssets[collateral].valueToLoanRate
		);

	    collateralAssets[collateral].valueToLoanRate = newValueToLoanRate;
	    collateralAssets[collateral].VTLUpdateTime = currentTime;
	}

	/// @notice Set penalty rate operation
	function setPenaltyRateInternal (address collateral, uint256 newPenaltyRate) internal {
		require (
			newPenaltyRate <= maxPenaltyRate &&
			newPenaltyRate <= collateralAssets[collateral].valueToLoanRate.sub(fivePercentLiquidationGap) &&
			collateralAssets[collateral].bonusRate <= newPenaltyRate,
			"SE05"
		);

		uint256 currentTime = block.timestamp;
		if (
			collateralAssets[collateral].penaltyUpdateTime != 0 &&
			newPenaltyRate > collateralAssets[collateral].penaltyRate
		) {
			uint256 deltaTime = currentTime.sub(collateralAssets[collateral].penaltyUpdateTime);
			require (deltaTime >= periodBetweenUpdates, "SE11");
			uint256 maxIncrease = collateralAssets[collateral].penaltyRate.add(penaltyRateMaxIncrease);
			require (newPenaltyRate <= maxIncrease, "SE12");
		}

		emit PenaltyRateChanged(collateral, newPenaltyRate, collateralAssets[collateral].penaltyRate);

	    collateralAssets[collateral].penaltyRate  = newPenaltyRate;
	    collateralAssets[collateral].penaltyUpdateTime = currentTime;
	}

	/// @notice Set Bonus rate operation
	function setBonusRateInternal (address collateral, uint256 newBonusRate) internal {
		require (
			newBonusRate <= collateralAssets[collateral].penaltyRate && newBonusRate >= rateDecimals,
			"SE05"
		);
		
		emit BonusRateChanged(collateral, newBonusRate, collateralAssets[collateral].bonusRate);
	    collateralAssets[collateral].bonusRate = newBonusRate;    
	}
}
