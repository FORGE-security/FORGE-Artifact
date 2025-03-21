// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";
import "contracts/libraries/PortfolioLib.sol";

contract TestGas is Setup {
    using NormalConfiguration for Configuration;

    using SafeCastLib for uint256;
    using AssemblyLib for uint256;
    using FixedPointMathLib for uint128;
    using FixedPointMathLib for uint256;

    address token_a;
    address token_b;
    address token_c;

    // helpers
    modifier usePools(uint256 amount) {
        _create_pools(amount);
        _;
    }

    function _getTokens() internal view returns (address, address) {
        return (token_a, token_b);
    }

    uint256 internal constant POOLS_LIMIT = 100;

    IPortfolio _subject;

    function setUp() public override {
        super.setUp();
        _subject = subject(); // We use the same subject in this contract.

        token_a =
            deployCoin("token", abi.encode("token a", "A", uint8(18))).to_addr();
        token_b =
            deployCoin("token", abi.encode("token b", "B", uint8(18))).to_addr();
        token_c =
            deployCoin("token", abi.encode("token c", "C", uint8(18))).to_addr();
    }

    function test_gas_single_allocate()
        public
        pauseGas
        usePools(1)
        useActor
        usePairTokens(10 ether)
    {
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeCall(
            IPortfolioActions.allocate,
            (
                false,
                address(this),
                ghost().poolId,
                1 ether,
                type(uint128).max,
                type(uint128).max
            )
        );
        vm.resumeGasMetering();
        _subject.multicall(data);
    }

    function test_gas_single_deallocate()
        public
        pauseGas
        usePools(1)
        useActor
        usePairTokens(10 ether)
        allocateSome(1 ether + uint128(BURNED_LIQUIDITY))
    {
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeCall(
            IPortfolioActions.deallocate, (false, ghost().poolId, 1 ether, 0, 0)
        );
        vm.resumeGasMetering();
        _subject.multicall(data);
    }

    function test_gas_single_swap()
        public
        pauseGas
        usePools(1)
        useActor
        usePairTokens(10 ether)
        allocateSome(1 ether)
    {
        bool sellAsset = true;

        Order memory maxOrder =
            subject().getMaxOrder(ghost().poolId, sellAsset, actor());
        uint128 inputAmount = maxOrder.input / 2;
        uint128 estimatedAmountOut = uint128(
            subject().getAmountOut(
                ghost().poolId, sellAsset, inputAmount, actor()
            )
        );

        bytes[] memory data = new bytes[](1);

        Order memory order = Order({
            useMax: false,
            poolId: ghost().poolId,
            input: inputAmount,
            output: estimatedAmountOut,
            sellAsset: sellAsset
        });

        data[0] = abi.encodeCall(IPortfolioActions.swap, (order));
        vm.resumeGasMetering();
        _subject.multicall(data);
    }

    function test_gas_multi_allocate_2_pairs()
        public
        pauseGas
        usePools(1)
        useActor
        usePairTokens(10_000 ether)
    {
        // Create another pair and pool.
        (address token0, address token1) = (token_b, token_c);

        _approveMint(address(token0), 100 ether);
        _approveMint(address(token1), 100 ether);

        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeCall(IPortfolioActions.createPair, (token0, token1));
        subject().multicall(data);

        uint16 hundred = uint16(100);
        Configuration memory testConfig = configureNormalStrategy().editStrategy(
            "strikePriceWad", abi.encode(10 ether)
        ).editStrategy("volatilityBasisPoints", abi.encode(1e4)).editStrategy(
            "durationSeconds", abi.encode(100 days)
        ).editStrategy("priceWad", abi.encode(10 ether));

        data[0] = abi.encodeCall(
            IPortfolioActions.createPool,
            (
                0, // magic pair id to use the nonce, which is the createPairId!
                testConfig.reserveXPerWad,
                testConfig.reserveYPerWad,
                hundred, // fee
                0, // prior fee
                address(0), // controller
                subject().DEFAULT_STRATEGY(),
                testConfig.strategyArgs
            )
        );

        subject().multicall(data);

        bytes[] memory instructions = new bytes[](2);

        for (uint256 i; i != 2; ++i) {
            uint64 poolId;
            if (i == 0) poolId = ghost().poolId;
            else poolId = AssemblyLib.encodePoolId(uint24(2), false, uint32(1));

            instructions[i] = abi.encodeCall(
                IPortfolioActions.allocate,
                (
                    false,
                    address(this),
                    poolId,
                    1 ether,
                    type(uint128).max,
                    type(uint128).max
                )
            );
        }

        vm.resumeGasMetering();
        _subject.multicall(instructions);
    }

    function test_gas_multi_allocate_2()
        public
        pauseGas
        usePools(2)
        useActor
        usePairTokens(10_000 ether)
    {
        _multi_allocate(2, false);
    }

    function test_gas_multi_allocate_5()
        public
        pauseGas
        usePools(5)
        useActor
        usePairTokens(10_000 ether)
    {
        _multi_allocate(5, false);
    }

    function test_gas_multi_allocate_10()
        public
        pauseGas
        usePools(10)
        useActor
        usePairTokens(10_000 ether)
    {
        _multi_allocate(10, false);
    }

    function test_gas_multi_allocate_25()
        public
        pauseGas
        usePools(25)
        useActor
        usePairTokens(10_000 ether)
    {
        _multi_allocate(25, false);
    }

    function test_gas_multi_allocate_50()
        public
        pauseGas
        usePools(50)
        useActor
        usePairTokens(10_000 ether)
    {
        _multi_allocate(50, false);
    }

    function test_gas_multi_allocate_100()
        public
        pauseGas
        usePools(100)
        useActor
        usePairTokens(10_000 ether)
    {
        _multi_allocate(100, false);
    }

    function test_gas_multi_deallocate_2_pool_2_pair()
        public
        pauseGas
        usePools(1)
        useActor
        usePairTokens(10_000 ether)
    {
        // Create another pair and pool.
        (address token0, address token1) = (token_b, token_c);

        _approveMint(address(token0), 100 ether);
        _approveMint(address(token1), 100 ether);

        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeCall(IPortfolioActions.createPair, (token0, token1));
        subject().multicall(data);

        uint16 hundred = uint16(100);

        Configuration memory testConfig = configureNormalStrategy().editStrategy(
            "strikePriceWad", abi.encode(10 ether)
        ).editStrategy("priceWad", abi.encode(10 ether));

        data[0] = abi.encodeCall(
            IPortfolioActions.createPool,
            (
                0, // magic pair id to use the nonce, which is the createPairId!
                testConfig.reserveXPerWad,
                testConfig.reserveYPerWad,
                hundred, // fee
                0, // prior fee
                address(0), // controller
                subject().DEFAULT_STRATEGY(),
                testConfig.strategyArgs
            )
        );

        subject().multicall(data);

        bytes[] memory instructions = new bytes[](2);

        for (uint256 i; i != 2; ++i) {
            uint64 poolId;
            if (i == 0) poolId = ghost().poolId;
            else poolId = AssemblyLib.encodePoolId(uint24(2), false, uint32(1));

            bytes[] memory go = new bytes[](1);
            go[0] = abi.encodeCall(
                IPortfolioActions.allocate,
                (
                    false,
                    address(this),
                    poolId,
                    1 ether + uint128(BURNED_LIQUIDITY),
                    type(uint128).max,
                    type(uint128).max
                )
            );
            subject().multicall(go);

            instructions[i] = abi.encodeCall(
                IPortfolioActions.deallocate, (false, poolId, 1 ether, 0, 0)
            );
        }

        vm.resumeGasMetering();
        _subject.multicall(instructions);
    }

    function test_gas_multi_deallocate_2()
        public
        pauseGas
        usePools(2)
        useActor
        usePairTokens(10_000 ether)
    {
        _multi_allocate(2, true);
        _multi_deallocate(2, false);
    }

    function test_gas_multi_deallocate_5()
        public
        pauseGas
        usePools(5)
        useActor
        usePairTokens(10_000 ether)
    {
        _multi_allocate(5, true);
        _multi_deallocate(5, false);
    }

    function test_gas_multi_deallocate_10()
        public
        pauseGas
        usePools(10)
        useActor
        usePairTokens(10_000 ether)
    {
        _multi_allocate(10, true);
        _multi_deallocate(10, false);
    }

    function test_gas_multi_deallocate_25()
        public
        pauseGas
        usePools(25)
        useActor
        usePairTokens(10_000 ether)
    {
        _multi_allocate(25, true);
        _multi_deallocate(25, false);
    }

    function test_gas_multi_deallocate_50()
        public
        pauseGas
        usePools(50)
        useActor
        usePairTokens(10_000 ether)
    {
        _multi_allocate(50, true);
        _multi_deallocate(50, false);
    }

    function test_gas_multi_deallocate_100()
        public
        pauseGas
        usePools(100)
        useActor
        usePairTokens(10_000 ether)
    {
        _multi_allocate(100, true);
        _multi_deallocate(100, false);
    }

    function test_gas_multi_create_pool_100()
        public
        pauseGas
        usePools(2)
        useActor
        usePairTokens(10_000 ether)
    {
        _multi_allocate(2, true);
        _multi_deallocate(2, false);
    }

    /*
    function test_gas_multi_swap_2_pairs()
        public
        pauseGas
        usePools(1)
        useActor
        usePairTokens(10_000 ether)

    {
        // Create another pair and pool.
        (address token0, address token1) =
            (address(subjects().tokens[1]), address(subjects().tokens[2]));

        _approveMint(address(token0), 100 ether);
        _approveMint(address(token1), 100 ether);

        subject().createPair(token0, token1);
        subject().createPool(
            0, address(0), 0, 100, 1e4, 100, 0, 10 ether, 10 ether
        );

        bytes[] memory instructions = new bytes[](2);

        for (uint256 i; i != 2; ++i) {
            uint64 poolId;
            if (i == 0) poolId = ghost().poolId;
            else poolId = AssemblyLib.encodePoolId(uint24(2), false, uint32(1));
            subject().allocate(
                false, poolId, 5 ether, type(uint128).max, type(uint128).max
            );

            {
                bool sellAsset = i % 2 == 0;
                PortfolioPool memory pool =
                    IPortfolioStruct(address(_subject)).pools(poolId);
                uint128 amountIn = RMM01Portfolio(payable(address(_subject)))
                    .computeMaxInput({
                    poolId: poolId,
                    sellAsset: sellAsset,
                    reserveIn: sellAsset
                        ? pool.virtualX.divWadDown(pool.liquidity)
                        : pool.virtualY.divWadDown(pool.liquidity),
                    liquidity: pool.liquidity
                }).scaleFromWadDown(pool.pair.decimalsQuote).safeCastTo128()
                    / 20;
                uint128 estimatedAmountOut = uint128(
                    _subject.getAmountOut(poolId, sellAsset, amountIn, actor())
                        * 95 / 100
                );

                Order memory swapOrder = Order({
                    useMax: false,
                    poolId: poolId,
                    input: amountIn,
                    output: estimatedAmountOut,
                    sellAsset: sellAsset
                });
            }

            instructions[i] =
                abi.encodeCall(IPortfolioActions.swap, (swapOrder));
        }

        vm.resumeGasMetering();
        _subject.multicall(instructions);
    }
    */

    function test_gas_multi_swap_2()
        public
        pauseGas
        usePools(2)
        useActor
        usePairTokens(10_000 ether)
    {
        _multi_allocate(2, true);
        _multi_swap(2, false);
    }

    function test_gas_multi_swap_5()
        public
        pauseGas
        usePools(5)
        useActor
        usePairTokens(10_000 ether)
    {
        _multi_allocate(5, true);
        _multi_swap(5, false);
    }

    function test_gas_multi_swap_10()
        public
        pauseGas
        usePools(10)
        useActor
        usePairTokens(10_000 ether)
    {
        _multi_allocate(10, true);
        _multi_swap(10, false);
    }

    function test_gas_multi_swap_25()
        public
        pauseGas
        usePools(25)
        useActor
        usePairTokens(10_000 ether)
    {
        _multi_allocate(25, true);
        _multi_swap(25, false);
    }

    function test_gas_multi_swap_50()
        public
        pauseGas
        usePools(50)
        useActor
        usePairTokens(10_000 ether)
    {
        _multi_allocate(50, true);
        _multi_swap(50, false);
    }

    function test_gas_multi_swap_100()
        public
        pauseGas
        usePools(100)
        useActor
        usePairTokens(10_000 ether)
    {
        _multi_allocate(100, true);
        _multi_swap(100, false);
    }

    function _create_pools(uint256 amount) internal {
        require(amount <= POOLS_LIMIT);
        address controller = address(0);
        (address a0, address q0) = _getTokens();
        bytes[] memory instructions = new bytes[](amount + 1);
        for (uint256 i; i != (amount + 1); ++i) {
            if (i == 0) {
                instructions[i] =
                    abi.encodeCall(IPortfolioActions.createPair, (a0, q0));
            } else {
                // todo: implement better config fuzzing!
                uint128 strike =
                    uint128(bound(uint256(0), 0.1 ether, 10_000 ether));
                uint128 price =
                    uint128(bound(uint256(0), strike * 2 / 3, strike * 3 / 2));
                uint32 volatility = uint32(
                    bound(uint256(0), MIN_VOLATILITY * 1000, MAX_VOLATILITY)
                );
                uint32 duration =
                    uint32(bound(uint256(0), MIN_DURATION * 100, MAX_DURATION));

                Configuration memory testConfig = configureNormalStrategy()
                    .editStrategy("strikePriceWad", abi.encode(strike)).editStrategy(
                    "volatilityBasisPoints", abi.encode(volatility)
                ).editStrategy("durationSeconds", abi.encode(duration))
                    .editStrategy("priceWad", abi.encode(price));

                testConfig.asset = address(1); // note: avoids validate failure
                testConfig.quote = address(1); // note: avoids validate failure
                testConfig.validate(NormalConfiguration.validateNormalStrategy);

                instructions[i] = abi.encodeCall(
                    IPortfolioActions.createPool,
                    (
                        0, // magic pair id to use the nonce, which is the createPairId!
                        testConfig.reserveXPerWad,
                        testConfig.reserveYPerWad,
                        uint16(100 + 100 / i), // fee
                        0, // prior fee
                        controller,
                        subject().DEFAULT_STRATEGY(),
                        testConfig.strategyArgs
                    )
                );
            }
        }

        // Super important
        uint64 poolId = AssemblyLib.encodePoolId(
            uint24(1), controller != address(0), uint32(1)
        );
        // By setting this poolId all the modifiers that rely on the tokens asset and quote
        // can use this set poolId's pair. Since we created all the pools with the same pair,
        // all the test modifiers work, even though we don't use a config modifier in the beginning of them.
        setGhostPoolId(poolId);
        assertEq(ghost().poolId, poolId, "ghost poolId not set");

        subject().multicall(instructions);
    }

    function _multi_allocate(
        uint256 amount,
        bool dontResumeGasMetering
    ) internal {
        require(amount <= POOLS_LIMIT);

        // Fund all the tokens we have, because it only makes sense to use internal balances
        // for multiple instructions.

        bytes[] memory instructions = new bytes[](amount);
        for (uint256 i; i != amount; ++i) {
            // We can do this because we create pools from one nonce, so just add the nonce to the firsty poolId.
            uint64 poolId = uint64(ghost().poolId + i);

            instructions[i] = abi.encodeCall(
                IPortfolioActions.allocate,
                (
                    false,
                    address(this),
                    poolId,
                    1 ether + uint128(BURNED_LIQUIDITY),
                    type(uint128).max,
                    type(uint128).max
                )
            );
        }

        if (!dontResumeGasMetering) vm.resumeGasMetering();
        _subject.multicall(instructions);
    }

    function _multi_deallocate(
        uint256 amount,
        bool dontResumeGasMetering
    ) internal {
        require(amount <= POOLS_LIMIT);

        bytes[] memory instructions = new bytes[](amount);
        for (uint256 i; i != amount; ++i) {
            // We can do this because we create pools from one nonce, so just add the nonce to the firsty poolId.
            uint64 poolId = uint64(ghost().poolId + i);

            instructions[i] = abi.encodeCall(
                IPortfolioActions.deallocate, (false, poolId, 1 ether, 0, 0)
            );
        }

        if (!dontResumeGasMetering) vm.resumeGasMetering();
        _subject.multicall(instructions);
    }

    function _multi_swap(uint256 amount, bool dontResumeGasMetering) internal {
        require(amount <= POOLS_LIMIT);

        // Fund all the tokens we have, because it only makes sense to use internal balances
        // for multiple instructions.
        PortfolioPool memory pool =
            IPortfolioStruct(address(_subject)).pools(ghost().poolId);

        bytes[] memory instructions = new bytes[](amount);
        for (uint256 i; i != amount; ++i) {
            uint64 poolId = uint64(ghost().poolId + i); // We can do this because we create pools from one nonce.

            bool sellAsset = i % 2 == 0;
            Order memory maxOrder =
                subject().getMaxOrder(poolId, sellAsset, actor());
            uint128 amountIn = maxOrder.input;

            // This estimated amount is accurate, however, each getAmountOut computation uses the current invariant.
            // Since all the computed output amounts use the current invariant, once these are executed there will be small
            // discrepencies in the invariant which will throw the Portfolio_InvalidInvariant error.
            // To properly get all the amounts out, the getAmountOut needs to take into account the invariant change as well.
            uint128 estimatedAmountOut = uint128(
                _subject.getAmountOut(poolId, sellAsset, amountIn, actor())
            );

            // For now, we use a slightly underestimated amount out so that we can test the multi swaps.
            estimatedAmountOut = estimatedAmountOut * 99_999 / 100_000;

            Order memory order = Order({
                useMax: false,
                poolId: poolId,
                input: amountIn,
                output: estimatedAmountOut,
                sellAsset: sellAsset
            });

            instructions[i] = abi.encodeCall(IPortfolioActions.swap, (order));
        }

        if (!dontResumeGasMetering) vm.resumeGasMetering();
        _subject.multicall(instructions);
    }

    function _createInstruction(uint24 pairId)
        internal
        view
        returns (bytes memory)
    {
        Configuration memory testConfig = configureNormalStrategy(); // default strategy
        (testConfig.asset, testConfig.quote) = (address(1), address(1)); // avoids failure
        testConfig.validate(NormalConfiguration.validateNormalStrategy);

        bytes memory payload = abi.encodeCall(
            IPortfolioActions.createPool,
            (
                pairId, // magic pair id to use the nonce, which is the createPairId!
                testConfig.reserveXPerWad,
                testConfig.reserveYPerWad,
                uint16(100), // fee
                uint16(10), // prior fee
                address(0), // controller
                subject().DEFAULT_STRATEGY(),
                testConfig.strategyArgs
            )
        );

        return payload;
    }

    function _allocateInstruction(uint64 poolId)
        internal
        view
        returns (bytes memory)
    {
        return abi.encodeCall(
            IPortfolioActions.allocate,
            (
                false,
                address(this),
                poolId,
                1 ether,
                type(uint128).max,
                type(uint128).max
            )
        );
    }

    function _swapInstruction(
        bool direction,
        uint64 poolId
    ) internal view returns (bytes memory) {
        uint128 amountIn = uint128(0.05 ether);
        uint128 amountOut = subject().getAmountOut(
            poolId, direction, amountIn, actor()
        ).safeCastTo128();

        Order memory order = Order({
            useMax: false,
            poolId: poolId,
            input: amountIn,
            output: amountOut,
            sellAsset: direction
        });

        return abi.encodeCall(IPortfolioActions.swap, (order));
    }

    function _deallocateInstruction(uint64 poolId)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeCall(
            IPortfolioActions.deallocate, (false, poolId, 1 ether, 0, 0)
        );
    }

    function _approveMint(address token, uint256 amount) internal {
        Coin.wrap(token).prepare(actor(), address(subject()), amount);
    }

    // -=- Start Gas Study -=- //

    function test_gas_chain_create_allocate_from_portfolio()
        public
        pauseGas
        useActor
    {
        // create the pair first
        (address asset, address quote) = _getTokens();

        {
            bytes[] memory actions = new bytes[](1);
            actions[0] =
                abi.encodeCall(IPortfolioActions.createPair, (asset, quote));
            subject().multicall(actions);
        }

        uint24 pairId = 1;
        uint64 poolId = AssemblyLib.encodePoolId(
            pairId, false, subject().getPoolNonce(pairId) + 1
        );

        bytes[] memory instructions = new bytes[](2);
        instructions[0] = _createInstruction(pairId);
        instructions[1] = _allocateInstruction(poolId);

        // Fund account with tokens to pay from portfolio
        _approveMint(asset, 100 ether);
        _approveMint(quote, 100 ether);

        // Run the gas
        vm.resumeGasMetering();
        _subject.multicall(instructions);
    }

    /// @dev blocked by https://github.com/primitivefinance/portfolio/issues/423
    function test_gas_chain_swap_allocate_from_portfolio()
        public
        pauseGas
        usePools(1)
        useActor
        usePairTokens(100 ether)
    {
        // Allocate to first pool
        uint64 poolId = ghost().poolId;

        {
            bytes[] memory actions = new bytes[](1);
            actions[0] = abi.encodeCall(
                IPortfolioActions.allocate,
                (
                    false,
                    address(this),
                    poolId,
                    10 ether,
                    type(uint128).max,
                    type(uint128).max
                )
            );
            subject().multicall(actions);
        }

        bytes[] memory instructions = new bytes[](2);
        instructions[0] = _swapInstruction(true, poolId);
        instructions[1] = _allocateInstruction(poolId);

        vm.resumeGasMetering();
        _subject.multicall(instructions);
    }

    function test_gas_chain_swap_deallocate_create_allocate_from_portfolio()
        public
        pauseGas
        usePools(1)
        useActor
        usePairTokens(100 ether)
    {
        // Allocate to first pool
        uint24 pairId = 1;
        uint64 poolId = ghost().poolId;

        {
            bytes[] memory actions = new bytes[](1);
            actions[0] = abi.encodeCall(
                IPortfolioActions.allocate,
                (
                    false,
                    address(this),
                    poolId,
                    25 ether,
                    type(uint128).max,
                    type(uint128).max
                )
            );
            subject().multicall(actions);
        }

        bytes[] memory instructions = new bytes[](4);
        instructions[0] = _swapInstruction(true, poolId);
        instructions[1] = _deallocateInstruction(poolId);
        instructions[2] = _createInstruction(pairId);
        instructions[3] = _allocateInstruction(poolId + 1);

        vm.resumeGasMetering();
        _subject.multicall(instructions);
    }

    function test_gas_single_allocate_from_portfolio_balance()
        public
        pauseGas
        usePools(1)
        useActor
        usePairTokens(10 ether)
    {
        bytes[] memory instructions = new bytes[](1);
        instructions[0] = _allocateInstruction(ghost().poolId);
        vm.resumeGasMetering();
        _subject.multicall(instructions);
    }

    function test_gas_single_swap_from_portfolio_balance()
        public
        pauseGas
        usePools(1)
        useActor
        usePairTokens(10 ether)
    {
        bytes[] memory instructions = new bytes[](1);
        instructions[0] = _allocateInstruction(ghost().poolId);
        _subject.multicall(instructions);

        instructions[0] = _swapInstruction(true, ghost().poolId);
        vm.resumeGasMetering();
        _subject.multicall(instructions);
    }

    function test_gas_create_pool_allocate_transfer_from_wallet()
        public
        pauseGas
    {
        // create the pair first
        (address asset, address quote) = _getTokens();
        {
            bytes[] memory actions = new bytes[](1);
            actions[0] =
                abi.encodeCall(IPortfolioActions.createPair, (asset, quote));
            subject().multicall(actions);
        }

        uint24 pairId = 1;
        uint64 poolId = AssemblyLib.encodePoolId(
            pairId, false, subject().getPoolNonce(pairId) + 1
        );

        bytes[] memory instructions = new bytes[](2);
        instructions[0] = _createInstruction(pairId);
        instructions[1] = _allocateInstruction(poolId);
        _approveMint(asset, 100 ether);
        _approveMint(quote, 100 ether);

        // Run the gas
        vm.resumeGasMetering();
        _subject.multicall(instructions);
    }

    function test_gas_chain_allocate_deallocate_from_portfolio_balance()
        public
        pauseGas
        usePools(1)
        useActor
        usePairTokens(10 ether)
        allocateSome(uint128(BURNED_LIQUIDITY))
    {
        bytes[] memory instructions = new bytes[](2);
        instructions[0] = _allocateInstruction(ghost().poolId);
        instructions[1] = _deallocateInstruction(ghost().poolId);

        vm.resumeGasMetering();
        _subject.multicall(instructions);
    }

    function test_gas_single_swap_from_wallet()
        public
        pauseGas
        usePools(1)
        useActor
        usePairTokens(10 ether)
    {
        bytes[] memory instructions = new bytes[](1);

        instructions[0] = _allocateInstruction(ghost().poolId);
        subject().multicall(instructions);

        instructions[0] = _swapInstruction(true, ghost().poolId);
        vm.resumeGasMetering();
        _subject.multicall(instructions);
    }
}
