// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IRoyaltyRegistry} from "manifoldxyz/IRoyaltyRegistry.sol";

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import {LSSVMPair} from "../../LSSVMPair.sol";
import {LSSVMRouter} from "../../LSSVMRouter.sol";
import {RoyaltyEngine} from "../../RoyaltyEngine.sol";
import {ICurve} from "../../bonding-curves/ICurve.sol";
import {RouterCaller} from "../mixins/RouterCaller.sol";
import {LSSVMPairFactory} from "../../LSSVMPairFactory.sol";
import {IERC721Mintable} from "../interfaces/IERC721Mintable.sol";
import {ConfigurableWithRoyalties} from "../mixins/ConfigurableWithRoyalties.sol";

/// @dev Gives more realistic scenarios where swaps have to go through multiple pools, for more accurate gas profiling
abstract contract RouterMultiPoolWithRoyalties is Test, ERC721Holder, ConfigurableWithRoyalties, RouterCaller {
    IERC721Mintable test721;
    ERC2981 test2981;
    RoyaltyEngine royaltyEngine;
    ICurve bondingCurve;
    LSSVMPairFactory factory;
    LSSVMRouter router;
    mapping(uint256 => LSSVMPair) pairs;
    address payable constant feeRecipient = payable(address(69));
    uint256 constant protocolFeeMultiplier = 3e15;
    uint256 numInitialNFTs = 10;

    function setUp() public {
        bondingCurve = setupCurve();
        test721 = setup721();
        test2981 = setup2981();
        royaltyEngine = setupRoyaltyEngine();
        IRoyaltyRegistry(royaltyEngine.royaltyRegistry()).setRoyaltyLookupAddress(address(test721), address(test2981));

        factory = setupFactory(royaltyEngine, feeRecipient);
        router = new LSSVMRouter(factory);
        factory.setBondingCurveAllowed(bondingCurve, true);
        factory.setRouterAllowed(router, true);

        // set NFT approvals
        test721.setApprovalForAll(address(factory), true);
        test721.setApprovalForAll(address(router), true);

        // mint NFT #1-10 to caller
        for (uint256 i = 1; i <= numInitialNFTs; i++) {
            test721.mint(address(this), i);
        }

        // Pair 1 has NFT#1 at 1 ETH price, willing to also buy at the same price
        // Pair 2 has NFT#2 at 2 ETH price, willing to also buy at the same price
        // Pair 3 has NFT#3 at 3 ETH price, willing to also buy at the same price
        // Pair 4 has NFT#4 at 4 ETH price, willing to also buy at the same price
        // Pair 5 has NFT#5 at 5 ETH price, willing to also buy at the same price
        // For all, assume no price changes
        for (uint256 i = 1; i <= 5; i++) {
            uint256[] memory idList = new uint256[](1);
            idList[0] = i;
            pairs[i] = this.setupPair{value: modifyInputAmount(i * 1 ether)}(
                factory,
                test721,
                bondingCurve,
                payable(address(0)),
                LSSVMPair.PoolType.TRADE,
                modifyDelta(0),
                0,
                uint128(i * 1 ether),
                idList,
                (i * 1 ether),
                address(router)
            );
        }
    }

    function test_swapTokenForSpecific5NFTs() public {
        // Swap across all 5 pools
        LSSVMRouter.PairSwapSpecific[] memory swapList = new LSSVMRouter.PairSwapSpecific[](5);
        uint256 totalInputAmount = 0;
        uint256 totalRoyaltyAmount = 0;
        for (uint256 i = 0; i < 5; i++) {
            (,,, uint256 inputAmount, uint256 protocolFee) = pairs[i + 1].getBuyNFTQuote(1);

            // calculate royalty and add it to the input amount
            uint256 royaltyAmount = calcRoyalty(inputAmount - protocolFee);
            totalRoyaltyAmount += royaltyAmount;

            totalInputAmount += inputAmount;
            uint256[] memory nftIds = new uint256[](1);
            nftIds[0] = i + 1;
            swapList[i] = LSSVMRouter.PairSwapSpecific({pair: pairs[i + 1], nftIds: nftIds});
        }
        uint256 startBalance = test721.balanceOf(address(this));
        this.swapTokenForSpecificNFTs{value: modifyInputAmount(totalInputAmount)}(
            router, swapList, payable(address(this)), address(this), block.timestamp, totalInputAmount
        );
        uint256 endBalance = test721.balanceOf(address(this));
        require((endBalance - startBalance) == 5, "Too few NFTs acquired");

        // check that royalty has been issued
        assertEq(getBalance(ROYALTY_RECEIVER), totalRoyaltyAmount);
    }

    function test_swap5NFTsForToken() public {
        // Swap across all 5 pools
        LSSVMRouter.PairSwapSpecific[] memory swapList = new LSSVMRouter.PairSwapSpecific[](5);
        uint256 totalOutputAmount = 0;
        uint256 totalRoyaltyAmount = 0;
        for (uint256 i = 0; i < 5; i++) {
            uint256 outputAmount;
            (,,, outputAmount,) = pairs[i + 1].getSellNFTQuote(1);

            // calculate royalty and rm it from the output amount
            uint256 royaltyAmount = calcRoyalty(outputAmount);
            outputAmount -= royaltyAmount;
            totalRoyaltyAmount += royaltyAmount;

            totalOutputAmount += outputAmount;
            uint256[] memory nftIds = new uint256[](1);
            // Set it to be an ID we own
            nftIds[0] = i + 6;
            swapList[i] = LSSVMRouter.PairSwapSpecific({pair: pairs[i + 1], nftIds: nftIds});
        }
        uint256 startBalance = test721.balanceOf(address(this));
        router.swapNFTsForToken(swapList, totalOutputAmount, payable(address(this)), block.timestamp);
        uint256 endBalance = test721.balanceOf(address(this));
        require((startBalance - endBalance) == 5, "Too few NFTs sold");

        // check that royalty has been issued
        assertEq(getBalance(ROYALTY_RECEIVER), totalRoyaltyAmount);
    }
}
