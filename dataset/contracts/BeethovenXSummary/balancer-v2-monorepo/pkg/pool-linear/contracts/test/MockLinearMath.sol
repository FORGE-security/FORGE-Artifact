// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;

import "../LinearMath.sol";

contract MockLinearMath is LinearMath {
    function calcBptOutPerMainIn(uint256 mainIn, uint256 mainBalance, uint256 wrappedBalance, uint256 rate, uint256 bptSupply) external pure returns (uint256) {
        return _calcBptOutPerMainIn(mainIn, mainBalance, wrappedBalance, rate, bptSupply);
    }

    function calcBptInPerMainOut(uint256 mainOut, uint256 mainBalance, uint256 wrappedBalance, uint256 rate, uint256 bptSupply) external pure returns (uint256) {
        return _calcBptInPerMainOut(mainOut, mainBalance, wrappedBalance, rate, bptSupply);
    }

    function calcWrappedOutPerMainIn(uint256 mainIn, uint256 mainBalance, uint256 wrappedBalance, uint256 rate) external pure returns (uint256) {
        return _calcWrappedOutPerMainIn(mainIn, mainBalance, wrappedBalance, rate);
    }

    function calcWrappedInPerMainOut(uint256 mainOut, uint256 mainBalance, uint256 wrappedBalance, uint256 rate) external pure returns (uint256) {
        return _calcWrappedInPerMainOut(mainOut, mainBalance, wrappedBalance, rate);
    }

    function calcMainInPerBptOut(uint256 bptOut, uint256 mainBalance, uint256 wrappedBalance, uint256 rate, uint256 bptSupply) external pure returns (uint256) {
        return _calcMainInPerBptOut(bptOut, mainBalance, wrappedBalance, rate, bptSupply);
    }

    function calcMainOutPerBptIn(uint256 bptIn, uint256 mainBalance, uint256 wrappedBalance, uint256 rate, uint256 bptSupply) external pure returns (uint256) {
        return _calcMainOutPerBptIn(bptIn, mainBalance, wrappedBalance, rate, bptSupply);
    }

    function calcMainInPerWrappedOut(uint256 wrappedOut, uint256 mainBalance, uint256 wrappedBalance, uint256 rate) external pure returns (uint256) {
        return _calcMainInPerWrappedOut(wrappedOut, mainBalance, rate);
    }

    function calcMainOutPerWrappedIn(uint256 wrappedIn, uint256 mainBalance, uint256 wrappedBalance, uint256 rate) external pure returns (uint256) {
        return _calcMainOutPerWrappedIn(wrappedIn, mainBalance, rate);
    }
}
