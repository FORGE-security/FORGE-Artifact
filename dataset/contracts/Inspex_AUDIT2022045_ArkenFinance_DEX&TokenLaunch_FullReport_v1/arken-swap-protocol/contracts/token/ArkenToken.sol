// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.11;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol';

contract ArkenToken is ERC20, ERC20Permit, ERC20Votes {
    constructor(address _to, uint256 _totalSupply)
        ERC20('Arken Token', 'ARKEN')
        ERC20Permit('Arken Token')
    {
        _mint(_to, _totalSupply);
    }

    // The functions below are overrides required by Solidity.

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}
