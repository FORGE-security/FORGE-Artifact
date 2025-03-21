// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../TestCommons.sol";
import "../utils/TestConstants.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/interfaces/types/IporTypes.sol";

contract AmmPoolsServiceProvideLiquidity is TestCommons {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    BuilderUtils.IporProtocol internal _iporProtocol;

    event ProvideLiquidity(
        address indexed from,
        address indexed beneficiary,
        address indexed to,
        uint256 exchangeRate,
        uint256 assetAmount,
        uint256 ipTokenAmount
    );

    function setUp() public {
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);

        _cfg.approvalsForUsers = _users;
        _cfg.iporOracleUpdater = _userOne;
        _cfg.iporRiskManagementOracleUpdater = _userOne;
    }

    function testShouldEmitCorrectEventWhenProvideLiquidity() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.expectEmit(true, true, true, true);
        emit ProvideLiquidity(
            _liquidityProvider,
            _userOne,
            address(_iporProtocol.ammTreasury),
            1000000000000000000,
            TestConstants.USD_14_000_18DEC,
            14000000000000000000000
        );
        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_userOne, TestConstants.USD_14_000_18DEC);
    }

    function testShouldProvideLiquidityAndTakeIpTokenWhenSimpleCase1And18Decimals() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_14_000_18DEC);
        IporTypes.AmmBalancesMemory memory balance = _iporProtocol.ammPoolsLens.getAmmBalance(
            address(_iporProtocol.asset)
        );

        // then
        assertEq(TestConstants.USD_14_000_18DEC, _iporProtocol.ipToken.balanceOf(_liquidityProvider));
        assertEq(TestConstants.USD_14_000_18DEC, _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)));
        assertEq(TestConstants.USD_14_000_18DEC, balance.liquidityPool);
        assertEq(9986000 * TestConstants.D18, _iporProtocol.asset.balanceOf(_liquidityProvider));
    }

    function testShouldProvideLiquidityAndTakeIpTokenWhenUnpauseMethod() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        address router = address(_iporProtocol.router);

        bytes4[] memory methods = new bytes4[](1);
        methods[0] = _iporProtocol.ammPoolsService.provideLiquidityDai.selector;

        address[] memory pauseGuardians = new address[](1);
        pauseGuardians[0] = _admin;
        vm.prank(_admin);
        AccessControl(router).addPauseGuardians(pauseGuardians);
        vm.prank(_admin);
        AccessControl(router).pause(methods);
        uint256 isPausedBefore = AccessControl(address(_iporProtocol.router)).paused(
            _iporProtocol.ammPoolsService.provideLiquidityDai.selector
        );

        // when
        vm.prank(_admin);
        AccessControl(router).unpause(methods);
        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_14_000_18DEC);
        IporTypes.AmmBalancesMemory memory balance = _iporProtocol.ammPoolsLens.getAmmBalance(
            address(_iporProtocol.asset)
        );

        // then
        uint256 isPausedAfter = AccessControl(address(_iporProtocol.router)).paused(
            _iporProtocol.ammPoolsService.provideLiquidityDai.selector
        );
        assertEq(TestConstants.USD_14_000_18DEC, _iporProtocol.ipToken.balanceOf(_liquidityProvider));
        assertEq(TestConstants.USD_14_000_18DEC, _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)));
        assertEq(TestConstants.USD_14_000_18DEC, balance.liquidityPool);
        assertEq(9986000 * TestConstants.D18, _iporProtocol.asset.balanceOf(_liquidityProvider));
        assertTrue(isPausedBefore == 1, "Method should be paused before");
        assertTrue(isPausedAfter == 0, "Method should not be paused after");
    }

    function testShouldNotProvideLiquidityWhenMethodPaused() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        address router = address(_iporProtocol.router);
        bytes4[] memory methods = new bytes4[](1);
        methods[0] = _iporProtocol.ammPoolsService.provideLiquidityDai.selector;
        address[] memory pauseGuardians = new address[](1);
        pauseGuardians[0] = _admin;
        vm.prank(_admin);
        AccessControl(router).addPauseGuardians(pauseGuardians);
        vm.prank(_admin);
        AccessControl(router).pause(methods);
        uint256 isPausedBefore = AccessControl(address(_iporProtocol.router)).paused(
            _iporProtocol.ammPoolsService.provideLiquidityDai.selector
        );

        // when
        vm.prank(_liquidityProvider);
        vm.expectRevert(bytes(IporErrors.METHOD_PAUSED));
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_14_000_18DEC);

        // then
        assertTrue(isPausedBefore == 1, "Method should not be paused");
    }

    function testShouldProvideLiquidityAndTakeIpTokenWhemSimpleCase1And6Decimals() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        // when
        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_14_000_6DEC);
        IporTypes.AmmBalancesMemory memory balance = _iporProtocol.ammPoolsLens.getAmmBalance(
            address(_iporProtocol.asset)
        );

        // then
        assertEq(TestConstants.USD_14_000_18DEC, _iporProtocol.ipToken.balanceOf(_liquidityProvider));
        assertEq(TestConstants.USD_14_000_6DEC, _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)));
        assertEq(TestConstants.USD_14_000_18DEC, balance.liquidityPool);
        assertEq(9986000000000, _iporProtocol.asset.balanceOf(_liquidityProvider));
    }

    function testShouldNotProvideLiquidityWhenLiquidityPoolIsEmpty() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_10_000_18DEC);

        //simulation that Liquidity Pool Balance equal 0, but ipToken is not burned
        vm.prank(address(_iporProtocol.router));
        _iporProtocol.ammStorage.subtractLiquidityInternal(TestConstants.USD_10_000_18DEC);

        // when
        vm.prank(_liquidityProvider);
        vm.expectRevert("IPOR_300");
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_10_000_18DEC);
    }

    function testShouldNotProvideLiquidityWhenMaxLiquidityPoolBalanceExceeded() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.ammGovernanceService.setAmmPoolsParams(address(_iporProtocol.asset), 20000, 50, 8500);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_15_000_18DEC);

        // when other user provides liquidity
        vm.prank(_userOne);
        vm.expectRevert("IPOR_304");
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_15_000_18DEC);
    }
}
