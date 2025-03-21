// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract VikingsWarToken is ERC20Burnable {
    constructor (string memory name, string memory symbol, address initialAccount, uint256 initialBalance) ERC20(name, symbol) {
        _mint(initialAccount, initialBalance);
    }
}