// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {TypeCasts} from "../../contracts/shared/libraries/TypeCasts.sol";
import {Message} from "../../contracts/messaging/libraries/Message.sol";

import {RootManager} from "../../contracts/messaging/RootManager.sol";
import {MerkleTreeManager} from "../../contracts/messaging/Merkle.sol";
import {WatcherManager} from "../../contracts/messaging/WatcherManager.sol";
import {MerkleLib} from "../../contracts/messaging/libraries/Merkle.sol";
import {Connector} from "../../contracts/messaging/connectors/Connector.sol";
import {SpokeConnector} from "../../contracts/messaging/connectors/SpokeConnector.sol";
import {MerkleTreeManager} from "../../contracts/messaging/Merkle.sol";

import "../utils/ConnectorHelper.sol";
import "../utils/Mock.sol";

import "forge-std/console.sol";

/**
 * @notice This contract is designed to test the full messaging flow using mocked hub and spoke connectors,
 * root manager, etc.
 */
contract PingPong is ConnectorHelper {
  // ============ Storage ============

  // ============ constants
  bytes32 constant EMPTY_ROOT = bytes32(0x27ae5ba08d7291c96c8cbddcc148bf48a6d68c7974b94356f53754ef6171d757);

  // ============ config
  uint32 _originDomain = uint32(123);
  address _originAMB = address(123);

  uint32 _destinationDomain = uint32(456);
  address _destinationAMB = address(456);

  uint32 _mainnetDomain = uint32(345);
  address _destinationMainnetAMB = address(456456);
  address _originMainnetAMB = address(123123);

  uint256 PROCESS_GAS = 850_000;
  uint256 RESERVE_GAS = 15_000;

  MerkleTreeManager referenceSpokeTree;
  MerkleTreeManager referenceAggregateTree;

  MerkleTreeManager destinationSpokeTree;
  MerkleTreeManager originSpokeTree;
  MerkleTreeManager aggregateTree;

  uint256 _delayBlocks = 40;
  address _watcherManager;

  // ============ connectors
  struct ConnectorPair {
    address spoke;
    address hub;
  }

  ConnectorPair _originConnectors;
  ConnectorPair _destinationConnectors;

  // ============ destination router
  bytes32 _destinationRouter;

  // ============ Test set up ============
  function setUp() public {
    // deploy the contracts
    utils_deployContracts();
    // deploy + configure the root manager
    utils_configureContracts();
  }

  // ============ Utils ============
  function utils_deployContracts() public {
    // deploy merkle
    utils_createReferenceTrees();
    // deploy watcher manager
    _watcherManager = address(new WatcherManager());
    // deploy root manager
    _rootManager = address(new RootManager(_delayBlocks, address(aggregateTree), _watcherManager));
    aggregateTree.setArborist(_rootManager);

    // Mock sourceconnector on l2
    _originConnectors.spoke = address(
      new MockSpokeConnector(
        _originDomain, // uint32 _domain,
        _mainnetDomain, // uint32 _mirrorDomain
        _originAMB, // address _amb,
        _rootManager, // address _rootManager,
        address(originSpokeTree), // address merkle root manager
        address(0), // address _mirrorConnector
        PROCESS_GAS, // uint256 _mirrorGas
        PROCESS_GAS, // uint256 _processGas,
        RESERVE_GAS, // uint256 _reserveGas
        0, // uint256 _delayBlocks
        _watcherManager
      )
    );
    originSpokeTree.setArborist(_originConnectors.spoke);
    MockSpokeConnector(_originConnectors.spoke).setUpdatesAggregate(true);

    // Mock sourceconnector on l1
    _originConnectors.hub = address(
      new MockHubConnector(
        _mainnetDomain, // uint32 _domain,
        _originDomain, // uint32 _mirrorDomain,
        _originMainnetAMB, // address _amb,
        _rootManager, // address _rootManager,
        _originConnectors.spoke, // address _mirrorConnector,
        PROCESS_GAS // uint256 _mirrorGas
      )
    );
    MockHubConnector(_originConnectors.hub).setUpdatesAggregate(true);

    // Mock dest connector on l2
    _destinationConnectors.spoke = address(
      new MockSpokeConnector(
        _destinationDomain, // uint32 _domain,
        _mainnetDomain, // uint32 _mirrorDomain,
        _destinationAMB, // address _amb,
        _rootManager, // address _rootManager,
        address(destinationSpokeTree), // address merkle root manager
        address(0), // address _mirrorConnector,
        PROCESS_GAS, // uint256 _mirrorGas
        PROCESS_GAS, // uint256 _processGas,
        RESERVE_GAS, // uint256 _reserveGas
        0, // uint256 _delayBlocks
        _watcherManager
      )
    );
    destinationSpokeTree.setArborist(_destinationConnectors.spoke);
    MockSpokeConnector(_destinationConnectors.spoke).setUpdatesAggregate(true);

    // Mock dest connector on l1
    _destinationConnectors.hub = address(
      new MockHubConnector(
        _mainnetDomain, // uint32 _domain,
        _destinationDomain, // uint32 _mirrorDomain,
        _destinationMainnetAMB, // address _amb,
        _rootManager, // address _rootManager,
        _destinationConnectors.spoke, // address _mirrorConnector,
        PROCESS_GAS
      )
    );
    MockHubConnector(_destinationConnectors.hub).setUpdatesAggregate(true);
    _destinationRouter = TypeCasts.addressToBytes32(address(12356556423));
  }

  function utils_configureContracts() public {
    // enroll this as approved sender for messaging
    SpokeConnector(_originConnectors.spoke).addSender(address(this));
    SpokeConnector(_originConnectors.spoke).setMirrorConnector(_originConnectors.hub);
    SpokeConnector(_destinationConnectors.spoke).setMirrorConnector(_destinationConnectors.hub);
    // check setup
    assertEq(SpokeConnector(_destinationConnectors.spoke).mirrorConnector(), _destinationConnectors.hub);
    assertEq(SpokeConnector(_originConnectors.spoke).mirrorConnector(), _originConnectors.hub);
    assertEq(SpokeConnector(_destinationConnectors.hub).mirrorConnector(), _destinationConnectors.spoke);
    assertEq(SpokeConnector(_originConnectors.hub).mirrorConnector(), _originConnectors.spoke);

    MockSpokeConnector(_destinationConnectors.spoke).setUpdatesAggregate(true);

    // configure root manager with connectors
    RootManager(_rootManager).addConnector(_originDomain, _originConnectors.hub);
    RootManager(_rootManager).addConnector(_destinationDomain, _destinationConnectors.hub);
    // check setup
    assertEq(RootManager(_rootManager).connectors(0), _originConnectors.hub);
    assertEq(RootManager(_rootManager).connectors(1), _destinationConnectors.hub);
    assertEq(RootManager(_rootManager).domains(0), _originDomain);
    assertEq(RootManager(_rootManager).domains(1), _destinationDomain);
  }

  // Create merkle tree managers we'll use for managing reference trees to ensure correct behavior below.
  function utils_createReferenceTrees() public {
    // Deploy implementation
    MerkleTreeManager impl = new MerkleTreeManager();

    // Deploy reference proxies (properly sets the owner)
    ERC1967Proxy spokeProxy = new ERC1967Proxy(
      address(impl),
      abi.encodeWithSelector(MerkleTreeManager.initialize.selector, address(this))
    );
    referenceSpokeTree = MerkleTreeManager(address(spokeProxy));

    ERC1967Proxy aggregateProxy = new ERC1967Proxy(
      address(impl),
      abi.encodeWithSelector(MerkleTreeManager.initialize.selector, address(this))
    );
    referenceAggregateTree = MerkleTreeManager(address(aggregateProxy));

    // Deploy real proxies
    ERC1967Proxy destProxy = new ERC1967Proxy(
      address(impl),
      abi.encodeWithSelector(MerkleTreeManager.initialize.selector, address(this))
    );
    destinationSpokeTree = MerkleTreeManager(address(destProxy));

    ERC1967Proxy originProxy = new ERC1967Proxy(
      address(impl),
      abi.encodeWithSelector(MerkleTreeManager.initialize.selector, address(this))
    );
    originSpokeTree = MerkleTreeManager(address(originProxy));

    ERC1967Proxy rootProxy = new ERC1967Proxy(
      address(impl),
      abi.encodeWithSelector(MerkleTreeManager.initialize.selector, address(this))
    );
    aggregateTree = MerkleTreeManager(address(rootProxy));
  }

  // Helper to `dispatch` a message on origin, update the reference tree, and ensure behavior was correct.
  function utils_dispatchAndAssert(bytes memory body) public returns (bytes memory message, bytes32 messageHash) {
    // Format the expected message and get the hash (leaf).
    message = Message.formatMessage(
      _originDomain,
      bytes32(uint256(uint160(address(this)))), // TODO necessary?
      0,
      _destinationDomain,
      _destinationRouter,
      body
    );
    messageHash = keccak256(message);

    // Insert the node into the reference tree and get the expected new root.
    (bytes32 expectedRoot, uint256 expectedCount) = referenceSpokeTree.insert(messageHash);
    // Get initial count.
    uint256 initialCount = SpokeConnector(_originConnectors.spoke).MERKLE().count();
    vm.expectEmit(true, true, true, true);
    emit Dispatch(messageHash, initialCount, expectedRoot, message);

    // Call `dispatch`: will add the message hash to the current tree.
    SpokeConnector(_originConnectors.spoke).dispatch(_destinationDomain, _destinationRouter, body);

    assertEq(SpokeConnector(_originConnectors.spoke).outboundRoot(), expectedRoot);
    // Assert index increased by 1.
    uint256 updatedCount = SpokeConnector(_originConnectors.spoke).MERKLE().count();
    assertEq(updatedCount, expectedCount);
    assertEq(updatedCount, initialCount + 1);
  }

  // Send outbound root from origin.
  function utils_sendOutboundRootAndAssert() public returns (bytes32 outboundRoot) {
    outboundRoot = SpokeConnector(_originConnectors.spoke).outboundRoot();

    // Expect event emitted.
    vm.expectEmit(true, true, true, true);
    emit MessageSent(abi.encode(outboundRoot), address(this));

    SpokeConnector(_originConnectors.spoke).send();

    // Make sure correct root was sent.
    assertEq(MockSpokeConnector(_originConnectors.spoke).lastOutbound(), keccak256(abi.encode(outboundRoot)));
  }

  // Aggregate an inbound root on the hub.
  function utils_aggregateAndAssert(bytes32 inboundRoot) public {
    // Expect MessageProcessed event emitted.
    vm.expectEmit(true, true, true, true);
    emit MessageProcessed(abi.encode(inboundRoot), _originMainnetAMB);

    // The AMB would normally deliver to the HubConnector the inboundRoot.
    vm.prank(_originMainnetAMB);
    Connector(_originConnectors.hub).processMessage(abi.encode(inboundRoot));

    // Make sure inboundRoot was received.
    assertEq(MockHubConnector(_originConnectors.hub).lastReceived(), keccak256(abi.encode(inboundRoot)));
  }

  // Propagate aggregateRoot on all connectors.
  function utils_propagateAndAssert(bytes32 inboundRoot) public returns (bytes32 aggregateRoot) {
    // Aggregate this inboundRoot into the reference tree (as it should be done in `propagate`).
    bytes32[] memory inboundRoots = new bytes32[](1);
    inboundRoots[0] = inboundRoot;
    (bytes32 expectedAggregateRoot, uint256 expectedAggregateCount) = referenceAggregateTree.insert(inboundRoots);

    // Move ahead the expected number of delay blocks.
    vm.roll(block.number + RootManager(_rootManager).delayBlocks());

    // Get initial count for aggregate tree.
    uint256 initialAggregateCount = RootManager(_rootManager).MERKLE().count();

    // Format params.
    uint32[] memory domains = new uint32[](2);
    domains[0] = _originDomain;
    domains[1] = _destinationDomain;
    address[] memory connectors = new address[](2);
    connectors[0] = _originConnectors.hub;
    connectors[1] = _destinationConnectors.hub;

    // Propagate the aggregate root.
    RootManager(_rootManager).propagate(domains, connectors);

    // Assert that the current aggregate root matches expected (from reference tree).
    aggregateRoot = RootManager(_rootManager).MERKLE().root();
    assertEq(aggregateRoot, expectedAggregateRoot);

    // Assert index increased by 1.
    uint256 updatedAggregateCount = RootManager(_rootManager).MERKLE().count();
    assertEq(updatedAggregateCount, expectedAggregateCount);
    assertEq(updatedAggregateCount, initialAggregateCount + 1);

    // Assert that the aggregate root was sent on all connectors.
    assertEq(MockHubConnector(_originConnectors.hub).lastOutbound(), keccak256(abi.encode(expectedAggregateRoot)));
    assertEq(MockHubConnector(_destinationConnectors.hub).lastOutbound(), keccak256(abi.encode(expectedAggregateRoot)));
  }

  // Process a given aggregateRoot on a given spoke.
  function utils_processAggregateRootAndAssert(
    address connector,
    address amb,
    bytes32 aggregateRoot
  ) public {
    // Expect MessageProcessed on the target spoke.
    vm.expectEmit(true, true, true, true);
    emit MessageProcessed(abi.encode(aggregateRoot), amb);

    vm.prank(amb);
    Connector(connector).processMessage(abi.encode(aggregateRoot));

    // Make sure aggregateRoot was received.
    assertEq(MockSpokeConnector(connector).lastReceived(), keccak256(abi.encode(aggregateRoot)));

    // `pendingAggregateRoots` should be updated.
    assertEq(SpokeConnector(connector).pendingAggregateRoots(aggregateRoot), block.number);
  }

  // Get the proof/path for a given message in the reference spoke tree.
  function utils_getProofForMessage(bytes memory message) public returns (bytes32[32] memory) {}

  // ============ Testing scenarios ============

  function test_messageFlowsWork() public {
    utils_createReferenceTrees();

    // Ensure the current roots reflects the default root of an empty tree.
    assertEq(SpokeConnector(_originConnectors.spoke).outboundRoot(), EMPTY_ROOT); // Origin SpokeConnector tree.
    assertEq(RootManager(_rootManager).MERKLE().root(), EMPTY_ROOT); // Aggregate tree.

    /// 1. Send message through Messaging contract.
    // Generate a message body.
    bytes memory body = abi.encode(_destinationDomain * _originDomain);

    // Dispatch.
    (bytes memory message, bytes32 messageHash) = utils_dispatchAndAssert(body);

    // 2. Send outboundRoot through Connector to hub.
    bytes32 outboundRoot = utils_sendOutboundRootAndAssert();

    // 3. Aggregate inbound root on the hub.
    utils_aggregateAndAssert(outboundRoot);

    // 4. Propagate roots to both connectors.
    bytes32 aggregateRoot = utils_propagateAndAssert(outboundRoot);

    // 5. Process aggregateRoot on destination spoke, as well as origin spoke (should be broadcasted to both).
    utils_processAggregateRootAndAssert(_destinationConnectors.spoke, _destinationAMB, aggregateRoot);
    utils_processAggregateRootAndAssert(_originConnectors.spoke, _originAMB, aggregateRoot);

    // Now fast forward `delayBlocks` so the aggregateRoot we just delivered to the destination spoke chain
    // will be considered verified.
    uint256 destinationDelay = MockSpokeConnector(_destinationConnectors.spoke).delayBlocks();
    vm.roll(block.number + destinationDelay);

    // 6. Process original message.
    // bytes32[32] memory branch = referenceAggregateTree.branch();

    // console.log("Need a proof for leaf:");
    // console.logBytes32(outboundRoot);
    // console.log("At index:");
    // console.log(referenceAggregateTree.count());
    // console.log("In tree:");
    // for (uint256 i; i < branch.length; i++) {
    //   console.logBytes32(branch[i]);
    // }

    // console.logBytes32(messageHash);
    // console.logBytes32(outboundRoot);
    console.logBytes32(aggregateRoot);

    // If the root == target leaf (i.e. the leaf is in the first index), then the proof == zeroHashes.
    bytes32[32] memory messageProof = MerkleLib.zeroHashes();
    bytes32[32] memory aggregateProof = MerkleLib.zeroHashes();

    SpokeConnector.Proof[] memory proofs = new SpokeConnector.Proof[](1);
    proofs[0] = SpokeConnector.Proof(message, messageProof, 0);
    SpokeConnector(_destinationConnectors.spoke).proveAndProcess(proofs, aggregateRoot, aggregateProof, 0);

    // assertEq(uint256(SpokeConnector(_destinationConnectors.spoke).messages(keccak256(message))), 2);
  }
}
