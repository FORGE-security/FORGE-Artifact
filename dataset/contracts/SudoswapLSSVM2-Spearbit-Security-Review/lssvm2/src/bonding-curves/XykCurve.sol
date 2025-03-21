// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {ICurve} from "./ICurve.sol";
import {LSSVMPair} from "../LSSVMPair.sol";
import {LSSVMPairERC20} from "../LSSVMPairERC20.sol";
import {CurveErrorCodes} from "./CurveErrorCodes.sol";
import {LSSVMPairCloner} from "../lib/LSSVMPairCloner.sol";
import {ILSSVMPairFactoryLike} from "../LSSVMPairFactory.sol";

/*
    @author 0xacedia
    @notice Bonding curve logic for an x*y=k curve using virtual reserves.
    @dev    The virtual token reserve is stored in `spotPrice` and the virtual nft reserve is stored in `delta`.
            An LP can modify the virtual reserves by changing the `spotPrice` (tokens) or `delta` (nfts).*/
contract XykCurve is ICurve, CurveErrorCodes {
    using FixedPointMathLib for uint256;

    /**
     * @dev See {ICurve-validateDelta}
     */
    function validateDelta(uint128 /*delta*/ ) external pure override returns (bool) {
        // all values are valid
        return true;
    }

    /**
     * @dev See {ICurve-validateSpotPrice}
     */
    function validateSpotPrice(uint128 /*newSpotPrice*/ ) external pure override returns (bool) {
        // all values are valid
        return true;
    }

    /**
     * @dev See {ICurve-getBuyInfo}
     */
    function getBuyInfo(
        uint128 spotPrice,
        uint128 delta,
        uint256 numItems,
        uint256 feeMultiplier,
        uint256 protocolFeeMultiplier
    )
        external
        pure
        override
        returns (
            Error error,
            uint128 newSpotPrice,
            uint128 newDelta,
            uint256 inputValue,
            uint256 tradeFee,
            uint256 protocolFee
        )
    {
        if (numItems == 0) {
            return (Error.INVALID_NUMITEMS, 0, 0, 0, 0, 0);
        }

        // get the pair's virtual nft and token reserves
        uint256 tokenBalance = spotPrice;
        uint256 nftBalance = delta;

        // If numItems is too large, we will get divide by zero error
        if (numItems >= nftBalance) {
            return (Error.INVALID_NUMITEMS, 0, 0, 0, 0, 0);
        }

        // calculate the amount to send in
        uint256 inputValueWithoutFee = (numItems * tokenBalance) / (nftBalance - numItems);

        // add the fees to the amount to send in
        protocolFee = inputValueWithoutFee.mulWadDown(protocolFeeMultiplier);
        tradeFee = inputValueWithoutFee.mulWadDown(feeMultiplier);
        inputValue = inputValueWithoutFee + tradeFee + protocolFee;

        // set the new virtual reserves
        newSpotPrice = uint128(spotPrice + inputValueWithoutFee); // token reserve
        newDelta = uint128(nftBalance - numItems); // nft reserve

        // If we got all the way here, no math error happened
        error = Error.OK;
    }

    /**
     * @dev See {ICurve-getSellInfo}
     */
    function getSellInfo(
        uint128 spotPrice,
        uint128 delta,
        uint256 numItems,
        uint256 feeMultiplier,
        uint256 protocolFeeMultiplier
    )
        external
        pure
        override
        returns (
            Error error,
            uint128 newSpotPrice,
            uint128 newDelta,
            uint256 outputValue,
            uint256 tradeFee,
            uint256 protocolFee
        )
    {
        if (numItems == 0) {
            return (Error.INVALID_NUMITEMS, 0, 0, 0, 0, 0);
        }

        // get the pair's virtual nft and eth/erc20 balance
        uint256 tokenBalance = spotPrice;
        uint256 nftBalance = delta;

        // calculate the amount to send out
        uint256 outputValueWithoutFee = (numItems * tokenBalance) / (nftBalance + numItems);

        // subtract fees from amount to send out
        protocolFee = outputValueWithoutFee.mulWadDown(protocolFeeMultiplier);
        tradeFee = outputValueWithoutFee.mulWadDown(feeMultiplier);
        outputValue = outputValueWithoutFee - tradeFee - protocolFee;

        // set the new virtual reserves
        newSpotPrice = uint128(spotPrice - outputValueWithoutFee); // token reserve
        newDelta = uint128(nftBalance + numItems); // nft reserve

        // If we got all the way here, no math error happened
        error = Error.OK;
    }
}
