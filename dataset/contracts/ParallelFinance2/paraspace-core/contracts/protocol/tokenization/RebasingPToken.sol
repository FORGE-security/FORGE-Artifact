// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IPool} from "../../interfaces/IPool.sol";
import {PToken} from "./PToken.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";

/**
 * @title Rebasing PToken
 *
 * @notice Implementation of the interest bearing token for the ParaSpace protocol
 */
contract RebasingPToken is PToken {
    using WadRayMath for uint256;

    constructor(IPool pool) PToken(pool) {
        //intentionally empty
    }

    /**
     * @dev Calculates the balance of the user: principal balance + interest generated by the principal
     * @param user The user whose balance is calculated
     * @return The balance of the user
     **/
    function balanceOf(address user) public view override returns (uint256) {
        return
            _scaledBalanceOf(user, lastRebasingIndex()).rayMul(
                POOL.getReserveNormalizedIncome(_underlyingAsset)
            );
    }

    /**
     * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
     * updated stored balance divided by the reserve's liquidity index at the moment of the update
     * @param user The user whose balance is calculated
     * @return The scaled balance of the user
     **/
    function scaledBalanceOf(address user)
        public
        view
        override
        returns (uint256)
    {
        return _scaledBalanceOf(user, lastRebasingIndex());
    }

    /**
     * @dev Returns the scaled balance of the user and the scaled total supply.
     * @param user The address of the user
     * @return The scaled balance of the user
     * @return The scaled balance and the scaled total supply
     **/
    function getScaledUserBalanceAndSupply(address user)
        external
        view
        override
        returns (uint256, uint256)
    {
        uint256 rebasingIndex = lastRebasingIndex();
        return (
            _scaledBalanceOf(user, rebasingIndex),
            _scaledTotalSupply(rebasingIndex)
        );
    }

    /**
     * @dev calculates the total supply of the specific aToken
     * since the balance of every single user increases over time, the total supply
     * does that too.
     * @return the current total supply
     **/
    function totalSupply() public view override returns (uint256) {
        uint256 currentSupplyScaled = _scaledTotalSupply(lastRebasingIndex());

        if (currentSupplyScaled == 0) {
            return 0;
        }

        return
            currentSupplyScaled.rayMul(
                POOL.getReserveNormalizedIncome(_underlyingAsset)
            );
    }

    /**
     * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
     * @return the scaled total supply
     **/
    function scaledTotalSupply()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _scaledTotalSupply(lastRebasingIndex());
    }

    function _scaledBalanceOf(address user, uint256 rebasingIndex)
        internal
        view
        returns (uint256)
    {
        return ((super.scaledBalanceOf(user) * rebasingIndex) / WadRayMath.RAY);
    }

    function _scaledTotalSupply(uint256 rebasingIndex)
        internal
        view
        returns (uint256)
    {
        return ((super.scaledTotalSupply() * rebasingIndex) / WadRayMath.RAY);
    }

    /**
     * @return Current rebasing index of stETH in RAY
     **/
    function lastRebasingIndex() internal view virtual returns (uint256) {
        // returns 1 RAY by default which makes it identical to PToken in behaviour
        return WadRayMath.RAY;
    }
}
