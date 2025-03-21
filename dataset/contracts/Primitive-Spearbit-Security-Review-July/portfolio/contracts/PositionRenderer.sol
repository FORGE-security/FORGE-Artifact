// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import "openzeppelin/utils/Base64.sol";
import "openzeppelin/utils/Strings.sol";
import "solmate/tokens/ERC20.sol";
import "solmate/utils/SafeCastLib.sol";
import "./interfaces/IPortfolio.sol";
import "./interfaces/IStrategy.sol";
import "./strategies/NormalStrategy.sol";

/// @dev Contract to render a position.
contract PositionRenderer {
    using Strings for *;
    using SafeCastLib for *;

    function uri(uint256 id) external view returns (string memory) {
        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '{"name":"',
                        _generateName(id),
                        '","image":"',
                        _generateImage(),
                        '","license":"MIT","creator":"primitive.eth",',
                        '"description":"Concentrated liquidity tokens of a two-token AMM",',
                        '"properties":{',
                        _generatePair(id),
                        ",",
                        _generatePool(id),
                        ",",
                        _generateConfig(id),
                        "}}"
                    )
                )
            )
        );
    }

    function _generateName(uint256 id) private view returns (string memory) {
        (address tokenAsset,, address tokenQuote,) = IPortfolio(msg.sender)
            .pairs(PoolId.wrap(id.safeCastTo64()).pairId());

        return string.concat(
            "Primitive Portfolio LP ",
            ERC20(tokenAsset).symbol(),
            "-",
            ERC20(tokenQuote).symbol()
        );
    }

    function _generateImage() private pure returns (string memory) {
        return string.concat(
            "data:image/svg+xml;base64,",
            Base64.encode(
                bytes(
                    '<svg width="512" height="512" fill="none" xmlns="http://www.w3.org/2000/svg"><path fill="#000" d="M0 0h512v512H0z"/><path fill-rule="evenodd" clip-rule="evenodd" d="M339.976 134.664h41.048L256 340.586 130.976 134.664h41.047V98H64.143L256 414 447.857 98H339.976v36.664Zm-38.759 0V98h-90.436v36.664h90.436Z" fill="#fff"/></svg>'
                )
            )
        );
    }

    function _generatePair(uint256 id) private view returns (string memory) {
        (address tokenAsset,, address tokenQuote,) = IPortfolio(msg.sender)
            .pairs(PoolId.wrap(id.safeCastTo64()).pairId());

        return string.concat(
            '"asset_name":"',
            ERC20(tokenAsset).name(),
            '",',
            '"asset_symbol":"',
            ERC20(tokenAsset).symbol(),
            '",',
            '"asset_address":"',
            Strings.toHexString(tokenAsset),
            '",',
            '"quote_name":"',
            ERC20(tokenQuote).name(),
            '",',
            '"quote_symbol":"',
            ERC20(tokenQuote).symbol(),
            '",',
            '"quote_address":"',
            Strings.toHexString(tokenQuote),
            '"'
        );
    }

    function _generatePool(uint256 id) private view returns (string memory) {
        (
            ,
            ,
            ,
            ,
            uint16 feeBasisPoints,
            uint16 priorityFeeBasisPoints,
            address controller,
            address strategy
        ) = IPortfolio(msg.sender).pools(uint64(id));

        return string.concat(
            '"fee_basis_points":"',
            feeBasisPoints.toString(),
            '",',
            '"priority_fee_basis_points":"',
            priorityFeeBasisPoints.toString(),
            '",',
            '"controller":"',
            Strings.toHexString(controller),
            '",',
            '"strategy":"',
            Strings.toHexString(strategy),
            '"'
        );
    }

    function _generateConfig(uint256 id) private view returns (string memory) {
        (,,,,,,, address strategy) = IPortfolio(msg.sender).pools(uint64(id));

        if (strategy == address(0)) {
            strategy = IPortfolio(msg.sender).DEFAULT_STRATEGY();
        }

        (
            uint128 strikePriceWad,
            uint32 volatilityBasisPoints,
            uint32 durationSeconds,
            uint32 creationTimestamp,
            bool isPerpetual
        ) = NormalStrategy(strategy).configs(uint64(id));

        return string.concat(
            '"strike_price_wad":"',
            strikePriceWad.toString(),
            '",',
            '"volatility_basis_points":"',
            volatilityBasisPoints.toString(),
            '",',
            '"duration_seconds":"',
            durationSeconds.toString(),
            '",',
            '"creation_timestamp":"',
            creationTimestamp.toString(),
            '",',
            '"is_perpetual":',
            isPerpetual ? "true" : "false"
        );
    }
}
