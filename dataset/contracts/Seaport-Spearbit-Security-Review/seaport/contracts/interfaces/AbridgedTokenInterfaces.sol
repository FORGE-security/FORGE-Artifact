// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ERC20Interface {
    function transferFrom(address, address, uint256) external returns (bool);

    function approve(address, uint256) external returns (bool);
}

interface ERC721Interface {
    function transferFrom(address, address, uint256) external;

    function setApprovalForAll(address, bool) external;

    function ownerOf(uint256) external view returns (address);
}

interface ERC1155Interface {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function setApprovalForAll(address, bool) external;
}
