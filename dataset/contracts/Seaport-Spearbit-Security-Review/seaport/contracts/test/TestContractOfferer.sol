// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {
    ERC20Interface,
    ERC721Interface,
    ERC1155Interface
} from "../interfaces/AbridgedTokenInterfaces.sol";

import {
    ContractOffererInterface
} from "../interfaces/ContractOffererInterface.sol";

import { ItemType } from "../lib/ConsiderationEnums.sol";

import { SpentItem, ReceivedItem } from "../lib/ConsiderationStructs.sol";

/**
 * @title TestContractOfferer
 * @author 0age
 * @notice TestContractOfferer is a maximally simple contract offerer. It offers
 *         a single item and expects to receive back another single item, and
 *         ignores all parameters supplied to it when previewing or generating
 *         an order. The offered item is placed into this contract as part of
 *         deployment and the corresponding token approvals are set for Seaport.
 */
contract TestContractOfferer is ContractOffererInterface {
    error OrderUnavailable();

    address private immutable _SEAPORT;

    SpentItem private _available;
    SpentItem private _required;

    bool public ready;
    bool public fulfilled;

    uint256 public extraAvailable;
    uint256 public extraRequired;

    constructor(address seaport) {
        // Set immutable values and storage variables.
        _SEAPORT = seaport;
        fulfilled = false;
        ready = false;
        extraAvailable = 0;
        extraRequired = 0;
    }

    receive() external payable {}

    function activate(
        SpentItem memory available,
        SpentItem memory required
    ) public payable {
        if (ready || fulfilled) {
            revert OrderUnavailable();
        }

        // Retrieve the offered item and set associated approvals.
        if (available.itemType == ItemType.NATIVE) {
            available.amount = address(this).balance;
        } else if (available.itemType == ItemType.ERC20) {
            ERC20Interface token = ERC20Interface(available.token);

            token.transferFrom(msg.sender, address(this), available.amount);

            token.approve(_SEAPORT, available.amount);
        } else if (available.itemType == ItemType.ERC721) {
            ERC721Interface token = ERC721Interface(available.token);

            token.transferFrom(msg.sender, address(this), available.identifier);

            token.setApprovalForAll(_SEAPORT, true);
        } else if (available.itemType == ItemType.ERC1155) {
            ERC1155Interface token = ERC1155Interface(available.token);

            token.safeTransferFrom(
                msg.sender,
                address(this),
                available.identifier,
                available.amount,
                ""
            );

            token.setApprovalForAll(_SEAPORT, true);
        }

        // Set storage variables.
        _available = available;
        _required = required;
        ready = true;
    }

    function extendAvailable() public {
        if (!ready || fulfilled) {
            revert OrderUnavailable();
        }

        extraAvailable++;

        _available.amount /= 2;
    }

    function extendRequired() public {
        if (!ready || fulfilled) {
            revert OrderUnavailable();
        }

        extraRequired++;
    }

    function generateOrder(
        address,
        SpentItem[] calldata,
        SpentItem[] calldata,
        bytes calldata context
    )
        external
        virtual
        override
        returns (SpentItem[] memory offer, ReceivedItem[] memory consideration)
    {
        // Ensure the caller is Seaport & the order has not yet been fulfilled.
        if (
            !ready || fulfilled || msg.sender != _SEAPORT || context.length != 0
        ) {
            revert OrderUnavailable();
        }

        // Set the offer and consideration that were supplied during deployment.
        offer = new SpentItem[](1 + extraAvailable);
        consideration = new ReceivedItem[](1 + extraRequired);

        for (uint256 i = 0; i < 1 + extraAvailable; ++i) {
            offer[i] = _available;
        }

        for (uint256 i = 0; i < 1 + extraRequired; ++i) {
            consideration[i] = ReceivedItem({
                itemType: _required.itemType,
                token: _required.token,
                identifier: _required.identifier,
                amount: _required.amount,
                recipient: payable(address(this))
            });
        }

        // Update storage to reflect that the order has been fulfilled.
        fulfilled = true;
    }

    function previewOrder(
        address caller,
        address,
        SpentItem[] calldata,
        SpentItem[] calldata,
        bytes calldata context
    )
        external
        view
        override
        returns (SpentItem[] memory offer, ReceivedItem[] memory consideration)
    {
        // Ensure the caller is Seaport & the order has not yet been fulfilled.
        if (!ready || fulfilled || caller != _SEAPORT || context.length != 0) {
            revert OrderUnavailable();
        }

        // Set the offer and consideration that were supplied during deployment.
        offer = new SpentItem[](1 + extraAvailable);
        consideration = new ReceivedItem[](1 + extraRequired);

        for (uint256 i = 0; i < 1 + extraAvailable; ++i) {
            offer[i] = _available;
        }

        for (uint256 i = 0; i < 1 + extraRequired; ++i) {
            consideration[i] = ReceivedItem({
                itemType: _required.itemType,
                token: _required.token,
                identifier: _required.identifier,
                amount: _required.amount,
                recipient: payable(address(this))
            });
        }
    }

    function getInventory()
        external
        view
        returns (SpentItem[] memory offerable, SpentItem[] memory receivable)
    {
        // Set offerable and receivable supplied at deployment if unfulfilled.
        if (!ready || fulfilled) {
            offerable = new SpentItem[](0);

            receivable = new SpentItem[](0);
        } else {
            offerable = new SpentItem[](1 + extraAvailable);
            for (uint256 i = 0; i < 1 + extraAvailable; ++i) {
                offerable[i] = _available;
            }

            receivable = new SpentItem[](1 + extraRequired);
            for (uint256 i = 0; i < 1 + extraRequired; ++i) {
                receivable[i] = _required;
            }
        }
    }

    function ratifyOrder(
        SpentItem[] calldata /* offer */,
        ReceivedItem[] calldata /* consideration */,
        bytes calldata /* context */,
        bytes32[] calldata /* orderHashes */,
        uint256 /* contractNonce */
    )
        external
        pure
        virtual
        override
        returns (bytes4 /* ratifyOrderMagicValue */)
    {
        return ContractOffererInterface.ratifyOrder.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return bytes4(0xf23a6e61);
    }

    function getMetadata()
        external
        pure
        override
        returns (
            uint256 schemaID, // maps to a Seaport standard's ID
            string memory name,
            bytes memory metadata // decoded based on the schemaID
        )
    {
        return (1337, "TestContractOfferer", "");
    }
}
