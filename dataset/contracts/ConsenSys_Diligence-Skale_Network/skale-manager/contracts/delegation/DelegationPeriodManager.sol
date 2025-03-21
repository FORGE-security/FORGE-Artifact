// SPDX-License-Identifier: AGPL-3.0-only

/*
    DelegationPeriodManager.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Dmytro Stebaiev
    @author Vadim Yavorsky

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.8.17;

import {
    IDelegationPeriodManager
} from "@skalenetwork/skale-manager-interfaces/delegation/IDelegationPeriodManager.sol";

import {Permissions} from "../Permissions.sol";

/**
 * @title Delegation Period Manager
 * @dev This contract handles all delegation offerings. Delegations are held for
 * a specified period (months), and different durations can have different
 * returns or `stakeMultiplier`. Currently, only delegation periods can be added.
 */
contract DelegationPeriodManager is Permissions, IDelegationPeriodManager {
    mapping(uint256 => uint256) public stakeMultipliers;

    bytes32 public constant DELEGATION_PERIOD_SETTER_ROLE =
        keccak256("DELEGATION_PERIOD_SETTER_ROLE");

    /**
     * @dev Initial delegation period and multiplier settings.
     */
    function initialize(address contractsAddress) public override initializer {
        Permissions.initialize(contractsAddress);
        stakeMultipliers[2] = 100; // 2 months at 100
        // stakeMultipliers[6] = 150;  // 6 months at 150
        // stakeMultipliers[12] = 200; // 12 months at 200
    }

    /**
     * @dev Allows the Owner to create a new available delegation period and
     * stake multiplier in the network.
     *
     * Emits a {DelegationPeriodWasSet} event.
     */
    function setDelegationPeriod(
        uint256 monthsCount,
        uint256 stakeMultiplier
    ) external override {
        require(
            hasRole(DELEGATION_PERIOD_SETTER_ROLE, msg.sender),
            "DELEGATION_PERIOD_SETTER_ROLE is required"
        );
        require(
            stakeMultipliers[monthsCount] == 0,
            "Delegation period is already set"
        );
        stakeMultipliers[monthsCount] = stakeMultiplier;

        emit DelegationPeriodWasSet(monthsCount, stakeMultiplier);
    }

    /**
     * @dev Checks whether given delegation period is allowed.
     */
    function isDelegationPeriodAllowed(
        uint256 monthsCount
    ) external view override returns (bool allowed) {
        return stakeMultipliers[monthsCount] != 0;
    }
}
