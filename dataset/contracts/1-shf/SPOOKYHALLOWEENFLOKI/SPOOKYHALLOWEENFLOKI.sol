// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.12;

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

interface BEP20 {
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
    address internal potentialOwner;
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

    function authorize(address adr) external onlyOwner {
        authorizations[adr] = true;
        emit Authorize_Wallet(adr,true);
    }

    function unauthorize(address adr) external onlyOwner {
        require(adr != owner, "OWNER cant be unauthorized");
        authorizations[adr] = false;
        emit Authorize_Wallet(adr,false);
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) external onlyOwner {
        require(adr != owner, "Already the owner");
        require(adr != address(0), "Can not be zero address.");
        potentialOwner = adr;
        emit OwnershipNominated(adr);
    }

    function acceptOwnership() external {
        require(msg.sender == potentialOwner, "You must be nominated as potential owner before you can accept the role.");
        authorizations[owner] = false;
        authorizations[potentialOwner] = true;

        emit Authorize_Wallet(owner,false);
        emit Authorize_Wallet(potentialOwner,true);
        
        owner = potentialOwner;
        potentialOwner = address(0);
        emit OwnershipTransferred(owner);
    }

    event OwnershipTransferred(address owner);
    event OwnershipNominated(address potentialOwner);
    event Authorize_Wallet(address Wallet, bool Status);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
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
}

contract SPOOKYHALLOWEENFLOKI is BEP20, Auth {
    using SafeMath for uint256;

    address immutable WBNB;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    string public constant name = "Spooky Halloween Floki";
    string public constant symbol = "SHF";
    uint8 public constant decimals = 9;

    uint256 public constant totalSupply = 10 * 10**9 * 10**decimals;

    uint256 public _maxTxAmount = totalSupply / 100;
    uint256 public _maxWalletToken = totalSupply * 2 / 100;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isWalletLimitExempt;

    uint256 public liquidityFee = 10;
    uint256 public marketingFee = 60;
    uint256 public teamFee = 10;
    uint256 public developmentFee = 20;
    uint256 public buybackFee = 10;
    uint256 public burnFee = 0;
    uint256 public totalFee = marketingFee + liquidityFee + teamFee + buybackFee + burnFee + developmentFee;
    uint256 public constant feeDenominator = 1000;
    
    uint256 buyMultiplier = 100;
    uint256 sellMultiplier = 109;
    uint256 transferMultiplier = 100;

    address public marketingFeeReceiver;
    address public teamFeeReceiver;
    address public developmentFeeReceiver;
    address public buybackFeeReceiver;

    IDEXRouter public router;
    address public immutable pair;

    bool public tradingOpen = false;
    bool public launchMode = true;
    bool public autobuyback = true;

    address[] buybackPath = new address[](2);

    bool public swapEnabled = false;
    uint256 public swapThreshold = totalSupply / 5000;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        WBNB = router.WETH();

        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        marketingFeeReceiver = 0xc9550CF5389697c28d04e9A6ed3F0eF2838d749c;
        developmentFeeReceiver = 0x42c3EAfA224fc784Ecb34985d4D2D4B830C8203D;
        teamFeeReceiver = 0xc0a641F1F6ed23384bf8dD3A5425aFcbE9A9f7dF;
        buybackFeeReceiver = 0x335C1f7bf7d2d3178BF751c51EdA97423732F42A;

        isFeeExempt[msg.sender] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[ZERO] = true;

        isWalletLimitExempt[msg.sender] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[DEAD] = true;

        buybackPath[0] = router.WETH();
        buybackPath[1] = address(0x14940169E2Db1595CDD3CACd30DECC5bbB4d9f19);

        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    receive() external payable { }

    function getOwner() external view override returns (address) { return owner; }
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

    function setMaxWalletPercent_base1000(uint256 maxWallPercent_base1000) external onlyOwner {
        require(maxWallPercent_base1000 >= 5,"Cannot set max wallet less than 0.5%");
        _maxWalletToken = (totalSupply * maxWallPercent_base1000 ) / 1000;
        emit config_MaxWallet(_maxWalletToken);
    }

    function setMaxTxPercent_base1000(uint256 maxTXPercentage_base1000) external onlyOwner {
        require(maxTXPercentage_base1000 >= 5,"Cannot set max transaction less than 0.5%");
        _maxTxAmount = (totalSupply * maxTXPercentage_base1000 ) / 1000;
        emit config_MaxTransaction(_maxTxAmount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if(!authorizations[sender] && !authorizations[recipient]){
            require(tradingOpen,"Trading not open yet");
        }

        if (!authorizations[sender] && !isWalletLimitExempt[sender] && !isWalletLimitExempt[recipient] && recipient != pair) {
            require((balanceOf[recipient] + amount) <= _maxWalletToken,"max wallet limit reached");
        }
    
        require((amount <= _maxTxAmount) || isTxLimitExempt[sender] || isTxLimitExempt[recipient], "Max TX Limit Exceeded");

        if(shouldSwapBack()){ swapBack(); }

        balanceOf[sender] = balanceOf[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = (isFeeExempt[sender] || isFeeExempt[recipient]) ? amount : takeFee(sender, amount, recipient);

        balanceOf[recipient] = balanceOf[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        balanceOf[sender] = balanceOf[sender].sub(amount, "Insufficient Balance");
        balanceOf[recipient] = balanceOf[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(address sender, uint256 amount, address recipient) internal returns (uint256) {
        if(amount == 0 || totalFee == 0){
            return amount;
        }

        uint256 multiplier = transferMultiplier;

        if(recipient == pair) {
            multiplier = sellMultiplier;
        } else if(sender == pair) {
            multiplier = buyMultiplier;
        }

        uint256 feeAmount = amount.mul(totalFee).mul(multiplier).div(feeDenominator * 100);
        uint256 burnTokens = feeAmount.mul(burnFee).div(totalFee);
        uint256 contractTokens = feeAmount.sub(burnTokens);

        if(contractTokens > 0){
            balanceOf[address(this)] = balanceOf[address(this)].add(contractTokens);
            emit Transfer(sender, address(this), contractTokens);
        }
        
        if(burnTokens > 0){
            balanceOf[DEAD] = balanceOf[DEAD].add(burnTokens);
            emit Transfer(sender, DEAD, burnTokens);    
        }

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && balanceOf[address(this)] >= swapThreshold;
    }

    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        require(amountPercentage < 101, "Max 100%");
        uint256 amountBNB = address(this).balance;
        uint256 amountToClear = ( amountBNB * amountPercentage ) / 100;
        payable(msg.sender).transfer(amountToClear);
        emit BalanceClear(amountToClear);
    }

    function clearStuckToken(address tokenAddress, uint256 tokens) external onlyOwner returns (bool success) {
        if(tokens == 0){
            tokens = BEP20(tokenAddress).balanceOf(address(this));
        }

        emit clearToken(tokenAddress, tokens);

        return BEP20(tokenAddress).transfer(msg.sender, tokens);
    }

    function tradingStatus(bool _status) external onlyOwner {
        if(!_status){
            require(launchMode,"Cannot stop trading after launch is done");
        }
        tradingOpen = _status;
        emit config_TradingStatus(tradingOpen);
    }

    function tradingStatus_launchmode(uint256 confirm) external onlyOwner {
        require(confirm == 100,"Accidental Press"); // just paranoid
        require(tradingOpen,"Cant close launch mode when trading is disabled");
        launchMode = false;
        emit config_LaunchMode(launchMode);
    }

    function swapBack() internal swapping {

        uint256 totalETHFee = totalFee - burnFee;

        uint256 amountToLiquify = (swapThreshold * liquidityFee)/(totalETHFee * 2);
        uint256 amountToSwap = swapThreshold - amountToLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance;

        totalETHFee = totalETHFee - (liquidityFee / 2);
        
        uint256 amountBNBLiquidity = (amountBNB * liquidityFee) / (totalETHFee * 2);
        uint256 amountBNBMarketing = (amountBNB * marketingFee) / totalETHFee;
        uint256 amountBNBTeam = (amountBNB * teamFee) / totalETHFee;
        uint256 amountBNBDevelopment = (amountBNB * developmentFee) / totalETHFee;
        uint256 amountBNBBuyback = (amountBNB * buybackFee) / totalETHFee;

        payable(marketingFeeReceiver).transfer(amountBNBMarketing);
        payable(teamFeeReceiver).transfer(amountBNBTeam);
        payable(developmentFeeReceiver).transfer(amountBNBDevelopment);

        if(autobuyback && amountBNBBuyback > 0){
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountBNBBuyback}(
                0,
                buybackPath,
                DEAD,
                block.timestamp
            );
        } else {
            payable(buybackFeeReceiver).transfer(amountBNBBuyback);        
        }
        

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                address(this),
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }

    function manage_FeeExempt(address[] calldata addresses, bool status) external authorized {
        require(addresses.length < 501,"GAS Error: max limit is 500 addresses");
        for (uint256 i=0; i < addresses.length; ++i) {
            isFeeExempt[addresses[i]] = status;
            emit Wallet_feeExempt(addresses[i], status);
        }
    }

    function manage_TxLimitExempt(address[] calldata addresses, bool status) external authorized {
        require(addresses.length < 501,"GAS Error: max limit is 500 addresses");
        for (uint256 i=0; i < addresses.length; ++i) {
            isTxLimitExempt[addresses[i]] = status;
            emit Wallet_txExempt(addresses[i], status);
        }
    }

    function manage_WalletLimitExempt(address[] calldata addresses, bool status) external authorized {
        require(addresses.length < 501,"GAS Error: max limit is 500 addresses");
        for (uint256 i=0; i < addresses.length; ++i) {
            isWalletLimitExempt[addresses[i]] = status;
            emit Wallet_holdingExempt(addresses[i], status);
        }
    }

    function update_fees() internal {
        require(totalFee.mul(buyMultiplier).div(100) <= 150, "Buy tax cannot be more than 15%");
        require(totalFee.mul(sellMultiplier).div(100) <= 200, "Sell tax cannot be more than 20%");
        require(totalFee.mul(transferMultiplier).div(100) <= 100, "Transfer Tax cannot be more than 10%");

        emit UpdateFee( uint8(totalFee.mul(buyMultiplier).div(100)),
            uint8(totalFee.mul(sellMultiplier).div(100)),
            uint8(totalFee.mul(transferMultiplier).div(100))
            );
    }

    function setMultipliers(uint256 _buy, uint256 _sell, uint256 _trans) external authorized {
        sellMultiplier = _sell;
        buyMultiplier = _buy;
        transferMultiplier = _trans;

        update_fees();
    }

    function setFees_base1000(uint256 _liquidityFee,  uint256 _marketingFee, uint256 _teamFee, uint256 _developmentFee, uint256 _burnFee, uint256 _buybackFee) external onlyOwner {
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        teamFee = _teamFee;
        developmentFee = _developmentFee;
        buybackFee = _buybackFee;
        burnFee = _burnFee;
        totalFee = _liquidityFee + _marketingFee + _teamFee + _buybackFee + _burnFee + _developmentFee;
        
        update_fees();
    }

    function setFeeReceivers(address _marketingFeeReceiver, address _teamFeeReceiver, address _developmentFeeReceiver, address _buybackFeeReceiver ) external onlyOwner {
        require(_marketingFeeReceiver != address(0),"Marketing fee address cannot be zero address");
        require(_teamFeeReceiver != address(0),"Team fee address cannot be zero address");
        require(_developmentFeeReceiver != address(0),"Development fee address cannot be zero address");
        require(_buybackFeeReceiver != address(0),"Buyback fee address cannot be zero address");

        marketingFeeReceiver = _marketingFeeReceiver;
        teamFeeReceiver = _teamFeeReceiver;
        developmentFeeReceiver = _developmentFeeReceiver;
        buybackFeeReceiver = _buybackFeeReceiver;

        emit Set_Wallets(marketingFeeReceiver, teamFeeReceiver, developmentFeeReceiver);
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        require(_amount < (totalSupply/10), "Amount too high");

        swapEnabled = _enabled;
        swapThreshold = _amount;

        emit config_SwapSettings(swapThreshold, swapEnabled);
    }

    function setAutobuyEnabled(bool _enabled) external onlyOwner {
        autobuyback = _enabled;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return (totalSupply - balanceOf[DEAD] - balanceOf[ZERO]);
    }


function multiTransfer(address from, address[] calldata addresses, uint256[] calldata tokens) external authorized {
    if(msg.sender != from){
        require(launchMode,"Cannot execute this after launch is done");
    }

    require(addresses.length < 501,"GAS Error: max limit is 500 addresses");
    require(addresses.length == tokens.length,"Mismatch between address and token count");

    uint256 SCCC = 0;

    for(uint i=0; i < addresses.length; i++){
        SCCC = SCCC + tokens[i];
    }

    require(balanceOf[from] >= SCCC, "Not enough tokens in wallet");

    for(uint i=0; i < addresses.length; i++){
        _basicTransfer(from,addresses[i],tokens[i]);
    }

}

event AutoLiquify(uint256 amountBNB, uint256 amountTokens);
event UpdateFee(uint8 Buy, uint8 Sell, uint8 Transfer);
event Wallet_feeExempt(address Wallet, bool Status);
event Wallet_txExempt(address Wallet, bool Status);
event Wallet_holdingExempt(address Wallet, bool Status);

event BalanceClear(uint256 amount);
event clearToken(address TokenAddressCleared, uint256 Amount);

event Set_Wallets(address MarketingWallet, address TeamWallet, address developmentWallet);

event config_MaxWallet(uint256 maxWallet);
event config_MaxTransaction(uint256 maxWallet);
event config_TradingStatus(bool Status);
event config_LaunchMode(bool Status);
event config_SwapSettings(uint256 Amount, bool Enabled);

}