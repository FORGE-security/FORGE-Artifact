// SPDX-License-Identifier: GPL-2.0

pragma solidity 0.7.6;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import './BaseModule.sol';
import '../helpers/SafeInt24Math.sol';
import '../helpers/UniswapNFTHelper.sol';
import '../helpers/MathHelper.sol';
import '../../interfaces/IAaveAddressHolder.sol';
import '../../interfaces/IUniswapAddressHolder.sol';
import '../../interfaces/actions/IAaveDeposit.sol';
import '../../interfaces/actions/IAaveWithdraw.sol';
import '../../interfaces/actions/IDecreaseLiquidity.sol';
import '../../interfaces/actions/ICollectFees.sol';
import '../../interfaces/actions/ISwap.sol';
import '../../interfaces/actions/ISwapToPositionRatio.sol';
import '../../interfaces/actions/IIncreaseLiquidity.sol';
import '../../interfaces/ILendingPool.sol';

contract AaveModule is BaseModule {
    IAaveAddressHolder public immutable aaveAddressHolder;
    IUniswapAddressHolder public immutable uniswapAddressHolder;
    using SignedSafeMath for int24;

    constructor(
        address _aaveAddressHolder,
        address _uniswapAddressHolder,
        address _registry
    ) BaseModule(_registry) {
        aaveAddressHolder = IAaveAddressHolder(_aaveAddressHolder);
        uniswapAddressHolder = IUniswapAddressHolder(_uniswapAddressHolder);
    }

    ///@notice deposit a position in an Aave lending pool
    ///@param positionManager address of the position manager
    ///@param tokenId id of the Uniswap position to deposit
    function depositIfNeeded(address positionManager, uint256 tokenId)
        public
        activeModule(positionManager, tokenId)
        onlyWhitelistedKeeper
    {
        (, bytes32 data) = IPositionManager(positionManager).getModuleInfo(tokenId, address(this));

        require(data != bytes32(0), 'AaveModule::depositIfNeeded: module data cannot be empty');

        uint24 rebalanceDistance = MathHelper.fromUint256ToUint24(uint256(data));
        address nonfungiblePositionManager = uniswapAddressHolder.nonfungiblePositionManagerAddress();
        ///@dev move token to aave only if the position's range is outside of the tick of the pool
        if (
            UniswapNFTHelper._checkDistanceFromRange(
                tokenId,
                nonfungiblePositionManager,
                uniswapAddressHolder.uniswapV3FactoryAddress()
            ) >
            0 &&
            rebalanceDistance <=
            UniswapNFTHelper._checkDistanceFromRange(
                tokenId,
                nonfungiblePositionManager,
                uniswapAddressHolder.uniswapV3FactoryAddress()
            )
        ) {
            _depositToAave(positionManager, tokenId);
        }
    }

    ///@notice check if withdraw is needed and execute
    ///@param positionManager address of the position manager
    ///@param token address of the token of Aave position
    ///@param id id of the Aave position to withdraw
    function withdrawIfNeeded(
        address positionManager,
        address token,
        uint256 id
    ) public onlyWhitelistedKeeper {
        require(token != address(0), 'AaveModule::withdrawIfNeeded: token cannot be address 0');

        address nonfungiblePositionManager = uniswapAddressHolder.nonfungiblePositionManagerAddress();

        uint256 tokenId = IPositionManager(positionManager).getTokenIdFromAavePosition(token, id);
        (, int24 tickPool, , , , , ) = IUniswapV3Pool(
            UniswapNFTHelper._getPoolFromTokenId(
                tokenId,
                INonfungiblePositionManager(nonfungiblePositionManager),
                uniswapAddressHolder.uniswapV3FactoryAddress()
            )
        ).slot0();

        (, , , int24 tickLower, int24 tickUpper) = UniswapNFTHelper._getTokens(
            tokenId,
            INonfungiblePositionManager(nonfungiblePositionManager)
        );
        if (tickPool > tickLower && tickPool < tickUpper) {
            _returnToUniswap(positionManager, token, id, tokenId);
        }
    }

    ///@notice deposit a uni v3 position to an Aave lending pool
    ///@param positionManager address of the position manager
    ///@param tokenId id of the Uniswap position to deposit
    function _depositToAave(address positionManager, uint256 tokenId) internal {
        (, , address token0, address token1, , , , , , , , ) = INonfungiblePositionManager(
            uniswapAddressHolder.nonfungiblePositionManagerAddress()
        ).positions(tokenId);

        (, int24 tickPool, , , , , ) = IUniswapV3Pool(
            UniswapNFTHelper._getPoolFromTokenId(
                tokenId,
                INonfungiblePositionManager(uniswapAddressHolder.nonfungiblePositionManagerAddress()),
                uniswapAddressHolder.uniswapV3FactoryAddress()
            )
        ).slot0();

        (, , , int24 tickLower, int24 tickUpper) = UniswapNFTHelper._getTokens(
            tokenId,
            INonfungiblePositionManager(uniswapAddressHolder.nonfungiblePositionManagerAddress())
        );

        address toAaveToken;
        if (tickPool > tickLower && tickPool > tickUpper) toAaveToken = token0;
        else if (tickPool < tickLower && tickPool < tickUpper) toAaveToken = token1;

        require(toAaveToken != address(0), 'AaveModule::_depositToAave: position is in range.');

        require(
            ILendingPool(aaveAddressHolder.lendingPoolAddress()).getReserveData(toAaveToken).aTokenAddress !=
                address(0),
            'AaveModule::_depositToAave: Aave token not found.'
        );

        (uint256 amount0ToDecrease, uint256 amount1ToDecrease) = UniswapNFTHelper._getAmountsfromTokenId(
            tokenId,
            INonfungiblePositionManager(uniswapAddressHolder.nonfungiblePositionManagerAddress()),
            uniswapAddressHolder.uniswapV3FactoryAddress()
        );

        IDecreaseLiquidity(positionManager).decreaseLiquidity(tokenId, amount0ToDecrease, amount1ToDecrease);
        (uint256 amount0Collected, uint256 amount1Collected) = ICollectFees(positionManager).collectFees(
            tokenId,
            false
        );

        toAaveToken == token0
            ? amount0Collected += ISwap(positionManager).swap(
                token1,
                toAaveToken,
                _findBestFee(token1, toAaveToken),
                amount1Collected
            )
            : amount1Collected += ISwap(positionManager).swap(
            token0,
            toAaveToken,
            _findBestFee(token0, toAaveToken),
            amount0Collected
        );

        (uint256 id, ) = IAaveDeposit(positionManager).depositToAave(token0, amount0Collected);

        IPositionManager(positionManager).pushTokenIdToAave(toAaveToken, id, tokenId);
        IPositionManager(positionManager).removePositionId(tokenId);
    }

    ///@notice return a position to Uniswap
    ///@param positionManager address of the position manager
    ///@param token address of the token of Aave position
    ///@param id id of the Aave position to withdraw
    function _returnToUniswap(
        address positionManager,
        address token,
        uint256 id,
        uint256 tokenId
    ) internal {
        uint256 amountWithdrawn = IAaveWithdraw(positionManager).withdrawFromAave(token, id);
        (address token0, address token1, uint24 fee, int24 tickLower, int24 tickUpper) = UniswapNFTHelper._getTokens(
            tokenId,
            INonfungiblePositionManager(uniswapAddressHolder.nonfungiblePositionManagerAddress())
        );

        (uint256 amount0Out, uint256 amount1Out) = ISwapToPositionRatio(positionManager).swapToPositionRatio(
            ISwapToPositionRatio.SwapToPositionInput({
                token0Address: token0,
                token1Address: token1,
                fee: fee,
                amount0In: token == token0 ? amountWithdrawn : 0,
                amount1In: token == token1 ? amountWithdrawn : 0,
                tickLower: tickLower,
                tickUpper: tickUpper
            })
        );

        IIncreaseLiquidity(positionManager).increaseLiquidity(tokenId, amount0Out, amount1Out);
        IPositionManager(positionManager).removeTokenIdFromAave(token, id);
        IPositionManager(positionManager).pushPositionId(tokenId);
    }

    ///@notice finds the best fee tier on which to perform a swap
    ///@dev this only tracks the currently in range liquidity, disregarding the range that could be reached with our swap
    ///@param token0 address of first token
    ///@param token1 address of second token
    ///@return fee suggested fee tier
    function _findBestFee(address token0, address token1) internal view returns (uint24 fee) {
        uint128 bestLiquidity;
        uint16[4] memory fees = [100, 500, 3000, 10000];

        for (uint256 i; i < 4; ++i) {
            try this.getPoolLiquidity(token0, token1, uint24(fees[i])) returns (uint128 nextLiquidity) {
                if (nextLiquidity > bestLiquidity) {
                    bestLiquidity = nextLiquidity;
                    fee = fees[i];
                }
            } catch {
                //pass
            }
        }

        if (bestLiquidity == 0) {
            revert('AaveModule::_findBestFee: No pool found with desired tokens');
        }
    }

    ///@notice wrapper of getPoolLiquidity to use try/catch statement
    ///@param token0 address of first token
    ///@param token1 address of second token
    ///@param fee pool fee tier
    ///@return liquidity of the pool
    function getPoolLiquidity(
        address token0,
        address token1,
        uint24 fee
    ) public view returns (uint128 liquidity) {
        return
            IUniswapV3Pool(
                UniswapNFTHelper._getPool(uniswapAddressHolder.uniswapV3FactoryAddress(), token0, token1, fee)
            ).liquidity();
    }
}
