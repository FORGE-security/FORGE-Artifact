// SPDX-License-Identifier: MIT

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is disstributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.13;
pragma experimental ABIEncoderV2;

// Finds new Curves! logs their addresses and provides `isCurve(address) -> (bool)`

import "../lib/openzeppelin-contracts/contracts/utils/Address.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import "./Curve.sol";
import "./interfaces/IFreeFromUpTo.sol";
import "./AssimilatorFactory.sol";
import "./assimilators/AssimilatorV2.sol";
import "./interfaces/ICurveFactory.sol";
import "./interfaces/IAssimilatorFactory.sol";
import "./Structs.sol";

contract CurveFactoryV2 is ICurveFactory, Ownable {
    using Address for address;

    IAssimilatorFactory public immutable assimilatorFactory;

    // add protocol fee
    int128 public totoalFeePercentage = 100000;
    int128 public protocolFee;
    address public protocolTreasury;

    // Global curve operational state
    bool public globalFrozen = false;
    bool public flashable = false;

    bool public globalGuarded = false;
    mapping (address => bool) public poolGuarded;

    uint256 public globalGuardAmt;
    mapping (address => uint256) public poolGuardAmt;
    mapping (address => uint256) public poolCapAmt;
    
    event GlobalFrozenSet(bool isFrozen);
    event FlashableSet(bool isFlashable);
    event TreasuryUpdated(address indexed newTreasury);
    event ProtocolFeeUpdated(address indexed treasury, int128 indexed fee);
    event NewCurve(address indexed caller, bytes32 indexed id, address indexed curve);
    event GlobalGuardSet(bool isGuarded);
    event GlobalGuardAmountSet (uint256 amount);
    event PoolGuardSet (address indexed pool, bool isGuarded);
    event PoolGuardAmountSet (address indexed pool, uint256 guardAmount);
    event PoolCapSet (address indexed pool, uint256 cap);

    mapping(bytes32 => address) public curves;

    constructor(
        int128 _protocolFee,
        address _treasury,
        address _assimFactory
    ) {
        require(totoalFeePercentage >= _protocolFee, "CurveFactory/fee-cant-be-over-100%");
        require(_treasury != address(0), "CurveFactory/zero-address");
        protocolFee = _protocolFee;
        protocolTreasury = _treasury;

        require(_assimFactory.isContract(), "CurveFactory/invalid-assimFactory");
        assimilatorFactory = IAssimilatorFactory(_assimFactory);
    }

    function getGlobalFrozenState() external view virtual override returns (bool) {
        return globalFrozen;
    }
    
    function getFlashableState() external view virtual override returns (bool) {
        return flashable;
    }

    function getProtocolFee() external view virtual override returns (int128) {
        return protocolFee;
    }

    function getProtocolTreasury() external view virtual override returns (address) {
        return protocolTreasury;
    }

    function setGlobalFrozen(bool _toFreezeOrNotToFreeze) external onlyOwner {
        emit GlobalFrozenSet(_toFreezeOrNotToFreeze);

        globalFrozen = _toFreezeOrNotToFreeze;
    }

    function toggleGlobalGuarded () external onlyOwner {
        globalGuarded = !globalGuarded;
        emit GlobalGuardSet(globalGuarded);
    }

    function setPoolGuarded (address pool, bool guarded ) external onlyOwner {
        poolGuarded[pool] = guarded;
        emit PoolGuardSet(pool, guarded);
    }

    function setGlobalGuardAmount (uint256 amount) external onlyOwner {
        globalGuardAmt = amount;
        emit GlobalGuardAmountSet (globalGuardAmt);
    }

    function setPoolCap (address pool, uint256 cap) external onlyOwner {
        poolCapAmt[pool] = cap;
        emit PoolCapSet(pool, cap);
    }

    function setPoolGuardAmount (address pool, uint256 amount) external onlyOwner {
        poolGuardAmt[pool] = amount;
        emit PoolGuardAmountSet(pool, amount);
    }

    function isPoolGuarded (address pool) external view override returns (bool) {
        bool _poolGuarded = poolGuarded[pool];
        if(!_poolGuarded){
            return globalGuarded;
        }else{
            return true;
        }
    }

    function getPoolGuardAmount (address pool) external view override returns (uint256) {
        uint256 _poolGuardAmt = poolGuardAmt[pool];
        if(_poolGuardAmt == 0) {
            return globalGuardAmt;
        }else{
            return _poolGuardAmt;
        }
    }

    function getPoolCap (address pool) external view override returns (uint256) {
        return poolCapAmt[pool];
    }
    
    function setFlashable(bool _toFlashOrNotToFlash) external onlyOwner {
        emit FlashableSet(_toFlashOrNotToFlash);

        flashable = _toFlashOrNotToFlash;
    }

    function updateProtocolTreasury(address _newTreasury) external onlyOwner {
        require(_newTreasury != protocolTreasury, "CurveFactory/same-treasury-address");
        require(_newTreasury != address(0), "CurveFactory/zero-address");
        protocolTreasury = _newTreasury;
        emit TreasuryUpdated(protocolTreasury);
    }

    function updateProtocolFee(int128 _newFee) external onlyOwner {
        require(totoalFeePercentage >= _newFee, "CurveFactory/fee-cant-be-over-100%");
        require(_newFee != protocolFee, "CurveFactory/same-protocol-fee");
        protocolFee = _newFee;
        emit ProtocolFeeUpdated(protocolTreasury, protocolFee);
    }

    function getCurve(address _baseCurrency, address _quoteCurrency) external view returns (address) {
        bytes32 curveId = keccak256(abi.encode(_baseCurrency, _quoteCurrency));
        return (curves[curveId]);
    }

    function newCurve(CurveInfo memory _info) public returns (Curve) {
        bytes32 curveId = keccak256(abi.encode(_info._baseCurrency, _info._quoteCurrency));
        if (curves[curveId] != address(0)) revert("CurveFactory/pair-exists");
        AssimilatorV2 _baseAssim;
        _baseAssim = (assimilatorFactory.getAssimilator(_info._baseCurrency));
        if (address(_baseAssim) == address(0))
            _baseAssim = (assimilatorFactory.newAssimilator(_info._baseOracle, _info._baseCurrency, _info._baseDec));
        AssimilatorV2 _quoteAssim;
        _quoteAssim = (assimilatorFactory.getAssimilator(_info._quoteCurrency));
        if (address(_quoteAssim) == address(0))
            _quoteAssim = (
                assimilatorFactory.newAssimilator(_info._quoteOracle, _info._quoteCurrency, _info._quoteDec)
            );

        address[] memory _assets = new address[](10);
        uint256[] memory _assetWeights = new uint256[](2);

        // Base Currency
        _assets[0] = _info._baseCurrency;
        _assets[1] = address(_baseAssim);
        _assets[2] = _info._baseCurrency;
        _assets[3] = address(_baseAssim);
        _assets[4] = _info._baseCurrency;

        // Quote Currency (typically USDC)
        _assets[5] = _info._quoteCurrency;
        _assets[6] = address(_quoteAssim);
        _assets[7] = _info._quoteCurrency;
        _assets[8] = address(_quoteAssim);
        _assets[9] = _info._quoteCurrency;

        // Weights
        _assetWeights[0] = _info._baseWeight;
        _assetWeights[1] = _info._quoteWeight;

        // New curve
        Curve curve = new Curve(_info._name, _info._symbol, _assets, _assetWeights, address(this));
        curve.setParams(
            _info._alpha,
            _info._beta,
            _info._feeAtHalt,
            _info._epsilon,
            _info._lambda
        );
        curve.turnOffWhitelisting();
        curve.transferOwnership(protocolTreasury);
        curves[curveId] = address(curve);

        emit NewCurve(msg.sender, curveId, address(curve));

        return curve;
    }
}
