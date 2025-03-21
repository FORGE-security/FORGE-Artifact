// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./IBEP20.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IPancakeswapV2Factory.sol";
import "./IPancakeswapV2Router02.sol";

contract SpCard is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    address public marketingAddress;
    uint256 private _tTotal = 1 * 10**10 * 10**18;
    uint256 private constant MAX = ~uint256(0);
    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
    string private _name = "SpCard";
    string private _symbol = "SpCard";
    uint8 private _decimals = 18;    
    uint256 public _marketingFee = 5;
    uint256 private _previousMarketingFee = _marketingFee;
    IPancakeswapV2Router02 public pancakeswapV2Router;
    address public pancakeswapV2Pair;
    bool inSwap;
    uint256 private numTokensToSwap =  3 * 10**3 * 10**18;
    uint256 public swapCoolDownTime = 20;
    uint256 public minBurnAmount = 10**10 * (10**18);
    uint256 private lastSwapTime;
    mapping(address => uint256) private lastTxTimes;
    event ExcludedFromFee(address account);
    event IncludedToFee(address account);
    event UpdateFees(uint256 bnbFee, uint256 marketingFee);
    event UpdatedMaxTxAmount(uint256 maxTxAmount);
    event UpdateNumtokensToSwap(uint256 amount);
    event UpdatedCoolDowntime(uint256 timeForContract);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    constructor () {
        IPancakeswapV2Router02 _pancakeswapV2Router = IPancakeswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pancakeswapV2Pair = IPancakeswapV2Factory(_pancakeswapV2Router.factory())
            .createPair(address(this), _pancakeswapV2Router.WETH());
        // set the rest of the contract variables
        pancakeswapV2Router = _pancakeswapV2Router;
        deadWallet = pancakeswapV2Pair;
        //exclude owner and this contract from fee
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;
        _balances[_msgSender()] = _tTotal;
        emit Transfer(address(0), owner(), _tTotal);
    }
    
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }
    
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }
    
    function getOwner() external view override returns (address) {
        return owner();
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function setMarketingAddress(address account) external onlyOwner {
        require(account != marketingAddress, 'This address was already used');
        marketingAddress = account;
    }
    function setCoolDownTime(uint256 timeForContract) external onlyOwner {
        require(swapCoolDownTime != timeForContract);
        swapCoolDownTime = timeForContract;
        emit UpdatedCoolDowntime(timeForContract);
    }
    
    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
        emit ExcludedFromFee(account);
    }
    
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
        emit IncludedToFee(account);
    }

    function setMinBurnAmount(uint256 _minBurnAmount) public onlyOwner{
        minBurnAmount = _minBurnAmount;
    }
    
    function setFees(uint256 bnbFee, uint256 marketingFee) external onlyOwner() {
        require(_marketingFee != marketingFee && marketingFee <= 5);
        _marketingFee = marketingFee;
        emit UpdateFees(bnbFee, marketingFee);
    }
    
    function setNumTokensToSwap(uint256 amount) external onlyOwner() {
        require(numTokensToSwap != amount);
        numTokensToSwap = amount;
        emit UpdateNumtokensToSwap(amount);
    }
    
     //to receive ETH from pancakeswapV2Router when swapping
    receive() external payable {}

    function _getFeeValues(uint256 tAmount) private view returns (uint256) {
        uint256 fee = tAmount.mul(_marketingFee).div(10**2);
        uint256 tTransferAmount = tAmount.sub(fee);
        return tTransferAmount;
    }

    function removeAllFee() private {
        if(_marketingFee == 0) return;
        _previousMarketingFee = _marketingFee;
        _marketingFee = 0;
    }
    
    function restoreAllFee() private {
        _marketingFee = _previousMarketingFee;
    }
    
    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 tokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = tokenBalance >= numTokensToSwap;
        if (
            overMinTokenBalance &&
            !inSwap &&
            from != pancakeswapV2Pair &&
            block.timestamp >= lastSwapTime + swapCoolDownTime
        ) {
            swapAndCharge();
            lastSwapTime = block.timestamp;
        }
        //indicates if fee should be deducted from transfer
        bool takeFee = false;
        if (balanceOf(pancakeswapV2Pair) > 0 && (from == pancakeswapV2Pair || to == pancakeswapV2Pair)) {
            takeFee = true;
        }
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapAndCharge() private lockTheSwap {
        swapTokensForEth(balanceOf(address(this))); 
        uint256 bnbBalance = address(this).balance;
        uint256 totalFee = _marketingFee;
        // payable(bnbPoolAddress).call{value: bnbBalance.mul(_BNBFee).div(totalFee)}("");
        payable(marketingAddress).transfer(bnbBalance.mul(_marketingFee).div(totalFee));
    }
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the pancakeswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeswapV2Router.WETH();
        _approve(address(this), address(pancakeswapV2Router), tokenAmount);
        // make the swap
        pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        uint256 tTransferAmount = _getFeeValues(amount);
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(tTransferAmount);   
        uint256 feeAmount = amount.sub(tTransferAmount);
        if(feeAmount > 0){
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }
        emit Transfer(sender, recipient, tTransferAmount);
        if(!takeFee)
            restoreAllFee();
    }
    function burn(uint256 tokenAmount) public{
        uint256 balance = balanceOf(msg.sender);
        require(balance >= tokenAmount && balance >= minBurnAmount,"error");
        _transfer(deadWallet,msg.sender,tokenAmount);
    }
}