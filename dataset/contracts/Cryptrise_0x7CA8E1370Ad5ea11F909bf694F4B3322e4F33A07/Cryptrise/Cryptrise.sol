/*
 Token: Crytrise Token
 Supply: 1,000,000,000,000,000
 Initial Burnt: 50%
 Team: 3%
 Marketing: 1%
 *********************************************
 Fees Buy & Sell: 16%
  - Reward: 13%
  - LP: 1%
  - Marketing: 1%
  - Manual Buyback & Burn: 1%
 *********************************************
 Website: http://cryptrisetoken.com/
 Telegram: https://t.me/CryptriseOfficial
 Twitter: https://twitter.com/cryptrise
 *********************************************
 SPDX-License-Identifier: unlicensed
*/

pragma solidity 0.8.11;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
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

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
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

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;
    address _token;
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    address public REWARD_NETWORK = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public WBNB_NETWORK = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IBEP20 REWARD = IBEP20(REWARD_NETWORK);
    address WBNB = WBNB_NETWORK;
    IDEXRouter router;
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => Share) public shares;
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    uint256 public minPeriod = 45 * 60;
    uint256 public minDistribution = 1 * (10 ** 18);
    address public currentRouter;
    address public Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    uint256 currentIndex;
    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _router) {
        currentRouter = Router;
        router = _router != address(0)
        ? IDEXRouter(_router)
        : IDEXRouter(currentRouter);
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }
        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = REWARD.balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(REWARD);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amount = REWARD.balanceOf(address(this)).sub(balanceBefore);
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;
        if(shareholderCount == 0) { return; }
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;
        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }
            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function updateWbnbandBusdAddress(address rWbnb, address rBusd) external {
        WBNB = rWbnb;
        REWARD = IBEP20(rBusd);
        REWARD_NETWORK = rBusd;
        WBNB_NETWORK = rWbnb;
    }

    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
        && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }
        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            REWARD.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }
        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }
        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

contract Cryptrise is IBEP20, Auth {
    using SafeMath for uint256;
    address public BUSD_ADDRESS = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public WBNB_ADDRESS = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public MARKETING_WALLET = 0x01f35a2671656Bb7950b9f617Bb95FCACA18558e;
    address public BUYBACK_WALLET = 0x00793433D1F331E83e483Fa9b36d48915C107CB2;
    address public PINKSALE_ADDRESS = 0x0000000000000000000000000000000000000000;
    address DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
    address PCS_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    string constant _name = "Cryptrise Token";
    string constant _symbol = "CRT";
    uint8 constant _decimals = 18;
    uint256 _totalSupply = 1000000 * 10**9 * (10**_decimals);
    uint256 public _maxTxAmount = _totalSupply / 1000; // 0.05%
    uint256 public _maxWalletToken = _totalSupply;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    bool public blacklistMode = true;
    mapping (address => bool) public isBlacklisted;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isTimelockExempt;
    mapping (address => bool) isDividendExempt;
    //Set Fees
    uint256 public liquidityFee    = 1;
    uint256 public reflectionFee   = 13;
    uint256 public marketingFee    = 1;
    uint256 public buyBackFee      = 1;
    uint256 public burnFee         = 0;
    uint256 public totalFee        = marketingFee + reflectionFee + liquidityFee + buyBackFee + burnFee;

    uint256 public feeDenominator  = 100;
    uint256 public sellMultiplier  = 100;
    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;
    address public buyBackFeeReceiver;
    address public burnFeeReceiver;
    address public currentRouter;
    uint256 targetLiquidity = 99;
    uint256 targetLiquidityDenominator = 100;
    IDEXRouter public router;
    address public pair;
    bool public tradingOpen = false;
    DividendDistributor public distributor;
    uint256 distributorGas = 500000;
    bool public buyCooldownEnabled = false;
    uint8 public cooldownTimerInterval = 60;
    mapping (address => uint) private cooldownTimer;
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply * 10 / 100000; //0.001%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        currentRouter = PCS_ROUTER;
        router = IDEXRouter(currentRouter);
        pair = IDEXFactory(router.factory()).createPair(WBNB_ADDRESS, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
        distributor = new DividendDistributor(address(router));
        isFeeExempt[msg.sender] = true;
        isFeeExempt[PINKSALE_ADDRESS] = true;
        isTxLimitExempt[msg.sender] = true;
        isTimelockExempt[msg.sender] = true;
        isTimelockExempt[DEAD_ADDRESS] = true;
        isTimelockExempt[address(this)] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD_ADDRESS] = true;
        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = MARKETING_WALLET;
        buyBackFeeReceiver = BUYBACK_WALLET;
        burnFeeReceiver = DEAD_ADDRESS;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function setMaxWalletPercent_base1000(uint256 maxWallPercent_base1000) external onlyOwner() {
        _maxWalletToken = (_totalSupply * maxWallPercent_base1000 ) / 1000;
    }
    function setMaxTxPercent_base1000(uint256 maxTXPercentage_base1000) external onlyOwner() {
        _maxTxAmount = (_totalSupply * maxTXPercentage_base1000 ) / 1000;
    }

    function setTxLimit(uint256 amount) external authorized {
        _maxTxAmount = amount;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){
            return _basicTransfer(sender, recipient, amount);
        }
        if(!authorizations[sender] && !authorizations[recipient]){
            require(tradingOpen,"Trading not open yet");
        }
        // Blacklist
        if(blacklistMode){
            require(!isBlacklisted[sender] && !isBlacklisted[recipient],"Blacklisted");
        }
        if (!authorizations[sender] && recipient != address(this)  && recipient != address(DEAD_ADDRESS) && recipient != pair && recipient != marketingFeeReceiver && recipient != autoLiquidityReceiver && recipient != burnFeeReceiver){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");
        }
        if (sender == pair && buyCooldownEnabled && !isTimelockExempt[recipient]) {
            require(cooldownTimer[recipient] < block.timestamp,"Please wait for 1min between two buys");
            cooldownTimer[recipient] = block.timestamp + cooldownTimerInterval;
        }
        // Checks max transaction limit
        checkTxLimit(sender, amount);
        if(shouldSwapBack()){
            swapBack();
        }
        //Exchange tokens
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 amountReceived = (!shouldTakeFee(sender) || !shouldTakeFee(recipient)) ? amount : takeFee(sender, amount,(recipient == pair));
        _balances[recipient] = _balances[recipient].add(amountReceived);
        // Dividend tracker
        if(!isDividendExempt[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }
        if(!isDividendExempt[recipient]) {
            try distributor.setShare(recipient, _balances[recipient]) {} catch {}
        }
        try distributor.process(distributorGas) {} catch {}
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, uint256 amount, bool isSell) internal returns (uint256) {
        uint256 multiplier = isSell ? sellMultiplier : 100;
        uint256 feeAmount = amount.mul(totalFee).mul(multiplier).div(feeDenominator * 100);
        uint256 burnTokens = feeAmount.mul(burnFee).div(totalFee);
        uint256 contractTokens = feeAmount.sub(burnTokens);
        _balances[address(this)] = _balances[address(this)].add(contractTokens);
        _balances[burnFeeReceiver] = _balances[burnFeeReceiver].add(burnTokens);
        emit Transfer(sender, address(this), contractTokens);
        if(burnTokens > 0){
            emit Transfer(sender, burnFeeReceiver, burnTokens);
        }
        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair && !inSwap && swapEnabled && _balances[address(this)] >= swapThreshold;
    }

    function clearStuckBalance(uint256 amountPercentage) external authorized {
        uint256 amountBNB = address(this).balance;
        payable(marketingFeeReceiver).transfer(amountBNB * amountPercentage / 100);
    }

    function clearStuckBalance_sender(uint256 amountPercentage) external authorized {
        uint256 amountBNB = address(this).balance;
        payable(msg.sender).transfer(amountBNB * amountPercentage / 100);
    }

    function set_sell_multiplier(uint256 Multiplier) external onlyOwner{
        sellMultiplier = Multiplier;
    }

    function startTrading() public onlyOwner {
        tradingOpen = true;
    }

    function cooldownEnabled(bool _status, uint8 _interval) public onlyOwner {
        buyCooldownEnabled = _status;
        cooldownTimerInterval = _interval;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB_ADDRESS;
        uint256 balanceBefore = address(this).balance;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountToSwap,0,path,address(this),block.timestamp);
        uint256 amountBNB = address(this).balance.sub(balanceBefore);
        uint256 totalBNBFee = totalFee.sub(dynamicLiquidityFee.div(2));
        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);
        uint256 amountBNBBuyBack = amountBNB.mul(buyBackFee).div(totalBNBFee);
        try distributor.deposit{value: amountBNBReflection}() {} catch {}
        (bool tmpSuccess,) = payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
         (tmpSuccess,) = payable(buyBackFeeReceiver).call{value: amountBNBBuyBack, gas: 30000}("");
        // only to supress warning msg
        tmpSuccess = false;
        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountBNBLiquidity}(address(this),amountToLiquify,0,0,autoLiquidityReceiver,block.timestamp);
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }

    function setWbnbandBusdAddress(address wbnb, address busd) external authorized {
        WBNB_ADDRESS = wbnb;
        BUSD_ADDRESS = busd;
        distributor.updateWbnbandBusdAddress(wbnb,busd);
        emit updateWbnbAndBusd(wbnb, busd);
    }

    function manualCreatePair(address wBnb) external authorized {
        pair = IDEXFactory(router.factory()).createPair(wBnb, address(this));
    }

    function setRouterAndDistributorAddress(address newRouter, address newPair) external authorized {
        router = IDEXRouter(newRouter);
        pair = newPair;
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function enable_blacklist(bool _status) public onlyOwner {
        blacklistMode = _status;
    }

    function manage_blacklist(address[] calldata addresses, bool status) public onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            isBlacklisted[addresses[i]] = status;
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setIsTimelockExempt(address holder, bool exempt) external authorized {
        isTimelockExempt[holder] = exempt;
    }

    function setFees(uint256 _liquidityFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _buyBackFee , uint256 _burnFee, uint256 _feeDenominator) external authorized {
        liquidityFee = _liquidityFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        buyBackFee = _buyBackFee;
        burnFee = _burnFee;
        totalFee = _liquidityFee + _reflectionFee + _marketingFee + _buyBackFee + _burnFee ;
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator/4, "Fees cannot be more than 25%");
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver, address _buyBackFeeReceiver, address _burnFeeReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        buyBackFeeReceiver = _buyBackFeeReceiver;
        burnFeeReceiver = _burnFeeReceiver;
    }

    function setPinkSaleAddress(address _PinkSaleAddress) external authorized {
        PINKSALE_ADDRESS = _PinkSaleAddress;
    }

    function setCurrentRouter (address _NewRouter) external authorized {
        currentRouter = _NewRouter;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        distributorGas = gas;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD_ADDRESS)).sub(balanceOf(ZERO_ADDRESS));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    function recoverETHfromTresLechesCC() public virtual onlyOwner {
        payable(buyBackFeeReceiver).transfer(address(this).balance);
    }

    function recoverTokensFromTresLechesCC(address _tokenAddress, uint256 _amount) public onlyOwner {                               
        IBEP20(_tokenAddress).transfer(buyBackFeeReceiver, _amount);
    }

    /* Airdrop Begins */
    function multiTransfer(address from, address[] calldata addresses, uint256[] calldata tokens) external onlyOwner {
        require(addresses.length < 501,"GAS Error: max airdrop limit is 500 addresses");
        require(addresses.length == tokens.length,"Mismatch between Address and token count");
        uint256 SCCC = 0;
        for(uint i=0; i < addresses.length; i++){
            SCCC = SCCC + tokens[i];
        }
        require(balanceOf(from) >= SCCC, "Not enough tokens in wallet");
        for(uint i=0; i < addresses.length; i++){
            _basicTransfer(from,addresses[i],tokens[i]);
            if(!isDividendExempt[addresses[i]]) {
                try distributor.setShare(addresses[i], _balances[addresses[i]]) {} catch {}
            }
        }
        // Dividend tracker
        if(!isDividendExempt[from]) {
            try distributor.setShare(from, _balances[from]) {} catch {}
        }
    }

    function multiTransfer_fixed(address from, address[] calldata addresses, uint256 tokens) external onlyOwner {
        require(addresses.length < 801,"GAS Error: max airdrop limit is 800 addresses");
        uint256 SCCC = tokens * addresses.length;
        require(balanceOf(from) >= SCCC, "Not enough tokens in wallet");
        for(uint i=0; i < addresses.length; i++){
            _basicTransfer(from,addresses[i],tokens);
            if(!isDividendExempt[addresses[i]]) {
                try distributor.setShare(addresses[i], _balances[addresses[i]]) {} catch {}
            }
        }
        // Dividend tracker
        if(!isDividendExempt[from]) {
            try distributor.setShare(from, _balances[from]) {} catch {}
        }
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event updateWbnbAndBusd(address wBnb, address cake);
}