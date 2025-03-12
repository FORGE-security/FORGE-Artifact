// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2020 Spilsbury Holdings Ltd
pragma solidity >=0.6.10 <=0.8.10;
pragma experimental ABIEncoderV2;

interface ISafeEngine {
    struct SAFE {
        // Total amount of collateral locked in a SAFE
        uint256 lockedCollateral;  // [wad]
        // Total amount of debt generated by a SAFE
        uint256 generatedDebt;     // [wad]
    }

    function approveSAFEModification(address account) external;

    function coinBalance(address account) external view returns (uint256);

    function safes(bytes32 collateralType, address safe) external view returns (SAFE memory);
}