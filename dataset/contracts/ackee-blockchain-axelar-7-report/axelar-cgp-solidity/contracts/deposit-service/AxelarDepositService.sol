// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IAxelarDepositService } from '../interfaces/IAxelarDepositService.sol';
import { IAxelarGateway } from '../interfaces/IAxelarGateway.sol';
import { IERC20 } from '../interfaces/IERC20.sol';
import { IWETH9 } from '../interfaces/IWETH9.sol';
import { IReceiverImplementation } from '../interfaces/IReceiverImplementation.sol';
import { Upgradable } from '../util/Upgradable.sol';
import { DepositReceiver } from './DepositReceiver.sol';
import { ReceiverImplementation } from './ReceiverImplementation.sol';

// This should be owned by the microservice that is paying for gas.
contract AxelarDepositService is Upgradable, ReceiverImplementation, IAxelarDepositService {
    constructor(address gateway, string memory wrappedSymbol) ReceiverImplementation(gateway, wrappedSymbol) {}

    // @dev This method is meant to called directly by user to send native token cross-chain
    function sendNative(string calldata destinationChain, string calldata destinationAddress) external payable {
        address wrappedTokenAddress = wrappedToken();
        uint256 amount = msg.value;

        if (amount == 0) revert NothingDeposited();

        IWETH9(wrappedTokenAddress).deposit{ value: amount }();
        IERC20(wrappedTokenAddress).approve(gateway, amount);
        IAxelarGateway(gateway).sendToken(destinationChain, destinationAddress, wrappedSymbol(), amount);
    }

    // @dev Generates a deposit address for sending an ERC20 token cross-chain
    function addressForTokenDeposit(
        bytes32 salt,
        address refundAddress,
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata tokenSymbol
    ) external view returns (address) {
        return
            _depositAddress(
                salt,
                abi.encodeWithSelector(
                    ReceiverImplementation.receiveAndSendToken.selector,
                    refundAddress,
                    destinationChain,
                    destinationAddress,
                    tokenSymbol
                )
            );
    }

    // @dev Generates a deposit address for sending native currency cross-chain
    function addressForNativeDeposit(
        bytes32 salt,
        address refundAddress,
        string calldata destinationChain,
        string calldata destinationAddress
    ) public view returns (address) {
        return
            _depositAddress(
                salt,
                abi.encodeWithSelector(
                    ReceiverImplementation.receiveAndSendNative.selector,
                    refundAddress,
                    destinationChain,
                    destinationAddress
                )
            );
    }

    // @dev Generates a deposit address for unwrapping WETH-like token into native currency
    function addressForNativeUnwrap(
        bytes32 salt,
        address refundAddress,
        address recipient
    ) external view returns (address) {
        return
            _depositAddress(salt, abi.encodeWithSelector(ReceiverImplementation.receiveAndUnwrapNative.selector, refundAddress, recipient));
    }

    // @dev Receives ERC20 token from the deposit address and sends it cross-chain
    function sendTokenDeposit(
        bytes32 salt,
        address refundAddress,
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata tokenSymbol
    ) external {
        // NOTE: `DepositReceiver` is destroyed in the same runtime context that it is deployed.
        new DepositReceiver{ salt: salt }(
            abi.encodeWithSelector(
                ReceiverImplementation.receiveAndSendToken.selector,
                refundAddress,
                destinationChain,
                destinationAddress,
                tokenSymbol
            )
        );
    }

    // @dev Refunds ERC20 tokens from the deposit address if they don't match the intended token
    // Only refundAddress can refund the token that was intended to go cross-chain (if not sent yet)
    function refundTokenDeposit(
        bytes32 salt,
        address refundAddress,
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata tokenSymbol,
        address[] calldata refundTokens
    ) external {
        for (uint256 i; i < refundTokens.length; i++) {
            address gatewayToken = IAxelarGateway(gateway).tokenAddresses(tokenSymbol);

            // Allowing only the refundAddress to refund the intended token
            if (refundTokens[i] == gatewayToken && msg.sender != refundAddress) continue;

            // Saving to public storage to be accessed by the DepositReceiver
            refundToken = refundTokens[i];
            // NOTE: `DepositReceiver` is destroyed in the same runtime context that it is deployed.
            new DepositReceiver{ salt: salt }(
                abi.encodeWithSelector(
                    ReceiverImplementation.receiveAndSendToken.selector,
                    refundAddress,
                    destinationChain,
                    destinationAddress,
                    tokenSymbol
                )
            );
        }

        refundToken = address(0);
    }

    // @dev Receives native currency, wraps it into WETH-like token and sends cross-chain
    function sendNativeDeposit(
        bytes32 salt,
        address refundAddress,
        string calldata destinationChain,
        string calldata destinationAddress
    ) external {
        // NOTE: `DepositReceiver` is destroyed in the same runtime context that it is deployed.
        new DepositReceiver{ salt: salt }(
            abi.encodeWithSelector(
                ReceiverImplementation.receiveAndSendNative.selector,
                refundAddress,
                destinationChain,
                destinationAddress
            )
        );
    }

    // @dev Refunds ERC20 tokens from the deposit address after the native deposit was sent
    // Only refundAddress can refund the native currency intended to go cross-chain (if not sent yet)
    function refundNativeDeposit(
        bytes32 salt,
        address refundAddress,
        string calldata destinationChain,
        string calldata destinationAddress,
        address[] calldata refundTokens
    ) external {
        // Allowing only the refundAddress to refund the native currency
        if (addressForNativeDeposit(salt, refundAddress, destinationChain, destinationAddress).balance > 0 && msg.sender != refundAddress)
            return;

        for (uint256 i; i < refundTokens.length; i++) {
            refundToken = refundTokens[i];
            // NOTE: `DepositReceiver` is destroyed in the same runtime context that it is deployed.
            new DepositReceiver{ salt: salt }(
                abi.encodeWithSelector(
                    ReceiverImplementation.receiveAndSendNative.selector,
                    refundAddress,
                    destinationChain,
                    destinationAddress
                )
            );
        }

        refundToken = address(0);
    }

    // @dev Receives WETH-like token, unwraps and send native currency to the recipient
    function nativeUnwrap(
        bytes32 salt,
        address refundAddress,
        address payable recipient
    ) external {
        // NOTE: `DepositReceiver` is destroyed in the same runtime context that it is deployed.
        new DepositReceiver{ salt: salt }(
            abi.encodeWithSelector(ReceiverImplementation.receiveAndUnwrapNative.selector, refundAddress, recipient)
        );
    }

    // @dev Refunds ERC20 tokens from the deposit address except WETH-like token
    // Only refundAddress can refund the WETH-like token intended to be unwrapped (if not yet)
    function refundNativeUnwrap(
        bytes32 salt,
        address refundAddress,
        address payable recipient,
        address[] calldata refundTokens
    ) external {
        for (uint256 i; i < refundTokens.length; i++) {
            address wrappedTokenAddress = wrappedToken();

            // Allowing only the refundAddress to refund the WETH-like token
            if (refundTokens[i] == wrappedTokenAddress && msg.sender != refundAddress) continue;

            refundToken = refundTokens[i];
            // NOTE: `DepositReceiver` is destroyed in the same runtime context that it is deployed.
            new DepositReceiver{ salt: salt }(
                abi.encodeWithSelector(ReceiverImplementation.receiveAndUnwrapNative.selector, refundAddress, recipient)
            );
        }

        refundToken = address(0);
    }

    function _depositAddress(bytes32 create2Salt, bytes memory delegateData) internal view returns (address) {
        /* Convert a hash which is bytes32 to an address which is 20-byte long
        according to https://docs.soliditylang.org/en/v0.8.1/control-structures.html?highlight=create2#salted-contract-creations-create2 */
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff),
                                address(this),
                                create2Salt,
                                // Encoding delegateData as a constructor param
                                keccak256(abi.encodePacked(type(DepositReceiver).creationCode, abi.encode(delegateData)))
                            )
                        )
                    )
                )
            );
    }

    function contractId() public pure returns (bytes32) {
        return keccak256('axelar-deposit-service');
    }
}
