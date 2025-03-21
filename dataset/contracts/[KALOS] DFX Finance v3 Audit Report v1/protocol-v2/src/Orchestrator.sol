// SPDX-License-Identifier: MIT

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "./lib/ABDKMath64x64.sol";
import "./Storage.sol";
import "./CurveMath.sol";

library Orchestrator {
    using SafeERC20 for IERC20;
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    int128 private constant ONE_WEI = 0x12;

    event ParametersSet(
        uint256 alpha,
        uint256 beta,
        uint256 delta,
        uint256 epsilon,
        uint256 lambda
    );

    event AssetIncluded(
        address indexed numeraire,
        address indexed reserve,
        uint256 weight
    );

    event AssimilatorIncluded(
        address indexed derivative,
        address indexed numeraire,
        address indexed reserve,
        address assimilator
    );

    function setParams(
        Storage.Curve storage curve,
        uint256 _alpha,
        uint256 _beta,
        uint256 _feeAtHalt,
        uint256 _epsilon,
        uint256 _lambda
    ) external {
        require(0 < _alpha && _alpha < 1e18, "Curve/parameter-invalid-alpha");

        require(_beta < _alpha, "Curve/parameter-invalid-beta");

        require(_feeAtHalt <= 5e17, "Curve/parameter-invalid-max");

        require(_epsilon <= 1e16, "Curve/parameter-invalid-epsilon");

        require(_lambda <= 1e18, "Curve/parameter-invalid-lambda");

        int128 _omega = getFee(curve);

        curve.alpha = (_alpha + 1).divu(1e18);

        curve.beta = (_beta + 1).divu(1e18);

        curve.delta =
            (_feeAtHalt).divu(1e18).div(
                uint256(2).fromUInt().mul(curve.alpha.sub(curve.beta))
            ) +
            ONE_WEI;

        curve.epsilon = (_epsilon + 1).divu(1e18);

        curve.lambda = (_lambda + 1).divu(1e18);

        int128 _psi = getFee(curve);

        require(_omega >= _psi, "Curve/parameters-increase-fee");

        emit ParametersSet(
            _alpha,
            _beta,
            curve.delta.mulu(1e18),
            _epsilon,
            _lambda
        );
    }

    function setAssimilator(
        Storage.Curve storage curve,
        address _baseCurrency,
        address _baseAssim,
        address _quoteCurrency,
        address _quoteAssim
    ) external {
        require(
            _baseCurrency != address(0),
            "Curve/numeraire-cannot-be-zero-address"
        );
        require(
            _baseAssim != address(0),
            "Curve/numeraire-assimilator-cannot-be-zero-address"
        );
        require(
            _quoteCurrency != address(0),
            "Curve/reserve-cannot-be-zero-address"
        );
        require(
            _quoteAssim != address(0),
            "Curve/reserve-assimilator-cannot-be-zero-address"
        );

        Storage.Assimilator storage _baseAssimilator = curve.assimilators[
            _baseCurrency
        ];
        _baseAssimilator.addr = _baseAssim;

        Storage.Assimilator storage _quoteAssimilator = curve.assimilators[
            _quoteCurrency
        ];
        _quoteAssimilator.addr = _quoteAssim;

        curve.assets[0] = _baseAssimilator;
        curve.assets[1] = _quoteAssimilator;
    }

    function getFee(
        Storage.Curve storage curve
    ) private view returns (int128 fee_) {
        int128 _gLiq;

        // Always pairs
        int128[] memory _bals = new int128[](2);

        for (uint256 i = 0; i < _bals.length; i++) {
            int128 _bal = Assimilators.viewNumeraireBalance(
                curve.assets[i].addr
            );

            _bals[i] = _bal;

            _gLiq += _bal;
        }

        fee_ = CurveMath.calculateFee(
            _gLiq,
            _bals,
            curve.beta,
            curve.delta,
            curve.weights
        );
    }

    function initialize(
        Storage.Curve storage curve,
        address[] storage numeraires,
        address[] storage reserves,
        address[] storage derivatives,
        address[] calldata _assets,
        uint256[] calldata _assetWeights
    ) external {
        require(
            _assetWeights.length == 2,
            "Curve/assetWeights-must-be-length-two"
        );
        require(
            _assets.length % 5 == 0,
            "Curve/assets-must-be-divisible-by-five"
        );

        for (uint256 i = 0; i < _assetWeights.length; i++) {
            uint256 ix = i * 5;

            numeraires.push(_assets[ix]);
            derivatives.push(_assets[ix]);

            reserves.push(_assets[2 + ix]);
            if (_assets[ix] != _assets[2 + ix])
                derivatives.push(_assets[2 + ix]);

            includeAsset(
                curve,
                _assets[ix], // numeraire
                _assets[1 + ix], // numeraire assimilator
                _assets[2 + ix], // reserve
                _assets[3 + ix], // reserve assimilator
                _assets[4 + ix], // reserve approve to
                _assetWeights[i]
            );
        }
    }

    function includeAsset(
        Storage.Curve storage curve,
        address _numeraire,
        address _numeraireAssim,
        address _reserve,
        address _reserveAssim,
        address _reserveApproveTo,
        uint256 _weight
    ) private {
        require(
            _numeraire != address(0),
            "Curve/numeraire-cannot-be-zero-address"
        );

        require(
            _numeraireAssim != address(0),
            "Curve/numeraire-assimilator-cannot-be-zero-address"
        );

        require(_reserve != address(0), "Curve/reserve-cannot-be-zero-address");

        require(
            _reserveAssim != address(0),
            "Curve/reserve-assimilator-cannot-be-zero-address"
        );

        require(_weight < 1e18, "Curve/weight-must-be-less-than-one");

        if (_numeraire != _reserve)
            IERC20(_numeraire).safeApprove(_reserveApproveTo, type(uint).max);

        Storage.Assimilator storage _numeraireAssimilator = curve.assimilators[
            _numeraire
        ];

        _numeraireAssimilator.addr = _numeraireAssim;

        _numeraireAssimilator.ix = uint8(curve.assets.length);

        Storage.Assimilator storage _reserveAssimilator = curve.assimilators[
            _reserve
        ];

        _reserveAssimilator.addr = _reserveAssim;

        _reserveAssimilator.ix = uint8(curve.assets.length);

        int128 __weight = _weight.divu(1e18).add(uint256(1).divu(1e18));

        curve.weights.push(__weight);

        curve.assets.push(_numeraireAssimilator);

        emit AssetIncluded(_numeraire, _reserve, _weight);

        emit AssimilatorIncluded(
            _numeraire,
            _numeraire,
            _reserve,
            _numeraireAssim
        );

        if (_numeraireAssim != _reserveAssim) {
            emit AssimilatorIncluded(
                _reserve,
                _numeraire,
                _reserve,
                _reserveAssim
            );
        }
    }

    function viewCurve(
        Storage.Curve storage curve
    )
        external
        view
        returns (
            uint256 alpha_,
            uint256 beta_,
            uint256 delta_,
            uint256 epsilon_,
            uint256 lambda_
        )
    {
        alpha_ = curve.alpha.mulu(1e18);

        beta_ = curve.beta.mulu(1e18);

        delta_ = curve.delta.mulu(1e18);

        epsilon_ = curve.epsilon.mulu(1e18);

        lambda_ = curve.lambda.mulu(1e18);
    }
}
