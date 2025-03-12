// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ICurve {
    function get_virtual_price() external view returns (uint256);

    function balances(int128) external view returns (uint256);

    function add_liquidity(
        // ypool
        uint256[4] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function remove_liquidity_imbalance(uint256[4] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity(uint256 _amount, uint256[4] calldata amounts) external;

    function remove_liquidity_one_coin(uint256 _token_amount, int128, uint256 min_amount) external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function get_dy(
        int128 from,
        int128 to,
        uint256 _from_amount
    ) external view returns (uint256);
}
