contract StratVLEV is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    bool public wantIsWBNB = false;
    address public wantAddress;
    address public vTokenAddress;
    address[] public venusMarkets;
    address public uniRouterAddress;

    address public constant wbnbAddress =
        0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant venusAddress =
        0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63;
    address public constant earnedAddress = venusAddress;
    address public constant venusDistributionAddress =
        0xfD36E2c2a6789Db23113685031d7F16329158384;

    address public crudeFarmAddress;
    address public CRUDEAddress;
    address public govAddress; // timelock contract

    uint256 public sharesTotal = 0;
    uint256 public lastEarnBlock = 0;

    uint256 public controllerFee = 20;
    uint256 public constant controllerFeeMax = 10000; // 100 = 1%
    uint256 public constant controllerFeeUL = 300; // 3% upperlimit

    uint256 public buyBackRate = 200;
    uint256 public constant buyBackRateMax = 10000; // 100 = 1%
    uint256 public constant buyBackRateUL = 800; // 8% upperlimit
    address public constant buyBackAddress =
        0x000000000000000000000000000000000000dEaD;
    uint256 public entranceFeeFactor = 9993; // < 0.1% entrance fee - goes to pool + prevents front-running
    uint256 public constant entranceFeeFactorMax = 10000;
    uint256 public constant entranceFeeFactorLL = 9950; // 0.5% is the max entrance fee settable. LL = lowerlimit

    address[] public venusToWantPath;
    address[] public earnedToCRUDEPath;

    /**
     * @dev Variables that can be changed to config profitability and risk:
     * {borrowRate}          - What % of our collateral do we borrow per leverage level.
     * {borrowDepth}         - How many levels of leverage do we take.
     * {BORROW_RATE_MAX}     - A limit on how much we can push borrow risk.
     * {BORROW_DEPTH_MAX}    - A limit on how many steps we can leverage.
     */
    uint256 public borrowRate = 585;
    uint256 public borrowDepth = 3;
    uint256 public constant BORROW_RATE_MAX = 595;
    uint256 public constant BORROW_RATE_MAX_HARD = 599;
    uint256 public constant BORROW_DEPTH_MAX = 6;
    bool onlyGov = true;

    uint256 public supplyBal = 0; // Cached want supplied to venus
    uint256 public borrowBal = 0; // Cached want borrowed from venus
    uint256 public supplyBalTargeted = 0; // Cached targetted want supplied to venus to achieve desired leverage
    uint256 public supplyBalMin = 0;
    /**
     * @dev Events that the contract emits
     */
    event StratRebalance(uint256 _borrowRate, uint256 _borrowDepth);

    modifier onlyGovAddress(){
          require(msg.sender == govAddress, "!Allowed");_;
    }
    function setData(
        address _govAddress,
        address _crudeFarmAddress,
        address _CRUDEAddress,
        address _wantAddress,
        address _vTokenAddress,
        address _uniRouterAddress
    ) external onlyOwner {
        govAddress = _govAddress;
        crudeFarmAddress = _crudeFarmAddress;
        CRUDEAddress = _CRUDEAddress;

        wantAddress = _wantAddress;
        if (wantAddress == wbnbAddress) {
            wantIsWBNB = true;
            venusToWantPath = [venusAddress, wbnbAddress];
        } else {
            venusToWantPath = [venusAddress, wbnbAddress, wantAddress];
            // if (venusAddress == wantAddress) {}      // Then venusToWantPath will never be used.
        }

        earnedToCRUDEPath = [venusAddress, wbnbAddress, CRUDEAddress];
        // if (wbnbAddress == venusAddress) {}      // Not possible

        vTokenAddress = _vTokenAddress;
        venusMarkets = [vTokenAddress];
        uniRouterAddress = _uniRouterAddress;

        transferOwnership(crudeFarmAddress);

        IERC20(venusAddress).safeApprove(uniRouterAddress, uint256(-1));
        IERC20(wantAddress).safeApprove(uniRouterAddress, uint256(-1));
        if (!wantIsWBNB) {
            IERC20(wantAddress).safeApprove(vTokenAddress, uint256(-1));
        }

        IVenusDistribution(venusDistributionAddress).enterMarkets(venusMarkets);
    }

    function _supply(uint256 _amount) internal {
        if (wantIsWBNB) {
            IVBNB(vTokenAddress).mint{value: _amount}();
        } else {
            IVToken(vTokenAddress).mint(_amount);
        }
    }

    function _removeSupply(uint256 _amount) internal {
        IVToken(vTokenAddress).redeemUnderlying(_amount);
    }

    function _borrow(uint256 _amount) internal {
        IVToken(vTokenAddress).borrow(_amount);
    }

    function _repayBorrow(uint256 _amount) internal {
        if (wantIsWBNB) {
            IVBNB(vTokenAddress).repayBorrow{value: _amount}();
        } else {
            IVToken(vTokenAddress).repayBorrow(_amount);
        }
    }

    function deposit(address _userAddress, uint256 _wantAmt)
        public
        onlyOwner
        nonReentrant
        whenNotPaused
        returns (uint256)
    {
        updateBalance();

        uint256 sharesAdded = _wantAmt;
        if (wantLockedTotal() > 0 && sharesTotal > 0) {
            sharesAdded = _wantAmt
                .mul(sharesTotal)
                .mul(entranceFeeFactor)
                .div(wantLockedTotal())
                .div(entranceFeeFactorMax);
        }

        sharesTotal = sharesTotal.add(sharesAdded);

        IERC20(wantAddress).safeTransferFrom(
            address(msg.sender),
            address(this),
            _wantAmt
        );

        _farm(true);

        return sharesAdded;
    }

    function farm(bool _withLev) public nonReentrant {
        _farm(_withLev);
    }

    function _farm(bool _withLev) internal {
        if (wantIsWBNB) {
            _unwrapBNB(); // WBNB -> BNB. Venus accepts BNB, not WBNB.
            _leverage(address(this).balance, _withLev);
        } else {
            _leverage(wantLockedInHere(), _withLev);
        }

        updateBalance();

        deleverageUntilNotOverLevered(); // It is possible to still be over-levered after depositing.
    }

    /**
     * @dev Repeatedly supplies and borrows bnb following the configured {borrowRate} and {borrowDepth}
     * into the vToken contract.
     */
    function _leverage(uint256 _amount, bool _withLev) internal {
        if (_withLev) {
            for (uint256 i = 0; i < borrowDepth; i++) {
                _supply(_amount);
                _amount = _amount.mul(borrowRate).div(1000);
                _borrow(_amount);
            }
        }

        _supply(_amount); // Supply remaining want that was last borrowed.
    }

    /**
     * @dev Redeem to the desired leverage amount, then use it to repay borrow.
     * If already over leverage, redeem max amt redeemable, then use it to repay borrow.
     */
    function deleverageOnce() public {
        if (onlyGov) {
            require(msg.sender == govAddress, "!Allowed");
        }

        updateBalance(); // Updates borrowBal & supplyBal & supplyBalTargeted & supplyBalMin

        if (supplyBal <= supplyBalTargeted) {
            _removeSupply(supplyBal.sub(supplyBalMin));
        } else {
            _removeSupply(supplyBal.sub(supplyBalTargeted));
        }

        if (wantIsWBNB) {
            _unwrapBNB(); // WBNB -> BNB
            _repayBorrow(address(this).balance);
        } else {
            _repayBorrow(wantLockedInHere());
        }

        updateBalance(); // Updates borrowBal & supplyBal & supplyBalTargeted & supplyBalMin
    }

    /**
     * @dev Redeem the max possible, use it to repay borrow
     */
    function deleverageUntilNotOverLevered() public {
        // updateBalance(); // To be more accurate, call updateBalance() first to cater for changes due to interest rates

        // If borrowRate slips below targetted borrowRate, withdraw the max amt first.
        // Further actual deleveraging will take place later on.
        // (This can happen in when net interest rate < 0, and supplied balance falls below targeted.)
        while (supplyBal > 0 && supplyBal <= supplyBalTargeted) {
            deleverageOnce();
        }
    }

    /**
     * @dev Incrementally alternates between paying part of the debt and withdrawing part of the supplied
     * collateral. Continues to do this untill all want tokens is withdrawn. For partial deleveraging,
     * this continues until at least _minAmt of want tokens is reached.
     */

    function _deleverage(bool _delevPartial, uint256 _minAmt) internal {
        updateBalance(); // Updates borrowBal & supplyBal & supplyBalTargeted & supplyBalMin

        deleverageUntilNotOverLevered();

        if (wantIsWBNB) {
            _wrapBNB(); // WBNB -> BNB
        }

        _removeSupply(supplyBal.sub(supplyBalMin));

        uint256 wantBal = wantLockedInHere();

        // Recursively repay borrowed + remove more from supplied
        while (wantBal < borrowBal) {
            // If only partially deleveraging, when sufficiently deleveraged, do not repay anymore
            if (_delevPartial && wantBal >= _minAmt) {
                return;
            }

            _repayBorrow(wantBal);

            updateBalance(); // Updates borrowBal & supplyBal & supplyBalTargeted & supplyBalMin

            _removeSupply(supplyBal.sub(supplyBalMin));

            wantBal = wantLockedInHere();
        }

        // If only partially deleveraging, when sufficiently deleveraged, do not repay
        if (_delevPartial && wantBal >= _minAmt) {
            return;
        }

        // Make a final repayment of borrowed
        _repayBorrow(borrowBal);

        // remove all supplied
        uint256 vTokenBal = IERC20(vTokenAddress).balanceOf(address(this));
        IVToken(vTokenAddress).redeem(vTokenBal);
    }

    /**
     * @dev Updates the risk profile and rebalances the vault funds accordingly.
     * @param _borrowRate percent to borrow on each leverage level.
     * @param _borrowDepth how many levels to leverage the funds.
     */
    function rebalance(uint256 _borrowRate, uint256 _borrowDepth) external onlyGovAddress {
        require(_borrowRate <= BORROW_RATE_MAX, "!rate");
        require(_borrowDepth <= BORROW_DEPTH_MAX, "!depth");

        _deleverage(false, uint256(-1)); // deleverage all supplied want tokens
        borrowRate = _borrowRate;
        borrowDepth = _borrowDepth;
        _farm(true);
    }

    function earn() external whenNotPaused {
        if (onlyGov) {
            require(msg.sender == govAddress, "!Allowed");
        }

        IVenusDistribution(venusDistributionAddress).claimVenus(address(this));

        uint256 earnedAmt = IERC20(venusAddress).balanceOf(address(this));

        earnedAmt = distributeFees(earnedAmt);
    
        earnedAmt = buyBack(earnedAmt);
        
        if (venusAddress != wantAddress) {
            IPancakeRouter02(uniRouterAddress).swapExactTokensForTokens(
                earnedAmt,
                0,
                venusToWantPath,
                address(this),
                now.add(600)
            );
        }

        lastEarnBlock = block.number;

        _farm(false); // Supply wantToken without leverage, to cater for net -ve interest rates.
    }

    function buyBack(uint256 _earnedAmt) internal returns (uint256) {
        if (buyBackRate <= 0) {
            return _earnedAmt;
        }

        uint256 buyBackAmt = _earnedAmt.mul(buyBackRate).div(buyBackRateMax);

        IPancakeRouter02(uniRouterAddress).swapExactTokensForTokens(
            buyBackAmt,
            0,
            earnedToCRUDEPath,
            address(this),
            now + 600
        );

        // Burn CRUDE tokens
        uint256 burnAmt = IERC20(CRUDEAddress).balanceOf(address(this));
        IERC20(CRUDEAddress).safeTransfer(buyBackAddress, burnAmt.div(2));
        return _earnedAmt.sub(buyBackAmt);
    }

    function distributeFees(uint256 _earnedAmt) internal returns (uint256) {
        if (_earnedAmt > 0) {
            if (controllerFee > 0) {
                uint256 fee =
                    _earnedAmt.mul(controllerFee).div(controllerFeeMax);
                IERC20(venusAddress).safeTransfer(govAddress, fee);
                return _earnedAmt.sub(fee);
            }
        }

        return _earnedAmt;
    }

    function withdraw(address _userAddress, uint256 _wantAmt)
        external
        onlyOwner
        nonReentrant
        returns (uint256)
    {
        uint256 sharesRemoved =
            _wantAmt.mul(sharesTotal).div(wantLockedTotal());
        if (sharesRemoved > sharesTotal) {
            sharesRemoved = sharesTotal;
        }
        sharesTotal = sharesTotal.sub(sharesRemoved);

        uint256 wantBal = IERC20(wantAddress).balanceOf(address(this));
        if (wantBal < _wantAmt) {
            _deleverage(true, _wantAmt.sub(wantBal));
            if (wantIsWBNB) {
                _wrapBNB(); // wrap BNB -> WBNB before sending it back to user
            }
            wantBal = IERC20(wantAddress).balanceOf(address(this));
        }

        if (wantBal < _wantAmt) {
            _wantAmt = wantBal;
        }

        IERC20(wantAddress).safeTransfer(crudeFarmAddress, _wantAmt);

        _farm(true);

        return sharesRemoved;
    }

    /**
     * @dev Pauses the strat.
     */
    function pause() public onlyGovAddress {
        _pause();

        IERC20(venusAddress).safeApprove(uniRouterAddress, 0);
        IERC20(wantAddress).safeApprove(uniRouterAddress, 0);
        if (!wantIsWBNB) {
            IERC20(wantAddress).safeApprove(vTokenAddress, 0);
        }
    }

    /**
     * @dev Unpauses the strat.
     */
    function unpause() external onlyGovAddress {
        _unpause();

        IERC20(venusAddress).safeApprove(uniRouterAddress, uint256(-1));
        IERC20(wantAddress).safeApprove(uniRouterAddress, uint256(-1));
        if (!wantIsWBNB) {
            IERC20(wantAddress).safeApprove(vTokenAddress, 0);
        }
    }

    /**
     * @dev Updates want locked in Venus after interest is accrued to this very block.
     * To be called before sensitive operations.
     */
    function updateBalance() public {
        supplyBal = IVToken(vTokenAddress).balanceOfUnderlying(address(this)); // a payable function because of acrueInterest()
        borrowBal = IVToken(vTokenAddress).borrowBalanceCurrent(address(this));
        supplyBalTargeted = borrowBal.mul(1000).div(borrowRate);
        supplyBalMin = borrowBal.mul(1000).div(BORROW_RATE_MAX_HARD);
    }

    function wantLockedTotal() public view returns (uint256) {
        return wantLockedInHere().add(supplyBal).sub(borrowBal);
    }

    function wantLockedInHere() public view returns (uint256) {
        uint256 wantBal = IERC20(wantAddress).balanceOf(address(this));
        if (wantIsWBNB) {
            uint256 bnbBal = address(this).balance;
            return bnbBal.add(wantBal);
        } else {
            return wantBal;
        }
    }


    function setFeesRates(uint256 _entranceFeeFactor,uint256 _controllerFee,uint256 _buyBackRate)external onlyGovAddress{
    require(_entranceFeeFactor > entranceFeeFactorLL, "too low");
    require(_entranceFeeFactor <= entranceFeeFactorMax, "too high");
    require(_controllerFee <= controllerFeeUL, "too high");
    require(buyBackRate <= buyBackRateUL, "too high");
    entranceFeeFactor = _entranceFeeFactor;
    controllerFee = _controllerFee;
    buyBackRate = _buyBackRate;
    }
/*
    function setEntranceFeeFactor(uint256 _entranceFeeFactor) public {
        require(msg.sender == govAddress, "!Allowed");
        require(_entranceFeeFactor > entranceFeeFactorLL, "too low");
        require(_entranceFeeFactor <= entranceFeeFactorMax, "too high");
        entranceFeeFactor = _entranceFeeFactor;
    }

    function setControllerFee(uint256 _controllerFee) public {
        require(msg.sender == govAddress, "!Allowed");
        require(_controllerFee <= controllerFeeUL, "too high");
        controllerFee = _controllerFee;
    }

    function setbuyBackRate(uint256 _buyBackRate) public {
        require(msg.sender == govAddress, "!Allowed");
        require(buyBackRate <= buyBackRateUL, "too high");
        buyBackRate = _buyBackRate;
    }
*/
function govChanges(address _govAddress, bool _onlyGov) external onlyGovAddress{
    govAddress = _govAddress;
    onlyGov = _onlyGov;
}

/*
    function setGov(address _govAddress) public onlyGovAddress {
        govAddress = _govAddress;
    }

    function setOnlyGov(bool _onlyGov) public onlyGovAddress{
        onlyGov = _onlyGov;
    }
*/

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) public onlyGovAddress {
        require(_token != earnedAddress, "!safe");
        require(_token != wantAddress, "!safe");
        require(_token != vTokenAddress, "!safe");
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function _wrapBNB() internal {
        // BNB -> WBNB
        uint256 bnbBal = address(this).balance;
        if (bnbBal > 0) {
            IWBNB(wbnbAddress).deposit{value: bnbBal}(); // BNB -> WBNB
        }
    }

    function _unwrapBNB() internal {
        // WBNB -> BNB
        uint256 wbnbBal = IERC20(wbnbAddress).balanceOf(address(this));
        if (wbnbBal > 0) {
            IWBNB(wbnbAddress).withdraw(wbnbBal);
        }
    }

    /**
     * @dev We should not have significant amts of BNB in this contract if any at all.
     * In case we do (eg. Venus returns all users' BNB to this contract or for any other reason),
     * We can wrap all BNB, allowing users to withdraw() as per normal.
     */
    function wrapBNB() public onlyGovAddress{
        require(wantIsWBNB, "!wantIsWBNB");
        _wrapBNB();
    }

    receive() external payable {}
}