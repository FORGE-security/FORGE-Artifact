/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity 0.8.10;

library UnstructuredStorage {
    function getStorageBool(bytes32 position) internal view returns (bool data) {
        assembly {
            data := sload(position)
        }
    }

    function getStorageAddress(bytes32 position) internal view returns (address data) {
        assembly {
            data := sload(position)
        }
    }

    function getStorageBytes32(bytes32 position) internal view returns (bytes32 data) {
        assembly {
            data := sload(position)
        }
    }

    function getStorageUint256(bytes32 position) internal view returns (uint256 data) {
        assembly {
            data := sload(position)
        }
    }

    function setStorageBool(bytes32 position, bool data) internal {
        assembly {
            sstore(position, data)
        }
    }

    function setStorageAddress(bytes32 position, address data) internal {
        assembly {
            sstore(position, data)
        }
    }

    function setStorageBytes32(bytes32 position, bytes32 data) internal {
        assembly {
            sstore(position, data)
        }
    }

    function setStorageUint256(bytes32 position, uint256 data) internal {
        assembly {
            sstore(position, data)
        }
    }
}
