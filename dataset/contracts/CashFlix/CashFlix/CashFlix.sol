//SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

/**
 * 
 *    $$$$$$\   $$$$$$\   $$$$$$\  $$\   $$\ $$$$$$$$\ $$\       $$$$$$\ $$\   $$\                        $$\    $$$$$$$$\ $$\       $$$$$$\ $$\   $$\ 
 *   $$  __$$\ $$  __$$\ $$  __$$\ $$ |  $$ |$$  _____|$$ |      \_$$  _|$$ |  $$ |                     $$$$$$\  $$  _____|$$ |      \_$$  _|$$ |  $$ |
 *   $$ /  \__|$$ /  $$ |$$ /  \__|$$ |  $$ |$$ |      $$ |        $$ |  \$$\ $$  |                    $$  __$$\ $$ |      $$ |        $$ |  \$$\ $$  |
 *   $$ |      $$$$$$$$ |\$$$$$$\  $$$$$$$$ |$$$$$\    $$ |        $$ |   \$$$$  /       $$$$$$\       $$ /  \__|$$$$$\    $$ |        $$ |   \$$$$  / 
 *   $$ |      $$  __$$ | \____$$\ $$  __$$ |$$  __|   $$ |        $$ |   $$  $$<        \______|      \$$$$$$\  $$  __|   $$ |        $$ |   $$  $$<  
 *   $$ |  $$\ $$ |  $$ |$$\   $$ |$$ |  $$ |$$ |      $$ |        $$ |  $$  /\$$\                      \___ $$\ $$ |      $$ |        $$ |  $$  /\$$\ 
 *   \$$$$$$  |$$ |  $$ |\$$$$$$  |$$ |  $$ |$$ |      $$$$$$$$\ $$$$$$\ $$ /  $$ |                    $$\  \$$ |$$ |      $$$$$$$$\ $$$$$$\ $$ /  $$ |
 *    \______/ \__|  \__| \______/ \__|  \__|\__|      \________|\______|\__|  \__|                    \$$$$$$  |\__|      \________|\______|\__|  \__|
 *                                                                                                      \_$$  _/                                       
 *                                                                                                        \ _/                                         
 *                                                                                                                                                 
 *  
 *      01000011 01101111 01110110 01101001 01000011 01101111 01101001 01101110  00101101  01000011 01010110 01000011                                              
 *      01000100 01100101 01110110 01100101 01101100 01101111 01110000 01100101 01100100  01000010 01111001  01000100 01100001 01101110 01110101 01110011 01101000 
 * 
 *      https://cashflix.org - Pay Directly with your Crypto Wallet in Physical & Online Stores, 
 *                                                                               using any of your Crypto Assets
 * 
 */

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
        emit Authorized(adr);
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
        emit Unauthorized(adr);
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
    event Authorized(address adr);
    event Unauthorized(address adr);
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

    IBEP20 BUSD = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
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
    uint256 public minDistribution = 1 * (10 ** 18);

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

    function getShareholderInfo(address shareholder) external view returns (uint256, uint256, uint256, uint256) {
        return (
            totalShares,
            totalDistributed,
            shares[shareholder].amount,
            shares[shareholder].totalRealised
        );
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        
        emit DistributionCriteriaUpdated(minPeriod, minDistribution);
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        distributeDividend(shareholder);

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        
        emit ShareUpdated(shareholder, amount);
    }
    
    function owner() view external onlyToken() returns(address) {
        address cashflixToken = _token;
        return cashflixToken;
    }
    

    function deposit() external payable override {
        uint256 balanceBefore = BUSD.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(BUSD);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = BUSD.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
        
        emit Deposit(msg.value, amount);
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 count = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
                count++;
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
        
        emit DividendsProcessed(iterations, count, currentIndex);
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
            BUSD.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            
            emit Distribution(shareholder, amount);
        }
    }

    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function claimDividendFor(address shareholder) external {
        distributeDividend(shareholder);
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
    
    event DistributionCriteriaUpdated(uint256 minPeriod, uint256 minDistribution);
    event ShareUpdated(address shareholder, uint256 amount);
    event Deposit(uint256 amountBNB, uint256 amountBUSD);
    event Distribution(address shareholder, uint256 amount);
    event DividendsProcessed(uint256 iterations, uint256 count, uint256 index);
}

contract CashFlix is IBEP20, Auth {
    using SafeMath for uint256;

    address BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "CashFlix";
    string constant _symbol = "$flix";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 88888888 * (10 ** _decimals); // 88,888,888 $flix Tokens
    uint256 public _maxTxAmount = _totalSupply / 1000; // 0.1%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;

    bool feeEnabled = true;

    bool autoLiquifyEnabled = true;
    uint256 liquidityFee = 200;
    uint256 liquidityFeeAccumulator;

    uint256 buybackFee = 200;
    uint256 reflectionFee = 500;
    uint256 marketingFee = 400;
    uint256 rndFee = 200;
    uint256 totalFee = 1500;
    uint256 feeDenominator = 10000;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver = 0xa56A5d45121c9B41A1a43C4cE71Ff8f66A54f825;
    address public rndFeeReceiver = 0xfB832726521fd749E4C7DEF121a3a48878F575Bd;
    uint256 marketingFees;
    uint256 rndFees;
    

    IDEXRouter public router;
    address public pair;

    uint256 public launchedAt;

    bool autoBuybackEnabled = false;
    uint256 autoBuybackCap;
    uint256 autoBuybackAccumulator;
    uint256 autoBuybackAmount;
    uint256 autoBuybackBlockPeriod;
    uint256 autoBuybackBlockLast;

    DividendDistributor public distributor;
    bool autoClaimEnabled = false;
    uint256 distributorGas = 500000;

    bool swapEnabled = true;
    uint256 swapThreshold = _totalSupply / 4000; // 0.025%
    
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = uint256(-1);

        distributor = new DividendDistributor(address(router));

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        autoLiquidityReceiver = msg.sender;

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
        return approve(spender, uint256(-1));
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(-1)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        checkLaunched(sender);
        checkTxLimit(sender, amount);

        if(shouldSwapBack()){ swapBack(); }
        if(shouldAutoBuyback()){ triggerAutoBuyback(); }

        if(!launched() && recipient == pair){ require(_balances[sender] > 0); launch(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        if(autoClaimEnabled){
            try distributor.process(distributorGas) {} catch {}
        }

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkLaunched(address sender) internal view {
        require(launched() || isAuthorized(sender), "Pre-Launch Protection");
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return feeEnabled && !isFeeExempt[sender];
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if(launchedAt + 1 >= block.number){ return feeDenominator.sub(1); }
        return selling ? totalFee.add(liquidityFee) : totalFee;
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(receiver == pair)).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        if(receiver == pair && autoLiquifyEnabled){
            liquidityFeeAccumulator = liquidityFeeAccumulator.add(feeAmount.mul(liquidityFee).div(totalFee.add(liquidityFee)));
        }

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        if(liquidityFeeAccumulator >= swapThreshold && autoLiquifyEnabled){
            liquidityFeeAccumulator = liquidityFeeAccumulator.sub(swapThreshold);
            uint256 amountToLiquify = swapThreshold.div(2);

            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = WBNB;

            uint256 balanceBefore = address(this).balance;

            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountToLiquify,
                0,
                path,
                address(this),
                block.timestamp
            );

            uint256 amountBNB = address(this).balance.sub(balanceBefore);

            router.addLiquidityETH{value: amountBNB}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            
            emit AutoLiquify(amountBNB, amountToLiquify);
        }else{
            uint256 amountToSwap = swapThreshold;

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

            uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(totalFee);
            uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalFee);
            uint256 amountBNBRnD = amountBNB.mul(rndFee).div(totalFee);
            

            try distributor.deposit{value: amountBNBReflection}() {} catch {}

            (bool success, ) = payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
            if(success){ marketingFees = marketingFees.add(amountBNBMarketing); }

            (success, ) = payable(rndFeeReceiver).call{value: amountBNBRnD, gas: 30000}("");
            if(success){ rndFees = rndFees.add(amountBNBRnD); }

            emit SwapBack(amountToSwap, amountBNB);
        }
    }

    function shouldAutoBuyback() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && autoBuybackEnabled
        && autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number
        && address(this).balance >= autoBuybackAmount;
    }

    function buybackWEI(uint256 amount) external authorized {
        _buyback(amount);
    }

    function buybackBNB(uint256 amount) external authorized {
        _buyback(amount * (10 ** 18));
    }

    function _buyback(uint256 amount) internal {
        buyTokens(amount, DEAD);
        emit Buyback(amount);
    }

    function triggerAutoBuyback() internal {
        buyTokens(autoBuybackAmount, DEAD);
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

    function setAutoBuybackSettings(bool _enabled, uint256 _cap, uint256 _amount, uint256 _period) external authorized {
        autoBuybackEnabled = _enabled;
        autoBuybackCap = _cap;
        autoBuybackAccumulator = 0;
        autoBuybackAmount = _amount;
        autoBuybackBlockPeriod = _period;
        autoBuybackBlockLast = block.number;
        emit AutoBuybackSettingsUpdated(_enabled, _cap, _amount, _period);
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
        autoClaimEnabled = true;
        emit Launch();
    }

    function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
        emit TxLimitUpdated(amount);
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
        emit DividendExemptUpdated(holder, exempt);
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
        emit FeeExemptUpdated(holder, exempt);
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
        emit TxLimitExemptUpdated(holder, exempt);
    }

    function setFees(
        bool _enabled,
        uint256 _liquidityFee,
        uint256 _buybackFee,
        uint256 _reflectionFee,
        uint256 _marketingFee,
        uint256 _rndFee,
        uint256 _feeDenominator
    ) external authorized {
        feeEnabled = _enabled;

        buybackFee = _buybackFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        rndFee = _rndFee;

        totalFee = buybackFee.add(reflectionFee).add(marketingFee).add(rndFee);

        liquidityFee = _liquidityFee;

        feeDenominator = _feeDenominator;
        require(totalFee.add(liquidityFee) < feeDenominator/5);
        
        emit FeesUpdated(_enabled, _liquidityFee, _buybackFee, _reflectionFee, _marketingFee, _rndFee, _feeDenominator);
    }

    function setFeeReceivers(address _liquidityReceiver, address _marketingFeeReceiver, address _rndFeeReceiver) external authorized {
        autoLiquidityReceiver = _liquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        rndFeeReceiver = _rndFeeReceiver;
        emit FeeReceiversUpdated(_liquidityReceiver, _marketingFeeReceiver, _rndFeeReceiver);
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
        emit SwapBackSettingsUpdated(_enabled, _amount);
    }

    function setAutoLiquifyEnabled(bool _enabled) external authorized {
        autoLiquifyEnabled = _enabled;
        emit AutoLiquifyUpdated(_enabled);
    }
    
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas, bool _autoClaim) external authorized {
        require(gas <= 1000000);
        distributorGas = gas;
        autoClaimEnabled = _autoClaim;
        emit DistributorSettingsUpdated(gas, _autoClaim);
    }

    function getAccumulatedFees() external view returns (uint256, uint256) {
        return (marketingFees, rndFees);
    }

    function getAutoBuybackSettings() external view returns (bool,uint256,uint256,uint256,uint256,uint256) {
        return (
            autoBuybackEnabled,
            autoBuybackCap,
            autoBuybackAccumulator,
            autoBuybackAmount,
            autoBuybackBlockPeriod,
            autoBuybackBlockLast
        );
    }
    
    function getAutoLiquifySettings() external view returns (bool,uint256,uint256) {
        return (
            autoLiquifyEnabled,
            liquidityFeeAccumulator,
            swapThreshold
        );
    }

    function getSwapBackSettings() external view returns (bool,uint256) {
        return (
            swapEnabled,
            swapThreshold
        );
    }

    function getFees() external view returns (bool,uint256,uint256,uint256,uint256,uint256,uint256) {
        return (
            feeEnabled,
            buybackFee,
            reflectionFee,
            marketingFee,
            rndFee,
            liquidityFee,
            feeDenominator
        );
    }
    
    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(router), "$flix: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(router));
        router = IDEXRouter(newAddress);
    }
    
    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(distributor), "$flix: The dividend tracker already has that address");

        DividendDistributor newDistributor = DividendDistributor(payable(newAddress));

        require(newDistributor.owner() == address(this), "$flix: The new dividend tracker must be owned by the $flix token contract");

        isDividendExempt[address(newDistributor)] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[address(router)] = true;

        emit UpdateDividendTracker(newAddress, address(newDistributor));

        distributor = newDistributor;
    }

    event Launch();
    event AutoLiquify(uint256 amountBNB, uint256 amountToken);
    event SwapBack(uint256 amountToken, uint256 amountBNB);
    event Buyback(uint256 amountBNB);
    event AutoBuybackSettingsUpdated(bool enabled, uint256 cap, uint256 amount, uint256 period);
    event TxLimitUpdated(uint256 amount);
    event DividendExemptUpdated(address holder, bool exempt);
    event FeeExemptUpdated(address holder, bool exempt);
    event TxLimitExemptUpdated(address holder, bool exempt);
    event FeesUpdated(bool enabled, uint256 liquidityFee, uint256 buybackFee, uint256 reflectionFee, uint256 marketingFee, uint256 rndFee, uint256 feeDenominator);
    event FeeReceiversUpdated(address autoLiquidityReceiver, address marketingFeeReceiver, address rndFeeReceiver);
    event SwapBackSettingsUpdated(bool enabled, uint256 amount);
    event AutoLiquifyUpdated(bool enabled);
    event DistributorSettingsUpdated(uint256 gas, bool autoClaim);
    event UpdateUniswapV2Router(address newAddress, address router);
    event UpdateDividendTracker(address newAddress, address dividendTracker);
}