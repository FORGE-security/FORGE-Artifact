pragma solidity ^0.5.11;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./LPToken.sol";
import "./MathUtils.sol";

library SwapUtils {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using MathUtils for uint256;

    /*** EVENTS ***/

    event TokenSwap(address indexed buyer, uint256 tokensSold,
        uint256 tokensBought, uint128 soldId, uint128 boughtId
    );
    event AddLiquidity(address indexed provider, uint256[] tokenAmounts,
        uint256[] fees, uint256 invariant, uint256 lpTokenSupply
    );
    event RemoveLiquidity(address indexed provider, uint256[] tokenAmounts,
        uint256 lpTokenSupply
    );
    event RemoveLiquidityOne(address indexed provider, uint256 lpTokenAmount,
        uint256 lpTokenSupply, uint256 boughtId, uint256 tokensBought
    );
    event RemoveLiquidityImbalance(address indexed provider,
        uint256[] tokenAmounts, uint256[] fees, uint256 invariant,
        uint256 lpTokenSupply
    );

    struct Swap {
        LPToken lpToken;

        // contract references for all tokens being pooled
        IERC20[] pooledTokens;

        // multipliers for each pooled token's precision to get to POOL_PRECISION
        // for example, TBTC has 18 decimals, so the multiplier should be 1. WBTC
        // has 8, so the multiplier should be 10 ** 18 / 10 ** 8 => 10 ** 10
        uint256[] tokenPrecisionMultipliers;

        // the pool balance of each token, in the token's precision
        // the contract's actual token balance might differ
        uint256[] balances;

        // variables around the management of A,
        // the amplification coefficient * n * (n - 1)
        // see https://www.curve.fi/stableswap-paper.pdf for details
        uint256 A;

        // fee calculation
        uint256 swapFee;
        uint256 adminFee;
        uint256 defaultWithdrawFee;

        mapping(address => uint256) depositTimestamp;
        mapping(address => uint256) withdrawFeeMultiplier;
    }

    // the precision all pools tokens will be converted to
    uint8 constant POOL_PRECISION_DECIMALS = 18;

    // the denominator used to calculate admin and LP fees. For example, an
    // LP fee might be something like tradeAmount.mul(fee).div(FEE_DENOMINATOR)
    uint256 constant FEE_DENOMINATOR = 10 ** 10;

    // Max swap fee is 1% or 100bps of each swap
    uint256 constant MAX_SWAP_FEE = 10 ** 8;

    // Max adminFee is 100% of the swapFee
    // adminFee does not add additional fee on top of swapFee
    // Instead it takes a certain % of the swapFee. Therefore it has no impact on the
    // users but only on the earnings of LPs
    uint256 constant MAX_ADMIN_FEE = 10 ** 10;

    // Max withdrawFee is 1% of the value withdrawn
    // Fee will be redistributed to the LPs in the pool, rewarding
    // long term providers.
    uint256 constant MAX_WITHDRAW_FEE = 10 ** 8;

    /*** VIEW & PURE FUNCTIONS ***/

    /**
     * @notice Return A, the the amplification coefficient * n * (n - 1)
     * @dev See the StableSwap paper for details
     */
    function getA(Swap storage self) public view returns (uint256) {
        return self.A;
    }

    /**
     * @notice Return POOL_PRECISION_DECIMALS, precision decimals of all pool tokens
     *         to be converted to
     */
    function getPoolPrecisionDecimals() public pure returns (uint8) {
        return POOL_PRECISION_DECIMALS;
    }

    /**
     * @notice Return timestamp of last deposit of given address
     */
    function getDepositTimestamp(Swap storage self, address user) public view returns (uint256) {
        return self.depositTimestamp[user];
    }

    /**
     * @notice calculate the dy and fee of withdrawing in one token
     * @param tokenAmount the amount to withdraw in the pool's precision
     * @param tokenIndex which token will be withdrawn
     * @return the dy and the associated fee
     */
    function calculateWithdrawOneToken(
        Swap storage self, uint256 tokenAmount, uint8 tokenIndex
    ) public view returns(uint256, uint256) {

        uint256 dy;
        uint256 newY;

        (dy, newY) = calculateWithdrawOneTokenDY(self, tokenIndex, tokenAmount);

        // dy_0 (without fees)
        // dy, dy_0 - dy
        return (dy, _xp(self)[tokenIndex].sub(newY).div(
            self.tokenPrecisionMultipliers[tokenIndex]).sub(dy));
    }

    /**
     * @notice Calculate the dy of withdrawing in one token
     * @param tokenIndex which token will be withdrawn
     * @param tokenAmount the amount to withdraw in the pools precision
     * @return the d and the new y after withdrawing one token
     */
    function calculateWithdrawOneTokenDY(
        Swap storage self, uint8 tokenIndex, uint256 tokenAmount
    ) internal view returns(uint256, uint256) {
        // Get the current D, then solve the stableswap invariant
        // y_i for D - tokenAmount
        uint256 D0 = getD(_xp(self), getA(self));
        uint256 D1 = D0.sub(tokenAmount.mul(D0).div(self.lpToken.totalSupply()));

        uint256[] memory xpReduced = _xp(self);

        uint256 newY = getYD(getA(self), tokenIndex, xpReduced, D1);

        for (uint i = 0; i<self.pooledTokens.length; i++) {
            uint256 xpi = _xp(self)[i];
            // if i == tokenIndex, dxExpected = xp[i] * D1 / D0 - newY
            // else dxExpected = xp[i] - (xp[i] * D1 / D0)
            // xpReduced[i] -= dxExpected * fee / FEE_DENOMINATOR
            xpReduced[i] = xpReduced[i].sub(
                ((i == tokenIndex) ?
                    xpi.mul(D1).div(D0).sub(newY) :
                    xpi.sub(xpi.mul(D1).div(D0))
                ).mul(feePerToken(self)).div(FEE_DENOMINATOR));
        }

        uint256 dy = xpReduced[tokenIndex].sub(
            getYD(getA(self), tokenIndex, xpReduced, D1));
        dy = dy.sub(1).div(self.tokenPrecisionMultipliers[tokenIndex]);

        return (dy, newY);
    }

    /**
     * @notice Calculate the price of a token in the pool given
     *         precision-adjusted balances and a particular D
     *         and precision-adjusted array of balances.
     * @dev This is accomplished via solving the quadratic equation
     *      iteratively. See the StableSwap paper and Curve.fi
     *      implementation for details.
     * @param _A the the amplification coefficient * n * (n - 1). See the
     *        StableSwap paper for details
     * @param tokenIndex which token we're calculating
     * @param xp a precision-adjusted set of pool balances. Array should be
     *        the same cardinality as the pool
     * @param D the stableswap invariant
     * @return the price of the token, in the same precision as in xp
     */
    function getYD(uint256 _A, uint8 tokenIndex, uint256[] memory xp, uint256 D)
        internal pure returns (uint256) {
        uint256 numTokens = xp.length;
        require(tokenIndex < numTokens, "Token not found");

        uint256 c = D;
        uint256 s = 0;
        uint256 nA = _A.mul(numTokens);
        uint256 cDivider = 1;

        for (uint i = 0; i < numTokens; i++) {
            if (i != tokenIndex) {
                s = s.add(xp[i]);
                c = c.mul(D);
                cDivider = cDivider.mul(xp[i]).mul(numTokens);
            } else {
                continue;
            }
        }
        c = c.mul(D).div(nA.mul(numTokens).mul(cDivider));

        uint256 b = s.add(D.div(nA));
        uint256 yPrev = 0;
        uint256 y = D;
        for (uint i = 0; i<256; i++) {
            yPrev = y;
            y = y.mul(y).add(c).div(y.mul(2).add(b).sub(D));
            if(y.within1(yPrev)) {
                break;
            }
        }
        return y;
    }

    /**
     * @notice Get D, the StableSwap invariant, based on a set of balances
     *         and a particular A
     * @param xp a precision-adjusted set of pool balances. Array should be
     *        the same cardinality as the pool
     * @param _A the the amplification coefficient * n * (n - 1). See the
     *        StableSwap paper for details
     * @return The invariant, at the precision of the pool
     */
    function getD(uint256[] memory xp, uint256 _A)
        internal pure returns (uint256) {
        uint256 numTokens = xp.length;
        uint256 s = 0;
        for (uint i = 0; i < numTokens; i++) {
            s = s.add(xp[i]);
        }
        if (s == 0) {
            return 0;
        }

        uint256 prevD = 0;
        uint256 D = s;
        uint256 nA = _A.mul(numTokens);

        for (uint i = 0; i < 256; i++) {
            uint256 dP = D;
            for (uint j = 0; j < numTokens; j++) {
                dP = dP.mul(D).div(xp[j].mul(numTokens).add(1));
            }
            prevD = D;
            D = nA.mul(s).add(dP.mul(numTokens)).mul(D).div(
                nA.sub(1).mul(D).add(numTokens.add(1).mul(dP)));
            if (D.within1(prevD)) {
                break;
            }
        }
        return D;
    }

    /**
     * @notice Get D, the StableSwap invariant, based on self Swap struct
     * @return The invariant, at the precision of the pool
     */
    function getD(Swap storage self)
        internal view returns (uint256) {
        return getD(_xp(self), getA(self));
    }

    /**
     * @notice Given a set of balances and precision multipliers, return the
     *         precision-adjusted balances.
     * @dev
     * @param _balances an array of token balances, in their native precisions.
     *        These should generally correspond with pooled tokens.
     * @param precisionMultipliers an array of multipliers, corresponding to
     *        the amounts in the _balances array. When multiplied together they
     *        should yield amounts at the pool's precision.
     * @return an array of amounts "scaled" to the pool's precision
     */
    function _xp(
        uint256[] memory _balances,
        uint256[] memory precisionMultipliers
    ) internal pure returns (uint256[] memory) {
        uint256 numTokens = _balances.length;
        require(
            numTokens == precisionMultipliers.length,
            "Balances must map to token precision multipliers"
        );
        uint256[] memory xp = _balances;
        for (uint i = 0; i < numTokens; i++) {
            xp[i] = xp[i].mul(precisionMultipliers[i]);
        }
        return xp;
    }

    /**
     * @notice Return the precision-adjusted balances of all tokens in the pool
     * @return the pool balances "scaled" to the pool's precision, allowing
     *          them to be more easily compared.
     */
    function _xp(Swap storage self, uint256[] memory _balances)
        internal view returns (uint256[] memory) {
        return _xp(_balances, self.tokenPrecisionMultipliers);
    }

    /**
     * @notice Return the precision-adjusted balances of all tokens in the pool
     * @return the pool balances "scaled" to the pool's precision, allowing
     *          them to be more easily compared.
     */
    function _xp(Swap storage self) internal view returns (uint256[] memory) {
        return _xp(self.balances, self.tokenPrecisionMultipliers);
    }

    /**
     * @notice Get the virtual price, to help calculate profit
     * @return the virtual price, scaled to the POOL_PRECISION
     */
    function getVirtualPrice(Swap storage self) external view returns (uint256) {
        uint256 D = getD(_xp(self), getA(self));
        uint256 supply = self.lpToken.totalSupply();
        return D.mul(10 ** uint256(getPoolPrecisionDecimals())).div(supply);
    }

    /**
     * @notice Calculate the balances of the tokens to send to the user
     *         after given amount of pool token is burned.
     * @param amount Amount of pool token to burn
     * @return balances of the tokens to send to the user
     */
    function calculateRebalanceAmounts(Swap storage self, uint256 amount)
    internal view returns(uint256[] memory) {
        uint256 tokenSupply = self.lpToken.totalSupply();
        uint256[] memory amounts = new uint256[](self.pooledTokens.length);

        for (uint i = 0; i < self.pooledTokens.length; i++) {
            amounts[i] = self.balances[i].mul(amount).div(tokenSupply);
        }

        return amounts;
    }

    /**
     * @notice Calculate the new balances of the tokens given the indexes of the token
     *         that is swapped from (FROM) and the token that is swapped to (TO).
     *         This function is used as a helper function to calculate how much TO token
     *         the user should receive on swap.
     * @param tokenIndexFrom index of FROM token
     * @param tokenIndexTo index of TO token
     * @param x the new total amount of FROM token
     * @param xp balances of the tokens in the pool
     * @return the amount of TO token that should remain in the pool
     */
    function getY(
        Swap storage self, uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 x,
        uint256[] memory xp
    ) internal view returns (uint256) {
        uint256 numTokens = self.pooledTokens.length;
        require(tokenIndexFrom != tokenIndexTo, "Can't compare token to itself");
        require(
            tokenIndexFrom < numTokens && tokenIndexTo < numTokens,
            "Tokens must be in pool"
        );

        uint256 _A = getA(self);
        uint256 D = getD(xp, _A);
        uint256 c = D;
        uint256 s = 0;
        uint256 nA = numTokens.mul(_A);
        uint256 cDivider = 1;

        uint256 _x = 0;
        for (uint i = 0; i < numTokens; i++) {
            if (i == tokenIndexFrom) {
                _x = x;
            } else if (i != tokenIndexTo) {
                _x = xp[i];
            }
            else {
                continue;
            }
            s = s.add(_x);
            c = c.mul(D);
            cDivider = cDivider.mul(_x).mul(numTokens);
        }
        c = c.mul(D).div(nA.mul(numTokens).mul(cDivider));
        uint256 b = s.add(D.div(nA));
        uint256 yPrev = 0;
        uint256 y = D;

        // iterative approximation
        for (uint i = 0; i < 256; i++) {
            yPrev = y;
            y = y.mul(y).add(c).div(y.mul(2).add(b).sub(D));
            if (y.within1(yPrev)) {
                break;
            }
        }
        return y;
    }

    /**
     * @notice Externally calculates a swap between two tokens.
     * @param tokenIndexFrom the token to sell
     * @param tokenIndexTo the token to buy
     * @param dx the number of tokens to sell
     * @return dy the number of tokens the user will get
     */
    function calculateSwap(
        Swap storage self, uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx
    ) external view returns(uint256 dy) {
        (dy, ) = _calculateSwap(self, tokenIndexFrom, tokenIndexTo, dx);
    }

    /**
     * @notice Internally calculates a swap between two tokens.
     * @dev The caller is expected to transfer the actual amounts (dx and dy)
     *      using the token contracts.
     * @param tokenIndexFrom the token to sell
     * @param tokenIndexTo the token to buy
     * @param dx the number of tokens to sell
     * @return dy the number of tokens the user will get
     * @return dyFee the associated fee
     */
    function _calculateSwap(
        Swap storage self, uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx
    ) internal view returns(uint256 dy, uint256 dyFee) {
        uint256[] memory xp = _xp(self);
        uint256 x = dx.mul(self.tokenPrecisionMultipliers[tokenIndexFrom]).add(
            xp[tokenIndexFrom]);
        uint256 y = getY(self, tokenIndexFrom, tokenIndexTo, x, xp);
        dy = xp[tokenIndexTo].sub(y).sub(1);
        dyFee = dy.mul(self.swapFee).div(FEE_DENOMINATOR);
        dy = dy.sub(dyFee).div(self.tokenPrecisionMultipliers[tokenIndexTo]);
    }

    /**
     * @notice A simple method to calculate amount of each underlying
     *         tokens that is returned upon burning given amount of
     *         LP tokens
     * @param amount the amount of LP tokens that would to be burned on
     *        withdrawal
     */
    function calculateRemoveLiquidity(Swap storage self, uint256 amount)
    external view returns (uint256[] memory) {
        uint256 totalSupply = self.lpToken.totalSupply();
        uint256[] memory amounts = new uint256[](self.pooledTokens.length);

        for (uint i = 0; i < self.pooledTokens.length; i++) {
            amounts[i] = self.balances[i].mul(amount).div(totalSupply);
        }
        return amounts;
    }

    /**
     * @notice calculate the fee that is applied when the given user withdraws
     * @param user address you want to calculate withdraw fee of
     * @return current withdraw fee of the user
     */
    function calculateCurrentWithdrawFee(Swap storage self, address user) public view returns (uint256) {
        uint256 endTime = self.depositTimestamp[user].add(4 weeks);

        if (endTime > block.timestamp) {
            uint256 timeLeftover = endTime - block.timestamp;
            return self.defaultWithdrawFee
            .mul(self.withdrawFeeMultiplier[user])
            .mul(timeLeftover)
            .div(4 weeks)
            .div(FEE_DENOMINATOR);
        } else {
            return 0;
        }
    }

    /**
     * @notice A simple method to calculate prices from deposits or
     *         withdrawals, excluding fees but including slippage. This is
     *         helpful as an input into the various "min" parameters on calls
     *         to fight front-running
     * @dev This shouldn't be used outside frontends for user estimates.
     * @param amounts an array of token amounts to deposit or withdrawal,
     *        corresponding to pooledTokens. The amount should be in each
     *        pooled token's native precision
     * @param deposit whether this is a deposit or a withdrawal
     */
    function calculateTokenAmount(
        Swap storage self, uint256[] calldata amounts, bool deposit
    ) external view returns(uint256) {
        uint256 numTokens = self.pooledTokens.length;
        uint256 _A = getA(self);
        uint256 D0 = getD(_xp(self, self.balances), _A);
        uint256[] memory balances1 = self.balances;
        for (uint i = 0; i < numTokens; i++) {
            if (deposit) {
                balances1[i] = balances1[i].add(amounts[i]);
            } else {
                balances1[i] = balances1[i].sub(amounts[i]);
            }
        }
        uint256 D1 = getD(_xp(self, balances1), _A);
        uint256 totalSupply = self.lpToken.totalSupply();
        return (deposit ? D1.sub(D0) : D0.sub(D1)).mul(totalSupply).div(D0);
    }

    /**
     * @notice return accumulated amount of admin fees of the token with given index
     * @param index Index of the pooled token
     * @return admin balance in the token's precision
     */
    function getAdminBalance(Swap storage self, uint256 index) external view returns (uint256) {
        return self.pooledTokens[index].balanceOf(address(this)) - self.balances[index];
    }

    /**
     * @notice internal helper function to calculate fee per token multiplier used in
     *         swap fee calculations
     */
    function feePerToken(Swap storage self)
    internal view returns(uint256) {
        return self.swapFee.mul(self.pooledTokens.length).div(
            self.pooledTokens.length.sub(1).mul(4));
    }

    /*** STATE MODIFYING FUNCTIONS ***/

    /**
     * @notice swap two tokens in the pool
     * @param tokenIndexFrom the token the user wants to sell
     * @param tokenIndexTo the token the user wants to buy
     * @param dx the amount of tokens the user wants to sell
     * @param minDy the min amount the user would like to receive, or revert.
     */
    function swap(
        Swap storage self, uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx,
        uint256 minDy
    ) external {
        (uint256 dy, uint256 dyFee) = _calculateSwap(self, tokenIndexFrom, tokenIndexTo, dx);
        require(dy >= minDy, "Swap didn't result in min tokens");

        uint256 dyAdminFee = dyFee.mul(self.adminFee).div(FEE_DENOMINATOR).div(self.tokenPrecisionMultipliers[tokenIndexTo]);

        self.balances[tokenIndexFrom] = self.balances[tokenIndexFrom].add(dx);
        self.balances[tokenIndexTo] = self.balances[tokenIndexTo].sub(dy).sub(dyAdminFee);

        self.pooledTokens[tokenIndexFrom].safeTransferFrom(
            msg.sender, address(this), dx);
        self.pooledTokens[tokenIndexTo].safeTransfer(msg.sender, dy);

        emit TokenSwap(msg.sender, dx, dy, tokenIndexFrom, tokenIndexTo);
    }

    /**
     * @notice Add liquidity to the pool
     * @param amounts the amounts of each token to add, in their native
     *        precision
     * @param minToMint the minimum LP tokens adding this amount of liquidity
     *        should mint, otherwise revert. Handy for front-running mitigation
     */
    function addLiquidity(Swap storage self, uint256[] calldata amounts, uint256 minToMint)
        external {
        require(
            amounts.length == self.pooledTokens.length,
            "Amounts must map to pooled tokens"
        );

        uint256[] memory fees = new uint256[](self.pooledTokens.length);

        // current state
        uint256 D0 = 0;
        if (self.lpToken.totalSupply() > 0) {
            D0 = getD(self);
        }
        uint256[] memory newBalances = self.balances;

        for (uint i = 0; i < self.pooledTokens.length; i++) {
            require(
                self.lpToken.totalSupply() > 0 || amounts[i] > 0,
                "If token supply is zero, must supply all tokens in pool"
            );
            newBalances[i] = self.balances[i].add(amounts[i]);
        }

        // invariant after change
        uint256 D1 = getD(_xp(self, newBalances), getA(self));
        require(D1 > D0, "D should increase after additional liquidity");

        // updated to reflect fees and calculate the user's LP tokens
        uint256 D2 = D1;
        if (self.lpToken.totalSupply() > 0) {
            for (uint i = 0; i < self.pooledTokens.length; i++) {
                uint256 idealBalance = D1.mul(self.balances[i]).div(D0);
                fees[i] = feePerToken(self).mul(
                    idealBalance.difference(newBalances[i])).div(FEE_DENOMINATOR);
                self.balances[i] = newBalances[i].sub(
                    fees[i].mul(self.adminFee).div(FEE_DENOMINATOR));
                newBalances[i] = newBalances[i].sub(fees[i]);
            }
            D2 = getD(_xp(self, newBalances), getA(self));
        } else {
            // the initial depositor doesn't pay fees
            self.balances = newBalances;
        }

        uint256 toMint = 0;
        if (self.lpToken.totalSupply() == 0) {
            toMint = D1;
        } else {
            toMint = D2.sub(D0).mul(self.lpToken.totalSupply()).div(D0);
        }

        require(toMint >= minToMint, "Couldn't mint min requested LP tokens");

        for (uint i = 0; i < self.pooledTokens.length; i++) {
            if (amounts[i] > 0) {
                self.pooledTokens[i].safeTransferFrom(
                    msg.sender, address(this), amounts[i]);
            }
        }

        updateUserWithdrawFee(self, msg.sender, toMint);
        // mint the user's LP tokens
        self.lpToken.mint(msg.sender, toMint);

        emit AddLiquidity(
            msg.sender, amounts, fees, D1, self.lpToken.totalSupply()
        );
    }

    /**
     * @notice Calculate base withdraw fee for the user. If the user is currently
     *         not participating in the pool, sets to default value. If not, recalculate
     *         the starting withdraw fee based on the last deposit's time & amount relative
     *         to the new deposit.
     * @param user address of the user depositing tokens
     * @param toMint amount of pool tokens to be minted
     */
    function updateUserWithdrawFee(Swap storage self, address user, uint256 toMint) internal {
        uint256 currentFee = calculateCurrentWithdrawFee(self, user);
        uint256 currentBalance = self.lpToken.balanceOf(user);

        self.withdrawFeeMultiplier[user] = currentBalance.mul(currentFee)
            .add(toMint.mul(self.defaultWithdrawFee.add(1)))
            .mul(FEE_DENOMINATOR)
            .div(toMint.add(currentBalance))
            .div(self.defaultWithdrawFee.add(1));

        self.depositTimestamp[user] = block.timestamp;
    }

    /**
     * @notice Burn LP tokens to remove liquidity from the pool.
     * @dev Liquidity can always be removed, even when the pool is paused.
     * @param amount the amount of LP tokens to burn
     * @param minAmounts the minimum amounts of each token in the pool
     *        acceptable for this burn. Useful as a front-running mitigation
     */
    function removeLiquidity(
        Swap storage self, uint256 amount, uint256[] calldata minAmounts
    ) external {
        require(amount <= self.lpToken.balanceOf(msg.sender), ">LP.balanceOf");
        require(
            minAmounts.length == self.pooledTokens.length,
            "Min amounts should correspond to pooled tokens"
        );

        uint256 adjustedAmount = amount
            .mul(FEE_DENOMINATOR.sub(calculateCurrentWithdrawFee(self, msg.sender)))
            .div(FEE_DENOMINATOR);

        uint256[] memory amounts = calculateRebalanceAmounts(self, adjustedAmount);

        for (uint i = 0; i < amounts.length; i++) {
            require(
                amounts[i] >= minAmounts[i],
                "Resulted in fewer tokens than expected"
            );
            self.balances[i] = self.balances[i].sub(amounts[i]);
        }

        self.lpToken.burnFrom(msg.sender, amount);

        for (uint i = 0; i < self.pooledTokens.length; i++) {
            self.pooledTokens[i].safeTransfer(msg.sender, amounts[i]);
        }

        emit RemoveLiquidity(
            msg.sender, amounts, self.lpToken.totalSupply()
        );
    }

    /**
     * @notice Remove liquidity from the pool all in one token.
     * @param tokenAmount the amount of the token you want to receive
     * @param tokenIndex the index of the token you want to receive
     * @param minAmount the minimum amount to withdraw, otherwise revert
     */
    function removeLiquidityOneToken(
        Swap storage self, uint256 tokenAmount, uint8 tokenIndex,
        uint256 minAmount
    ) external {
        uint256 totalSupply = self.lpToken.totalSupply();
        uint256 numTokens = self.pooledTokens.length;
        require(tokenAmount <= self.lpToken.balanceOf(msg.sender), ">LP.balanceOf");
        require(tokenIndex < numTokens, "Token not found");

        uint256 dyFee = 0;
        uint256 dy = 0;

        (dy, dyFee) = calculateWithdrawOneToken(self, tokenAmount, tokenIndex);
        dy = dy
        .mul(FEE_DENOMINATOR.sub(calculateCurrentWithdrawFee(self, msg.sender)))
        .div(FEE_DENOMINATOR);

        require(dy >= minAmount, "The min amount of tokens wasn't met");

        self.balances[tokenIndex] = self.balances[tokenIndex].sub(
            dy.add(dyFee.mul(self.adminFee).div(FEE_DENOMINATOR))
        );
        self.lpToken.burnFrom(msg.sender, tokenAmount);
        self.pooledTokens[tokenIndex].safeTransfer(msg.sender, dy);

        emit RemoveLiquidityOne(
            msg.sender, tokenAmount, totalSupply, tokenIndex, dy
        );
    }

    /**
     * @notice Remove liquidity from the pool, weighted differently than the
     *         pool's current balances.
     * @param amounts how much of each token to withdraw
     * @param maxBurnAmount the max LP token provider is willing to pay to
     *        remove liquidity. Useful as a front-running mitigation.
     */
    function removeLiquidityImbalance(
        Swap storage self, uint256[] memory amounts, uint256 maxBurnAmount
    ) public {
        require(
            amounts.length == self.pooledTokens.length,
            "Amounts should correspond to pooled tokens"
        );
        require(maxBurnAmount <= self.lpToken.balanceOf(msg.sender) && maxBurnAmount != 0, ">LP.balanceOf");

        uint256 tokenSupply = self.lpToken.totalSupply();
        uint256 _fee = feePerToken(self);

        uint256[] memory balances1 = self.balances;

        uint256 D0 = getD(_xp(self), getA(self));
        for (uint i = 0; i < self.pooledTokens.length; i++) {
            balances1[i] = balances1[i].sub(amounts[i]);
        }
        uint256 D1 = getD(_xp(self, balances1), getA(self));
        uint256[] memory fees = new uint256[](self.pooledTokens.length);

        for (uint i = 0; i < self.pooledTokens.length; i++) {
            uint256 idealBalance = D1.mul(self.balances[i]).div(D0);
            uint256 difference = idealBalance.difference(balances1[i]);
            fees[i] = _fee.mul(difference).div(FEE_DENOMINATOR);
            self.balances[i] = balances1[i].sub(fees[i].mul(self.adminFee).div(
                FEE_DENOMINATOR));
            balances1[i] = balances1[i].sub(fees[i]);
        }

        uint256 D2 = getD(_xp(self, balances1), getA(self));

        uint256 tokenAmount = D0.sub(D2).mul(tokenSupply).div(D0).add(1);
        tokenAmount = tokenAmount
            .mul(FEE_DENOMINATOR)
            .div(FEE_DENOMINATOR.sub(calculateCurrentWithdrawFee(self, msg.sender)));

        require(
            tokenAmount <= maxBurnAmount,
            "More expensive than the max burn amount"
        );

        self.lpToken.burnFrom(msg.sender, tokenAmount);

        for (uint i = 0; i < self.pooledTokens.length; i++) {
            self.pooledTokens[i].safeTransfer(msg.sender, amounts[i]);
        }

        emit RemoveLiquidityImbalance(
            msg.sender, amounts, fees, D1, tokenSupply.sub(tokenAmount));
    }

    /**
     * @notice withdraw all admin fees to a given address
     * @param to Address to send the fees to
     */
    function withdrawAdminFees(Swap storage self, address to) external {
        for (uint256 i = 0; i < self.pooledTokens.length; i++) {
            IERC20 token = self.pooledTokens[i];
            uint256 balance = token.balanceOf(address(this)) - self.balances[i];
            if (balance > 0) {
                token.safeTransfer(to, balance);
            }
        }
    }

    /**
     * @notice update the admin fee
     * @dev adminFee cannot be higher than 100% of the swap fee
     * @param newAdminFee new admin fee to be applied on future transactions
     */
    function setAdminFee(Swap storage self, uint256 newAdminFee) external {
        require(newAdminFee <= MAX_ADMIN_FEE, "Fee is too high");
        self.adminFee = newAdminFee;
    }

    /**
     * @notice update the swap fee
     * @dev fee cannot be higher than 1% of each swap
     * @param newSwapFee new swap fee to be applied on future transactions
     */
    function setSwapFee(Swap storage self, uint256 newSwapFee) external {
        require(newSwapFee <= MAX_SWAP_FEE, "Fee is too high");
        self.swapFee = newSwapFee;
    }

    /**
     * @notice update the default withdraw fee. This also affects deposits made in the past as well.
     * @param newWithdrawFee new withdraw fee to be applied
     */
    function setDefaultWithdrawFee(Swap storage self, uint256 newWithdrawFee) external {
        require(newWithdrawFee <= MAX_WITHDRAW_FEE, "Fee is too high");
        self.defaultWithdrawFee = newWithdrawFee;
    }
}
