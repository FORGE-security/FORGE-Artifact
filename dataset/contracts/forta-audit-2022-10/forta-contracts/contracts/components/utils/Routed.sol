// SPDX-License-Identifier: UNLICENSED
// See Forta Network License: https://github.com/forta-network/forta-contracts/blob/master/LICENSE.md

pragma solidity ^0.8.9;

import "./AccessManaged.sol";

/**
 * Since Router is deprecated, we are keeping RoutedUpgradeable in this state to preserve storage
 * layout in deployed `BaseComponentUpgradeable` contracts.
 */
abstract contract RoutedUpgradeable is AccessManagedUpgradeable {

    /// @custom:oz-retyped-from IRouter
    /// @custom:oz-renamed-from _router
    address private _deprecated_router;

    event RouterUpdated(address indexed router);

    /// Sets Router instance to address(0).
    function disableRouter() public {
        if (_deprecated_router == address(0)) {
            revert ZeroAddress("_deprecated_router");
        }
        _deprecated_router = address(0);
        emit RouterUpdated(address(0));
    }

    uint256[49] private __gap;
}