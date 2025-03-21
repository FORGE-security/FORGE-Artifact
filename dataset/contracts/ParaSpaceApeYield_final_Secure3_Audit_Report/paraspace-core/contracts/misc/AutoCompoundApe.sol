// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {Ownable} from "../dependencies/openzeppelin/contracts/Ownable.sol";
import {SafeMath} from "../dependencies/openzeppelin/contracts/SafeMath.sol";
import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";
import {SafeERC20} from "../dependencies/openzeppelin/contracts/SafeERC20.sol";
import {ApeCoinStaking} from "../dependencies/yoga-labs/ApeCoinStaking.sol";
import {IAutoCompoundApe} from "../interfaces/IAutoCompoundApe.sol";
import {CApe} from "./CApe.sol";

contract AutoCompoundApe is Ownable, CApe, IAutoCompoundApe {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @notice Ape coin single pool POOL_ID for ApeCoinStaking
    uint256 public constant APE_COIN_POOL_ID = 0;
    /// @notice Minimal ApeCoin amount to deposit ape to ApeCoinStaking
    uint256 public constant MIN_OPERATION_AMOUNT = 100 * 1e18;

    ApeCoinStaking public immutable apeStaking;
    IERC20 public immutable apeCoin;
    uint256 public bufferBalance;

    constructor(address _apeCoin, address _apeStaking) {
        apeStaking = ApeCoinStaking(_apeStaking);
        apeCoin = IERC20(_apeCoin);
        apeCoin.safeApprove(_apeStaking, type(uint256).max);
    }

    /// @inheritdoc IAutoCompoundApe
    function deposit(address onBehalf, uint256 amount) external override {
        require(amount > 0, "zero amount");
        uint256 amountShare = getShareByPooledApe(amount);
        if (amountShare == 0) {
            amountShare = amount;
        }
        _mint(onBehalf, amountShare);

        _transferTokenIn(msg.sender, amount);
        _harvest();
        _compound();

        emit Deposit(msg.sender, onBehalf, amount, amountShare);
    }

    /// @inheritdoc IAutoCompoundApe
    function withdraw(uint256 amount) external override {
        require(amount > 0, "zero amount");

        uint256 amountShare = getShareByPooledApe(amount);
        _burn(msg.sender, amountShare);

        _harvest();
        uint256 _bufferBalance = bufferBalance;
        if (amount > _bufferBalance) {
            _withdrawFromApeCoinStaking(amount - _bufferBalance);
        }
        _transferTokenOut(msg.sender, amount);

        _compound();

        emit Redeem(msg.sender, amount, amountShare);
    }

    /// @inheritdoc IAutoCompoundApe
    function harvestAndCompound() external {
        _harvest();
        _compound();
    }

    function _getTotalPooledApeBalance()
        internal
        view
        override
        returns (uint256)
    {
        (uint256 stakedAmount, ) = apeStaking.addressPosition(address(this));
        uint256 rewardAmount = apeStaking.pendingRewards(
            APE_COIN_POOL_ID,
            address(this),
            0
        );
        return stakedAmount + rewardAmount + bufferBalance;
    }

    function _withdrawFromApeCoinStaking(uint256 amount) internal {
        uint256 balanceBefore = apeCoin.balanceOf(address(this));
        apeStaking.withdrawSelfApeCoin(amount);
        uint256 balanceAfter = apeCoin.balanceOf(address(this));
        uint256 realWithdraw = balanceAfter - balanceBefore;
        bufferBalance += realWithdraw;
    }

    function _transferTokenIn(address from, uint256 amount) internal {
        apeCoin.safeTransferFrom(from, address(this), amount);
        bufferBalance += amount;
    }

    function _transferTokenOut(address to, uint256 amount) internal {
        apeCoin.safeTransfer(to, amount);
        bufferBalance -= amount;
    }

    function _compound() internal {
        uint256 _bufferBalance = bufferBalance;
        if (_bufferBalance >= MIN_OPERATION_AMOUNT) {
            apeStaking.depositSelfApeCoin(_bufferBalance);
            bufferBalance = 0;
        }
    }

    function _harvest() internal {
        uint256 rewardAmount = apeStaking.pendingRewards(
            APE_COIN_POOL_ID,
            address(this),
            0
        );
        if (rewardAmount > 0) {
            apeStaking.claimSelfApeCoin();
            bufferBalance += rewardAmount;
        }
    }

    function rescueERC20(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
        if (token == address(apeCoin)) {
            require(
                bufferBalance <= apeCoin.balanceOf(address(this)),
                "balance below backed balance"
            );
        }
        emit RescueERC20(token, to, amount);
    }
}
