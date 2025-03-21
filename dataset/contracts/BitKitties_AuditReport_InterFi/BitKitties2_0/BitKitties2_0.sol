//SPDX-License-Identifier: MIT

/**
    __________  ___  __  __  _____  __   __  ___                  
    \___  _   \|__|/  |_| |/ /|__|/  |_/  |_|__| ___    ______   _______    ________    
      |  |_|  /| \_  __/ | /  | \_  __/   __/ |/ __ \ /  ___/    \___   \   \   __  \  
     |  |_|  \| | | | | |\ \ | | | |  | |  | || ___/ \___ \       /  ___/ ___\  \_\  \ ___ 
    |_______/|_| |_| |_|  \_\_| |_|  |_|  |_| \___/______/        \______\\__\\_______\\__\                     
    
    https://t.me/BitKitties
    bitkitties.io
 */
 
pragma solidity ^0.8.5;

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

/**
 * Allows for contract ownership along with multi-address authorization
 */
abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
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
    
    IBEP20 rewardsToken = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
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

    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10 ** 8);

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
        router = _router != address(0)
            ? IDEXRouter(_router)
            : IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
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
        uint256 balanceBefore = rewardsToken.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(rewardsToken);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = rewardsToken.balanceOf(address(this)).sub(balanceBefore);

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
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            rewardsToken.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    
    function claimDividend(address shareholder) external onlyToken{
        distributeDividend(shareholder);
    }
    
    function rescueDividends(address to) external onlyToken {
        rewardsToken.transfer(to, rewardsToken.balanceOf(address(this)));
    }
    
    function setRewardsToken(address _rewardsToken) external onlyToken{
        rewardsToken = IBEP20(_rewardsToken);
    }
    
    function rescueToken(address token, address to) external onlyToken {
        IBEP20(token).transfer(to, IBEP20(token).balanceOf(address(this)));
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

contract BitKitties2_0 is IBEP20, Auth {
    using SafeMath for uint256;

    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "BitKitties 2.0";
    string constant _symbol = "BTK2";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 1000000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply / 50; 
    
    uint256 public _minBalanceToEmptyWallet = 10000 * (10** _decimals);
    uint256 public _maxDailyTxPercentage = 30;
    
    uint256 public _sellWait = 86400;

    address[] private _privatesaleWallets;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) private _isSniper;
    mapping (address => uint256) private _transactionBlockLog;

    
    uint256 public snipersCaught = 0;
    bool public sniperProtection = true;
    bool public gasLimitActive = false;
    uint256 public gasPriceLimit;
    bool public sameBlockActive = true;
    mapping (address => uint256) private lastTrade;

    uint256 public launchedAt = 0;


    struct SellsHistory {
        uint256 sellTime;
        uint256 salesAmount;
    }

    mapping (address => SellsHistory) public _sellsHistoryPerAddress;

    uint256 liquidityFee = 3;
    uint256 buybackFee = 2;
    uint256 reflectionFee = 4;
    uint256 marketingFee = 3;
    uint256 totalFee = 12;
    uint256 feeDenominator = 100;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;

    uint256 targetLiquidity = 25;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;
    
    bool public tradingOpen = false;
    bool public hasLiquidityBeenAdded = false;

    
    uint256 private maxWalletPercent = 2;
    uint256 private maxWalletDivisor = 100;
    uint256 private _maxWalletSize = (_totalSupply * maxWalletPercent) / maxWalletDivisor;

    uint256 buybackMultiplierNumerator = 200;
    uint256 buybackMultiplierDenominator = 100;
    uint256 buybackMultiplierTriggeredAt;
    uint256 buybackMultiplierLength = 30 minutes;

    bool public autoBuybackEnabled = false;
    bool public autoBuybackMultiplier = true;
    uint256 autoBuybackCap;
    uint256 autoBuybackAccumulator;
    uint256 autoBuybackAmount;
    uint256 autoBuybackBlockPeriod;
    uint256 autoBuybackBlockLast;
    
    address constant private _routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;


    DividendDistributor distributor;
    uint256 distributorGas = 500000;

    bool public swapEnabled = true;
    bool public privatesalercheckEnabled = true;
    uint256 public swapThresholdDen = 200; 
    uint256 public swapThreshold = _totalSupply.div(swapThresholdDen); 
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        distributor = new DividendDistributor(address(router));
        
        address _presaler = msg.sender;
        isFeeExempt[_presaler] = true;
        isTxLimitExempt[_presaler] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = msg.sender;

        _balances[_presaler] = _totalSupply;
        emit Transfer(address(0), _presaler, _totalSupply);
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

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        
        if(sniperProtection) {
          // if sender is a sniper address, reject the sell.
          if(isSniper(sender)) {
            revert('Sniper rejected.');
          }
          // check if this is the liquidity adding tx to startup.
          if(!hasLiquidityBeenAdded) {
            _checkLiquidityAdd(recipient, sender);
          } else {
            if(
              launchedAt > 0
                && sender == pair
                && sender != owner
                && recipient != owner
            ) {
              if(block.number - launchedAt < 3) {
                _isSniper[recipient] = true;
                snipersCaught++;
              }
            }
            
            if (_transactionBlockLog[recipient] == block.number) {
                _isSniper[recipient] = true;
                snipersCaught++;
            }
          }
          checkpairisnotsniper();
        }
        
        _transactionBlockLog[recipient] =block.number;
        
        if(sender != owner && recipient != owner && !isFeeExempt[sender]){
            require(tradingOpen,"Trading not open yet");
            if (gasLimitActive) {
            require(tx.gasprice <= gasPriceLimit, "Gas price exceeds limit.");
            }
            if (sameBlockActive) {
                if (sender == pair){
                    require(lastTrade[recipient] != block.number);
                    lastTrade[recipient] = block.number;
                } else {
                    require(lastTrade[sender] != block.number);
                    lastTrade[sender] = block.number;
                }
            }
        }
        
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        checkTxLimit(sender, amount);
        
        if( recipient != pair && recipient != _routerAddress && sender != owner && recipient != owner && sender != address(this) && recipient != address(this)) {
           require(balanceOf(recipient) + amount <= _maxWalletSize, "Transfer amount exceeds the maxWalletSize.");
        }   
        
        if (privatesalercheckEnabled && isprivatesale(sender) ) {
        bool isTransferBetweenWallets;
        if (sender != owner && recipient != owner && sender != pair && recipient != pair && !isContract(sender) && !isContract(recipient))
        isTransferBetweenWallets = true;
        
        if (isTransferBetweenWallets){
            cloneSellDataToTransferWallet(sender, recipient);
        }
        if(!isFeeExempt[sender] && recipient == pair){
            require(canSell(sender, amount), "Wait");
            updateAddressLastSellData(sender, amount);
         }
        }

        if(shouldSwapBack()){ swapBack(); }
        if(shouldAutoBuyback()){ triggerAutoBuyback(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _swapTokensForFees(uint256 amount) external onlyOwner{
        uint256 contractTokenBalance = balanceOf(address(this));
        require(amount <= swapThreshold);
        require(contractTokenBalance >= amount);
        swapBack();
    }
    
    function updateMinBalanceToEmptyWallet(uint256 newAmount) external onlyOwner {
        require(_minBalanceToEmptyWallet != newAmount, "$POOKY#19");
        _minBalanceToEmptyWallet = newAmount;
    }
    
    function updateSellWait(uint256 newSellWait) external onlyOwner {
        require(newSellWait != _sellWait, "$POOKY#21");
        _sellWait = newSellWait;
    }
    
    function isSniper(address account) public view returns(bool) {
        return _isSniper[account];
    }
    
    function checkpairisnotsniper() internal {
        if (isSniper(pair))
        _isSniper[pair] = false;
    }
    
    function removeSniper(address account) external onlyOwner { 
        require(_isSniper[account], 'Account is not a recorded sniper.');
        _isSniper[account] = false;
    }

    function launch() public onlyOwner {
        require(!tradingOpen, 'Already launched' );
        launchedAt = block.number;
        hasLiquidityBeenAdded = true;
        tradingOpen = true;
    }
    
    function setSniperProtection(bool enabled) public onlyOwner {
        sniperProtection = enabled;
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
    
    function _checkLiquidityAdd(address to, address from) private {
        // if liquidity is added by the _liquidityholders set trading enables to true and start the anti sniper timer
        require(!hasLiquidityBeenAdded, 'Liquidity already added and marked.');
    
        if(to == pair && isFeeExempt[from]) {
          hasLiquidityBeenAdded = true;
          tradingOpen = true;
          launchedAt = block.number;
        }
    }
    
    function isContract(address _target) internal view returns (bool) {
        if (_target == address(0)) {
            return false;
        }

        uint256 size;
        assembly { size := extcodesize(_target) }
        return size > 0;
    }
    
    function AddtoWhitelist(address[] memory u_addr) public onlyOwner {
        for (uint i = 0; i < u_addr.length; i++){
            _privatesaleWallets.push(u_addr[i]);
        }
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if(selling && buybackMultiplierTriggeredAt.add(buybackMultiplierLength) > block.timestamp){ return getMultipliedFee(); }
        return totalFee;
    }

    function getMultipliedFee() public view returns (uint256) {
        uint256 remainingTime = buybackMultiplierTriggeredAt.add(buybackMultiplierLength).sub(block.timestamp);
        uint256 feeIncrease = totalFee.mul(buybackMultiplierNumerator).div(buybackMultiplierDenominator).sub(totalFee);
        return totalFee.add(feeIncrease.mul(remainingTime).div(buybackMultiplierLength));
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(receiver == pair)).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }
    
    function _canSell(address from, uint256 amount) external view returns(bool){
        return canSell(from, amount);
    }

    function canSell(address from, uint256 amount) private view returns(bool){
        // If address is excluded from fees or is the owner of the contract or is the contract we allow all transfers to avoid probles with liquidity or dividends
        if (isFeeExempt[from]){
            return true;
        }
        
        bool isprivatesaleWallets = false;
        for (uint i = 0; i < _privatesaleWallets.length; i++){
            if(_privatesaleWallets[i] == from){
                isprivatesaleWallets = true;
                break;
            }
        }
        
        require(isprivatesaleWallets = true);
        uint256 walletBalance = balanceOf(from);
        // If walletBalance <=  _minBalanceToEmptyWallet tokens let them sell all.
        if(walletBalance <= _minBalanceToEmptyWallet && _sellsHistoryPerAddress[from].sellTime.add(_sellWait) < block.timestamp){
            return true;
        }
        // If wallet is trying to sell more than 10% of it's balance we won't allow the transfer
        if(walletBalance > 0 && amount > walletBalance.mul(_maxDailyTxPercentage).div(100)){
            return false;
        }
        // If time of last sell plus waiting time is greater than actual time we need to check if addres is trying to sell more than 10%
        if(_sellsHistoryPerAddress[from].sellTime.add(_sellWait) >= block.timestamp){
            uint256 maxSell = walletBalance.add(_sellsHistoryPerAddress[from].salesAmount).mul(_maxDailyTxPercentage).div(100);
            return _sellsHistoryPerAddress[from].salesAmount.add(amount) < maxSell;
        }
        if(_sellsHistoryPerAddress[from].sellTime.add(_sellWait) < block.timestamp){
            return true;
        }
        return false;
    }

    function getTimeUntilNextTransfer(address from) external view returns(uint256){
        if(_sellsHistoryPerAddress[from].sellTime.add(_sellWait) > block.timestamp){
            return _sellsHistoryPerAddress[from].sellTime.add(_sellWait).sub(block.timestamp);
        }
        return 0;
    }
    
    function setMaxWalletSize(uint256 percent, uint256 divisor) external onlyOwner {
        uint256 check = (_totalSupply * percent) / divisor;
        require(check >= (_totalSupply / 1000), "Max Wallet amt must be above 0.1% of total supply.");
        _maxWalletSize = check;
    }

    function updateAddressLastSellData(address from, uint256 amount) private {
        // If tiem of last sell plus waiting time is lower than the actual time is either a first sale or waiting time has expired
        // We can reset all struct values for this address
        if(_sellsHistoryPerAddress[from].sellTime.add(_sellWait) < block.timestamp){
            _sellsHistoryPerAddress[from].salesAmount = amount;
            _sellsHistoryPerAddress[from].sellTime = block.timestamp;
            return;
        }
        _sellsHistoryPerAddress[from].salesAmount += amount;
    }
    
    function _isprivatesaleWallets(address who) external view returns (bool){
        return isprivatesale(who);
    }

    function isprivatesale(address who) private view returns (bool){
       bool isprivatesaleWallets = false;
        for (uint i = 0; i < _privatesaleWallets.length; i++){
            if(_privatesaleWallets[i] == who){
                isprivatesaleWallets = true;
                break;
            }
        }
        return isprivatesaleWallets;
    }
    
    function cloneSellDataToTransferWallet(address to, address from) private {
        _sellsHistoryPerAddress[to].salesAmount = _sellsHistoryPerAddress[from].salesAmount;
        _sellsHistoryPerAddress[to].sellTime = _sellsHistoryPerAddress[from].sellTime;
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountBNB = address(this).balance.sub(balanceBefore);
        uint256 totalBNBFee = totalFee.sub(dynamicLiquidityFee.div(2));
        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);

        try distributor.deposit{value: amountBNBReflection}() {} catch {}
        (bool success, /* bytes memory data */) = payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
        require(success, "receiver rejected ETH transfer");

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }

    function shouldAutoBuyback() internal view returns (bool) {
        return msg.sender != pair
            && !inSwap
            && autoBuybackEnabled
            && autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number
            && address(this).balance >= autoBuybackAmount;
    }

    function triggerManualBuyback(uint256 amount, bool triggerBuybackMultiplier) external authorized {
        buyTokens(amount, DEAD);
        if(triggerBuybackMultiplier){
            buybackMultiplierTriggeredAt = block.timestamp;
            emit BuybackMultiplierActive(buybackMultiplierLength);
        }
    }
    
    function activateBuybackMultiplier() external authorized {
        buybackMultiplierTriggeredAt = block.timestamp;
        emit BuybackMultiplierActive(buybackMultiplierLength);
    }
    
    function clearBuybackMultiplier() external authorized {
        buybackMultiplierTriggeredAt = 0;
    }

    function triggerAutoBuyback() internal {
        buyTokens(autoBuybackAmount, DEAD);
        if(autoBuybackMultiplier){
            buybackMultiplierTriggeredAt = block.timestamp;
            emit BuybackMultiplierActive(buybackMultiplierLength);
        }
        autoBuybackBlockLast = block.number;
        autoBuybackAccumulator = autoBuybackAccumulator.add(autoBuybackAmount);
        if(autoBuybackAccumulator > autoBuybackCap){ autoBuybackEnabled = false; }
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }
    
    function setProtectionSettings(bool antiSnipe, bool antiGas, bool antiBlock) external onlyOwner {
        sniperProtection = antiSnipe;
        gasLimitActive = antiGas;
        sameBlockActive = antiBlock;
    }
    
    function setGasPriceLimit(uint256 gas) external onlyOwner {
        require(gas >= 75);
        gasPriceLimit = gas * 1 gwei;
    }

    function setAutoBuybackSettings(bool _enabled, uint256 _cap, uint256 _amount, uint256 _period, bool _autoBuybackMultiplier) external authorized {
        autoBuybackEnabled = _enabled;
        autoBuybackCap = _cap;
        autoBuybackAccumulator = 0;
        autoBuybackAmount = _amount;
        autoBuybackBlockPeriod = _period;
        autoBuybackBlockLast = block.number;
        autoBuybackMultiplier = _autoBuybackMultiplier;
    }

    function setBuybackMultiplierSettings(uint256 numerator, uint256 denominator, uint256 length) external authorized {
        buybackMultiplierNumerator = numerator;
        buybackMultiplierDenominator = denominator;
        buybackMultiplierLength = length;
    }

    function setTxLimit(uint256 amount) external onlyOwner {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }
   
    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }
    
    function isExcludedFromDividend(address account) public view returns(bool) {
        return isDividendExempt[account];
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return isFeeExempt[account];
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setFees(uint256 _liquidityFee, uint256 _buybackFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _feeDenominator) external onlyOwner { 
        require(liquidityFee != _liquidityFee && _liquidityFee <= 3, "Liq. too high!");
        require(buybackFee != _buybackFee && _buybackFee <= 2, "Buyback too high!");
        require(reflectionFee != _reflectionFee && _reflectionFee <= 4, "Ref. too high!");
        require(marketingFee != _marketingFee && _marketingFee <= 3, "Mar. too high!");
        liquidityFee = _liquidityFee;
        buybackFee = _buybackFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        totalFee = _liquidityFee.add(_buybackFee).add(_reflectionFee).add(_marketingFee);
        feeDenominator = _feeDenominator;
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        require(_amount >= 200);
        swapEnabled = _enabled;
        swapThresholdDen = _amount;
    }
    
    function setprivatesalercheckEnabled(bool _enabled) external onlyOwner {
        privatesalercheckEnabled = _enabled;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external onlyOwner {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }
    
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }
    
    function claimDividend() external {
        distributor.claimDividend(msg.sender);
    }
    
    function setRewardsToken(address _rewardsToken) external onlyOwner {
        distributor.setRewardsToken(_rewardsToken);
    }
    
    function rescueTokenFromDividendDistributor(address token, address to) external onlyOwner {
        distributor.rescueToken(token, to);
    }

    function rescueToken(address token, address to) external onlyOwner {
        require(address(this) != token);
        IBEP20(token).transfer(to, IBEP20(token).balanceOf(address(this))); 
    }
    
    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        return distributor.getUnpaidEarnings(shareholder);
    } 

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000);
        distributorGas = gas;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }
    
    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event BuybackMultiplierActive(uint256 duration);
}