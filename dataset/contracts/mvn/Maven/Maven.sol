// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IFactoryV2 {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
}

interface IV2Pair {
    function factory() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function sync() external;
}

interface IRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, uint deadline
    ) external payable returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IRouter02 is IRouter01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface AntiSnipe {
    function checkUser(address from, address to, uint256 amt) external returns (bool);
    function setLaunch(address _initialLpPair, uint32 _liqAddBlock, uint64 _liqAddStamp, uint8 dec) external;
    function setLpPair(address pair, bool enabled) external;
    function setProtections(bool _as, bool _ab) external;
    function removeSniper(address account) external;
    function removeBlacklisted(address account) external;
    function isBlacklisted(address account) external view returns (bool);
    function setBlacklistEnabled(address account, bool enabled) external;
    function setBlacklistEnabledMultiple(address[] memory accounts, bool enabled) external;
    function setBlockTXDelay(uint256 delay) external;
}

contract Maven is IERC20 {
    // Ownership moved to in-contract for customizability.
    address private _owner;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) lpPairs;
    uint256 private timeSinceLastPair = 0;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _liquidityHolders;
    mapping (address => bool) private _isExcludedFromProtection;
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedFromLimits;

    mapping (address => bool) private presaleAddresses;
    bool private allowedPresaleExclusion = true;
   
    uint256 constant private startingSupply = 1_000_000_000;

    string constant private _name = "Maven";
    string constant private _symbol = "MVN";
    uint8 constant private _decimals = 18;
    uint256 constant private _tTotal = startingSupply * 10**_decimals;

    struct Fees {
        uint16 buyFee;
        uint16 sellFee;
        uint16 sellHighTxFee;
        uint16 transferFee;
    }

    struct Ratios {
        uint16 team;
        uint16 developmentPromos;
        uint16 totalSwap;
    }

    Fees public _taxRates = Fees({
        buyFee: 400,
        sellFee: 700,
        sellHighTxFee: 1000,
        transferFee: 1000
    });

    Ratios public _ratios = Ratios({
        team: 300,
        developmentPromos: 800,
        totalSwap: 1100
    });

    uint256 constant public maxBuyTaxes = 1500;
    uint256 constant public maxSellTaxes = 1500;
    uint256 constant public maxTransferTaxes = 1500;
    uint256 constant public maxRoundtripTax = 2000;
    uint256 constant masterTaxDivisor = 10000;

    IRouter02 public dexRouter;
    address public lpPair;
    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;

    struct TaxWallets {
        address payable team;
        address payable developmentPromos;
    }

    TaxWallets public _taxWallets = TaxWallets({
        team: payable(0x8dFA22A351d294eFE8901ea4aF70A58D7E70A17b),
        developmentPromos: payable(0x08d8bCAcb0D034861DB370E0c77B7a0e3DeC60Fc)
    });
    
    bool inSwap;
    bool public contractSwapEnabled = false;
    uint256 public swapThreshold;
    uint256 public swapAmount;
    bool public piContractSwapsEnabled;
    uint256 public piSwapPercent;
    
    uint256 private _maxTxAmountBuy = (_tTotal * 5) / 1000;
    uint256 private _maxTxAmountSell = (_tTotal * 5) / 1000;
    uint256 private _maxWalletSize = (_tTotal * 1) / 100;
    uint256 private _highTaxSize = (_tTotal * 25) / 10000;

    struct BurnXHolderValues {
        bool enabled;
        uint256 sellStamp;
        uint256 soldAmount;
    }

    mapping (address => BurnXHolderValues) burnXHolders;
    uint256 private burnXLimit = (_tTotal * 36) / 100000;
    uint256 public burnXTimer = 1 days;

    bool public tradingEnabled = false;
    bool public _hasLiqBeenAdded = false;
    AntiSnipe antiSnipe;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ContractSwapEnabledUpdated(bool enabled);
    event AutoLiquify(uint256 amountCurrency, uint256 amountTokens);
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Caller =/= owner.");
        _;
    }

    constructor () payable {
        _tOwned[msg.sender] = _tTotal;
        emit Transfer(address(0), msg.sender, _tTotal);

        // Set the owner.
        _owner = msg.sender;

        if (block.chainid == 56) {
            dexRouter = IRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        } else if (block.chainid == 97) {
            dexRouter = IRouter02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        } else if (block.chainid == 1 || block.chainid == 4 || block.chainid == 3) {
            dexRouter = IRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
            //Ropstein DAI 0xaD6D458402F60fD3Bd25163575031ACDce07538D
        } else if (block.chainid == 43114) {
            dexRouter = IRouter02(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
        } else if (block.chainid == 250) {
            dexRouter = IRouter02(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
        } else {
            revert();
        }

        lpPair = IFactoryV2(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        lpPairs[lpPair] = true;

        _approve(_owner, address(dexRouter), type(uint256).max);
        _approve(address(this), address(dexRouter), type(uint256).max);

        _isExcludedFromFees[_owner] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD] = true;
        _liquidityHolders[_owner] = true;
    }

    receive() external payable {}

//===============================================================================================================
//===============================================================================================================
//===============================================================================================================
    // Ownable removed as a lib and added here to allow for custom transfers and renouncements.
    // This allows for removal of ownership privileges from the owner once renounced or transferred.
    function transferOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Call renounceOwnership to transfer owner to the zero address.");
        require(newOwner != DEAD, "Call renounceOwnership to transfer owner to the zero address.");
        setExcludedFromFees(_owner, false);
        setExcludedFromFees(newOwner, true);
        
        if(balanceOf(_owner) > 0) {
            finalizeTransfer(_owner, newOwner, balanceOf(_owner), false, false, true);
        }
        
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
        
    }

    function renounceOwnership() external onlyOwner {
        setExcludedFromFees(_owner, false);
        address oldOwner = _owner;
        _owner = address(0);
        emit OwnershipTransferred(oldOwner, address(0));
    }
//===============================================================================================================
//===============================================================================================================
//===============================================================================================================

    function totalSupply() external pure override returns (uint256) { if (_tTotal == 0) { revert(); } return _tTotal; }
    function decimals() external pure override returns (uint8) { if (_tTotal == 0) { revert(); } return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return _owner; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) internal {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function approveContractContingency() external onlyOwner returns (bool) {
        _approve(address(this), address(dexRouter), type(uint256).max);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }

        return _transfer(sender, recipient, amount);
    }

    function setNewRouter(address newRouter) external onlyOwner {
        IRouter02 _newRouter = IRouter02(newRouter);
        address get_pair = IFactoryV2(_newRouter.factory()).getPair(address(this), _newRouter.WETH());
        if (get_pair == address(0)) {
            lpPair = IFactoryV2(_newRouter.factory()).createPair(address(this), _newRouter.WETH());
        }
        else {
            lpPair = get_pair;
        }
        dexRouter = _newRouter;
        _approve(address(this), address(dexRouter), type(uint256).max);
    }

    function setLpPair(address pair, bool enabled) external onlyOwner {
        if (!enabled) {
            lpPairs[pair] = false;
            antiSnipe.setLpPair(pair, false);
        } else {
            if (timeSinceLastPair != 0) {
                require(block.timestamp - timeSinceLastPair > 3 days, "3 Day cooldown.!");
            }
            lpPairs[pair] = true;
            timeSinceLastPair = block.timestamp;
            antiSnipe.setLpPair(pair, true);
        }
    }

    function setInitializer(address initializer) external onlyOwner {
        require(!tradingEnabled);
        require(initializer != address(this), "Can't be self.");
        antiSnipe = AntiSnipe(initializer);
    }

    function isExcludedFromLimits(address account) external view returns (bool) {
        return _isExcludedFromLimits[account];
    }

    function isExcludedFromFees(address account) external view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function isExcludedFromProtection(address account) external view returns (bool) {
        return _isExcludedFromProtection[account];
    }

    function setExcludedFromLimits(address account, bool enabled) external onlyOwner {
        _isExcludedFromLimits[account] = enabled;
    }

    function setExcludedFromFees(address account, bool enabled) public onlyOwner {
        _isExcludedFromFees[account] = enabled;
    }

    function setExcludedFromProtection(address account, bool enabled) external onlyOwner {
        _isExcludedFromProtection[account] = enabled;
    }

//================================================ BLACKLIST

    function setBlacklistEnabled(address account, bool enabled) external onlyOwner {
        antiSnipe.setBlacklistEnabled(account, enabled);
    }

    function setBlacklistEnabledMultiple(address[] memory accounts, bool enabled) external onlyOwner {
        antiSnipe.setBlacklistEnabledMultiple(accounts, enabled);
    }

    function isBlacklisted(address account) external view returns (bool) {
        return antiSnipe.isBlacklisted(account);
    }

    function removeSniper(address account) external onlyOwner {
        antiSnipe.removeSniper(account);
    }

    function setProtectionSettings(bool _antiSnipe, bool _antiBlock) external onlyOwner {
        antiSnipe.setProtections(_antiSnipe, _antiBlock);
    }

    function setBlockTXDelay(uint256 delay) external onlyOwner {
        require(delay <= 30, "Cannot exceed 30 blocks.");
        antiSnipe.setBlockTXDelay(delay);
    }

    function setTaxes(uint16 buyFee, uint16 sellFee, uint16 sellHighTxFee, uint16 transferFee) external onlyOwner {
        require(buyFee <= maxBuyTaxes
                && sellFee <= maxSellTaxes
                && transferFee <= maxTransferTaxes
                && sellHighTxFee <= maxSellTaxes,
                "Cannot exceed maximums.");
        require(buyFee + sellFee <= maxRoundtripTax && buyFee + sellHighTxFee <= maxRoundtripTax, "Cannot exceed roundtrip maximum.");
        _taxRates.buyFee = buyFee;
        _taxRates.sellFee = sellFee;
        _taxRates.sellHighTxFee = sellHighTxFee;
        _taxRates.transferFee = transferFee;
    }

    function setRatios(uint16 team, uint16 developmentPromos) external onlyOwner {
        _ratios.team = team;
        _ratios.developmentPromos = developmentPromos;
        _ratios.totalSwap = team + developmentPromos;
        uint256 total = _taxRates.buyFee + _taxRates.sellFee;
        require(_ratios.totalSwap <= total, "Cannot exceed sum of buy and sell fees.");
    }

    function setWallets(address payable developmentPromos, address payable team) external onlyOwner {
        _taxWallets.developmentPromos = payable(developmentPromos);
        _taxWallets.team = payable(team);
    }


    function setMaxTxPercents(uint256 percentBuy, uint256 divisorBuy, uint256 percentSell, uint256 divisorSell) external onlyOwner {
        require((_tTotal * percentBuy) / divisorBuy >= (_tTotal / 1000), "Max Transaction amt must be above 0.1% of total supply.");
        require((_tTotal * percentSell) / divisorSell >= (_tTotal / 1000), "Max Transaction amt must be above 0.1% of total supply.");
        _maxTxAmountBuy = (_tTotal * percentBuy) / divisorBuy;
        _maxTxAmountSell = (_tTotal * percentSell) / divisorSell;
    }

    function setMaxWalletSize(uint256 percent, uint256 divisor) external onlyOwner {
        require((_tTotal * percent) / divisor >= (_tTotal / 100), "Max Wallet amt must be above 1% of total supply.");
        _maxWalletSize = (_tTotal * percent) / divisor;
    }

    function getMaxTX() external view returns (uint256 buy, uint256 sell) {
        return (_maxTxAmountBuy / (10**_decimals), _maxTxAmountSell / (10**_decimals));
    }

    function getMaxWallet() external view returns (uint256) {
        return _maxWalletSize / (10**_decimals);
    }

    function setSwapSettings(uint256 thresholdPercent, uint256 thresholdDivisor, uint256 amountPercent, uint256 amountDivisor) external onlyOwner {
        swapThreshold = (_tTotal * thresholdPercent) / thresholdDivisor;
        swapAmount = (_tTotal * amountPercent) / amountDivisor;
        require(swapThreshold <= swapAmount, "Threshold cannot be above amount.");
    }

    function setPriceImpactSwapAmount(uint256 priceImpactSwapPercent) external onlyOwner {
        require(priceImpactSwapPercent <= 200, "Cannot set above 2%.");
        piSwapPercent = priceImpactSwapPercent;
    }

    function setContractSwapEnabled(bool swapEnabled, bool priceImpactSwapEnabled) external onlyOwner {
        contractSwapEnabled = swapEnabled;
        piContractSwapsEnabled = priceImpactSwapEnabled;
        emit ContractSwapEnabledUpdated(swapEnabled);
    }

    function setHigherTaxSize(uint256 percent, uint256 divisor) external onlyOwner {
        require((_tTotal * percent) / divisor >= ((_tTotal * 25) / 10000), "Higher tax TX size must be above 0.25%.");
        _highTaxSize = (_tTotal * percent) / divisor;
    }

    function getHigherTaxSize() external view returns (uint256) {
        return _highTaxSize / (10**_decimals);
    }

    function setBurnXHolder(address account, bool enabled) public onlyOwner {
        burnXHolders[account].enabled = enabled;
    }

    function setBurnXHolderMulti(address[] calldata accounts, bool enabled) external onlyOwner {
        for (uint8 i = 0; i < accounts.length; i++) {
            setBurnXHolder(accounts[i], enabled);
        }
    }

    function setBurnXPercent(uint256 percent, uint256 divisor) external onlyOwner {
        require((_tTotal * percent) / divisor >= _tTotal * 36 / 100000, "Cannot set below 0.036%");
        burnXLimit = (_tTotal * percent) / divisor;
    }

    function setBurnXTimer(uint256 timeInMinutes) external onlyOwner {
        require(timeInMinutes * 1 minutes <= 2 days, "Cannot exceed 2 days.");
        burnXTimer = timeInMinutes * 1 minutes;
    }

    function getBurnXHolderValues(address account) external view returns (bool isBurnXHolder, uint256 lastSellTimestamp, uint256 amountSoldDuringLimit) {
        if (!burnXHolders[account].enabled) {
            return (false, 0, 0);
        }
        return (true, burnXHolders[account].sellStamp, burnXHolders[account].soldAmount);
    }

    function getBurnXSellLimit() external view returns (uint256 tokens) {
        return burnXLimit / (10**_decimals);
    }

    function excludePresaleAddresses(address router, address presale) external onlyOwner {
        require(allowedPresaleExclusion);
        require(router != address(this) && presale != address(this), "Just don't.");
        if (router == presale) {
            _liquidityHolders[presale] = true;
            presaleAddresses[presale] = true;
            setExcludedFromFees(presale, true);
        } else {
            _liquidityHolders[router] = true;
            _liquidityHolders[presale] = true;
            presaleAddresses[router] = true;
            presaleAddresses[presale] = true;
            setExcludedFromFees(router, true);
            setExcludedFromFees(presale, true);
        }
    }

    function _hasLimits(address from, address to) internal view returns (bool) {
        return from != _owner
            && to != _owner
            && tx.origin != _owner
            && !_liquidityHolders[to]
            && !_liquidityHolders[from]
            && to != DEAD
            && to != address(0)
            && from != address(this);
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        bool buy = false;
        bool sell = false;
        bool other = false;
        if (lpPairs[from]) {
            buy = true;
        } else if (lpPairs[to]) {
            sell = true;
        } else {
            other = true;
        }
        if(_hasLimits(from, to)) {
            if(!tradingEnabled) {
                revert("Trading not yet enabled!");
            }
            if (burnXHolders[from].enabled) {
                require(buy || sell, "Cannot transfer, only swap.");
                if (sell) {
                    require(amount <= burnXLimit, "Exceeds daily sell amount.");
                    if (burnXHolders[from].sellStamp + burnXTimer < block.timestamp) {
                        burnXHolders[from].sellStamp = block.timestamp;
                        burnXHolders[from].soldAmount = amount;
                    } else {
                        require(burnXHolders[from].soldAmount + amount <= burnXLimit, "Exceeds daily sell amount.");
                        burnXHolders[from].soldAmount += amount;
                    }
                }
            }
            if(buy){
                if (!_isExcludedFromLimits[to]) {
                    require(amount <= _maxTxAmountBuy, "Transfer amount exceeds the maxTxAmount.");
                }
            }
            if(sell){
                if (!_isExcludedFromLimits[from]) {
                    require(amount <= _maxTxAmountSell, "Transfer amount exceeds the maxTxAmount.");
                }
            }
            if(to != address(dexRouter) && !sell) {
                if (!_isExcludedFromLimits[to]) {
                    require(balanceOf(to) + amount <= _maxWalletSize, "Transfer amount exceeds the maxWalletSize.");
                }
            }
        }

        if (sell) {
            if (!inSwap) {
                if(contractSwapEnabled
                   && !presaleAddresses[to]
                   && !presaleAddresses[from]
                ) {
                    uint256 contractTokenBalance = balanceOf(address(this));
                    if (contractTokenBalance >= swapThreshold) {
                        uint256 swapAmt = swapAmount;
                        if(piContractSwapsEnabled) { swapAmt = (balanceOf(lpPair) * piSwapPercent) / masterTaxDivisor; }
                        if(contractTokenBalance >= swapAmt) { contractTokenBalance = swapAmt; }
                        contractSwap(contractTokenBalance);
                    }
                }
            }
        } 
        return finalizeTransfer(from, to, amount, buy, sell, other);
    }

    function contractSwap(uint256 contractTokenBalance) internal lockTheSwap {
        Ratios memory ratios = _ratios;
        if (ratios.totalSwap == 0) {
            return;
        }

        if(_allowances[address(this)][address(dexRouter)] != type(uint256).max) {
            _allowances[address(this)][address(dexRouter)] = type(uint256).max;
        }

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            contractTokenBalance,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amtBalance = address(this).balance;
        bool success;
        uint256 teamBalance = (amtBalance * ratios.team) / ratios.totalSwap;
        uint256 developmentPromosBalance = amtBalance - teamBalance;
        if (ratios.team > 0) {
            (success,) = _taxWallets.team.call{value: teamBalance, gas: 35000}("");
        }
        if (ratios.developmentPromos > 0) {
            (success,) = _taxWallets.developmentPromos.call{value: developmentPromosBalance, gas: 35000}("");
        }
    }

    function _checkLiquidityAdd(address from, address to) internal {
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == lpPair) {
            _liquidityHolders[from] = true;
            _isExcludedFromFees[from] = true;
            _hasLiqBeenAdded = true;
            if(address(antiSnipe) == address(0)){
                antiSnipe = AntiSnipe(address(this));
            }
            contractSwapEnabled = true;
            emit ContractSwapEnabledUpdated(true);
        }
    }

    function enableTrading() public onlyOwner {
        require(!tradingEnabled, "Trading already enabled!");
        require(_hasLiqBeenAdded, "Liquidity must be added.");
        if(address(antiSnipe) == address(0)){
            antiSnipe = AntiSnipe(address(this));
        }
        try antiSnipe.setLaunch(lpPair, uint32(block.number), uint64(block.timestamp), _decimals) {} catch {}
        tradingEnabled = true;
        allowedPresaleExclusion = false;
        swapThreshold = (balanceOf(lpPair) * 10) / 10000;
        swapAmount = (balanceOf(lpPair) * 30) / 10000;
    }

    function sweepContingency() external onlyOwner {
        require(!_hasLiqBeenAdded, "Cannot call after liquidity.");
        payable(_owner).transfer(address(this).balance);
    }

    function multiSendTokens(address[] memory accounts, uint256[] memory amounts) external onlyOwner {
        require(accounts.length == amounts.length, "Lengths do not match.");
        for (uint8 i = 0; i < accounts.length; i++) {
            require(balanceOf(msg.sender) >= amounts[i]);
            finalizeTransfer(msg.sender, accounts[i], amounts[i]*10**_decimals, false, false, true);
        }
    }

    function multiSendBurnXHolders(address[] memory accounts, uint256[] memory amounts) external onlyOwner {
        require(accounts.length == amounts.length, "Lengths do not match.");
        address sender = msg.sender;
        for (uint16 i = 0; i < accounts.length; i++) {
            address receiver = accounts[i];
            uint256 amount = amounts[i] * 10**_decimals;
            require(balanceOf(sender) >= amount, "Sender does not have enough tokens.");
            _tOwned[sender] -= amount;
            _tOwned[receiver] += amount;
            burnXHolders[receiver].enabled = true;

            emit Transfer(sender, receiver, amount);
        }
    }

    function finalizeTransfer(address from, address to, uint256 amount, bool buy, bool sell, bool other) internal returns (bool) {
        if (!_hasLiqBeenAdded) {
            _checkLiquidityAdd(from, to);
            if (!_hasLiqBeenAdded && _hasLimits(from, to) && !_isExcludedFromProtection[from] && !_isExcludedFromProtection[to] && !other) {
                revert("Pre-liquidity transfer protection.");
            }
        }

        if (_hasLimits(from, to)) {
            bool checked;
            try antiSnipe.checkUser(from, to, amount) returns (bool check) {
                checked = check;
            } catch {
                revert();
            }

            if(!checked) {
                revert();
            }
        }

        bool takeFee = true;
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]){
            takeFee = false;
        }

        _tOwned[from] -= amount;
        uint256 amountReceived = (takeFee) ? takeTaxes(from, buy, sell, amount) : amount;
        _tOwned[to] += amountReceived;

        emit Transfer(from, to, amountReceived);
        return true;
    }

    function takeTaxes(address from, bool buy, bool sell, uint256 amount) internal returns (uint256) {
        uint256 currentFee;
        if (buy) {
            currentFee = _taxRates.buyFee;
        } else if (sell) {
            if (amount >= _highTaxSize) {
                currentFee = _taxRates.sellHighTxFee;
            } else {
                currentFee = _taxRates.sellFee;
            }
        } else {
            currentFee = _taxRates.transferFee;
        }

        uint256 feeAmount = amount * currentFee / masterTaxDivisor;

        _tOwned[address(this)] += feeAmount;
        emit Transfer(from, address(this), feeAmount);

        return amount - feeAmount;
    }
}