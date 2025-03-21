pragma solidity ^0.4.24;

import "./interfaces/IBlockReward.sol";
import "./interfaces/IKeysManager.sol";
import "./interfaces/IProxyStorage.sol";
import "./interfaces/IPoaNetworkConsensus.sol";
import "./libs/SafeMath.sol";


contract BlockReward is IBlockReward {
    using SafeMath for uint256;

    uint256 public blockRewardAmount;
    uint256 public emissionFundsAmount;

    // solhint-disable var-name-mixedcase
    address internal SYSTEM_ADDRESS = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;
    // solhint-enable var-name-mixedcase
    
    address public emissionFunds;
    IProxyStorage public proxyStorage;

    uint256 public hbbftLastTime;
    uint256 public hbbftKeyIndex;
    uint256 public hbbftTimeThreshold;
    address[] public hbbftPayoutKeys;

    event Rewarded(address[] receivers, uint256[] rewards, bool indexed isHBBFT);

    modifier onlySystem {
        require(msg.sender == SYSTEM_ADDRESS);
        _;
    }

    constructor(
        address _proxyStorage,
        address _emissionFunds,
        uint256 _blockRewardAmount,
        uint256 _emissionFundsAmount,
        uint256 _hbbftTimeThreshold
    ) public {
        require(_proxyStorage != address(0));
        require(_blockRewardAmount != 0);
        require(_hbbftTimeThreshold != 0);
        proxyStorage = IProxyStorage(_proxyStorage);
        emissionFunds = _emissionFunds;
        blockRewardAmount = _blockRewardAmount;
        emissionFundsAmount = _emissionFundsAmount;
        hbbftTimeThreshold = _hbbftTimeThreshold;
    }

    function getHBBFTPayoutKeys() public view returns(address[]) {
        return hbbftPayoutKeys;
    }

    function getTime() public view returns(uint256) {
        return now;
    }

    function reward(address[] benefactors, uint16[] kind)
        external
        onlySystem
        returns (address[], uint256[])
    {
        require(benefactors.length == kind.length);
        require(benefactors.length == 1);
        require(kind[0] == 0);

        address miningKey = benefactors[0];
        
        require(_isMiningActive(miningKey));

        address payoutKey = _getPayoutByMining(miningKey);

        address[] memory receivers = new address[](2);
        uint256[] memory rewards = new uint256[](2);

        receivers[0] = (payoutKey != address(0)) ? payoutKey : miningKey;
        rewards[0] = blockRewardAmount;
        receivers[1] = emissionFunds;
        rewards[1] = emissionFundsAmount;

        emit Rewarded(receivers, rewards, false);
    
        return (receivers, rewards);
    }

    function rewardHBBFT()
        external
        onlySystem
        returns (address[], uint256[])
    {
        uint256 currentTime = getTime();
        address[] memory receivers;
        uint256[] memory rewards;
        uint256 keysNumberToReward;
        uint256 n;
        
        if (hbbftPayoutKeys.length == 0) { // the first call
            hbbftLastTime = currentTime.sub(hbbftTimeThreshold);
            _hbbftRefreshPayoutKeys();
        }

        keysNumberToReward = currentTime.sub(hbbftLastTime).div(hbbftTimeThreshold);

        if (keysNumberToReward == 0 || hbbftPayoutKeys.length == 0) {
            receivers = new address[](0);
            rewards = new uint256[](0);
            return (receivers, rewards);
        }

        receivers = new address[](keysNumberToReward.add(1));
        rewards = new uint256[](receivers.length);

        for (n = 0; n < keysNumberToReward; n++) {
            receivers[n] = hbbftPayoutKeys[hbbftKeyIndex];
            rewards[n] = blockRewardAmount;
            hbbftLastTime += hbbftTimeThreshold;
            hbbftKeyIndex++;

            if (hbbftKeyIndex >= hbbftPayoutKeys.length) {
                _hbbftRefreshPayoutKeys();
            }
        }

        receivers[n] = emissionFunds;
        rewards[n] = emissionFundsAmount.mul(keysNumberToReward);

        emit Rewarded(receivers, rewards, true);

        return (receivers, rewards);
    }

    function _getPayoutByMining(address _miningKey)
        private
        view
        returns (address)
    {
        IKeysManager keysManager = IKeysManager(proxyStorage.getKeysManager());
        return keysManager.getPayoutByMining(_miningKey);
    }

    function _hbbftRefreshPayoutKeys() private {
        IPoaNetworkConsensus poa = IPoaNetworkConsensus(proxyStorage.getPoaConsensus());
        address[] memory validators = poa.getValidators();

        delete hbbftPayoutKeys;
        for (uint256 i = 0; i < validators.length; i++) {
            address miningKey = validators[i];
            address payoutKey = _getPayoutByMining(miningKey);
            hbbftPayoutKeys.push((payoutKey != address(0)) ? payoutKey : miningKey);
        }

        hbbftKeyIndex = 0;
    }

    function _isMiningActive(address _miningKey)
        private
        view
        returns (bool)
    {
        IKeysManager keysManager = IKeysManager(proxyStorage.getKeysManager());
        return keysManager.isMiningActive(_miningKey);
    }
}
