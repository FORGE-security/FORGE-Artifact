// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "contracts/libraries/AssemblyLib.sol";

contract TestAssemblyLib is Test {
    function testFuzz_isBetween(
        uint256 value,
        uint256 lower,
        uint256 upper
    ) public {
        vm.assume(lower <= upper);
        bool valid = AssemblyLib.isBetween(value, lower, upper);

        if (value >= lower && value <= upper) {
            assertTrue(valid);
        } else {
            assertFalse(valid);
        }
    }

    function testFuzz_addSignedDelta(uint128 input, int128 delta) public {
        // If delta is positive but the sum of input and delta is greater than
        // the maximum value of uint128, we revert.
        if (
            delta >= 0
                && (uint256(input) + uint256(uint128(delta))) > type(uint128).max
        ) {
            vm.expectRevert();
        }

        // If delta is negative but its absolute value is greater than input,
        // we revert.
        if (
            delta == -170141183460469231731687303715884105728
                || delta < 0 && uint128(-delta) > input
        ) {
            vm.expectRevert();
        }

        uint128 output = AssemblyLib.addSignedDelta(input, delta);

        assertEq(
            output, delta < 0 ? input - uint128(-delta) : input + uint128(delta)
        );
    }
}
