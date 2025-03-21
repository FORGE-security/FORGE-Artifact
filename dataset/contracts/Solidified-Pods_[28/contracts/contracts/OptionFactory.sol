// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;

import "./PodPut.sol";
import "./wPodPut.sol";

contract OptionFactory {
    PodPut[] public options;

    event OptionCreated(
        address indexed deployer,
        PodPut option,
        address underlyingAsset,
        address strikeAsset,
        uint256 strikePrice,
        uint256 expirationDate
    );

    /**
     * @notice creates a new PodPut Contract
     * @param _name The option token name. Eg. "Pods Put WBTC-USDC 5000 2020-02-23"
     * @param _symbol The option token symbol. Eg. "podWBTC:20AA"
     * @param _optionType The option type. Eg. "0 for Put, 1 for Call"
     * @param _underlyingAsset The underlying asset. Eg. "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
     * @param _strikeAsset The strike asset. Eg. "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
     * @param _strikePrice The option strike price including decimals (strikePriceDecimals == strikeAssetDecimals), Eg, 5000000000
     * @param _expirationDate The Expiration Option date in blocknumbers. E.g 19203021
     * @param _uniswapFactory Uniswap factory address that will be used to sell options
     */
    function createOption(
        string memory _name,
        string memory _symbol,
        PodOption.OptionType _optionType,
        address _underlyingAsset,
        address _strikeAsset,
        uint256 _strikePrice,
        uint256 _expirationDate,
        address _uniswapFactory
    ) public returns (PodPut) {
        require(_expirationDate > block.number, "Expiration lower than current block");

        PodPut option = new PodPut(
            _name,
            _symbol,
            _optionType,
            _underlyingAsset,
            _strikeAsset,
            _strikePrice,
            _expirationDate,
            _uniswapFactory
        );

        options.push(option);
        emit OptionCreated(msg.sender, option, _underlyingAsset, _strikeAsset, _strikePrice, _expirationDate);
        return option;
    }

    /**
     * @notice creates a new wPodPut Contract
     * @param _name The option token name. Eg. "Pods Put ETH-USDC 5000 2020-02-23"
     * @param _symbol The option token symbol. Eg. "podETH:20AA"
     * @param _optionType The option type. Eg. "0 for Put, 1 for Call"
     * @param _underlyingAsset The underlying asset. Eg. "weth address implementation"
     * @param _strikeAsset The strike asset. Eg. "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
     * @param _strikePrice The option strike price including decimals (strikePriceDecimals == strikeAssetDecimals), Eg, 5000000000
     * @param _expirationDate The Expiration Option date in blocknumbers. E.g 19203021
     * @param _uniswapFactory Uniswap factory address that will be used to sell options
     */
    function createEthOption(
        string memory _name,
        string memory _symbol,
        PodOption.OptionType _optionType,
        address _underlyingAsset,
        address _strikeAsset,
        uint256 _strikePrice,
        uint256 _expirationDate,
        address _uniswapFactory
    ) public returns (wPodPut) {
        require(_expirationDate > block.number, "Expiration lower than current block");

        wPodPut option = new wPodPut(
            _name,
            _symbol,
            _optionType,
            _underlyingAsset,
            _strikeAsset,
            _strikePrice,
            _expirationDate,
            _uniswapFactory
        );

        options.push(option);
        emit OptionCreated(msg.sender, option, _underlyingAsset, _strikeAsset, _strikePrice, _expirationDate);
        return option;
    }
}
