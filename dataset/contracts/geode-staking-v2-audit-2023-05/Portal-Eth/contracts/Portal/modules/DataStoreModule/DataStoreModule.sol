// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

// interfaces
import {IDataStoreModule} from "../../interfaces/modules/IDataStoreModule.sol";
// libraries
import {DataStoreModuleLib as DSML} from "./libs/DataStoreModuleLib.sol";
// external
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title DSM: DataStore Module
 *
 * @notice A storage management tool designed to create a safe and scalable storage layout
 * for upgradable contracts with various types of data classes (users,packages,definitions).
 *
 * @dev review: this module delegates its functionality to DSML (DataStoreModuleLib).
 * DSM or DSML has NO access control.
 *
 * @dev There are no additional functionalities implemented seperately from the library.
 *
 * @dev NO function needs to be overriden when inherited.
 *
 * @dev __DataStoreModule_init (or _unchained) call is NOT NECESSARY when inherited.
 *
 * @dev No storage-altering external/public functions are exposed here, only view/pure external functions.
 *
 * @author Ice Bear & Crash Bandicoot
 */
abstract contract DataStoreModule is IDataStoreModule, Initializable {
  using DSML for DSML.IsolatedStorage;

  /**
   * @custom:section                           ** VARIABLES **
   *
   * @dev Do not add any other variables here. Modules do NOT have a gap.
   * Library's main struct has a gap, providing up to 16 storage slots for this module.
   */
  DSML.IsolatedStorage internal DATASTORE;

  /**
   * @custom:section                           ** INITIALIZING **
   */

  function __DataStoreModule_init() internal onlyInitializing {}

  function __DataStoreModule_init_unchained() internal onlyInitializing {}

  /**
   * @custom:section                           ** HELPER FUNCTIONS **
   *
   * @custom:visibility -> pure-external
   */

  /**
   * @notice useful function for string inputs - returns same with the DSML.generateId
   * @dev id is generated by keccak(name, type)
   */
  function generateId(
    string calldata _name,
    uint256 _type
  ) external pure virtual override returns (uint256 id) {
    id = uint256(keccak256(abi.encodePacked(_name, _type)));
  }

  /**
   * @notice useful view function for string inputs - returns same with the DSML.generateId
   */
  function getKey(
    uint256 _id,
    bytes32 _param
  ) external pure virtual override returns (bytes32 key) {
    return DSML.getKey(_id, _param);
  }

  /**
   * @custom:section                           ** DATA GETTER FUNCTIONS **
   *
   * @custom:visibility -> view-external
   */

  /**
   * @dev useful for outside reach, shouldn't be used within contracts as a referance
   * @return allIdsByType is an array of IDs of the given TYPE from Datastore,
   * returns a specific index
   */
  function allIdsByType(
    uint256 _type,
    uint256 _index
  ) external view virtual override returns (uint256) {
    return DATASTORE.allIdsByType[_type][_index];
  }

  function allIdsByTypeLength(uint256 _type) external view virtual override returns (uint256) {
    return DATASTORE.allIdsByType[_type].length;
  }

  function readUint(uint256 id, bytes32 key) external view virtual override returns (uint256 data) {
    data = DATASTORE.readUint(id, key);
  }

  function readAddress(
    uint256 id,
    bytes32 key
  ) external view virtual override returns (address data) {
    data = DATASTORE.readAddress(id, key);
  }

  function readBytes(
    uint256 id,
    bytes32 key
  ) external view virtual override returns (bytes memory data) {
    data = DATASTORE.readBytes(id, key);
  }

  /**
   * @custom:section                           ** ARRAY GETTER FUNCTIONS **
   *
   * @custom:visibility -> view-external
   */

  function readUintArray(
    uint256 id,
    bytes32 key,
    uint256 index
  ) external view virtual override returns (uint256 data) {
    data = DATASTORE.readUintArray(id, key, index);
  }

  function readBytesArray(
    uint256 id,
    bytes32 key,
    uint256 index
  ) external view virtual override returns (bytes memory data) {
    data = DATASTORE.readBytesArray(id, key, index);
  }

  function readAddressArray(
    uint256 id,
    bytes32 key,
    uint256 index
  ) external view virtual override returns (address data) {
    data = DATASTORE.readAddressArray(id, key, index);
  }
}
