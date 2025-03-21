// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "../libraries/Orders.sol";

interface IBaseExchange {
    event Cancel(bytes32 indexed hash);
    event Execute(
        bytes32 indexed hash,
        address bidder,
        uint256 amount,
        uint256 price,
        address recipient,
        address referrer
    );
    event Bid(bytes32 indexed hash, address bidder, uint256 amount, uint256 price, address recipient, address referrer);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function factory() external view returns (address);

    function royaltyFeeInfo() external view returns (address recipient, uint8 permil);

    function canTrade(address token) external view returns (bool);

    function bestBid(bytes32 hash)
        external
        view
        returns (
            address bidder,
            uint256 amount,
            uint256 price,
            address recipient,
            address referrer,
            uint256 blockNumber
        );

    function isCancelled(bytes32 hash) external view returns (bool);

    function amountFilled(bytes32 hash) external view returns (uint256);

    function cancel(Orders.Ask memory order) external;

    function bid(Orders.Ask memory askOrder, Orders.Bid memory bidOrder) external returns (bool executed);

    function bid(
        Orders.Ask memory askOrder,
        uint256 bidAmount,
        uint256 bidPrice,
        address bidRecipient,
        address bidReferrer
    ) external returns (bool executed);

    function claim(Orders.Ask memory order) external;
}
