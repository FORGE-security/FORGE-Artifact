// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

// import "./IERC20Minimal.sol"; // This is needed if deploying to Tron
import "../MesonConfig.sol";

/// @title MesonHelpers
/// @notice The class that provides helper functions for Meson protocol
contract MesonHelpers is MesonConfig {
  bytes4 private constant ERC20_TRANSFER_SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));

  function _msgSender() internal view returns (address) {
    return msg.sender;
  }

  function _msgData() internal pure returns (bytes calldata) {
    return msg.data;
  }

  function getShortCoinType() external pure returns (bytes2) {
    return bytes2(SHORT_COIN_TYPE);
  }

  /// @notice Safe transfers tokens from Meson contract to a recipient
  /// for interacting with ERC20 tokens that do not consistently return true/false
  /// @param token The contract address of the token which will be transferred
  /// @param recipient The recipient of the transfer
  /// @param amount The value of the transfer (always in decimal 6)
  /// @param isUCT Whether the transferred token is UCT (minted by Meson, see `UCTUpgradeable.sol`)
  function _safeTransfer(
    address token,
    address recipient,
    uint256 amount,
    bool isUCT
  ) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(
      bytes4(0xa9059cbb), // bytes4(keccak256(bytes("transfer(address,uint256)")))
      recipient,
      amount
      // isUCT ? amount : amount * 1e12 // need to switch to this line if deploying to BNB Chain or Conflux
    ));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "transfer failed");

    // The above do not support Tron, so need to switch to the next line if deploying to Tron
    // IERC20Minimal(token).transfer(recipient, amount);
  }

  /// @notice Help the senders to transfer their assets to the Meson contract
  /// @param token The contract address of the token which will be transferred
  /// @param sender The sender of the transfer
  /// @param amount The value of the transfer (always in decimal 6)
  /// @param isUCT Whether the transferred token is UCT (minted by Meson, see `UCTUpgradeable.sol`)
  function _unsafeDepositToken(
    address token,
    address sender,
    uint256 amount,
    bool isUCT
  ) internal {
    require(token != address(0), "Token not supported");
    require(amount > 0, "Amount must be greater than zero");
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(
      bytes4(0x23b872dd), // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")))
      sender,
      address(this),
      amount
      // isUCT ? amount : amount * 1e12 // need to switch to this line if deploying to BNB Chain or Conflux
    ));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "transferFrom failed");
  }

  /// @notice Calculate `swapId` from `encodedSwap`, `initiator`
  /// See variable `_postedSwaps` in `MesonSwap.sol` for the defination of `encodedSwap`
  function _getSwapId(uint256 encodedSwap, address initiator) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(encodedSwap, initiator));
  }

  /// @notice Decode `amount` from `encodedSwap`
  /// See variable `_postedSwaps` in `MesonSwap.sol` for the defination of `encodedSwap`
  function _amountFrom(uint256 encodedSwap) internal pure returns (uint256) {
    return encodedSwap >> 208;
  }

  /// @notice Calculate the service fee from `encodedSwap`
  /// See variable `_postedSwaps` in `MesonSwap.sol` for the defination of `encodedSwap`
  function _serviceFee(uint256 encodedSwap) internal pure returns (uint256) {
    return _amountFrom(encodedSwap) / 1000; // Default to `serviceFee` = 0.1% * `amount`
  }

  /// [Suggestion]: mutable service fee points rate
  // uint public feePointsRate = 10;
  // modifier onlyOwner() {...}
  // function setFeePoints(uint newFeePoints) onlyOwner external {...}
  // function _serviceFee(uint256 encodedSwap) internal pure returns (uint256) {
  //   return uint256(encodedSwap >> 208) * feePointsRate / 10000;
  // }

  /// @notice Decode `fee` (the fee for LPs) from `encodedSwap`
  /// See variable `_postedSwaps` in `MesonSwap.sol` for the defination of `encodedSwap`
  function _feeForLp(uint256 encodedSwap) internal pure returns (uint256) {
    return (encodedSwap >> 88) & 0xFFFFFFFFFF;
  }

  /// @notice Decode `salt` from `encodedSwap`
  /// See variable `_postedSwaps` in `MesonSwap.sol` for the defination of `encodedSwap`
  function _saltFrom(uint256 encodedSwap) internal pure returns (uint80) {
    return uint80(encodedSwap >> 128);
  }
  
  /// @notice Whether the swap was signed in the non-typed manner (usually by hardware wallets)
  function _signNonTyped(uint256 encodedSwap) internal pure returns (bool) {
    return (encodedSwap & 0x0800000000000000000000000000000000000000000000000000) > 0;
  }

  /// @notice Whether the swap needs to pay service fee
  /// See method `release` in `MesonPools.sol` for more details about the service fee
  function _feeWaived(uint256 encodedSwap) internal pure returns (bool) {
    return (encodedSwap & 0x4000000000000000000000000000000000000000000000000000) > 0;
  }

  /// @notice Decode `expireTs` from `encodedSwap`
  /// See variable `_postedSwaps` in `MesonSwap.sol` for the defination of `encodedSwap`
  function _expireTsFrom(uint256 encodedSwap) internal pure returns (uint256) {
    return (encodedSwap >> 48) & 0xFFFFFFFFFF;
    // [Suggestion]: return uint40(encodedSwap >> 48);
  }

  /// @notice Decode the initial chain (`inChain`) from `encodedSwap`
  /// See variable `_postedSwaps` in `MesonSwap.sol` for the defination of `encodedSwap`
  function _inChainFrom(uint256 encodedSwap) internal pure returns (uint16) {
    return uint16(encodedSwap >> 8);
  }

  /// @notice Decode the token index of initial chain (`inToken`) from `encodedSwap`
  /// See variable `_postedSwaps` in `MesonSwap.sol` for the defination of `encodedSwap`
  function _inTokenIndexFrom(uint256 encodedSwap) internal pure returns (uint8) {
    return uint8(encodedSwap);
  }

  /// @notice Decode the target chain (`outChain`) from `encodedSwap`
  /// See variable `_postedSwaps` in `MesonSwap.sol` for the defination of `encodedSwap`
  function _outChainFrom(uint256 encodedSwap) internal pure returns (uint16) {
    return uint16(encodedSwap >> 32);
  }

  /// @notice Decode the token index of target chain (`outToken`) from `encodedSwap`
  /// See variable `_postedSwaps` in `MesonSwap.sol` for the defination of `encodedSwap`
  function _outTokenIndexFrom(uint256 encodedSwap) internal pure returns (uint8) {
    return uint8(encodedSwap >> 24);
  }

  /// @notice Decode `outToken` from `encodedSwap`, and encode it with `poolIndex` to `poolTokenIndex`.
  /// See variable `_balanceOfPoolToken` in `MesonStates.sol` for the defination of `poolTokenIndex`
  function _poolTokenIndexForOutToken(uint256 encodedSwap, uint40 poolIndex) internal pure returns (uint48) {
    return uint48((encodedSwap & 0xFF000000) << 16) | poolIndex;
  }

  /// @notice Decode `initiator` from `postedSwap`
  /// See variable `_postedSwaps` in `MesonSwap.sol` for the defination of `postedSwap`
  function _initiatorFromPosted(uint200 postedSwap) internal pure returns (address) {
    return address(uint160(postedSwap >> 40));
  }

  /// @notice Decode `poolIndex` from `postedSwap`
  /// See variable `_postedSwaps` in `MesonSwap.sol` for the defination of `postedSwap`
  function _poolIndexFromPosted(uint200 postedSwap) internal pure returns (uint40) {
    return uint40(postedSwap);
  }
  
  /// @notice Encode `lockedSwap` from `until` and `poolIndex`
  /// See variable `_lockedSwaps` in `MesonPools.sol` for the defination of `lockedSwap`
  function _lockedSwapFrom(uint256 until, uint40 poolIndex) internal pure returns (uint80) {
    return (uint80(until) << 40) | poolIndex;
  }

  /// @notice Decode `poolIndex` from `lockedSwap`
  /// See variable `_lockedSwaps` in `MesonPools.sol` for the defination of `lockedSwap`
  function _poolIndexFromLocked(uint80 lockedSwap) internal pure returns (uint40) {
    return uint40(lockedSwap);
  }

  /// @notice Decode `until` from `lockedSwap`
  /// See variable `_lockedSwaps` in `MesonPools.sol` for the defination of `lockedSwap`
  function _untilFromLocked(uint80 lockedSwap) internal pure returns (uint256) {
    return uint256(lockedSwap >> 40);
  }

  /// @notice Encode `poolTokenIndex` from `tokenIndex` and `poolIndex`
  /// See variable `_balanceOfPoolToken` in `MesonStates.sol` for the defination of `poolTokenIndex`
  function _poolTokenIndexFrom(uint8 tokenIndex, uint40 poolIndex) internal pure returns (uint48) {
    return (uint48(tokenIndex) << 40) | poolIndex;
  }

  /// @notice Decode `tokenIndex` from `poolTokenIndex`
  /// See variable `_balanceOfPoolToken` in `MesonStates.sol` for the defination of `poolTokenIndex`
  function _tokenIndexFrom(uint48 poolTokenIndex) internal pure returns (uint8) {
    return uint8(poolTokenIndex >> 40);
  }

  /// @notice Decode `poolIndex` from `poolTokenIndex`
  /// See variable `_balanceOfPoolToken` in `MesonStates.sol` for the defination of `poolTokenIndex`
  function _poolIndexFrom(uint48 poolTokenIndex) internal pure returns (uint40) {
    return uint40(poolTokenIndex);
  }

  /// @notice Check the initiator's signature for a swap request
  /// Signatures are constructed with the package `mesonfi/sdk`. Go to `packages/sdk/src/SwapSigner.ts` and 
  /// see how to generate a signautre in class `EthersWalletSwapSigner` method `signSwapRequest`
  /// @param encodedSwap Encoded swap information. See variable `_postedSwaps` in `MesonSwap.sol` for the defination of `encodedSwap`
  /// @param r Part of the signature
  /// @param s Part of the signature
  /// @param v Part of the signature
  /// @param signer The signer for the swap request which is the `initiator`
  function _checkRequestSignature(
    uint256 encodedSwap,
    bytes32 r,
    bytes32 s,
    uint8 v,
    address signer
  ) internal pure {
    require(signer != address(0), "Signer cannot be empty address");
    require(v == 27 || v == 28, "Invalid signature");
    require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "Invalid signature");

    bool nonTyped = _signNonTyped(encodedSwap);

    if (_inChainFrom(encodedSwap) == 0x00c3) {
      bytes32 digest = keccak256(abi.encodePacked(
        nonTyped
          ? bytes25(0x1954524f4e205369676e6564204d6573736167653a0a33330a)  // HEX of "\x19TRON Signed Message:\n33\n"
          : bytes25(0x1954524f4e205369676e6564204d6573736167653a0a33320a), // HEX of "\x19TRON Signed Message:\n32\n"
        encodedSwap
      ));
      require(signer == ecrecover(digest, v, r, s), "Invalid signature");
      return;
    }

    if (nonTyped) {
      bytes32 digest = keccak256(abi.encodePacked(
        bytes28(0x19457468657265756d205369676e6564204d6573736167653a0a3332), // HEX of "\x19Ethereum Signed Message:\n32"
        encodedSwap
      ));
      require(signer == ecrecover(digest, v, r, s), "Invalid signature");
      return;
    }

    bytes32 typehash = REQUEST_TYPE_HASH;
    bytes32 digest;
    assembly {
      mstore(0, encodedSwap)
      mstore(32, keccak256(0, 32))
      mstore(0, typehash)
      digest := keccak256(0, 64)
    }
    require(signer == ecrecover(digest, v, r, s), "Invalid signature");
  }

  /// @notice Check the initiator's signature for the release request
  /// Signatures are constructed with the package `mesonfi/sdk`. Go to `packages/sdk/src/SwapSigner.ts` and 
  /// see how to generate a signautre in class `EthersWalletSwapSigner` method `signSwapRelease`
  /// @param encodedSwap Encoded swap information. See variable `_postedSwaps` in `MesonSwap.sol` for the defination of `encodedSwap`
  /// @param recipient The recipient address of the swap
  /// @param r Part of the signature
  /// @param s Part of the signature
  /// @param v Part of the signature
  /// @param signer The signer for the swap request which is the `initiator`
  function _checkReleaseSignature(
    uint256 encodedSwap,
    address recipient,
    bytes32 r,
    bytes32 s,
    uint8 v,
    address signer
  ) internal pure {
    require(signer != address(0), "Signer cannot be empty address");
    require(v == 27 || v == 28, "Invalid signature");
    require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "Invalid signature");

    bool nonTyped = _signNonTyped(encodedSwap);

    if (_inChainFrom(encodedSwap) == 0x00c3) {
      bytes32 digest = keccak256(abi.encodePacked(
        nonTyped
          ? bytes25(0x1954524f4e205369676e6564204d6573736167653a0a35330a)  // HEX of "\x19TRON Signed Message:\n53\n"
          : bytes25(0x1954524f4e205369676e6564204d6573736167653a0a33320a), // HEX of "\x19TRON Signed Message:\n32\n"
        encodedSwap,
        recipient
      ));
      require(signer == ecrecover(digest, v, r, s), "Invalid signature");
      return;
    }

    bytes32 digest;
    if (nonTyped) {
      digest = keccak256(abi.encodePacked(
        bytes28(0x19457468657265756d205369676e6564204d6573736167653a0a3332), // HEX of "\x19Ethereum Signed Message:\n32"
        keccak256(abi.encodePacked(encodedSwap, recipient))
      ));
    } else if (_outChainFrom(encodedSwap) == 0x00c3) {
      assembly {
        mstore(21, recipient)
        mstore8(32, 0x41)
        mstore(0, encodedSwap)
        mstore(32, keccak256(0, 53))
        // mstore(0, 0xcdd10eb72226dc70c96479571183c7d98ddba64dcc287980e7f6deceaad47c1c) // testnet
        mstore(0, 0xf6ea10de668a877958d46ed7d53eaf47124fda9bee9423390a28c203556a2e55) // mainnet
        digest := keccak256(0, 64)
      }
    } else {
      bytes32 typehash = RELEASE_TYPE_HASH;
      assembly {
        mstore(20, recipient)
        mstore(0, encodedSwap)
        mstore(32, keccak256(0, 52))
        mstore(0, typehash)
        digest := keccak256(0, 64)
      }
    }
    require(signer == ecrecover(digest, v, r, s), "Invalid signature");
  }
}
