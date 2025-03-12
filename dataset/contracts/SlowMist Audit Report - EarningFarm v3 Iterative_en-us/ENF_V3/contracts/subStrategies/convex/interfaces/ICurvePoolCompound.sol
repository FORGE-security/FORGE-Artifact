// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurvePoolCompound {
    function add_liquidity(uint256[2] memory _deposit_amounts, uint256 _min_mint_amount) external;

    function remove_liquidity_one_coin(
        uint256 _burn_amount,
        int128 i,
        uint256 _min_amount
    ) external;

    // function calc_token_amount(uint256[4] memory _deposit_amounts, bool _is_deposit) external view returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);
}
