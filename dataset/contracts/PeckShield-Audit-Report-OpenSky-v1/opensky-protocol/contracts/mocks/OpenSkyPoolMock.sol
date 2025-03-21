// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '../OpenSkyPool.sol';
import '../interfaces/IOpenSkyMoneymarket.sol';

interface IOpenSkyMoneyMarketUpdate {
    function simulateInterestIncrease(address to) external payable;
}

contract OpenSkyPoolMock is OpenSkyPool {
    using ReserveLogic for DataTypes.ReserveData;

    constructor(address settings_) OpenSkyPool(settings_) {}

    function updateState(
        uint256 reserveId,
        uint256 additionalAmount
    ) external {
        reserves[reserveId].updateState(additionalAmount);
    }

    function calculateIncome(uint256 reserveId, uint256 additionalIncome) external view returns (
        uint256, uint256, uint256, uint256, uint256
    ) {
        return reserves[reserveId].calculateIncome(additionalIncome);
    }

    function updateInterestPerSecond(
        uint256 reserveId,
        uint256 amountToAdd,
        uint256 amountToRemove
    ) external {
        reserves[reserveId].updateInterestPerSecond(amountToAdd, amountToRemove);
    }

    function updateLastMoneyMarketBalance(
        uint256 reserveId,
        uint256 amountToAdd,
        uint256 amountToRemove
    ) external {
        reserves[reserveId].updateLastMoneyMarketBalance(amountToAdd, amountToRemove);
    }

    function updateMoneyMarketIncome(uint256 reserveId) external payable {
        IOpenSkyMoneyMarketUpdate moneyMarket = IOpenSkyMoneyMarketUpdate(reserves[reserveId].moneyMarketAddress);
        moneyMarket.simulateInterestIncrease{value: msg.value}(reserves[reserveId].oTokenAddress);
    }

    function getMoneyMarketDelta(uint256 reserveId) public view returns (uint256) {
        return reserves[reserveId].getMoneyMarketDelta();
    }

    function getBorrowingInterestDelta(uint256 reserveId) public view returns (uint256) {
        return reserves[reserveId].getBorrowingInterestDelta();
    }
}
