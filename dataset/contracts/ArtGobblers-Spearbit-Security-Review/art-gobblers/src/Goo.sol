// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

/// @title Goo Token (GOO)
/// @author FrankieIsLost <frankie@paradigm.xyz>
/// @author transmissions11 <t11s@paradigm.xyz>
/// @notice Goo is the in-game token for ArtGobblers. It's a standard ERC20
/// token that can be burned and minted by the gobblers and pages contract.
contract Goo is ERC20("Goo", "GOO", 18) {
    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice The address of the Art Gobblers contract.
    address public immutable artGobblers;

    /// @notice The address of the Pages contract.
    address public immutable pages;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _artGobblers, address _pages) {
        artGobblers = _artGobblers;
        pages = _pages;
    }

    /*//////////////////////////////////////////////////////////////
                             MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Requires caller address to match user address.
    modifier only(address user) {
        if (msg.sender != user) revert Unauthorized();

        _;
    }

    /// @notice Mint any amount of goo to a user. Can only be called by ArtGobblers.
    /// @param to The address of the user to mint goo to.
    /// @param amount The amount of goo to mint.
    function mintForGobblers(address to, uint256 amount) public only(artGobblers) {
        _mint(to, amount);
    }

    /// @notice Burn any amount of goo from a user. Can only be called by ArtGobblers.
    /// @param from The address of the user to burn goo from.
    /// @param amount The amount of goo to burn.
    function burnForGobblers(address from, uint256 amount) public only(artGobblers) {
        _burn(from, amount);
    }

    /// @notice Burn any amount of goo from a user. Can only be called by Pages.
    /// @param from The address of the user to burn goo from.
    /// @param amount The amount of goo to burn.
    function burnForPages(address from, uint256 amount) public only(pages) {
        _burn(from, amount);
    }
}
