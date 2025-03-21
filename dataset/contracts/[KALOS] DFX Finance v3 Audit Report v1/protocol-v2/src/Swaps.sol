// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma experimental ABIEncoderV2;

import "../lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./Structs.sol";
import "./Assimilators.sol";
import "./Storage.sol";
import "./CurveMath.sol";
import "./lib/UnsafeMath64x64.sol";
import "./lib/ABDKMath64x64.sol";

library Swaps {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for int256;
    using UnsafeMath64x64 for int128;
    using ABDKMath64x64 for uint256;
    using SafeMath for uint256;

    event Trade(
        address indexed trader,
        address indexed origin,
        address indexed target,
        uint256 originAmount,
        uint256 targetAmount,
        int128 rawProtocolFee
    );

    int128 public constant ONE = 0x10000000000000000;

    function getOriginAndTarget(
        Storage.Curve storage curve,
        address _o,
        address _t
    )
        private
        view
        returns (Storage.Assimilator memory, Storage.Assimilator memory)
    {
        Storage.Assimilator memory o_ = curve.assimilators[_o];
        Storage.Assimilator memory t_ = curve.assimilators[_t];

        require(o_.addr != address(0), "Curve/origin-not-supported");
        require(t_.addr != address(0), "Curve/target-not-supported");

        return (o_, t_);
    }

    function originSwap(
        Storage.Curve storage curve,
        OriginSwapData memory _swapData,
        bool toETH
    ) external returns (uint256 tAmt_) {
        (
            Storage.Assimilator memory _o,
            Storage.Assimilator memory _t
        ) = getOriginAndTarget(curve, _swapData._origin, _swapData._target);

        if (_o.ix == _t.ix)
            return
                Assimilators.outputNumeraire(
                    _t.addr,
                    _swapData._recipient,
                    Assimilators.intakeRaw(_o.addr, _swapData._originAmount),
                    toETH
                );

        SwapInfo memory _swapInfo;
        (
            int128 _amt,
            int128 _oGLiq,
            int128 _nGLiq,
            int128[] memory _oBals,
            int128[] memory _nBals
        ) = getOriginSwapData(
                curve,
                _o.ix,
                _t.ix,
                _o.addr,
                _swapData._originAmount
            );

        _swapInfo.totalAmount = _amt;

        _amt = CurveMath.calculateTrade(
            curve,
            _oGLiq,
            _nGLiq,
            _oBals,
            _nBals,
            _amt,
            _t.ix
        );

        _swapInfo.curveFactory = ICurveFactory(_swapData._curveFactory);
        _swapInfo.amountToUser = _amt.us_mul(ONE - curve.epsilon);
        _swapInfo.totalFee = _swapInfo.amountToUser - _amt;
        _swapInfo.protocolFeePercentage = _swapInfo
            .curveFactory
            .getProtocolFee();
        _swapInfo.treasury = _swapInfo.curveFactory.getProtocolTreasury();
        _swapInfo.amountToTreasury = _swapInfo
            .totalFee
            .muli(_swapInfo.protocolFeePercentage)
            .divi(100000);
        Assimilators.transferFee(
            _t.addr,
            _swapInfo.amountToTreasury,
            _swapInfo.treasury
        );
        tAmt_ = Assimilators.outputNumeraire(
            _t.addr,
            _swapData._recipient,
            _swapInfo.amountToUser,
            toETH
        );

        emit Trade(
            msg.sender,
            _swapData._origin,
            _swapData._target,
            _swapData._originAmount,
            tAmt_,
            _swapInfo.amountToTreasury
        );
    }

    function viewOriginSwap(
        Storage.Curve storage curve,
        address _origin,
        address _target,
        uint256 _originAmount
    ) external view returns (uint256 tAmt_) {
        (
            Storage.Assimilator memory _o,
            Storage.Assimilator memory _t
        ) = getOriginAndTarget(curve, _origin, _target);

        if (_o.ix == _t.ix)
            return
                Assimilators.viewRawAmount(
                    _t.addr,
                    Assimilators.viewNumeraireAmount(_o.addr, _originAmount)
                );

        (
            int128 _amt,
            int128 _oGLiq,
            int128 _nGLiq,
            int128[] memory _nBals,
            int128[] memory _oBals
        ) = viewOriginSwapData(curve, _o.ix, _t.ix, _originAmount, _o.addr);

        _amt = CurveMath.calculateTrade(
            curve,
            _oGLiq,
            _nGLiq,
            _oBals,
            _nBals,
            _amt,
            _t.ix
        );

        _amt = _amt.us_mul(ONE - curve.epsilon);

        tAmt_ = Assimilators.viewRawAmount(_t.addr, _amt.abs());
    }

    function targetSwap(
        Storage.Curve storage curve,
        TargetSwapData memory _swapData
    ) external returns (uint256 oAmt_) {
        (
            Storage.Assimilator memory _o,
            Storage.Assimilator memory _t
        ) = getOriginAndTarget(curve, _swapData._origin, _swapData._target);

        if (_o.ix == _t.ix)
            return
                Assimilators.intakeNumeraire(
                    _o.addr,
                    Assimilators.outputRaw(
                        _t.addr,
                        _swapData._recipient,
                        _swapData._targetAmount
                    )
                );

        (
            int128 _amt,
            int128 _oGLiq,
            int128 _nGLiq,
            int128[] memory _oBals,
            int128[] memory _nBals
        ) = getTargetSwapData(
                curve,
                _t.ix,
                _o.ix,
                _t.addr,
                _swapData._recipient,
                _swapData._targetAmount
            );

        _amt = CurveMath.calculateTrade(
            curve,
            _oGLiq,
            _nGLiq,
            _oBals,
            _nBals,
            _amt,
            _o.ix
        );

        SwapInfo memory _swapInfo;

        _swapInfo.totalAmount = _amt;
        _swapInfo.curveFactory = ICurveFactory(_swapData._curveFactory);
        _swapInfo.amountToUser = _amt.us_mul(ONE + curve.epsilon);
        _swapInfo.totalFee = _swapInfo.amountToUser - _amt;
        _swapInfo.protocolFeePercentage = _swapInfo
            .curveFactory
            .getProtocolFee();
        _swapInfo.treasury = _swapInfo.curveFactory.getProtocolTreasury();
        _swapInfo.amountToTreasury = _swapInfo
            .totalFee
            .muli(_swapInfo.protocolFeePercentage)
            .divi(100000);

        Assimilators.transferFee(
            _o.addr,
            _swapInfo.amountToTreasury,
            _swapInfo.treasury
        );

        oAmt_ = Assimilators.intakeNumeraire(_o.addr, _swapInfo.amountToUser);

        emit Trade(
            msg.sender,
            _swapData._origin,
            _swapData._target,
            oAmt_,
            _swapData._targetAmount,
            _swapInfo.amountToTreasury
        );
    }

    function viewTargetSwap(
        Storage.Curve storage curve,
        address _origin,
        address _target,
        uint256 _targetAmount
    ) external view returns (uint256 oAmt_) {
        (
            Storage.Assimilator memory _o,
            Storage.Assimilator memory _t
        ) = getOriginAndTarget(curve, _origin, _target);

        if (_o.ix == _t.ix)
            return
                Assimilators.viewRawAmount(
                    _o.addr,
                    Assimilators.viewNumeraireAmount(_t.addr, _targetAmount)
                );

        (
            int128 _amt,
            int128 _oGLiq,
            int128 _nGLiq,
            int128[] memory _nBals,
            int128[] memory _oBals
        ) = viewTargetSwapData(curve, _t.ix, _o.ix, _targetAmount, _t.addr);

        _amt = CurveMath.calculateTrade(
            curve,
            _oGLiq,
            _nGLiq,
            _oBals,
            _nBals,
            _amt,
            _o.ix
        );

        _amt = _amt.us_mul(ONE + curve.epsilon);

        oAmt_ = Assimilators.viewRawAmount(_o.addr, _amt);
    }

    function getOriginSwapData(
        Storage.Curve storage curve,
        uint256 _inputIx,
        uint256 _outputIx,
        address _assim,
        uint256 _amt
    )
        private
        returns (
            int128 amt_,
            int128 oGLiq_,
            int128 nGLiq_,
            int128[] memory,
            int128[] memory
        )
    {
        uint256 _length = curve.assets.length;

        int128[] memory oBals_ = new int128[](_length);
        int128[] memory nBals_ = new int128[](_length);
        Storage.Assimilator[] memory _reserves = curve.assets;

        for (uint256 i = 0; i < _length; i++) {
            if (i != _inputIx)
                nBals_[i] = oBals_[i] = Assimilators.viewNumeraireBalance(
                    _reserves[i].addr
                );
            else {
                int128 _bal;
                (amt_, _bal) = Assimilators.intakeRawAndGetBalance(
                    _assim,
                    _amt
                );

                oBals_[i] = _bal.sub(amt_);
                nBals_[i] = _bal;
            }

            oGLiq_ += oBals_[i];
            nGLiq_ += nBals_[i];
        }

        nGLiq_ = nGLiq_.sub(amt_);
        nBals_[_outputIx] = ABDKMath64x64.sub(nBals_[_outputIx], amt_);

        return (amt_, oGLiq_, nGLiq_, oBals_, nBals_);
    }

    function getTargetSwapData(
        Storage.Curve storage curve,
        uint256 _inputIx,
        uint256 _outputIx,
        address _assim,
        address _recipient,
        uint256 _amt
    )
        private
        returns (
            int128 amt_,
            int128 oGLiq_,
            int128 nGLiq_,
            int128[] memory,
            int128[] memory
        )
    {
        uint256 _length = curve.assets.length;

        int128[] memory oBals_ = new int128[](_length);
        int128[] memory nBals_ = new int128[](_length);
        Storage.Assimilator[] memory _reserves = curve.assets;

        for (uint256 i = 0; i < _length; i++) {
            if (i != _inputIx)
                nBals_[i] = oBals_[i] = Assimilators.viewNumeraireBalance(
                    _reserves[i].addr
                );
            else {
                int128 _bal;
                (amt_, _bal) = Assimilators.outputRawAndGetBalance(
                    _assim,
                    _recipient,
                    _amt
                );

                oBals_[i] = _bal.sub(amt_);
                nBals_[i] = _bal;
            }

            oGLiq_ += oBals_[i];
            nGLiq_ += nBals_[i];
        }

        nGLiq_ = nGLiq_.sub(amt_);
        nBals_[_outputIx] = ABDKMath64x64.sub(nBals_[_outputIx], amt_);

        return (amt_, oGLiq_, nGLiq_, oBals_, nBals_);
    }

    function viewOriginSwapData(
        Storage.Curve storage curve,
        uint256 _inputIx,
        uint256 _outputIx,
        uint256 _amt,
        address _assim
    )
        private
        view
        returns (
            int128 amt_,
            int128 oGLiq_,
            int128 nGLiq_,
            int128[] memory,
            int128[] memory
        )
    {
        uint256 _length = curve.assets.length;
        int128[] memory nBals_ = new int128[](_length);
        int128[] memory oBals_ = new int128[](_length);

        for (uint256 i = 0; i < _length; i++) {
            if (i != _inputIx)
                nBals_[i] = oBals_[i] = Assimilators.viewNumeraireBalance(
                    curve.assets[i].addr
                );
            else {
                int128 _bal;
                (amt_, _bal) = Assimilators.viewNumeraireAmountAndBalance(
                    _assim,
                    _amt
                );

                oBals_[i] = _bal;
                nBals_[i] = _bal.add(amt_);
            }

            oGLiq_ += oBals_[i];
            nGLiq_ += nBals_[i];
        }

        nGLiq_ = nGLiq_.sub(amt_);
        nBals_[_outputIx] = ABDKMath64x64.sub(nBals_[_outputIx], amt_);

        return (amt_, oGLiq_, nGLiq_, nBals_, oBals_);
    }

    function viewTargetSwapData(
        Storage.Curve storage curve,
        uint256 _inputIx,
        uint256 _outputIx,
        uint256 _amt,
        address _assim
    )
        private
        view
        returns (
            int128 amt_,
            int128 oGLiq_,
            int128 nGLiq_,
            int128[] memory,
            int128[] memory
        )
    {
        uint256 _length = curve.assets.length;
        int128[] memory nBals_ = new int128[](_length);
        int128[] memory oBals_ = new int128[](_length);

        for (uint256 i = 0; i < _length; i++) {
            if (i != _inputIx)
                nBals_[i] = oBals_[i] = Assimilators.viewNumeraireBalance(
                    curve.assets[i].addr
                );
            else {
                int128 _bal;
                (amt_, _bal) = Assimilators.viewNumeraireAmountAndBalance(
                    _assim,
                    _amt
                );
                amt_ = amt_.neg();

                oBals_[i] = _bal;
                nBals_[i] = _bal.add(amt_);
            }

            oGLiq_ += oBals_[i];
            nGLiq_ += nBals_[i];
        }

        nGLiq_ = nGLiq_.sub(amt_);
        nBals_[_outputIx] = ABDKMath64x64.sub(nBals_[_outputIx], amt_);

        return (amt_, oGLiq_, nGLiq_, nBals_, oBals_);
    }
}
