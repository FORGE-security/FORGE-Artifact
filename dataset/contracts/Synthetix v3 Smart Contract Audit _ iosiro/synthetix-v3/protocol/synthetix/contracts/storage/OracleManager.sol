//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Represents Oracle Manager
 */
library OracleManager {
    bytes32 private constant _SLOT_ORACLE_MANAGER =
        keccak256(abi.encode("io.synthetix.synthetix.OracleManager"));

    struct Data {
        /**
         * @dev The oracle manager address.
         */
        address oracleManagerAddress;
    }

    /**
     * @dev Loads the singleton storage info about the oracle manager.
     */
    function load() internal pure returns (Data storage data) {
        bytes32 s = _SLOT_ORACLE_MANAGER;
        assembly {
            data.slot := s
        }
    }
}
