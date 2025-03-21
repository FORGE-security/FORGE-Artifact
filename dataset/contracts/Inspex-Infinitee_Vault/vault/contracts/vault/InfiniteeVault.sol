// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interface/Vault.sol";
import "../interface/FeeManager.sol";
import "../interface/YieldWorker.sol";
import "hardhat/console.sol";

contract InfiniteeVault is ERC20, Vault, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Info about reward, amount of user.
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 withdrawableBlock;
    }

    // The yield worker currently in use by the vault.
    YieldWorker public worker;
    // Fee Manager for calculate vault fee.
    FeeManager public feeManager;
    // Reward amount per share.
    uint256 public rewardPerShare;
    // Delay block for withdraw after deposit into vault.
    uint256 public delayWithdrawalBlock;
    // Info of each user that using vaults.
    mapping(address => UserInfo) public userInfos;
    // Operator address.
    address public operator;

    modifier onlyOperator {
        require(msg.sender == operator, "permission: not operator!");
        _;
    }

    event Deposit(address user, uint256 amount);
    event Withdraw(address user, uint256 amount);
    event OperatorWork(uint256 rewardPerShare);
    event WorkerChanged(address newWorker);
    event FeeManagerChanged(address newFeeManager);

    constructor(
        YieldWorker _worker,
        FeeManager _feeManager,
        string memory _name,
        string memory _symbol
    ) public ERC20(_name, _symbol) {
        worker = _worker;
        feeManager = _feeManager;
        operator = msg.sender;
    }

    // View

    function farmToken() public view override returns (address) {
        return worker.farmToken();
    }

    function rewardToken() public view override returns (address) {
        return worker.userRewardToken();
    }

    function pendingReward() public view override returns (uint256) {
        return worker.pendingReward();
    }

    function totalRewardPerShare() public view override returns (uint256) {
        uint256 _rewardPerShare = rewardPerShare;
        uint256 _pendingReward = pendingReward();
        uint256 _totalSupply = totalSupply();

        if (_pendingReward != 0 && _totalSupply != 0) {
            uint256 _pendingRewardPerShare =
                _pendingReward.mul(1e12).div(_totalSupply);
            _rewardPerShare = _rewardPerShare.add(_pendingRewardPerShare);
        }

        return _rewardPerShare;
    }

    function userPendingReward(address _user)
        public
        view
        override
        returns (uint256)
    {
        UserInfo memory user = userInfos[_user];
        uint256 pending =
            user.amount.mul(totalRewardPerShare()).div(1e12).sub(
                user.rewardDebt
            );
        return pending;
    }

    // Mutation

    function deposit(uint256 _amount) public override nonReentrant {
        UserInfo storage user = userInfos[msg.sender];

        worker.work();
        claimRewardAndPayFee();

        if (_amount > 0) {
            IERC20(farmToken()).safeTransferFrom(
                msg.sender,
                address(worker),
                _amount
            );
            worker.deposit();
            user.amount = user.amount.add(_amount);
            user.withdrawableBlock = block.number.add(delayWithdrawalBlock);
        }

        user.rewardDebt = user.amount.mul(totalRewardPerShare()).div(1e12);

        _mint(msg.sender, _amount);

        emit Deposit(msg.sender, _amount);
    }

    function withdrawAll() public override {
        UserInfo storage user = userInfos[msg.sender];
        withdraw(user.amount);
    }

    function withdraw(uint256 _amount) public override nonReentrant {
        UserInfo storage user = userInfos[msg.sender];
        require(user.amount >= _amount, "withdraw: not enough fund!");
        require(block.number >= user.withdrawableBlock, "withdraw: too fast after deposit!");

        worker.work();
        claimRewardAndPayFee();

        if (_amount > 0) {
            uint256 balance = balanceOf(msg.sender);
            require(balance >= _amount, "withdraw: not enough token!");

            _burn(msg.sender, _amount);
            user.amount = user.amount.sub(_amount);
        }

        user.rewardDebt = user.amount.mul(totalRewardPerShare()).div(1e12);

        worker.withdraw(_amount);
        IERC20(farmToken()).safeTransfer(msg.sender, _amount);

        emit Withdraw(msg.sender, _amount);
    }

    function work() public override onlyOperator {
        worker.work();
        emit OperatorWork(rewardPerShare);
    }

    function updateVault() public override {
        require(msg.sender == address(worker), "vault: only worker!");
        rewardPerShare = totalRewardPerShare();
    }

    function emergencyWithdrawWorker() external onlyOwner {
        worker.emergencyWithdraw();
    }

    function userEmergencyWithdraw() external {
        uint256 amount = userInfos[msg.sender].amount;
        if (amount > 0) {
            IERC20(farmToken()).safeTransfer(msg.sender, amount);
        }
    }

    function setWorker(YieldWorker _worker) public onlyOwner {
        worker = _worker;
        emit WorkerChanged(address(_worker));
    }

    function setFeeManager(FeeManager _feeManager) public onlyOwner {
        feeManager = _feeManager;
        emit FeeManagerChanged(address(_feeManager));
    }

    function setDelayWithdrawalBlock(uint256 _delay) external onlyOwner {
        delayWithdrawalBlock = _delay;
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }


    // Private

    function claimRewardAndPayFee() private {
        uint256 _pendingReward = userPendingReward(msg.sender);

        if (_pendingReward > 0) {
            worker.claimReward(_pendingReward);

            UserInfo memory user = userInfos[msg.sender];
            uint256 _feeRateBPS =
                feeManager.feeRateBPS(msg.sender, user.amount, user.rewardDebt);

            if (_feeRateBPS > 0) {
                uint256 _fee = _pendingReward.mul(_feeRateBPS).div(10000);
                IERC20(rewardToken()).safeTransfer(
                    feeManager.feeAddress(),
                    _fee
                );
                IERC20(rewardToken()).safeTransfer(
                    msg.sender,
                    _pendingReward.sub(_fee)
                );
            } else {
                IERC20(rewardToken()).safeTransfer(msg.sender, _pendingReward);
            }
        }
    }
}
