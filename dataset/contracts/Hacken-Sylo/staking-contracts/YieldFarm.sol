// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IStaking.sol";

contract YieldFarm {
    // lib
    using SafeMath for uint256;
    using SafeMath for uint128;

    // constants
    // 2.5% on incentivisation pool for each pool
    uint256 public constant TOTAL_DISTRIBUTED_AMOUNT = 10_000_000;
    // Needs to be equal community vualt if
    // Run for 50 weeks
    uint256 public constant NR_OF_EPOCHS = 50;
    uint128 public constant EPOCHS_DELAYED_FROM_STAKING_CONTRACT = 0;

    // state variables

    // addreses
    address private _lpTokenAddress;
    address private _communityVault; //TODO: need to confirm where are the token minted to for now
    // contracts
    IERC20 private _plug;
    IStaking private _staking;

    uint256[] private epochs = new uint256[](NR_OF_EPOCHS + 1);
    uint256 private _totalAmountPerEpoch;
    uint128 public lastInitializedEpoch;
    mapping(address => uint128) private lastEpochIdHarvested;
    uint256 public epochDuration; // init from staking contract
    uint256 public epochStart; // init from staking contract

    // events
    event MassHarvest(
        address indexed user,
        uint256 epochsHarvested,
        uint256 totalValue
    );
    event Harvest(
        address indexed user,
        uint128 indexed epochId,
        uint256 amount
    );

    // constructor
    constructor(
        address syloTokenAddress,
        address lpTokenAddress,
        address stakeContract,
        address communityVault
    ) public {
        _plug = IERC20(syloTokenAddress);
        _lpTokenAddress = lpTokenAddress;
        _staking = IStaking(stakeContract);
        _communityVault = communityVault;
        epochDuration = _staking.epochDuration();
        epochStart =
            _staking.epoch1Start() +
            epochDuration.mul(EPOCHS_DELAYED_FROM_STAKING_CONTRACT);
        _totalAmountPerEpoch = 
            TOTAL_DISTRIBUTED_AMOUNT
                .mul(10**18)
                .div(NR_OF_EPOCHS);
    }

    // public methods
    // public method to harvest all the unharvested epochs until current epoch - 1
    function massHarvest() external returns (uint256) {
        uint256 totalDistributedValue;
        uint256 epochId = _getEpochId().sub(1); // fails in epoch 0
        // force max number of epochs
        if (epochId > NR_OF_EPOCHS) {
            epochId = NR_OF_EPOCHS;
        }

        for (
            uint128 i = lastEpochIdHarvested[msg.sender] + 1;
            i <= epochId;
            i++
        ) {
            // i = epochId
            // compute distributed Value and do one single transfer at the end
            totalDistributedValue += _harvest(i);
        }

        emit MassHarvest(
            msg.sender,
            epochId - lastEpochIdHarvested[msg.sender],
            totalDistributedValue
        );

        if (totalDistributedValue > 0) {
            _plug.transferFrom(
                _communityVault,
                msg.sender,
                totalDistributedValue
            );
        }

        return totalDistributedValue;
    }

    function harvest(uint128 epochId) external returns (uint256) {
        // checks for requested epoch
        require(_getEpochId() > epochId, "This epoch is in the future");
        require(epochId <= NR_OF_EPOCHS, "Maximum number of epochs is 12");
        require(
            lastEpochIdHarvested[msg.sender].add(1) == epochId,
            "Harvest in order"
        );
        uint256 userReward = _harvest(epochId);
        if (userReward > 0) {
            _plug.transferFrom(_communityVault, msg.sender, userReward);
        }
        emit Harvest(msg.sender, epochId, userReward);
        return userReward;
    }

    // views
    // calls to the staking smart contract to retrieve the epoch total pool size
    function getPoolSize(uint128 epochId) external view returns (uint256) {
        return _getPoolSize(epochId);
    }

    function getCurrentEpoch() external view returns (uint256) {
        return _getEpochId();
    }

    // calls to the staking smart contract to retrieve user balance for an epoch
    function getEpochStake(address userAddress, uint128 epochId)
        external
        view
        returns (uint256)
    {
        return _getUserBalancePerEpoch(userAddress, epochId);
    }

    function userLastEpochIdHarvested() external view returns (uint256) {
        return lastEpochIdHarvested[msg.sender];
    }

    // internal methods

    function _initEpoch(uint128 epochId) internal {
        require(
            lastInitializedEpoch.add(1) == epochId,
            "Epoch can be init only in order"
        );
        lastInitializedEpoch = epochId;
        // call the staking smart contract to init the epoch
        epochs[epochId] = _getPoolSize(epochId);
    }

    function _harvest(uint128 epochId) internal returns (uint256) {
        // try to initialize an epoch. if it can't it fails
        // if it fails either user either a Plug account will init not init epochs
        if (lastInitializedEpoch < epochId) {
            _initEpoch(epochId);
        }
        // Set user state for last harvested
        lastEpochIdHarvested[msg.sender] = epochId;
        // compute and return user total reward. For optimization reasons the transfer have been moved to an upper layer (i.e. massHarvest needs to do a single transfer)

        // exit if there is no stake on the epoch
        if (epochs[epochId] == 0) {
            return 0;
        }
        return
            _totalAmountPerEpoch
                .mul(_getUserBalancePerEpoch(msg.sender, epochId))
                .div(epochs[epochId]);
    }

    // retrieve _lpTokenAddress token balance
    function _getPoolSize(uint128 epochId) internal view returns (uint256) {
        return
            _staking.getEpochPoolSize(
                _lpTokenAddress,
                _stakingEpochId(epochId)
            );
    }

    // retrieve _lpTokenAddress token balance per user per epoch
    function _getUserBalancePerEpoch(address userAddress, uint128 epochId)
        internal
        view
        returns (uint256)
    {
        return
            _staking.getEpochUserBalance(
                userAddress,
                _lpTokenAddress,
                _stakingEpochId(epochId)
            );
    }

    // compute epoch id from block.timestamp and epochStart date
    function _getEpochId() internal view returns (uint128 epochId) {
        if (block.timestamp < epochStart) {
            return 0;
        }
        epochId = uint128(
            block.timestamp.sub(epochStart).div(epochDuration).add(1)
        );
    }

    // get the staking epoch
    function _stakingEpochId(uint128 epochId) internal pure returns (uint128) {
        return epochId + EPOCHS_DELAYED_FROM_STAKING_CONTRACT;
    }
}