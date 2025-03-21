// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

interface IDebtLockerLike {

    function implementation() external view returns (address implementation_);

    function pool() external view returns (address pool_);

    function poolDelegate() external view returns (address poolDelegate_);

    function setPendingLender(address newLender_) external;

    function upgrade(uint256 toVersion_, bytes calldata arguments_) external;

}

interface IERC20Like {

    function approve(address account_, uint256 amount) external returns (bool success_);

    function balanceOf(address account_) external view returns(uint256);

    function transfer(address to_, uint256 amount) external returns (bool success_);

}

interface IMapleProxiedLike {

    function factory() external view returns (address factory_);

}

interface IMapleProxyFactoryLike {

    function createInstance(bytes calldata arguments_, bytes32 salt_) external returns (address instance_);

    function defaultVersion() external view returns (uint256 defaultVersion_);

    function enableUpgradePath(uint256 fromVersion_, uint256 toVersion_, address migrator_) external;

    function implementationOf(uint256 version_) external view returns (address implementation_);

    function registerImplementation(uint256 version_, address implementationAddress_, address initializer_) external;

    function upgradeEnabledForPath(uint256 toVersion_, uint256 fromVersion_) external view returns (bool allowed_);

    function versionOf(address implementation_) external view returns (uint256 version_);

    function setDefaultVersion(uint256 version_) external;

}

interface IMapleGlobalsLike {

    function setPriceOracle(address asset, address oracle) external;

}

interface IMapleLoanLike {

    function borrower() external view returns (address borrower_);

    function claimableFunds() external view returns (uint256 claimableFunds_);

    function closeLoan(uint256 amount_) external returns (uint256 principal_, uint256 interest_);

    function drawableFunds() external view returns (uint256 drawableFunds_);

    function fundsAsset() external view returns (address fundsAsset_);

    function getClosingPaymentBreakdown() external view returns (uint256 principal_, uint256 interest_, uint256 fees_);

    function getNextPaymentBreakdown() external view returns (uint256 principal_, uint256 interest_, uint256 delegateFee_, uint256 treasuryFee_);

    function implementation() external view returns (address implementation_);

    function lender() external view returns (address lender_);

    function makePayment(uint256 amount_) external returns (uint256 principal_, uint256 interest_);

    function nextPaymentDueDate() external view returns (uint256 nextPaymentDueDate_);

    function paymentInterval() external view returns (uint256 paymentInterval_);

    function pendingLender() external view returns (address pendingLender_);

    function principal() external view returns (uint256 principal_);

    function upgrade(uint256 toVersion_, bytes calldata arguments_) external;

}

interface IPoolLike {

    function balanceOf(address account_) external returns(uint256 balance_);

    function claim(address loan, address dlFactory) external;

    function deactivate() external;

    function deposit(uint256 amt) external;

    function fundLoan(address loan, address dlFactory, uint256 amount) external;

    function intendToWithdraw() external;

    function interestSum() external view returns (uint256);

    function liquidityAsset() external view returns (address);

    function liquidityCap() external view returns (uint256);

    function liquidityLocker() external pure returns (address);

    function name() external view returns (string memory);

    function poolDelegate() external view returns (address);

    function poolLosses() external view returns (uint256);

    function poolState() external returns(uint8 state);

    function principalOut() external view returns (uint256);

    function recognizableLossesOf(address _owner) external view returns (uint256);

    function setLiquidityCap(uint256 newLiquidityCap) external;

    function symbol() external view returns (string memory);

    function withdraw(uint256 amt) external;

    function withdrawableFundsOf(address _owner) external view returns (uint256);

    function totalSupply() external view returns (uint256 totalSupply_);

}

interface IPoolManagerLike {

    function asset() external view returns (address asset_);

    function delegateManagementFeeRate() external view returns (uint256 delegateManagementFeeRate_);

    function loanManagerList(uint256 index_) external view returns (address loanManager_);

    function pool() external view returns (address pool_);

    function poolDelegate() external view returns (address poolDelegate_);

    function setOpenToPublic() external;

    function totalAssets() external view returns (uint256 totalAssets_);

}

interface ITransitionLoanManagerLike {

    function add(address loan_) external;

    function principalOut() external view returns (uint256 principalOut_);

    function takeOwnership(address[] calldata loans_) external;

    function upgrade(uint256 toVersion_, bytes calldata arguments_) external;

}
