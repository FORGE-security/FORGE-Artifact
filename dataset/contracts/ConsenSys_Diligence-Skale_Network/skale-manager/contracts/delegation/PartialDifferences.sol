// SPDX-License-Identifier: AGPL-3.0-only

/*
    PartialDifferences.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Dmytro Stebaiev

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.8.17;

import {MathUtils} from "../utils/MathUtils.sol";
import {FractionUtils} from "../utils/FractionUtils.sol";

/**
 * @title Partial Differences Library
 * @dev This library contains functions to manage Partial Differences data
 * structure. Partial Differences is an array of value differences over time.
 *
 * For example: assuming an array [3, 6, 3, 1, 2], partial differences can
 * represent this array as [_, 3, -3, -2, 1].
 *
 * This data structure allows adding values on an open interval with O(1)
 * complexity.
 *
 * For example: add +5 to [3, 6, 3, 1, 2] starting from the second element (3),
 * instead of performing [3, 6, 3+5, 1+5, 2+5] partial differences allows
 * performing [_, 3, -3+5, -2, 1]. The original array can be restored by
 * adding values from partial differences.
 */
library PartialDifferences {
    using MathUtils for uint;

    struct Sequence {
        // month => diff
        mapping(uint256 => uint256) addDiff;
        // month => diff
        mapping(uint256 => uint256) subtractDiff;
        // month => value
        mapping(uint256 => uint256) value;
        uint256 firstUnprocessedMonth;
        uint256 lastChangedMonth;
    }

    struct Value {
        // month => diff
        mapping(uint256 => uint256) addDiff;
        // month => diff
        mapping(uint256 => uint256) subtractDiff;
        uint256 value;
        uint256 firstUnprocessedMonth;
        uint256 lastChangedMonth;
    }

    // functions for sequence

    function addToSequence(
        Sequence storage sequence,
        uint256 diff,
        uint256 month
    ) internal {
        require(
            sequence.firstUnprocessedMonth <= month,
            "Cannot add to the past"
        );
        if (sequence.firstUnprocessedMonth == 0) {
            sequence.firstUnprocessedMonth = month;
        }
        sequence.addDiff[month] = sequence.addDiff[month] + diff;
        if (sequence.lastChangedMonth != month) {
            sequence.lastChangedMonth = month;
        }
    }

    function subtractFromSequence(
        Sequence storage sequence,
        uint256 diff,
        uint256 month
    ) internal {
        require(
            sequence.firstUnprocessedMonth <= month,
            "Cannot subtract from the past"
        );
        if (sequence.firstUnprocessedMonth == 0) {
            sequence.firstUnprocessedMonth = month;
        }
        sequence.subtractDiff[month] = sequence.subtractDiff[month] + diff;
        if (sequence.lastChangedMonth != month) {
            sequence.lastChangedMonth = month;
        }
    }

    function getAndUpdateValueInSequence(
        Sequence storage sequence,
        uint256 month
    ) internal returns (uint256 value) {
        if (sequence.firstUnprocessedMonth == 0) {
            return 0;
        }

        if (sequence.firstUnprocessedMonth <= month) {
            for (uint256 i = sequence.firstUnprocessedMonth; i <= month; ++i) {
                uint256 nextValue = (sequence.value[i - 1] +
                    sequence.addDiff[i]).boundedSub(sequence.subtractDiff[i]);
                if (sequence.value[i] != nextValue) {
                    sequence.value[i] = nextValue;
                }
                if (sequence.addDiff[i] > 0) {
                    delete sequence.addDiff[i];
                }
                if (sequence.subtractDiff[i] > 0) {
                    delete sequence.subtractDiff[i];
                }
            }
            sequence.firstUnprocessedMonth = month + 1;
        }

        return sequence.value[month];
    }

    function reduceSequence(
        Sequence storage sequence,
        FractionUtils.Fraction memory reducingCoefficient,
        uint256 month
    ) internal {
        require(
            month + 1 >= sequence.firstUnprocessedMonth,
            "Cannot reduce value in the past"
        );
        require(
            reducingCoefficient.numerator <= reducingCoefficient.denominator,
            "Increasing of values is not implemented"
        );
        if (sequence.firstUnprocessedMonth == 0) {
            return;
        }
        uint256 value = getAndUpdateValueInSequence(sequence, month);
        if (value.approximatelyEqual(0)) {
            return;
        }

        sequence.value[month] =
            (sequence.value[month] * reducingCoefficient.numerator) /
            reducingCoefficient.denominator;

        for (uint256 i = month + 1; i <= sequence.lastChangedMonth; ++i) {
            sequence.subtractDiff[i] =
                (sequence.subtractDiff[i] * reducingCoefficient.numerator) /
                reducingCoefficient.denominator;
        }
    }

    // functions for value

    function addToValue(
        Value storage sequence,
        uint256 diff,
        uint256 month
    ) internal {
        require(
            sequence.firstUnprocessedMonth <= month,
            "Cannot add to the past"
        );
        if (sequence.firstUnprocessedMonth == 0) {
            sequence.firstUnprocessedMonth = month;
            sequence.lastChangedMonth = month;
        }
        if (month > sequence.lastChangedMonth) {
            sequence.lastChangedMonth = month;
        }

        if (month >= sequence.firstUnprocessedMonth) {
            sequence.addDiff[month] = sequence.addDiff[month] + diff;
        } else {
            sequence.value = sequence.value + diff;
        }
    }

    function subtractFromValue(
        Value storage sequence,
        uint256 diff,
        uint256 month
    ) internal {
        require(
            sequence.firstUnprocessedMonth <= month + 1,
            "Cannot subtract from the past"
        );
        if (sequence.firstUnprocessedMonth == 0) {
            sequence.firstUnprocessedMonth = month;
            sequence.lastChangedMonth = month;
        }
        if (month > sequence.lastChangedMonth) {
            sequence.lastChangedMonth = month;
        }

        if (month >= sequence.firstUnprocessedMonth) {
            sequence.subtractDiff[month] = sequence.subtractDiff[month] + diff;
        } else {
            sequence.value = sequence.value.boundedSub(diff);
        }
    }

    function getAndUpdateValue(
        Value storage sequence,
        uint256 month
    ) internal returns (uint256 value) {
        require(
            month + 1 >= sequence.firstUnprocessedMonth,
            "Cannot calculate value in the past"
        );
        if (sequence.firstUnprocessedMonth == 0) {
            return 0;
        }

        if (sequence.firstUnprocessedMonth <= month) {
            value = sequence.value;
            for (uint256 i = sequence.firstUnprocessedMonth; i <= month; ++i) {
                value = (value + sequence.addDiff[i]).boundedSub(
                    sequence.subtractDiff[i]
                );
                if (sequence.addDiff[i] > 0) {
                    delete sequence.addDiff[i];
                }
                if (sequence.subtractDiff[i] > 0) {
                    delete sequence.subtractDiff[i];
                }
            }
            if (sequence.value != value) {
                sequence.value = value;
            }
            sequence.firstUnprocessedMonth = month + 1;
        }

        return sequence.value;
    }

    function reduceValue(
        Value storage sequence,
        uint256 amount,
        uint256 month
    ) internal returns (FractionUtils.Fraction memory reducingCoefficient) {
        require(
            month + 1 >= sequence.firstUnprocessedMonth,
            "Cannot reduce value in the past"
        );
        if (sequence.firstUnprocessedMonth == 0) {
            return FractionUtils.createFraction(0);
        }
        uint256 value = getAndUpdateValue(sequence, month);
        if (value.approximatelyEqual(0)) {
            return FractionUtils.createFraction(0);
        }

        uint256 _amount = amount;
        if (value < amount) {
            _amount = value;
        }

        reducingCoefficient = FractionUtils.createFraction(
            value.boundedSub(_amount),
            value
        );
        reduceValueByCoefficient(sequence, reducingCoefficient, month);
        return reducingCoefficient;
    }

    function reduceValueByCoefficient(
        Value storage sequence,
        FractionUtils.Fraction memory reducingCoefficient,
        uint256 month
    ) internal {
        reduceValueByCoefficientAndUpdateSumIfNeeded({
            sequence: sequence,
            sumSequence: sequence,
            reducingCoefficient: reducingCoefficient,
            month: month,
            hasSumSequence: false
        });
    }

    function reduceValueByCoefficientAndUpdateSum(
        Value storage sequence,
        Value storage sumSequence,
        FractionUtils.Fraction memory reducingCoefficient,
        uint256 month
    ) internal {
        reduceValueByCoefficientAndUpdateSumIfNeeded({
            sequence: sequence,
            sumSequence: sumSequence,
            reducingCoefficient: reducingCoefficient,
            month: month,
            hasSumSequence: true
        });
    }

    function reduceValueByCoefficientAndUpdateSumIfNeeded(
        Value storage sequence,
        Value storage sumSequence,
        FractionUtils.Fraction memory reducingCoefficient,
        uint256 month,
        bool hasSumSequence
    ) internal {
        require(
            month + 1 >= sequence.firstUnprocessedMonth,
            "Cannot reduce value in the past"
        );
        if (hasSumSequence) {
            require(
                month + 1 >= sumSequence.firstUnprocessedMonth,
                "Cannot reduce value in the past"
            );
        }
        require(
            reducingCoefficient.numerator <= reducingCoefficient.denominator,
            "Increasing of values is not implemented"
        );
        if (sequence.firstUnprocessedMonth == 0) {
            return;
        }
        uint256 value = getAndUpdateValue(sequence, month);
        if (value.approximatelyEqual(0)) {
            return;
        }

        uint256 newValue = (sequence.value * reducingCoefficient.numerator) /
            reducingCoefficient.denominator;
        if (hasSumSequence) {
            subtractFromValue(
                sumSequence,
                sequence.value.boundedSub(newValue),
                month
            );
        }
        sequence.value = newValue;

        for (uint256 i = month + 1; i <= sequence.lastChangedMonth; ++i) {
            uint256 newDiff = (sequence.subtractDiff[i] *
                reducingCoefficient.numerator) /
                reducingCoefficient.denominator;
            if (hasSumSequence) {
                sumSequence.subtractDiff[i] = sumSequence
                    .subtractDiff[i]
                    .boundedSub(sequence.subtractDiff[i].boundedSub(newDiff));
            }
            sequence.subtractDiff[i] = newDiff;
        }
    }

    function getValueInSequence(
        Sequence storage sequence,
        uint256 month
    ) internal view returns (uint256 value) {
        if (sequence.firstUnprocessedMonth == 0) {
            return 0;
        }

        if (sequence.firstUnprocessedMonth <= month) {
            value = sequence.value[sequence.firstUnprocessedMonth - 1];
            for (uint256 i = sequence.firstUnprocessedMonth; i <= month; ++i) {
                value = value + sequence.addDiff[i] - sequence.subtractDiff[i];
            }
            return value;
        } else {
            return sequence.value[month];
        }
    }

    function getValuesInSequence(
        Sequence storage sequence
    ) internal view returns (uint256[] memory values) {
        if (sequence.firstUnprocessedMonth == 0) {
            return values;
        }
        uint256 begin = sequence.firstUnprocessedMonth - 1;
        uint256 end = sequence.lastChangedMonth + 1;
        if (end <= begin) {
            end = begin + 1;
        }
        values = new uint256[](end - begin);
        values[0] = sequence.value[sequence.firstUnprocessedMonth - 1];
        for (uint256 i = 0; i + 1 < values.length; ++i) {
            uint256 month = sequence.firstUnprocessedMonth + i;
            values[i + 1] =
                values[i] +
                sequence.addDiff[month] -
                sequence.subtractDiff[month];
        }
    }

    function getValue(
        Value storage sequence,
        uint256 month
    ) internal view returns (uint256 value) {
        require(
            month + 1 >= sequence.firstUnprocessedMonth,
            "Cannot calculate value in the past"
        );
        if (sequence.firstUnprocessedMonth == 0) {
            return 0;
        }

        if (sequence.firstUnprocessedMonth <= month) {
            value = sequence.value;
            for (uint256 i = sequence.firstUnprocessedMonth; i <= month; ++i) {
                value = value + sequence.addDiff[i] - sequence.subtractDiff[i];
            }
            return value;
        } else {
            return sequence.value;
        }
    }

    function getValues(
        Value storage sequence
    ) internal view returns (uint256[] memory values) {
        if (sequence.firstUnprocessedMonth == 0) {
            return values;
        }
        uint256 begin = sequence.firstUnprocessedMonth - 1;
        uint256 end = sequence.lastChangedMonth + 1;
        if (end <= begin) {
            end = begin + 1;
        }
        values = new uint256[](end - begin);
        values[0] = sequence.value;
        for (uint256 i = 0; i + 1 < values.length; ++i) {
            uint256 month = sequence.firstUnprocessedMonth + i;
            values[i + 1] =
                values[i] +
                sequence.addDiff[month] -
                sequence.subtractDiff[month];
        }
    }
}
