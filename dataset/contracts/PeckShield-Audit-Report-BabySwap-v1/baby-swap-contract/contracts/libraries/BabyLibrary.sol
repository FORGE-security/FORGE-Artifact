// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import '../interfaces/IBabyFactory.sol';
import '../interfaces/IBabyPair.sol';
import "./SafeMath.sol";

library BabyLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'BabyLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'BabyLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        return IBabyFactory(factory).getPair(tokenA, tokenB);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        pairFor(factory, tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IBabyPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'BabyLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'BabyLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'BabyLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'BabyLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function getAmountOutWithFee(uint amountIn, uint reserveIn, uint reserveOut, uint fee) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'BabyLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'BabyLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(fee);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'BabyLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'BabyLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    function getAmountInWithFee(uint amountOut, uint reserveIn, uint reserveOut, uint fee) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'BabyLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'BabyLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(10000);
        uint denominator = reserveOut.sub(amountOut).mul(fee);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'BabyLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAggregationAmountsOut(address[] memory factories, uint[] memory fees, uint[] memory minAmounts, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts, address[] memory usedFactories) {
        require(path.length >= 2, 'BabyLibrary: INVALID_PATH');
        require(factories.length == fees.length && path.length == minAmounts.length, "BabyLibrary: INVALID_AMOUNT");
        require(factories.length >= 1, 'BabyLibrary: INVALID_FACTORY');
        usedFactories = new address[](path.length - 1);
        usedFactories[0] = factories[0];
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            uint j = 0;
            for (; j < factories.length; j ++) {
                if (factories[j] == address(0)) {
                    continue;
                }
                (uint reserveIn, uint reserveOut) = getReserves(factories[j], path[i], path[i + 1]);
                amounts[i + 1] = getAmountOutWithFee(amounts[i], reserveIn, reserveOut, fees[j]);
                usedFactories[i + 1] = factories[j];
                if (reserveIn >= minAmounts[i] && reserveOut >= minAmounts[i + 1]) {
                    break;
                }
            }
            if (j == factories.length) {
                (uint reserveIn, uint reserveOut) = getReserves(factories[0], path[i], path[i + 1]);
                amounts[i + 1] = getAmountOutWithFee(amounts[i], reserveIn, reserveOut, fees[j]);
            }
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'BabyLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    function getAggregationAmountsIn(address[] memory factories, uint[] memory fees, uint[] memory minAmounts, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts, address[] memory usedFactories) {
        require(path.length >= 2, 'BabyLibrary: INVALID_PATH');
        require(factories.length == fees.length && path.length == minAmounts.length, "BabyLibrary: INVALID_AMOUNT");
        require(factories.length >= 1, 'BabyLibrary: INVALID_FACTORY');
        usedFactories = new address[](path.length - 1);
        usedFactories[amounts.length - 1] = factories[0];
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            for (uint j = 0; j < factories.length; j ++) {
                if (factories[j] == address(0)) {
                    continue;
                }
                (uint reserveIn, uint reserveOut) = getReserves(factories[j], path[i - 1], path[i]);
                amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
                usedFactories[i - 1] = factories[j];
                if (reserveIn >= minAmounts[i - 1] && reserveOut >= minAmounts[i]) {
                    break;
                }
            }
        }
    }
}
