// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "../EUSDToken.sol";

contract EUSDTokenTester is EUSDToken {
    bytes32 private immutable _PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    constructor(
        address _troveManagerAddress,
        address _troveManagerLiquidatorAddress,
        address _troveManagerRedemptionsAddress,
        address _stabilityPoolAddress,
        address _borrowerOperationsAddress,
        address _treasuryAddress,
        address _liquidityIncentiveAddress
    ) {
        EUSDToken.initialize(
            _troveManagerAddress,
            _troveManagerLiquidatorAddress,
            _troveManagerRedemptionsAddress,
            _stabilityPoolAddress,
            _borrowerOperationsAddress,
            _treasuryAddress,
            _liquidityIncentiveAddress
        );
    }

    function unprotectedMint(address _account, uint256 _amount) external {
        // No check on caller here

        _mint(_account, _amount);
    }

    function unprotectedBurn(address _account, uint256 _amount) external {
        // No check on caller here

        _burn(_account, _amount);
    }

    function unprotectedSendToPool(
        address _sender,
        address _poolAddress,
        uint256 _amount
    ) external {
        // No check on caller here

        _transfer(_sender, _poolAddress, _amount);
    }

    function unprotectedReturnFromPool(
        address _poolAddress,
        address _receiver,
        uint256 _amount
    ) external {
        // No check on caller here

        _transfer(_poolAddress, _receiver, _amount);
    }

    function callInternalApprove(
        address owner,
        address spender,
        uint256 amount
    ) external returns (bool) {
        _approve(owner, spender, amount);
        return true;
    }

    function getChainId() external view returns (uint256 chainID) {
        //return _chainID(); // it’s private
        assembly {
            chainID := chainid()
        }
    }

    function getDigest(
        address owner,
        address spender,
        uint256 amount,
        uint256 nonce,
        uint256 deadline
    ) external view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    uint16(0x1901),
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            _PERMIT_TYPEHASH,
                            owner,
                            spender,
                            amount,
                            nonce,
                            deadline
                        )
                    )
                )
            );
    }

    function recoverAddress(
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external pure returns (address) {
        return ecrecover(digest, v, r, s);
    }
}
