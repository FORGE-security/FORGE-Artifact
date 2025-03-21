// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.6;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "erc20permit/contracts/ERC20Permit.sol";
import "./IUSM.sol";
import "./Delegable.sol";
import "./WadMath.sol";
import "./FUM.sol";
import "./MinOut.sol";
import "./oracles/Oracle.sol";
// import "@nomiclabs/buidler/console.sol";

/**
 * @title USMTemplate
 * @author Alberto Cuesta Cañada, Jacob Eliosoff, Alex Roan
 * @notice Concept by Jacob Eliosoff (@jacob-eliosoff).
 *
 * This abstract USM contract must be inherited by a concrete implementation, that also adds an Oracle implementation - eg, by
 * also inheriting a concrete Oracle implementation.  See USM (and MockUSM) for an example.
 *
 * We use this inheritance-based design (rather than the more natural, and frankly normally more correct, composition-based design
 * of storing the Oracle here as a variable), because inheriting the Oracle makes all the latestPrice() calls *internal* rather
 * than calls to a separate oracle contract (or multiple contracts) - which leads to a significant saving in gas.
 */
abstract contract USMTemplate is IUSM, Oracle, ERC20Permit, Delegable {
    using Address for address payable;
    using SafeMath for uint;
    using WadMath for uint;

    enum Side {Buy, Sell}

    event MinFumBuyPriceChanged(uint previous, uint latest);
    event BuySellAdjustmentChanged(uint previous, uint latest);

    uint public constant WAD = 10 ** 18;
    uint public constant MAX_DEBT_RATIO = WAD * 8 / 10;                 // 80%
    uint public constant MIN_FUM_BUY_PRICE_HALF_LIFE = 1 days;          // Solidity for 1 * 24 * 60 * 60
    uint public constant BUY_SELL_ADJUSTMENT_HALF_LIFE = 1 minutes;     // Solidity for 1 * 60

    FUM public immutable fum;

    struct TimedValue {
        uint32 timestamp;
        uint224 value;
    }

    TimedValue public minFumBuyPriceStored;
    TimedValue public buySellAdjustmentStored = TimedValue({ timestamp: 0, value: uint224(WAD) });

    constructor() public ERC20Permit("Minimal USD", "USM")
    {
        fum = new FUM(this);
    }

    /** EXTERNAL TRANSACTIONAL FUNCTIONS **/

    /**
     * @notice Mint new USM, sending it to the given address, and only if the amount minted >= minUsmOut.  The amount of ETH is
     * passed in as msg.value.
     * @param to address to send the USM to.
     * @param minUsmOut Minimum accepted USM for a successful mint.
     */
    function mint(address to, uint minUsmOut) external payable override returns (uint usmOut) {
        usmOut = _mintUsm(to, minUsmOut);
    }

    /**
     * @dev Burn USM in exchange for ETH.
     * @param from address to deduct the USM from.
     * @param to address to send the ETH to.
     * @param usmToBurn Amount of USM to burn.
     * @param minEthOut Minimum accepted ETH for a successful burn.
     */
    function burn(address from, address payable to, uint usmToBurn, uint minEthOut)
        external override
        onlyHolderOrDelegate(from, "Only holder or delegate")
        returns (uint ethOut)
    {
        ethOut = _burnUsm(from, to, usmToBurn, minEthOut);
    }

    /**
     * @notice Funds the pool with ETH, minting new FUM and sending it to the given address, but only if the amount minted >=
     * minFumOut.  The amount of ETH is passed in as msg.value.
     * @param to address to send the FUM to.
     * @param minFumOut Minimum accepted FUM for a successful fund.
     */
    function fund(address to, uint minFumOut) external payable override returns (uint fumOut) {
        fumOut = _fundFum(to, minFumOut);
    }

    /**
     * @notice Defunds the pool by redeeming FUM in exchange for equivalent ETH from the pool.
     * @param from address to deduct the FUM from.
     * @param to address to send the ETH to.
     * @param fumToBurn Amount of FUM to burn.
     * @param minEthOut Minimum accepted ETH for a successful defund.
     */
    function defund(address from, address payable to, uint fumToBurn, uint minEthOut)
        external override
        onlyHolderOrDelegate(from, "Only holder or delegate")
        returns (uint ethOut)
    {
        ethOut = _defundFum(from, to, fumToBurn, minEthOut);
    }

    /**
     * @notice Defunds the pool by redeeming FUM from an arbitrary address in exchange for equivalent ETH from the pool.
     * Called only by the FUM contract, when FUM is sent to it.
     * @param from address to deduct the FUM from.
     * @param to address to send the ETH to.
     * @param fumToBurn Amount of FUM to burn.
     * @param minEthOut Minimum accepted ETH for a successful defund.
     */
    function defundFromFUM(address from, address payable to, uint fumToBurn, uint minEthOut)
        external override
        returns (uint ethOut)
    {
        require(msg.sender == address(fum), "Restricted to FUM");
        ethOut = _defundFum(from, to, fumToBurn, minEthOut);
    }

    /**
     * @notice If anyone sends ETH here, assume they intend it as a `mint`.
     * If decimals 8 to 11 (included) of the amount of Ether received are `0000` then the next 7 will
     * be parsed as the minimum Ether price accepted, with 2 digits before and 5 digits after the comma. 
     */
    receive() external payable {
        _mintUsm(msg.sender, MinOut.parseMinTokenOut(msg.value));
    }

    /**
     * @notice If a user sends USM tokens directly to this contract (or to the FUM contract), assume they intend it as a `burn`.
     * If using `transfer`/`transferFrom` as `burn`, and if decimals 8 to 11 (included) of the amount transferred received
     * are `0000` then the next 7 will be parsed as the maximum USM price accepted, with 5 digits before and 2 digits after the comma.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (recipient == address(this) || recipient == address(fum) || recipient == address(0)) {
            _burnUsm(sender, payable(sender), amount, MinOut.parseMinEthOut(amount));
        } else {
            super._transfer(sender, recipient, amount);
        }
    }

    /** INTERNAL TRANSACTIONAL FUNCTIONS */

    function _mintUsm(address to, uint minUsmOut) internal returns (uint usmOut)
    {
        // 1. Check that fund() has been called first - no minting before funding:
        uint rawEthInPool = ethPool();
        uint ethInPool = rawEthInPool.sub(msg.value);   // Backing out the ETH just received, which our calculations should ignore
        require(ethInPool > 0, "Fund before minting");

        // 2. Calculate usmOut:
        uint ethUsmPrice = cacheLatestPrice();
        uint usmTotalSupply = totalSupply();
        uint oldDebtRatio = debtRatio(ethUsmPrice, ethInPool, usmTotalSupply);
        usmOut = usmFromMint(ethUsmPrice, msg.value, ethInPool, usmTotalSupply);
        require(usmOut >= minUsmOut, "Limit not reached");

        // 3. Update buySellAdjustmentStored and mint the user's new USM:
        uint newDebtRatio = debtRatio(ethUsmPrice, rawEthInPool, usmTotalSupply.add(usmOut));
        _updateBuySellAdjustment(oldDebtRatio, newDebtRatio, buySellAdjustment());
        _mint(to, usmOut);
    }

    function _burnUsm(address from, address payable to, uint usmToBurn, uint minEthOut) internal returns (uint ethOut)
    {
        // 1. Calculate ethOut:
        uint ethUsmPrice = cacheLatestPrice();
        uint ethInPool = ethPool();
        uint usmTotalSupply = totalSupply();
        uint oldDebtRatio = debtRatio(ethUsmPrice, ethInPool, usmTotalSupply);
        ethOut = ethFromBurn(ethUsmPrice, usmToBurn, ethInPool, usmTotalSupply);
        require(ethOut >= minEthOut, "Limit not reached");

        // 2. Burn the input USM, update buySellAdjustmentStored, and return the user's ETH:
        uint newDebtRatio = debtRatio(ethUsmPrice, ethInPool.sub(ethOut), usmTotalSupply.sub(usmToBurn));
        require(newDebtRatio <= WAD, "Debt ratio too high");
        _burn(from, usmToBurn);
        _updateBuySellAdjustment(oldDebtRatio, newDebtRatio, buySellAdjustment());
        to.sendValue(ethOut);
    }

    function _fundFum(address to, uint minFumOut) internal returns (uint fumOut)
    {
        // 1. Refresh mfbp:
        uint ethUsmPrice = cacheLatestPrice();
        uint rawEthInPool = ethPool();
        uint ethInPool = rawEthInPool.sub(msg.value);   // Backing out the ETH just received, which our calculations should ignore
        uint usmTotalSupply = totalSupply();
        uint oldDebtRatio = debtRatio(ethUsmPrice, ethInPool, usmTotalSupply);
        uint fumTotalSupply = fum.totalSupply();
        _updateMinFumBuyPrice(oldDebtRatio, ethInPool, fumTotalSupply);

        // 2. Calculate fumOut:
        uint adjustment = buySellAdjustment();
        fumOut = fumFromFund(ethUsmPrice, msg.value, ethInPool, usmTotalSupply, fumTotalSupply, adjustment);
        require(fumOut >= minFumOut, "Limit not reached");

        // 3. Update buySellAdjustmentStored and mint the user's new FUM:
        uint newDebtRatio = debtRatio(ethUsmPrice, rawEthInPool, usmTotalSupply);
        _updateBuySellAdjustment(oldDebtRatio, newDebtRatio, adjustment);
        fum.mint(to, fumOut);
    }

    function _defundFum(address from, address payable to, uint fumToBurn, uint minEthOut) internal returns (uint ethOut)
    {
        // 1. Calculate ethOut:
        uint ethUsmPrice = cacheLatestPrice();
        uint ethInPool = ethPool();
        uint usmTotalSupply = totalSupply();
        uint oldDebtRatio = debtRatio(ethUsmPrice, ethInPool, usmTotalSupply);
        ethOut = ethFromDefund(ethUsmPrice, fumToBurn, ethInPool, usmTotalSupply);
        require(ethOut >= minEthOut, "Limit not reached");

        // 2. Burn the input FUM, update buySellAdjustmentStored, and return the user's ETH:
        uint newDebtRatio = debtRatio(ethUsmPrice, ethInPool.sub(ethOut), usmTotalSupply);
        require(newDebtRatio <= MAX_DEBT_RATIO, "Max debt ratio breach");
        fum.burn(from, fumToBurn);
        _updateBuySellAdjustment(oldDebtRatio, newDebtRatio, buySellAdjustment());
        to.sendValue(ethOut);
    }

    /**
     * @notice Set the min FUM price, based on the current oracle price and debt ratio. Emits a MinFumBuyPriceChanged event.
     * @dev The logic for calculating a new minFumBuyPrice is as follows.  We want to set it to the FUM price, in ETH terms, at
     * which debt ratio was exactly MAX_DEBT_RATIO.  So we can assume:
     *
     *     usmToEth(totalSupply()) / ethPool() = MAX_DEBT_RATIO, or in other words:
     *     usmToEth(totalSupply()) = MAX_DEBT_RATIO * ethPool()
     *
     * And with this assumption, we calculate the FUM price (buffer / FUM qty) like so:
     *
     *     minFumBuyPrice = ethBuffer() / fum.totalSupply()
     *                    = (ethPool() - usmToEth(totalSupply())) / fum.totalSupply()
     *                    = (ethPool() - (MAX_DEBT_RATIO * ethPool())) / fum.totalSupply()
     *                    = (1 - MAX_DEBT_RATIO) * ethPool() / fum.totalSupply()
     */
    function _updateMinFumBuyPrice(uint debtRatio_, uint ethInPool, uint fumTotalSupply) internal {
        uint previous = minFumBuyPriceStored.value;
        if (debtRatio_ <= MAX_DEBT_RATIO) {                 // We've dropped below (or were already below, whatev) max debt ratio
            if (previous != 0) {
                minFumBuyPriceStored.timestamp = 0;         // Clear mfbp
                minFumBuyPriceStored.value = 0;
                emit MinFumBuyPriceChanged(previous, 0);
            }
        } else if (previous == 0) {                         // We were < max debt ratio, but have now crossed above - so set mfbp
            // See reasoning in @dev comment above
            minFumBuyPriceStored.timestamp = uint32(block.timestamp);
            minFumBuyPriceStored.value = uint224((WAD - MAX_DEBT_RATIO).wadMulUp(ethInPool).wadDivUp(fumTotalSupply));
            emit MinFumBuyPriceChanged(previous, minFumBuyPriceStored.value);
        }
    }

    /**
     * @notice Update the buy/sell adjustment factor, as of the current block time, after a price-moving operation.
     * @param oldDebtRatio The debt ratio before the operation (eg, mint()) was done
     * @param newDebtRatio The current, post-op debt ratio
     */
    function _updateBuySellAdjustment(uint oldDebtRatio, uint newDebtRatio, uint oldAdjustment) internal {
        // Skip this if either the old or new debt ratio == 0.  Normally this will only happen on the system's first couple of
        // calls, but in principle it could happen later if every single USM holder burns all their USM.  This seems
        // vanishingly unlikely though if the system gets any uptake at all, and anyway if it does happen it will just mean a
        // couple of skipped updates to the buySellAdjustment - no big deal.
        if (oldDebtRatio != 0 && newDebtRatio != 0) {
            uint previous = buySellAdjustmentStored.value; // Not nec the same as oldAdjustment, because of the time decay!

            // Eg: if a user operation reduced debt ratio from 70% to 50%, it was either a fund() or a burn().  These are both
            // "long-ETH" operations.  So we can take (old / new)**2 = (70% / 50%)**2 = 1.4**2 = 1.96 as the ratio by which to
            // increase buySellAdjustment, which is intended as a measure of "how long-ETH recent user activity has been":
            uint newAdjustment = (oldAdjustment.mul(oldDebtRatio).mul(oldDebtRatio) / newDebtRatio) / newDebtRatio;
            buySellAdjustmentStored.timestamp = uint32(block.timestamp);
            buySellAdjustmentStored.value = uint224(newAdjustment);
            emit BuySellAdjustmentChanged(previous, newAdjustment);
        }
    }

    /** PUBLIC AND INTERNAL VIEW FUNCTIONS **/

    /**
     * @notice Total amount of ETH in the pool (ie, in the contract).
     * @return pool ETH pool
     */
    function ethPool() public view returns (uint pool) {
        pool = address(this).balance;
    }

    /**
     * @notice Calculate the amount of ETH in the buffer.
     * @return buffer ETH buffer
     */
    function ethBuffer(uint ethUsmPrice, uint ethInPool, uint usmTotalSupply, WadMath.Round upOrDown)
        internal pure returns (int buffer)
    {
        // Reverse the input upOrDown, since we're using it for usmToEth(), which will be *subtracted* from ethInPool below:
        WadMath.Round downOrUp = (upOrDown == WadMath.Round.Down ? WadMath.Round.Up : WadMath.Round.Down);
        buffer = int(ethInPool) - int(usmToEth(ethUsmPrice, usmTotalSupply, downOrUp));
        require(buffer <= int(ethInPool), "Underflow error");
    }

    /**
     * @notice Calculate debt ratio for a given eth to USM price: ratio of the outstanding USM (amount of USM in total supply), to
     * the current ETH pool amount.
     * @return ratio Debt ratio
     */
    function debtRatio(uint ethUsmPrice, uint ethInPool, uint usmTotalSupply) internal pure returns (uint ratio) {
        uint ethPoolValueInUsd = ethInPool.wadMulDown(ethUsmPrice);
        ratio = (ethInPool == 0 ? 0 : usmTotalSupply.wadDivUp(ethPoolValueInUsd));
    }

    /**
     * @notice Convert ETH amount to USM using a ETH/USD price.
     * @param ethAmount The amount of ETH to convert
     * @return usmOut The amount of USM
     */
    function ethToUsm(uint ethUsmPrice, uint ethAmount, WadMath.Round upOrDown) internal pure returns (uint usmOut) {
        usmOut = ethAmount.wadMul(ethUsmPrice, upOrDown);
    }

    /**
     * @notice Convert USM amount to ETH using a ETH/USD price.
     * @param usmAmount The amount of USM to convert
     * @return ethOut The amount of ETH
     */
    function usmToEth(uint ethUsmPrice, uint usmAmount, WadMath.Round upOrDown) internal pure returns (uint ethOut) {
        ethOut = usmAmount.wadDiv(ethUsmPrice, upOrDown);
    }

    /**
     * @notice Calculate the *marginal* price of USM (in ETH terms) - that is, of the next unit, before the price start sliding.
     * @return price USM price in ETH terms
     */
    function usmPrice(Side side, uint ethUsmPrice) internal view returns (uint price) {
        WadMath.Round upOrDown = (side == Side.Buy ? WadMath.Round.Up : WadMath.Round.Down);
        price = usmToEth(ethUsmPrice, WAD, upOrDown);

        uint adjustment = buySellAdjustment();
        if ((side == Side.Buy && adjustment < WAD) || (side == Side.Sell && adjustment > WAD)) {
            price = price.wadDiv(adjustment, upOrDown);
        }
    }

    /**
     * @notice Calculate the *marginal* price of FUM (in ETH terms) - that is, of the next unit, before the price start sliding.
     * @return price FUM price in ETH terms
     */
    function fumPrice(Side side, uint ethUsmPrice, uint ethInPool, uint usmTotalSupply, uint fumTotalSupply, uint adjustment)
        internal view returns (uint price)
    {
        WadMath.Round upOrDown = (side == Side.Buy ? WadMath.Round.Up : WadMath.Round.Down);
        if (fumTotalSupply == 0) {
            return usmToEth(ethUsmPrice, WAD, upOrDown);    // if no FUM issued yet, default fumPrice to 1 USD (in ETH terms)
        }
        int buffer = ethBuffer(ethUsmPrice, ethInPool, usmTotalSupply, upOrDown);
        price = (buffer <= 0 ? 0 : uint(buffer).wadDiv(fumTotalSupply, upOrDown));

        if (side == Side.Buy) {
            if (adjustment > WAD) {
                price = price.wadMulUp(adjustment);
            }
            // Floor the buy price at minFumBuyPrice:
            uint mfbp = minFumBuyPrice();
            if (price < mfbp) {
                price = mfbp;
            }
        } else {
            if (adjustment < WAD) {
                price = price.wadMulDown(adjustment);
            }
        }
    }

    /**
     * @notice How much USM a minter currently gets back for ethIn ETH, accounting for adjustment and sliding prices.
     * @param ethIn The amount of ETH passed to mint()
     * @return usmOut The amount of USM to receive in exchange
     */
    function usmFromMint(uint ethUsmPrice, uint ethIn, uint ethQty0, uint usmQty0)
        internal view returns (uint usmOut)
    {
        // Mint USM at a sliding-up USM price (ie, at a sliding-down ETH price).  **BASIC RULE:** anytime debtRatio() changes by
        // factor k (here > 1), ETH price changes by factor 1/k**2 (ie, USM price, in ETH terms, changes by factor k**2).
        // (Earlier versions of this logic scaled ETH price based on change in ethPool(), or change in ethPool()**2: the latter
        // gives simpler math - no cbrt() - but doesn't let mint/burn offset fund/defund, which debtRatio()**2 nicely does.)
        uint usmPrice0 = usmPrice(Side.Buy, ethUsmPrice);
        if (usmQty0 == 0) {
            // No USM in the system, so debtRatio() == 0 which breaks the integral below - skip sliding-prices this time:
            usmOut = ethIn.wadDivDown(usmPrice0);
        } else {
            uint ethQty1 = ethQty0.add(ethIn);

            // Math: this is an integral - sum of all USM minted at a sliding-down ETH price:
            // u - u_0 = ((((e / e_0)**3 - 1) * e_0 / ubp_0 + u_0) * u_0**2)**(1/3) - u_0
            uint integralFirstPart = ethQty1.wadDivDown(ethQty0).wadCubedDown().sub(WAD).mul(ethQty0).div(usmPrice0).add(usmQty0);
            usmOut = integralFirstPart.wadMulDown(usmQty0.wadSquaredDown()).wadCbrtDown().sub(usmQty0);
        }
    }

    /**
     * @notice How much ETH a burner currently gets from burning usmIn USM, accounting for adjustment and sliding prices.
     * @param usmIn The amount of USM passed to burn()
     * @return ethOut The amount of ETH to receive in exchange
     */
    function ethFromBurn(uint ethUsmPrice, uint usmIn, uint ethQty0, uint usmQty0)
        internal view returns (uint ethOut)
    {
        // Burn USM at a sliding-down USM price (ie, a sliding-up ETH price):
        uint usmPrice0 = usmPrice(Side.Sell, ethUsmPrice);
        uint usmQty1 = usmQty0.sub(usmIn);

        // Math: this is an integral - sum of all USM burned at a sliding price.  Follows the same mathematical invariant as
        // above: if debtRatio() *= k (here, k < 1), ETH price *= 1/k**2, ie, USM price in ETH terms *= k**2.
        // e_0 - e = e_0 - (e_0**2 * (e_0 - usp_0 * u_0 * (1 - (u / u_0)**3)))**(1/3)
        uint integralFirstPart = usmPrice0.wadMulDown(usmQty0).wadMulDown(WAD.sub(usmQty1.wadDivUp(usmQty0).wadCubedUp()));
        ethOut = ethQty0.sub(ethQty0.wadSquaredUp().wadMulUp(ethQty0.sub(integralFirstPart)).wadCbrtUp());
    }

    /**
     * @notice How much FUM a funder currently gets back for ethIn ETH, accounting for adjustment and sliding prices.
     * @param ethIn The amount of ETH passed to fund()
     * @return fumOut The amount of FUM to receive in exchange
     */
    function fumFromFund(uint ethUsmPrice, uint ethIn, uint ethQty0, uint usmQty0, uint fumQty0, uint adjustment)
        internal view returns (uint fumOut)
    {
        // Create FUM at a sliding-up FUM price:
        uint fumPrice0 = fumPrice(Side.Buy, ethUsmPrice, ethQty0, usmQty0, fumQty0, adjustment);
        if (usmQty0 == 0) {
            // No USM in the system - skip sliding-prices:
            fumOut = ethIn.wadDivDown(fumPrice0);
        } else {
            // Math: f - f_0 = e_0 * (e - e_0) / (e * fbp_0)
            uint ethQty1 = ethQty0.add(ethIn);
            fumOut = ethQty0.mul(ethIn).div(ethQty1.wadMulUp(fumPrice0));
        }
    }

    /**
     * @notice How much ETH a defunder currently gets back for fumIn FUM, accounting for adjustment and sliding prices.
     * @param fumIn The amount of FUM passed to defund()
     * @return ethOut The amount of ETH to receive in exchange
     */
    function ethFromDefund(uint ethUsmPrice, uint fumIn, uint ethQty0, uint usmQty0)
        internal view returns (uint ethOut)
    {
        // Burn FUM at a sliding-down FUM price:
        uint fumQty0 = fum.totalSupply();
        uint fumPrice0 = fumPrice(Side.Sell, ethUsmPrice, ethQty0, usmQty0, fumQty0, buySellAdjustment());
        if (usmQty0 == 0) {
            // No USM in the system - skip sliding-prices:
            ethOut = fumIn.wadMulDown(fumPrice0);
        } else {
            // Math: e_0 - e = e_0 * (f_0 - f) * fsp_0 / (e_0 + (f_0 - f) * fsp_0)
            ethOut = ethQty0.mul(fumIn.wadMulDown(fumPrice0)).div(ethQty0.add(fumIn.wadMulUp(fumPrice0)));
        }
    }

    /**
     * @notice The current min FUM buy price, equal to the stored value decayed by time since minFumBuyPriceTimestamp.
     * @return mfbp The minFumBuyPrice, in ETH terms
     */
    function minFumBuyPrice() public view returns (uint mfbp) {
        if (minFumBuyPriceStored.value != 0) {
            uint numHalvings = block.timestamp.sub(minFumBuyPriceStored.timestamp).wadDivDown(MIN_FUM_BUY_PRICE_HALF_LIFE);
            uint decayFactor = numHalvings.wadHalfExp();
            mfbp = uint256(minFumBuyPriceStored.value).wadMulUp(decayFactor);
        }   // Otherwise just returns 0
    }

    /**
     * @notice The current buy/sell adjustment, equal to the stored value decayed by time since buySellAdjustmentTimestamp.  This
     * adjustment is intended as a measure of "how long-ETH recent user activity has been", so that we can slide price
     * accordingly: if recent activity was mostly long-ETH (fund() and burn()), raise FUM buy price/reduce USM sell price; if
     * recent activity was short-ETH (defund() and mint()), reduce FUM sell price/raise USM buy price.  We use "it reduced debt
     * ratio" as a rough proxy for "the operation was long-ETH".
     *
     * (There is one odd case: when debt ratio > 100%, a *short*-ETH mint() will actually reduce debt ratio.  This does no real
     * harm except to make fast-succession mint()s and fund()s in such > 100% cases a little more expensive than they would be.)
     *
     * @return adjustment The sliding-price buy/sell adjustment
     */
    function buySellAdjustment() public view returns (uint adjustment) {
        uint numHalvings = block.timestamp.sub(buySellAdjustmentStored.timestamp).wadDivDown(BUY_SELL_ADJUSTMENT_HALF_LIFE);
        uint decayFactor = numHalvings.wadHalfExp(10);
        // Here we use the idea that for any b and 0 <= p <= 1, we can crudely approximate b**p by 1 + (b-1)p = 1 + bp - p.
        // Eg: 0.6**0.5 pulls 0.6 "about halfway" to 1 (0.8); 0.6**0.25 pulls 0.6 "about 3/4 of the way" to 1 (0.9).
        // So b**p =~ b + (1-p)(1-b) = b + 1 - b - p + bp = 1 + bp - p.
        // (Don't calculate it as 1 + (b-1)p because we're using uints, b-1 can be negative!)
        adjustment = WAD.add(uint256(buySellAdjustmentStored.value).wadMulDown(decayFactor)).sub(decayFactor);
    }

    /** EXTERNAL VIEW FUNCTIONS */

    /**
     * @notice Calculate the amount of ETH in the buffer.
     * @return buffer ETH buffer
     */
    function ethBuffer(WadMath.Round upOrDown) external view returns (int buffer) {
        buffer = ethBuffer(latestPrice(), ethPool(), totalSupply(), upOrDown);
    }

    /**
     * @notice Convert ETH amount to USM using the latest oracle ETH/USD price.
     * @param ethAmount The amount of ETH to convert
     * @return usmOut The amount of USM
     */
    function ethToUsm(uint ethAmount, WadMath.Round upOrDown) external view returns (uint usmOut) {
        usmOut = ethToUsm(latestPrice(), ethAmount, upOrDown);
    }

    /**
     * @notice Convert USM amount to ETH using the latest oracle ETH/USD price.
     * @param usmAmount The amount of USM to convert
     * @return ethOut The amount of ETH
     */
    function usmToEth(uint usmAmount, WadMath.Round upOrDown) external view returns (uint ethOut) {
        ethOut = usmToEth(latestPrice(), usmAmount, upOrDown);
    }

    /**
     * @notice Calculate debt ratio.
     * @return ratio Debt ratio
     */
    function debtRatio() external view returns (uint ratio) {
        ratio = debtRatio(latestPrice(), ethPool(), totalSupply());
    }

    /**
     * @notice Calculate the *marginal* price of USM (in ETH terms) - that is, of the next unit, before the price start sliding.
     * @return price USM price in ETH terms
     */
    function usmPrice(Side side) external view returns (uint price) {
        price = usmPrice(side, latestPrice());
    }

    /**
     * @notice Calculate the *marginal* price of FUM (in ETH terms) - that is, of the next unit, before the price start sliding.
     * @return price FUM price in ETH terms
     */
    function fumPrice(Side side) external view returns (uint price) {
        price = fumPrice(side, latestPrice(), ethPool(), totalSupply(), fum.totalSupply(), buySellAdjustment());
    }
}
