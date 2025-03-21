// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

import {IOutbox as ArbitrumL1_Outbox} from "@openzeppelin/contracts/vendor/arbitrum/IOutbox.sol";
import {IBridge as ArbitrumL1_Bridge} from "@openzeppelin/contracts/vendor/arbitrum/IBridge.sol";
import {IArbSys as ArbitrumL2_Bridge} from "@openzeppelin/contracts/vendor/arbitrum/IArbSys.sol";
import "@openzeppelin/contracts/crosschain/errors.sol";

import {IRootManager} from "../../../../contracts/messaging/interfaces/IRootManager.sol";
import {Node} from "../../../../contracts/messaging/interfaces/ambs/arbitrum/IArbitrumRollup.sol";

import {ArbitrumHubConnector, L2Message} from "../../../../contracts/messaging/connectors/arbitrum/ArbitrumHubConnector.sol";

import {IArbitrumInbox} from "../../../../contracts/messaging/interfaces/ambs/arbitrum/IArbitrumInbox.sol";
import {ArbitrumL2Amb} from "../../../../contracts/messaging/interfaces/ambs/arbitrum/ArbitrumL2Amb.sol";

import "../../../utils/ConnectorHelper.sol";
import "../../../utils/Mock.sol";

contract MockArbitrumRollup {
  Node _node;

  function getNode(uint64 _nodeNum) public view returns (Node memory) {
    return _node;
  }

  function setNode(
    bytes32 _confirmData,
    uint64 _stakerCount,
    uint64 _childStakerCount
  ) public {
    Node memory node;
    node.confirmData = _confirmData;
    node.stakerCount = _stakerCount;
    node.childStakerCount = _childStakerCount;
    _node = node;
  }
}

contract MockArbitrumOutbox {
  address private _rollup;
  bytes32 root;

  constructor(address rollup_) {
    _rollup = rollup_;
  }

  function rollup() public view returns (address) {
    return _rollup;
  }

  function setMerkleRoot(bytes32 _root) public {
    root = _root;
  }

  function calculateItemHash(
    address l2Sender,
    address to,
    uint256 l2Block,
    uint256 l1Block,
    uint256 l2Timestamp,
    uint256 value,
    bytes calldata data
  ) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(l2Sender, to, l2Block, l1Block, l2Timestamp, value, data));
  }

  function calculateMerkleRoot(
    bytes32[] memory proof,
    uint256 path,
    bytes32 item
  ) public returns (bytes32) {
    return root;
  }
}

contract ArbitrumHubConnectorTest is ConnectorHelper {
  // ============ Events ============
  event DefaultGasPriceUpdated(uint256 previous, uint256 current);

  // ============ Storage ============
  uint256 _defaultGasPrice = 10 gwei;
  address _outbox;
  address _rollup;

  // processFromRoot argument defaults
  uint64 _nodeNum = 17623;
  bytes32 _sendRoot = bytes32(abi.encode(12321));
  bytes32 _blockHash = bytes32(abi.encode(5646465));
  bytes32[] _proof = [_sendRoot, _blockHash];
  uint256 _index = 2;
  bytes32 _root = bytes32(abi.encode(3131312252525));
  L2Message _message;

  function setUp() public {
    _l2Connector = address(3432123);
    // deploy rollup
    _rollup = address(new MockArbitrumRollup());
    // deploy outbox
    _outbox = address(new MockArbitrumOutbox(_rollup));
    // deploy
    _l1Connector = address(
      new ArbitrumHubConnector(
        _l1Domain,
        _l2Domain,
        _amb,
        _rootManager,
        _l2Connector,
        _mirrorGas,
        _defaultGasPrice,
        _outbox
      )
    );

    // set message
    _message = L2Message(
      _l2Connector, // l2Sender
      _l1Connector, // to
      1232, // l2Block
      123123, // l1Block
      block.timestamp, // l2Timestamp
      0, // value
      abi.encodeWithSelector(Connector.processMessage.selector, _root) // callData
    );
  }

  // ============ Utils ============
  function utils_setHubConnectorVerifyMocks(address _sender) public {
    // setup mocks
    address outbox = address(654321);
    // 1. call to amb on active outbox
    vm.mockCall(_amb, abi.encodeWithSelector(ArbitrumL1_Bridge.activeOutbox.selector), abi.encode(outbox));

    // 2. call to outbox to get sender
    vm.mockCall(outbox, abi.encodeWithSelector(ArbitrumL1_Outbox.l2ToL1Sender.selector), abi.encode(_sender));
  }

  function utils_setHubConnectorProcessMocks(address _sender) public {
    _message.l2Sender = _sender;
    utils_setHubConnectorVerifyMocks(_sender);
    // call to get node and validate confirmData
    // - set the confirm data on the node
    MockArbitrumRollup(_rollup).setNode(keccak256(abi.encodePacked(_blockHash, _sendRoot)), 1, 1);

    // call to get the item hash -- fn implemented on mock outbox

    // call to calculate the merkle root
    MockArbitrumOutbox(_outbox).setMerkleRoot(_sendRoot);

    // 3. call to root manager
    vm.mockCall(_rootManager, abi.encodeWithSelector(IRootManager.aggregate.selector), abi.encode(true));
  }

  function utils_setHubConnectorProcessAssertAndCall() public {
    // should call getNode
    vm.expectCall(_rollup, abi.encodeWithSelector(MockArbitrumRollup.getNode.selector, _nodeNum));

    // should call calculateItemHash
    vm.expectCall(
      _outbox,
      abi.encodeWithSelector(
        MockArbitrumOutbox.calculateItemHash.selector,
        _message.l2Sender,
        _message.to,
        _message.l2Block,
        _message.l1Block,
        _message.l2Timestamp,
        _message.value,
        _message.callData
      )
    );

    // should call calculateMerkleRoot
    vm.expectCall(
      _outbox,
      abi.encodeWithSelector(
        MockArbitrumOutbox.calculateMerkleRoot.selector,
        _proof,
        _index,
        MockArbitrumOutbox(_outbox).calculateItemHash(
          _message.l2Sender,
          _message.to,
          _message.l2Block,
          _message.l1Block,
          _message.l2Timestamp,
          _message.value,
          _message.callData
        )
      )
    );

    // should call root manager
    vm.expectCall(_rootManager, abi.encodeWithSelector(IRootManager.aggregate.selector, _l2Domain, _root));

    // should emit an event
    vm.expectEmit(true, true, true, true);
    emit MessageProcessed(_message.callData, address(this));

    // make call
    ArbitrumHubConnector(_l1Connector).processMessageFromRoot(
      _nodeNum,
      _sendRoot,
      _blockHash,
      _proof,
      _index,
      _message
    );

    // ensure the index is processed
    assertTrue(ArbitrumHubConnector(_l1Connector).processed(_index));
  }

  // ============ ArbitrumHubConnector.setDefaultGasPrice ============
  function test_ArbitrumHubConnector__setDefaultGasPrice_shouldWork() public {
    uint256 updated = 100 wei;
    vm.expectEmit(true, true, true, true);
    emit DefaultGasPriceUpdated(_defaultGasPrice, updated);

    vm.prank(ArbitrumHubConnector(_l1Connector).owner());
    ArbitrumHubConnector(_l1Connector).setDefaultGasPrice(updated);
    assertEq(ArbitrumHubConnector(_l1Connector).defaultGasPrice(), updated);
  }

  // ============ ArbitrumHubConnector.verifySender ============
  function test_ArbitrumHubConnector__verifySender_shouldWorkIfTrue() public {
    address expected = address(234);
    utils_setHubConnectorVerifyMocks(expected);

    vm.prank(_amb);
    assertTrue(ArbitrumHubConnector(_l1Connector).verifySender(expected));
  }

  function test_ArbitrumHubConnector__verifySender_shouldWorkIfFalse() public {
    address expected = address(234);
    utils_setHubConnectorVerifyMocks(address(122));

    vm.prank(_amb);
    assertEq(ArbitrumHubConnector(_l1Connector).verifySender(expected), false);
  }

  function test_ArbitrumHubConnector__verifySender_shouldFailIfCallerNotAmb() public {
    address expected = address(234);
    utils_setHubConnectorVerifyMocks(expected);

    vm.expectRevert(NotCrossChainCall.selector);
    assertEq(ArbitrumHubConnector(_l1Connector).verifySender(expected), false);
  }

  // ============ ArbitrumHubConnector.sendMessage ============
  function test_ArbitrumHubConnector__sendMessage_works() public {
    // setup mock
    vm.mockCall(_amb, abi.encodeWithSelector(IArbitrumInbox.sendContractTransaction.selector), abi.encode(123));

    // data
    bytes memory _data = abi.encodePacked(bytes32(bytes("test")));

    // should emit an event
    vm.expectEmit(true, true, true, true);
    emit MessageSent(_data, _rootManager);

    // should call send contract transaction
    vm.expectCall(
      _amb,
      abi.encodeWithSelector(
        IArbitrumInbox.sendContractTransaction.selector,
        _mirrorGas,
        _defaultGasPrice,
        _l2Connector,
        0,
        abi.encodeWithSelector(Connector.processMessage.selector, _data)
      )
    );

    vm.prank(_rootManager);
    ArbitrumHubConnector(_l1Connector).sendMessage(_data);
  }

  function test_ArbitrumHubConnector__sendMessage_works_fuzz(bytes32 data) public {
    // setup mock
    vm.mockCall(_amb, abi.encodeWithSelector(IArbitrumInbox.sendContractTransaction.selector), abi.encode(123));

    // data
    bytes memory _data = abi.encodePacked(data);

    // should emit an event
    vm.expectEmit(true, true, true, true);
    emit MessageSent(_data, _rootManager);

    // should call send contract transaction
    vm.expectCall(
      _amb,
      abi.encodeWithSelector(
        IArbitrumInbox.sendContractTransaction.selector,
        _mirrorGas,
        _defaultGasPrice,
        _l2Connector,
        0,
        abi.encodeWithSelector(Connector.processMessage.selector, _data)
      )
    );

    vm.prank(_rootManager);
    ArbitrumHubConnector(_l1Connector).sendMessage(_data);
  }

  // ============ ArbitrumHubConnector.processMessageFromRootFromRoot ============
  function test_ArbitrumHubConnector__processMessageFromRoot_works() public {
    utils_setHubConnectorProcessMocks(_l2Connector);
    utils_setHubConnectorProcessAssertAndCall();
  }

  function test_ArbitrumHubConnector__processMessageFromRoot_failsIfInvalidSendRoot() public {
    utils_setHubConnectorProcessMocks(_l2Connector);

    // set confirmdata
    MockArbitrumRollup(_rollup).setNode(keccak256(abi.encodePacked("failure")), 1, 1);

    vm.expectRevert("!confirmData");
    ArbitrumHubConnector(_l1Connector).processMessageFromRoot(
      _nodeNum,
      _sendRoot,
      _blockHash,
      _proof,
      _index,
      _message
    );
  }

  function test_ArbitrumHubConnector__processMessageFromRoot_failsIfNoStaker() public {
    utils_setHubConnectorProcessMocks(_l2Connector);

    // set confirmdata
    MockArbitrumRollup(_rollup).setNode(keccak256(abi.encodePacked(_blockHash, _sendRoot)), 0, 1);

    vm.expectRevert("!staked");
    ArbitrumHubConnector(_l1Connector).processMessageFromRoot(
      _nodeNum,
      _sendRoot,
      _blockHash,
      _proof,
      _index,
      _message
    );
  }

  function test_ArbitrumHubConnector__processMessageFromRoot_failsIfNoChildStaker() public {
    utils_setHubConnectorProcessMocks(_l2Connector);

    // set confirmdata
    MockArbitrumRollup(_rollup).setNode(keccak256(abi.encodePacked(_blockHash, _sendRoot)), 1, 0);

    vm.expectRevert("!staked");
    ArbitrumHubConnector(_l1Connector).processMessageFromRoot(
      _nodeNum,
      _sendRoot,
      _blockHash,
      _proof,
      _index,
      _message
    );
  }

  function test_ArbitrumHubConnector__processMessageFromRoot_failsIfNotMirrorConnector() public {
    // setup mocks
    utils_setHubConnectorProcessMocks(address(654321));

    // should revert because not connector
    vm.expectRevert(bytes("!mirrorConnector"));
    // make call
    ArbitrumHubConnector(_l1Connector).processMessageFromRoot(
      _nodeNum,
      _sendRoot,
      _blockHash,
      _proof,
      _index,
      _message
    );
  }

  function test_ArbitrumHubConnector__processMessageFromRoot_failsIfProofTooLong() public {
    _proof = new bytes32[](257);
    utils_setHubConnectorProcessMocks(_l2Connector);

    // should revert because proof length
    vm.expectRevert(bytes("proof length"));
    // make call
    ArbitrumHubConnector(_l1Connector).processMessageFromRoot(
      _nodeNum,
      _sendRoot,
      _blockHash,
      _proof,
      _index,
      _message
    );
  }

  function test_ArbitrumHubConnector__processMessageFromRoot_failsIfProofNotMinimal() public {
    _index = 3021548;
    utils_setHubConnectorProcessMocks(_l2Connector);

    // should revert because proof length
    vm.expectRevert(bytes("!minimal proof"));
    // make call
    ArbitrumHubConnector(_l1Connector).processMessageFromRoot(
      _nodeNum,
      _sendRoot,
      _blockHash,
      _proof,
      _index,
      _message
    );
  }

  function test_ArbitrumHubConnector__processMessageFromRoot_failsIfAlreadyProcessed() public {
    utils_setHubConnectorProcessMocks(_l2Connector);
    utils_setHubConnectorProcessAssertAndCall();

    // should revert because proof length
    vm.expectRevert(bytes("spent"));
    // make call
    ArbitrumHubConnector(_l1Connector).processMessageFromRoot(
      _nodeNum,
      _sendRoot,
      _blockHash,
      _proof,
      _index,
      _message
    );
  }

  function test_ArbitrumHubConnector__processMessageFromRoot_failsIfIncorrectProof() public {
    utils_setHubConnectorProcessMocks(_l2Connector);

    // call to calculate the merkle root
    MockArbitrumOutbox(_outbox).setMerkleRoot(bytes32(abi.encodePacked("so dumb i cant merkle omg")));

    // should revert because proof length
    vm.expectRevert(bytes("!proof"));
    // make call
    ArbitrumHubConnector(_l1Connector).processMessageFromRoot(
      _nodeNum,
      _sendRoot,
      _blockHash,
      _proof,
      _index,
      _message
    );
  }

  function test_ArbitrumHubConnector__processMessageFromRoot_failsIfNot36Bytes() public {
    _message.callData = abi.encode(
      "somehow this should be longer than 36 bytes and really i should use a more elegant way to generate this but its the last test so im feeling pretty quick and dirty and my typing speed is faster than trying to think rn"
    );
    utils_setHubConnectorProcessMocks(_l2Connector);

    // should revert because not bridge
    vm.expectRevert(bytes("!length"));
    // make call
    ArbitrumHubConnector(_l1Connector).processMessageFromRoot(
      _nodeNum,
      _sendRoot,
      _blockHash,
      _proof,
      _index,
      _message
    );
  }
}
