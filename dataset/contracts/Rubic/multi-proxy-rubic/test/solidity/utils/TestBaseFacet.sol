// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import { TestBase, RubicMultiProxy, DSTest, LibSwap, IRubic, LibAllowList, console, InvalidAmount, ERC20, UniswapV2Router02 } from "./TestBase.sol";
import { NoSwapDataProvided, InformationMismatch, NativeAssetTransferFailed, ReentrancyError, InsufficientBalance, CannotBridgeToSameNetwork, NativeValueWithERC, InvalidReceiver, InvalidAmount, InvalidConfig, InvalidSendingToken, AlreadyInitialized, NotInitialized } from "src/Errors/GenericErrors.sol";
import { IFeesFacet } from "rubic/Interfaces/IFeesFacet.sol";
import { stdJson } from "forge-std/Script.sol";

contract ReentrancyChecker is DSTest {
    address private _facetAddress;
    bytes private _callData;

    constructor(address facetAddress) {
        _facetAddress = facetAddress;
        ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).approve(
            _facetAddress,
            type(uint256).max
        ); // approve USDC max to facet
        ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F).approve(
            _facetAddress,
            type(uint256).max
        ); // approve DAI max to facet
    }

    // must be called with abi.encodePacked(selector, someParam)
    // selector = function selector of the to-be-checked function
    // someParam = valid arguments for the function call
    function callFacet(bytes calldata callData) public {
        _callData = callData;
        (bool success, bytes memory data) = _facetAddress.call{
            value: 10 ether
        }(callData);
        if (!success) {
            if (
                keccak256(data) ==
                keccak256(abi.encodePacked(NativeAssetTransferFailed.selector))
            ) {
                revert ReentrancyError();
            } else {
                revert("Reentrancy Attack Test: initial call failed");
            }
        }
    }

    receive() external payable {
        (bool success, bytes memory data) = _facetAddress.call{
            value: 10 ether
        }(_callData);
        if (!success) {
            if (
                keccak256(data) ==
                keccak256(abi.encodePacked(ReentrancyError.selector))
            ) {
                revert ReentrancyError();
            } else {
                revert("Reentrancy Attack Test: reentrant call failed");
            }
        }
    }
}

// contains default test cases that can and should be used by
abstract contract TestBaseFacet is TestBase {
    using stdJson for string;

    //#region defaultTests (will be executed for every contract that inherits this contract)
    //@dev in case you want to exclude any of these test cases, you must override test case in child contract with empty body:
    //@dev e.g. "function testBaseCanBridgeTokens() public override {}"

    function testBase_CanBridgeTokens_fuzzed(uint256 amount) public virtual {
        vm.startPrank(USER_SENDER);

        vm.assume(amount > 0 && amount < 100_000);
        amount = amount * 10 ** usdc.decimals();

        // logFilePath = "./test/logs/"; // works but is not really a proper file
        // logFilePath = "./test/logs/fuzz_test.txt"; // throws error "failed to write to "....../test/logs/fuzz_test.txt": No such file or directory"
        logFilePath = string.concat(
            logFilePath,
            "fuzz_test_",
            facetName,
            ".txt"
        );

        vm.writeLine(logFilePath, vm.toString(amount));
        // approval
        usdc.approve(erc20proxy, amount);

        bridgeData.sendingAssetId = ADDRESS_USDC;
        bridgeData.minAmount = amount;

        //prepare check for events
        vm.expectEmit(true, true, true, true, _facetTestContractAddress);
        emit RubicTransferStarted(bridgeData);

        initiateBridgeTxWithFacet(false);
        vm.stopPrank();
    }

    function testBase_CanBridgeTokens()
        public
        virtual
        assertBalanceChange(
            ADDRESS_USDC,
            USER_SENDER,
            -int256(defaultUSDCAmount)
        )
        assertBalanceChange(ADDRESS_USDC, USER_RECEIVER, 0)
        assertBalanceChange(ADDRESS_DAI, USER_SENDER, 0)
        assertBalanceChange(ADDRESS_DAI, USER_RECEIVER, 0)
    {
        vm.startPrank(USER_SENDER);

        // approval
        usdc.approve(erc20proxy, bridgeData.minAmount);

        //prepare check for events
        vm.expectEmit(true, true, true, true, _facetTestContractAddress);

        emit RubicTransferStarted(bridgeData);

        initiateBridgeTxWithFacet(false);
        vm.stopPrank();
    }

    function testBase_CanBridgeTokensWithFees()
        public
        virtual
        setIntegratorFee(defaultUSDCAmount)
        assertBalanceChange(
            ADDRESS_USDC,
            USER_SENDER,
            -int256(defaultUSDCAmount)
        )
        assertBalanceChange(ADDRESS_USDC, USER_RECEIVER, 0)
        assertBalanceChange(ADDRESS_DAI, USER_SENDER, 0)
        assertBalanceChange(ADDRESS_DAI, USER_RECEIVER, 0)
        assertBalanceChange(
            ADDRESS_USDC,
            FEE_TREASURY,
            int256(rubicFeeTokenAmount)
        )
        assertBalanceChange(
            ADDRESS_USDC,
            INTEGRATOR,
            int256(integratorFeeTokenAmount)
        )
    {
        vm.startPrank(USER_SENDER);
        // approval
        usdc.approve(erc20proxy, bridgeData.minAmount);

        bridgeData.integrator = INTEGRATOR;
        //prepare check for events
        vm.expectEmit(true, true, true, true, _facetTestContractAddress);
        emit RubicTransferStarted(
            IRubic.BridgeData(
                bridgeData.transactionId,
                bridgeData.bridge,
                bridgeData.integrator,
                bridgeData.referrer,
                bridgeData.sendingAssetId,
                bridgeData.receivingAssetId,
                bridgeData.receiver,
                bridgeData.minAmount - feeTokenAmount,
                bridgeData.destinationChainId,
                bridgeData.hasSourceSwaps,
                bridgeData.hasDestinationCall
            )
        );

        initiateBridgeTxWithFacet(false);
        vm.stopPrank();
    }

    function testBase_CanBridgeNativeTokens()
        public
        virtual
        assertBalanceChange(
            address(0),
            USER_SENDER,
            -int256((1 ether + addToMessageValue))
        )
        assertBalanceChange(address(0), USER_RECEIVER, 0)
        assertBalanceChange(ADDRESS_USDC, USER_SENDER, 0)
        assertBalanceChange(ADDRESS_DAI, USER_SENDER, 0)
    {
        vm.startPrank(USER_SENDER);
        // customize bridgeData
        bridgeData.sendingAssetId = address(0);
        bridgeData.minAmount = 1 ether;

        //prepare check for events
        vm.expectEmit(true, true, true, true, _facetTestContractAddress);
        emit RubicTransferStarted(bridgeData);

        initiateBridgeTxWithFacet(true);
        vm.stopPrank();
    }

    function testBase_CanBridgeNativeTokensWithFees()
        public
        virtual
        setFixedNativeFee
        assertBalanceChange(
            address(0),
            USER_SENDER,
            -int256((1 ether + addToMessageValue))
        )
        assertBalanceChange(address(0), USER_RECEIVER, 0)
        assertBalanceChange(ADDRESS_USDC, USER_SENDER, 0)
        assertBalanceChange(ADDRESS_DAI, USER_SENDER, 0)
        assertBalanceChange(
            address(0),
            FEE_TREASURY,
            int(IFeesFacet(_facetTestContractAddress).fixedNativeFee())
        )
    {
        vm.startPrank(USER_SENDER);
        // customize bridgeData
        bridgeData.sendingAssetId = address(0);
        bridgeData.minAmount = 1 ether;

        //prepare check for events
        vm.expectEmit(true, true, true, true, _facetTestContractAddress);
        emit RubicTransferStarted(bridgeData);

        initiateBridgeTxWithFacet(true);
        vm.stopPrank();
    }

    function testBase_CanSwapAndBridgeTokens()
        public
        virtual
        assertBalanceChange(
            ADDRESS_DAI,
            USER_SENDER,
            -int256(swapData[0].fromAmount)
        )
        assertBalanceChange(ADDRESS_DAI, USER_RECEIVER, 0)
        assertBalanceChange(ADDRESS_USDC, USER_SENDER, 0)
        assertBalanceChange(ADDRESS_USDC, USER_RECEIVER, 0)
    {
        vm.startPrank(USER_SENDER);

        // prepare bridgeData
        bridgeData.hasSourceSwaps = true;

        // reset swap data
        setDefaultSwapDataSingleDAItoUSDC();

        //prepare check for events
        vm.expectEmit(true, true, true, true, _facetTestContractAddress);
        emit AssetSwapped(
            bridgeData.transactionId,
            ADDRESS_UNISWAP,
            ADDRESS_DAI,
            ADDRESS_USDC,
            swapData[0].fromAmount,
            bridgeData.minAmount,
            block.timestamp
        );
        vm.expectEmit(true, true, true, true, _facetTestContractAddress);
        emit RubicTransferStarted(bridgeData);

        // approval
        dai.approve(erc20proxy, swapData[0].fromAmount);

        // execute call in child contract
        initiateSwapAndBridgeTxWithFacet(false);
    }

    function testBase_CanSwapAndBridgeTokensWithFees()
        public
        virtual
        setIntegratorFee(swapData[0].fromAmount)
        assertBalanceChange(
            ADDRESS_DAI,
            USER_SENDER,
            -int256(swapData[0].fromAmount)
        )
        assertBalanceChange(ADDRESS_DAI, USER_RECEIVER, 0)
        assertBalanceChange(ADDRESS_USDC, USER_SENDER, 0)
        assertBalanceChange(ADDRESS_USDC, USER_RECEIVER, 0)
        assertBalanceChange(
            ADDRESS_DAI,
            FEE_TREASURY,
            int256(rubicFeeTokenAmount)
        )
        assertBalanceChange(
            ADDRESS_DAI,
            INTEGRATOR,
            int256(integratorFeeTokenAmount)
        )
    {
        vm.startPrank(USER_SENDER);

        // prepare bridgeData
        bridgeData.hasSourceSwaps = true;
        bridgeData.integrator = INTEGRATOR;

        // reset swap data
        setDefaultSwapDataSingleDAItoUSDC();

        //prepare check for events
        vm.expectEmit(true, true, true, true, _facetTestContractAddress);
        emit AssetSwapped(
            bridgeData.transactionId,
            ADDRESS_UNISWAP,
            ADDRESS_DAI,
            ADDRESS_USDC,
            swapData[0].fromAmount - feeTokenAmount,
            bridgeData.minAmount,
            block.timestamp
        );

        vm.expectEmit(true, true, true, true, _facetTestContractAddress);
        emit RubicTransferStarted(bridgeData);

        // approval
        dai.approve(erc20proxy, swapData[0].fromAmount);

        // execute call in child contract
        initiateSwapAndBridgeTxWithFacet(false);
    }

    function testBase_CanSwapAndBridgeNativeTokens()
        public
        virtual
        assertBalanceChange(ADDRESS_DAI, USER_RECEIVER, 0)
        assertBalanceChange(ADDRESS_USDC, USER_RECEIVER, 0)
    {
        vm.startPrank(USER_SENDER);
        // store initial balances
        uint256 initialUSDCBalance = usdc.balanceOf(USER_SENDER);

        // prepare bridgeData
        bridgeData.hasSourceSwaps = true;
        bridgeData.sendingAssetId = address(0);

        // prepare swap data
        address[] memory path = new address[](2);
        path[0] = ADDRESS_USDC;
        path[1] = ADDRESS_WETH;

        uint256 amountOut = 1 ether;

        // Calculate DAI amount
        uint256[] memory amounts = uniswap.getAmountsIn(amountOut, path);
        uint256 amountIn = amounts[0];

        bridgeData.minAmount = amountOut;

        delete swapData;
        swapData.push(
            LibSwap.SwapData({
                callTo: address(uniswap),
                approveTo: address(uniswap),
                sendingAssetId: ADDRESS_USDC,
                receivingAssetId: address(0),
                fromAmount: amountIn,
                callData: abi.encodeWithSelector(
                    uniswap.swapTokensForExactETH.selector,
                    amountOut,
                    amountIn,
                    path,
                    _facetTestContractAddress,
                    block.timestamp + 20 minutes
                ),
                requiresDeposit: true
            })
        );

        //prepare check for events
        vm.expectEmit(true, true, true, true, _facetTestContractAddress);
        emit AssetSwapped(
            bridgeData.transactionId,
            ADDRESS_UNISWAP,
            ADDRESS_USDC,
            address(0),
            swapData[0].fromAmount,
            bridgeData.minAmount,
            block.timestamp
        );

        //@dev the bridged amount will be higher than bridgeData.minAmount since the code will
        //     deposit all remaining ETH to the bridge. We cannot access that value (minAmount + remaining gas)
        //     therefore the test is designed to only check if an event was emitted but not match the parameters
        vm.expectEmit(false, false, false, false, _facetTestContractAddress);
        emit RubicTransferStarted(bridgeData);

        // approval
        usdc.approve(erc20proxy, amountIn);

        // execute call in child contract
        initiateSwapAndBridgeTxWithFacet(false);

        // check balances after call
        assertEq(
            usdc.balanceOf(USER_SENDER),
            initialUSDCBalance - swapData[0].fromAmount
        );
    }

    function testBase_Revert_BridgeWithInvalidDestinationCallFlag()
        public
        virtual
    {
        vm.startPrank(USER_SENDER);
        // prepare bridgeData
        bridgeData.hasDestinationCall = true;

        vm.expectRevert(InformationMismatch.selector);

        initiateBridgeTxWithFacet(false);
        vm.stopPrank();
    }

    function testBase_Revert_BridgeWithInvalidReceiverAddress()
        public
        virtual
    {
        vm.startPrank(USER_SENDER);
        // prepare bridgeData
        bridgeData.receiver = address(0);

        vm.expectRevert(InvalidReceiver.selector);

        initiateBridgeTxWithFacet(false);
        vm.stopPrank();
    }

    function testBase_Revert_BridgeAndSwapWithInvalidReceiverAddress()
        public
        virtual
    {
        vm.startPrank(USER_SENDER);
        // prepare bridgeData
        bridgeData.receiver = address(0);
        bridgeData.hasSourceSwaps = true;

        setDefaultSwapDataSingleDAItoUSDC();

        vm.expectRevert(InvalidReceiver.selector);

        initiateSwapAndBridgeTxWithFacet(false);
        vm.stopPrank();
    }

    function testBase_Revert_BridgeWithInvalidAmount() public virtual {
        vm.startPrank(USER_SENDER);
        // prepare bridgeData
        bridgeData.minAmount = 0;

        vm.expectRevert(InvalidAmount.selector);

        initiateBridgeTxWithFacet(false);
        vm.stopPrank();
    }

    //    function testBase_Revert_SendingFeesInDexCall()
    //        public
    //        virtual
    //        setIntegratorFee(swapData[0].fromAmount)
    //    {
    //        vm.startPrank(USER_SENDER);
    //
    //        // prepare bridgeData
    //        bridgeData.hasSourceSwaps = true;
    //        bridgeData.integrator = INTEGRATOR;
    //
    //        // preapre swapData
    //        delete swapData;
    //        // Swap DAI -> USDC
    //        address[] memory path = new address[](2);
    //        path[0] = ADDRESS_DAI;
    //        path[1] = ADDRESS_USDC;
    //
    //        uint256 amountOut = defaultUSDCAmount;
    //
    //        // Calculate DAI amount
    //        uint256[] memory amounts = uniswap.getAmountsIn(amountOut, path);
    //        uint256 amountIn = amounts[0];
    //
    //        swapData.push(
    //            LibSwap.SwapData({
    //                callTo: address(uniswap),
    //                approveTo: address(uniswap),
    //                sendingAssetId: ADDRESS_DAI,
    //                receivingAssetId: ADDRESS_USDC,
    //                fromAmount: amountIn,
    //                callData: abi.encodeWithSelector(
    //                    uniswap.swapExactTokensForTokens.selector,
    //                    amountIn,
    //                    amountOut,
    //                    path,
    //                    _facetTestContractAddress,
    //                    block.timestamp + 20 minutes
    //                ),
    //                requiresDeposit: true
    //            })
    //        );
    //
    //        // approval
    //        dai.approve(_facetTestContractAddress, swapData[0].fromAmount);
    //
    //        // prepare revert
    //        vm.expectRevert(FeesGone.selector);
    //
    //        // execute call in child contract
    //        initiateSwapAndBridgeTxWithFacet(false);
    //    }

    function testBase_Revert_SwapAndBridgeWithInvalidAmount() public virtual {
        vm.startPrank(USER_SENDER);
        // prepare bridgeData
        bridgeData.hasSourceSwaps = true;
        bridgeData.minAmount = 0;

        setDefaultSwapDataSingleDAItoUSDC();

        vm.expectRevert(InvalidAmount.selector);

        initiateSwapAndBridgeTxWithFacet(false);
        vm.stopPrank();
    }

    function testBase_Revert_BridgeToSameChainId() public virtual {
        vm.startPrank(USER_SENDER);
        // prepare bridgeData
        bridgeData.destinationChainId = 1;

        usdc.approve(erc20proxy, bridgeData.minAmount);

        vm.expectRevert(CannotBridgeToSameNetwork.selector);

        initiateBridgeTxWithFacet(false);
        vm.stopPrank();
    }

    function testBase_Revert_SwapAndBridgeToSameChainId() public virtual {
        vm.startPrank(USER_SENDER);
        // prepare bridgeData
        bridgeData.destinationChainId = 1;
        bridgeData.hasSourceSwaps = true;

        setDefaultSwapDataSingleDAItoUSDC();
        dai.approve(erc20proxy, swapData[0].fromAmount);

        vm.expectRevert(CannotBridgeToSameNetwork.selector);

        initiateSwapAndBridgeTxWithFacet(false);
        vm.stopPrank();
    }

    function testBase_Revert_SwapAndBridgeWithInvalidSwapData()
        public
        virtual
    {
        vm.startPrank(USER_SENDER);

        // prepare bridgeData
        bridgeData.hasSourceSwaps = true;

        // reset swap data
        delete swapData;

        vm.expectRevert(NoSwapDataProvided.selector);

        // execute call in child contract
        initiateSwapAndBridgeTxWithFacet(false);
    }

    function testBase_Revert_CallBridgeOnlyFunctionWithSourceSwapFlag()
        public
        virtual
    {
        vm.startPrank(USER_SENDER);

        // prepare bridgeData
        bridgeData.hasSourceSwaps = true;

        vm.expectRevert(InformationMismatch.selector);

        // execute call in child contract
        initiateBridgeTxWithFacet(false);
    }

    function testBase_Revert_CallerHasInsufficientFunds() public virtual {
        vm.startPrank(USER_SENDER);

        usdc.approve(erc20proxy, defaultUSDCAmount);

        usdc.transfer(USER_RECEIVER, usdc.balanceOf(USER_SENDER));

        vm.expectRevert(
            abi.encodeWithSelector(
                InsufficientBalance.selector,
                bridgeData.minAmount,
                0
            )
        );
        initiateBridgeTxWithFacet(false);
        vm.stopPrank();
    }

    //#endregion

    //#region optionalTests (must be called explicitly from inheriting contract)

    // checks if function is protected by nonReentrant modifier
    //! only works if function is also protected with "refundExcessiveGas" modifier
    function failReentrantCall(bytes memory callData) internal virtual {
        // deploy and call attacker contract
        ReentrancyChecker attacker = new ReentrancyChecker(
            _facetTestContractAddress
        );
        dai.transfer(address(attacker), dai.balanceOf(USER_SENDER));
        vm.deal(address(attacker), 10000 ether);
        vm.expectRevert(ReentrancyError.selector);
        attacker.callFacet(callData);
    }

    //#endregion

    //#region abstract functions

    // this function must be implemented by the facet test contract
    // it will contain the logic to:
    // a) prepare the facet-specific data
    // b) call the correct function selectors (as they differ for each facet)
    function initiateBridgeTxWithFacet(bool isNative) internal virtual;

    function initiateSwapAndBridgeTxWithFacet(bool isNative) internal virtual;

    //#endregion
}
