// SPDX-License-Identifier: AGPL-3.0-only

/*
    ContractManager.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Artem Payvin

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
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {
    AddressUpgradeable
} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { IContractManager } from "@skalenetwork/skale-manager-interfaces/IContractManager.sol";

import { StringUtils } from "./utils/StringUtils.sol";
import { InitializableWithGap } from "./thirdparty/openzeppelin/InitializableWithGap.sol";

/**
 * @title ContractManager
 * @dev Contract contains the actual current mapping from contract IDs
 * (in the form of human-readable strings) to addresses.
 */
contract ContractManager is InitializableWithGap, OwnableUpgradeable, IContractManager {
    using StringUtils for string;
    using AddressUpgradeable for address;

    string public constant BOUNTY = "Bounty";
    string public constant CONSTANTS_HOLDER = "ConstantsHolder";
    string public constant DELEGATION_PERIOD_MANAGER = "DelegationPeriodManager";
    string public constant PUNISHER = "Punisher";
    string public constant SKALE_TOKEN = "SkaleToken";
    string public constant TIME_HELPERS = "TimeHelpers";
    string public constant TOKEN_STATE = "TokenState";
    string public constant VALIDATOR_SERVICE = "ValidatorService";

    // mapping of actual smart contracts addresses
    mapping (bytes32 => address) public override contracts;

    function initialize() external override initializer {
        OwnableUpgradeable.__Ownable_init();
    }

    /**
     * @dev Allows the Owner to add contract to mapping of contract addresses.
     *
     * Emits a {ContractUpgraded} event.
     *
     * Requirements:
     *
     * - New address is non-zero.
     * - Contract is not already added.
     * - Contract address contains code.
     */
    function setContractsAddress(
        string calldata contractsName,
        address newContractsAddress
    )
        external
        override
        onlyOwner
    {
        // check newContractsAddress is not equal to zero
        require(newContractsAddress != address(0), "New address is equal zero");
        // create hash of contractsName
        bytes32 contractId = keccak256(abi.encodePacked(contractsName));
        // check newContractsAddress is not equal the previous contract's address
        require(contracts[contractId] != newContractsAddress, "Contract is already added");
        require(newContractsAddress.isContract(), "Given contract address does not contain code");
        // add newContractsAddress to mapping of actual contract addresses
        contracts[contractId] = newContractsAddress;
        emit ContractUpgraded(contractsName, newContractsAddress);
    }

    /**
     * @dev Returns contract address.
     *
     * Requirements:
     *
     * - Contract must exist.
     */
    function getDelegationPeriodManager()
        external
        view
        override
        returns (address delegationPeriodManager)
    {
        return getContract(DELEGATION_PERIOD_MANAGER);
    }

    function getBounty() external view override returns (address bounty) {
        return getContract(BOUNTY);
    }

    function getValidatorService() external view override returns (address validatorService) {
        return getContract(VALIDATOR_SERVICE);
    }

    function getTimeHelpers() external view override returns (address timeHelpers) {
        return getContract(TIME_HELPERS);
    }

    function getConstantsHolder() external view override returns (address constantsHolder) {
        return getContract(CONSTANTS_HOLDER);
    }

    function getSkaleToken() external view override returns (address skaleToken) {
        return getContract(SKALE_TOKEN);
    }

    function getTokenState() external view override returns (address tokenState) {
        return getContract(TOKEN_STATE);
    }

    function getPunisher() external view override returns (address punisher) {
        return getContract(PUNISHER);
    }

    function getContract(
        string memory name
    )
        public
        view
        override
        returns (address contractAddress)
    {
        contractAddress = contracts[keccak256(abi.encodePacked(name))];
        if (contractAddress == address(0)) {
            revert(name.strConcat(" contract has not been found"));
        }
    }
}
