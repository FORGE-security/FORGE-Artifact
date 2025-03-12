//SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.17;

import "./multiSign.sol";

contract MultiSignWallet is MultiSign {
    struct Transfer {
        uint256 amount;
        address payable to;
        uint256 requiredCount;
        bool sent;
    }
    mapping(bytes32 => Transfer) transfers; // txid => Transfer
    mapping(address => mapping(bytes32 => bool)) isSent; // signer => txid => isSent

    event Wrap(
        address indexed sender,
        address indexed to,
        bytes32 symbol,
        uint256 amount
    );

    constructor(address[] memory _signers, uint8 _requireCount)
        MultiSign(_signers, _requireCount)
    {}

    // send to user
    // txid is the txid of target chain, it must be unique
    // only the MultiSignWallet can do this
    function send(
        bytes32 txid,
        uint256 amount,
        address payable to
    ) external onlySigner {
        require(!transfers[txid].sent, "sent over");
        if (transfers[txid].to == address(0)) {
            transfers[txid] = Transfer(amount, to, 0, false);
        } else {
            require(
                transfers[txid].amount == amount && transfers[txid].to == to,
                "invalid transfer"
            );
        }
        if (!isSent[msg.sender][txid]) {
            isSent[msg.sender][txid] = true;
            transfers[txid].requiredCount++;
        }

        if (transfers[txid].requiredCount >= requireCount) {
            transfers[txid].sent = true;
            (bool success, ) = to.call{value: amount}("");
            require(success, "transfer failed");
            return;
        }
    }

    // deposit native token to this contract to wrap token in the target chain
    // to is the address in the target chain
    // symobl is the bridge token symbol in the target chain
    function wrap(address to, bytes32 symbol) external payable {
        emit Wrap(msg.sender, to, symbol, msg.value);
    }
}
