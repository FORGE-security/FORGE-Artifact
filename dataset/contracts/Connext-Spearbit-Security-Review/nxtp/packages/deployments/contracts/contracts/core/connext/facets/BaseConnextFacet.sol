// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {Home} from "../../../nomad-core/contracts/Home.sol";

import {AppStorage} from "../libraries/LibConnextStorage.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

contract BaseConnextFacet {
  AppStorage internal s;

  // ========== Properties ===========
  uint256 internal constant _NOT_ENTERED = 1;
  uint256 internal constant _ENTERED = 2;

  // Contains hash of empty bytes
  bytes32 internal constant EMPTY = hex"c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";

  // ========== Custom Errors ===========

  error BaseConnextFacet__onlyBridgeRouter_notBridgeRouter();
  error BaseConnextFacet__onlyOwner_notOwner();
  error BaseConnextFacet__onlyProposed_notProposedOwner();
  error BaseConnextFacet__whenNotPaused_paused();
  error BaseConnextFacet__nonReentrant_reentrantCall();

  // ============ Modifiers ============

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `nonReentrant` function from another `nonReentrant`
   * function is not supported. It is possible to prevent this from happening
   * by making the `nonReentrant` function external, and making it call a
   * `private` function that does the actual work.
   */
  modifier nonReentrant() {
    // On the first call to nonReentrant, _notEntered will be true
    if (s._status == _ENTERED) revert BaseConnextFacet__nonReentrant_reentrantCall();

    // Any calls to nonReentrant after this point will fail
    s._status = _ENTERED;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    s._status = _NOT_ENTERED;
  }

  /**
   * @notice Throws if called by any account other than the proposed owner.
   */
  modifier onlyBridgeRouter() {
    if (address(s.bridgeRouter) != msg.sender) revert BaseConnextFacet__onlyBridgeRouter_notBridgeRouter();
    _;
  }

  /**
   * @notice Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    if (LibDiamond.contractOwner() != msg.sender) revert BaseConnextFacet__onlyOwner_notOwner();
    _;
  }

  /**
   * @notice Throws if called by any account other than the proposed owner.
   */
  modifier onlyProposed() {
    if (s._proposed != msg.sender) revert BaseConnextFacet__onlyProposed_notProposedOwner();
    _;
  }

  /**
   * @notice Throws if all functionality is paused
   */
  modifier whenNotPaused() {
    if (s._paused) revert BaseConnextFacet__whenNotPaused_paused();
    _;
  }

  // ============ Internal functions ============
  /**
   * @notice Indicates if the ownership of the router whitelist has
   * been renounced
   */
  function _isRouterOwnershipRenounced() internal view returns (bool) {
    return LibDiamond.contractOwner() == address(0) || s._routerOwnershipRenounced;
  }

  /**
   * @notice Indicates if the ownership of the asset whitelist has
   * been renounced
   */
  function _isAssetOwnershipRenounced() internal view returns (bool) {
    return LibDiamond.contractOwner() == address(0) || s._assetOwnershipRenounced;
  }
}
