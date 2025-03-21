// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "../../../lib/forge-std/src/Test.sol";
import {OrderStructs} from "../../../contracts/libraries/OrderStructs.sol";

abstract contract TestParameters is Test {
    // Empty constants
    OrderStructs.MerkleTree internal _EMPTY_MERKLE_TREE;
    bytes4 internal constant _EMPTY_BYTES4 = bytes4(0);
    address internal constant _EMPTY_AFFILIATE = address(0);
    bytes32 public constant MAGIC_VALUE_ORDER_NONCE_EXECUTED = keccak256("ORDER_NONCE_EXECUTED");

    // Addresses
    address internal constant _owner = address(42);
    address internal constant _sender = address(88);
    address internal constant _recipient = address(90);
    address internal constant _transferrer = address(100);
    address internal constant _royaltyRecipient = address(22);
    address internal constant _affiliate = address(2);

    // Generic fee parameters
    uint16 internal constant _standardProtocolFeeBp = uint16(150);
    uint16 internal constant _minTotalFeeBp = uint16(200);
    uint16 internal constant _maxProtocolFeeBp = uint16(300);
    uint16 internal constant _standardRoyaltyFee = uint16(50);

    // Public/Private keys for maker/taker user
    uint256 internal constant makerUserPK = 1;
    uint256 internal constant takerUserPK = 2;
    // it is equal to vm.addr(makerUserPK)
    address internal constant makerUser = 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf;
    // it is equal to vm.addr(takerUserPK)
    address internal constant takerUser = 0x2B5AD5c4795c026514f8317c7a215E218DcCD6cF;

    // Initial balances
    // @dev The balances are on purpose different across users to make sure the tests are properly checking the assertion
    uint256 internal constant _initialETHBalanceUser = 100 ether;
    uint256 internal constant _initialWETHBalanceUser = 10 ether;
    uint256 internal constant _initialETHBalanceRoyaltyRecipient = 10 ether;
    uint256 internal constant _initialWETHBalanceRoyaltyRecipient = 25 ether;
    uint256 internal constant _initialETHBalanceOwner = 50 ether;
    uint256 internal constant _initialWETHBalanceOwner = 15 ether;
    uint256 internal constant _initialETHBalanceAffiliate = 30 ether;
    uint256 internal constant _initialWETHBalanceAffiliate = 12 ether;

    // Chainlink ETH/USD price feed (Ethereum mainnet)
    address internal constant CHAINLINK_ETH_USD_PRICE_FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
}
