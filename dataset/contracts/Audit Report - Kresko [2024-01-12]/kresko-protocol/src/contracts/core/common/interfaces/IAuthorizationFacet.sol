// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

interface IAuthorizationFacet {
    /**
     * @dev OpenZeppelin
     * Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * @notice WARNING:
     * When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block.
     *
     * See the following forum post for more information:
     * - https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296
     *
     * @dev Kresko
     *
     * TL;DR above:
     *
     * - If you iterate the EnumSet outside a single block scope you might get different results.
     * - Since when EnumSet member is deleted it is replaced with the highest index.
     * @return address with the `role`
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     * @notice See warning in {getRoleMember} if combining these two
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * @notice To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Returns true if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * @notice Requirements
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * @notice Requirements
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;
}
