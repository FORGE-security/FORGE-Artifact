// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "./Interfaces/ITroveManager.sol";
import "./Interfaces/ISortedTroves.sol";
import "./Dependencies/LiquityBase.sol";
import "./Dependencies/Ownable.sol";
import "./Dependencies/CheckContract.sol";

contract HintHelpers is LiquityBase, Ownable, CheckContract {
    string public constant NAME = "HintHelpers";

    ISortedTroves public sortedTroves;
    ITroveManager public troveManager;

    // --- Events ---

    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event TroveManagerAddressChanged(address _troveManagerAddress);

    // --- Dependency setters ---

    function setAddresses(address _sortedTrovesAddress, address _troveManagerAddress)
        external
        onlyOwner
    {
        checkContract(_sortedTrovesAddress);
        checkContract(_troveManagerAddress);

        sortedTroves = ISortedTroves(_sortedTrovesAddress);
        troveManager = ITroveManager(_troveManagerAddress);

        emit SortedTrovesAddressChanged(_sortedTrovesAddress);
        emit TroveManagerAddressChanged(_troveManagerAddress);

        _renounceOwnership();
    }

    // --- Functions ---

    /* getRedemptionHints() - Helper function for finding the right hints to pass to redeemCollateral().
     *
     * It simulates a redemption of `_LUSDamount` to figure out where the redemption sequence will start and what state the final Trove
     * of the sequence will end up in.
     *
     * Returns three hints:
     *  - `firstRedemptionHint` is the address of the first Trove with ICR >= MCR (i.e. the first Trove that will be redeemed).
     *  - `partialRedemptionHintNICR` is the final nominal ICR of the last Trove of the sequence after being hit by partial redemption,
     *     or zero in case of no partial redemption.
     *  - `truncatedLUSDamount` is the maximum amount that can be redeemed out of the the provided `_LUSDamount`. This can be lower than
     *    `_LUSDamount` when redeeming the full amount would leave the last Trove of the redemption sequence with less net debt than the
     *    minimum allowed value (i.e. MIN_NET_DEBT).
     *
     * The number of Troves to consider for redemption can be capped by passing a non-zero value as `_maxIterations`, while passing zero
     * will leave it uncapped.
     */

    function getRedemptionHints(
        uint256 _LUSDamount,
        uint256 _price,
        uint256 _maxIterations
    )
        external
        view
        returns (
            address firstRedemptionHint,
            uint256 partialRedemptionHintNICR,
            uint256 truncatedLUSDamount
        )
    {
        ISortedTroves sortedTrovesCached = sortedTroves;

        uint256 remainingLUSD = _LUSDamount;
        address currentTroveuser = sortedTrovesCached.getLast();

        while (
            currentTroveuser != address(0) &&
            troveManager.getCurrentICR(currentTroveuser, _price) < MCR
        ) {
            currentTroveuser = sortedTrovesCached.getPrev(currentTroveuser);
        }

        firstRedemptionHint = currentTroveuser;

        if (_maxIterations == 0) {
            _maxIterations = uint256(-1);
        }

        while (currentTroveuser != address(0) && remainingLUSD > 0 && _maxIterations-- > 0) {
            uint256 netLUSDDebt = _getNetDebt(troveManager.getTroveDebt(currentTroveuser)).add(
                troveManager.getPendingLUSDDebtReward(currentTroveuser)
            );

            if (netLUSDDebt > remainingLUSD) {
                if (netLUSDDebt > MIN_NET_DEBT) {
                    uint256 maxRedeemableLUSD = LiquityMath._min(
                        remainingLUSD,
                        netLUSDDebt.sub(MIN_NET_DEBT)
                    );

                    uint256 ETH = troveManager.getTroveColl(currentTroveuser).add(
                        troveManager.getPendingETHReward(currentTroveuser)
                    );

                    uint256 newColl = ETH.sub(maxRedeemableLUSD.mul(DECIMAL_PRECISION).div(_price));
                    uint256 newDebt = netLUSDDebt.sub(maxRedeemableLUSD);

                    uint256 compositeDebt = _getCompositeDebt(newDebt);
                    partialRedemptionHintNICR = LiquityMath._computeNominalCR(
                        newColl,
                        compositeDebt
                    );

                    remainingLUSD = remainingLUSD.sub(maxRedeemableLUSD);
                }
                break;
            } else {
                remainingLUSD = remainingLUSD.sub(netLUSDDebt);
            }

            currentTroveuser = sortedTrovesCached.getPrev(currentTroveuser);
        }

        truncatedLUSDamount = _LUSDamount.sub(remainingLUSD);
    }

    /* getApproxHint() - return address of a Trove that is, on average, (length / numTrials) positions away in the
    sortedTroves list from the correct insert position of the Trove to be inserted.

    Note: The output address is worst-case O(n) positions away from the correct insert position, however, the function
    is probabilistic. Input can be tuned to guarantee results to a high degree of confidence, e.g:

    Submitting numTrials = k * sqrt(length), with k = 15 makes it very, very likely that the ouput address will
    be <= sqrt(length) positions away from the correct insert position.
    */
    function getApproxHint(
        uint256 _CR,
        uint256 _numTrials,
        uint256 _inputRandomSeed
    )
        external
        view
        returns (
            address hintAddress,
            uint256 diff,
            uint256 latestRandomSeed
        )
    {
        uint256 arrayLength = troveManager.getTroveOwnersCount();

        if (arrayLength == 0) {
            return (address(0), 0, _inputRandomSeed);
        }

        hintAddress = sortedTroves.getLast();
        diff = LiquityMath._getAbsoluteDifference(_CR, troveManager.getNominalICR(hintAddress));
        latestRandomSeed = _inputRandomSeed;

        uint256 i = 1;

        while (i < _numTrials) {
            latestRandomSeed = uint256(keccak256(abi.encodePacked(latestRandomSeed)));

            uint256 arrayIndex = latestRandomSeed % arrayLength;
            address currentAddress = troveManager.getTroveFromTroveOwnersArray(arrayIndex);
            uint256 currentNICR = troveManager.getNominalICR(currentAddress);

            // check if abs(current - CR) > abs(closest - CR), and update closest if current is closer
            uint256 currentDiff = LiquityMath._getAbsoluteDifference(currentNICR, _CR);

            if (currentDiff < diff) {
                diff = currentDiff;
                hintAddress = currentAddress;
            }
            i++;
        }
    }

    function computeNominalCR(uint256 _coll, uint256 _debt) external pure returns (uint256) {
        return LiquityMath._computeNominalCR(_coll, _debt);
    }

    function computeCR(
        uint256 _coll,
        uint256 _debt,
        uint256 _price
    ) external pure returns (uint256) {
        return LiquityMath._computeCR(_coll, _debt, _price);
    }
}
