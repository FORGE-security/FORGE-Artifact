// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "./IBEP20.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IPancakeswapV2Factory.sol";
import "./IPancakeswapV2Router02.sol";



contract GameLoungeToken is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    address public bnbPoolAddress;
    
    uint256 private _tTotal = 10 * 10**6 * 10**18;
    uint256 private constant MAX = ~uint256(0);
    string private _name = "GameLounge";
    string private _symbol = "GML";
    uint8 private _decimals = 18;
    
    uint256 public _BNBFeeBuy = 2;
    uint256 public _BNBFeeSell = 11;
    uint256 private _previousBNBFeeBuy = _BNBFeeBuy;
    uint256 private _previousBNBFeeSell = _BNBFeeSell;
    
    uint256 public _liquidityFeeBuy = 0;
    uint256 public _liquidityFeeSell = 0;
    uint256 private _previousLiquidityFeeBuy = _liquidityFeeBuy;
    uint256 private _previousLiquidityFeeSell = _liquidityFeeSell;
    uint256 public swapPerc = 1000 ; // add 00

    IPancakeswapV2Router02 public pancakeswapV2Router;
    address public pancakeswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public presaleEnded = false;
    
    uint256 public _maxTxAmount =  1 * 10**6 * 10**18;
    uint256 private numTokensToSwap =  1000 * 10**18; 
    uint256 public swapCoolDownTime = 600;
    // address public pairToken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    // uint256 public swapCoolDownTimeForUser = 60;
    uint256 private lastSwapTime;
    mapping(address => uint256) private lastTxTimes;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
    event ExcludedFromFee(address account);
    event IncludedToFee(address account);
    event UpdateFees(uint256 bnbFee, uint256 liquidityFee);
    event UpdatedMaxTxAmount(uint256 maxTxAmount);
    event UpdateNumtokensToSwap(uint256 amount);
    event UpdateBNBPoolAddresss(address account);
    event SwapAndCharged(uint256 token, uint256 liquidAmount, uint256 bnbPool,  uint256 bnbLiquidity);
    event UpdatedCoolDowntime(uint256 timeForContract);
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {
        //Test Net
        //IPancakeswapV2Router02 _pancakeswapV2Router = IPancakeswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        //Mian Net
        IPancakeswapV2Router02 _pancakeswapV2Router = IPancakeswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        
        pancakeswapV2Pair = IPancakeswapV2Factory(_pancakeswapV2Router.factory())
            .createPair(address(this), _pancakeswapV2Router.WETH());

        // set the rest of the contract variables
        pancakeswapV2Router = _pancakeswapV2Router;
        
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

    function setBNBPoolAddresss(address account) external onlyOwner {
        require(account != bnbPoolAddress, 'This address was already used');
        bnbPoolAddress = account;
        emit UpdateBNBPoolAddresss(account);
    }
    function setCoolDownTime(uint256 timeForContract) external onlyOwner {
        require(swapCoolDownTime != timeForContract);
        swapCoolDownTime = timeForContract;
        emit UpdatedCoolDowntime(timeForContract);
    }
    function updatePresaleStatus(bool status) external onlyOwner {
        presaleEnded = status;
    }
    
    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
        emit ExcludedFromFee(account);
    }
     function setSwapPerc(uint256 _swapPerc) external onlyOwner {
        swapPerc  = _swapPerc;
        
    }
    
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
        emit IncludedToFee(account);
    }
    
    function setBuyFees(uint256 bnbFee, uint256 liquidityFee) external onlyOwner() {
        require(_BNBFeeBuy != bnbFee || _liquidityFeeBuy != liquidityFee);
        _BNBFeeBuy = bnbFee;
        _liquidityFeeBuy = liquidityFee;
        emit UpdateFees(bnbFee, liquidityFee);
    }

       function setSellFees(uint256 bnbFee, uint256 liquidityFee) external onlyOwner() {
        require(_BNBFeeSell != bnbFee || _liquidityFeeSell != liquidityFee);
        _BNBFeeSell = bnbFee;
        _liquidityFeeSell = liquidityFee;
        emit UpdateFees(bnbFee, liquidityFee);
    }
   
    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        _maxTxAmount = maxTxAmount;
        emit UpdatedMaxTxAmount(maxTxAmount);
    }
    
    function setNumTokensToSwap(uint256 amount) external onlyOwner() {
        require(numTokensToSwap != amount);
        numTokensToSwap = amount;
        emit UpdateNumtokensToSwap(amount);
    }


    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
     //to receive ETH from pancakeswapV2Router when swapping
    receive() external payable {}

    function _getBuyFeeValues(uint256 tAmount) private view returns (uint256) {
        uint256 fee = tAmount.mul(_BNBFeeBuy + _liquidityFeeBuy).div(10**2);
        uint256 tTransferAmount = tAmount.sub(fee);
        return tTransferAmount;
    }

    function _getSellFeeValues(uint256 tAmount) private view returns (uint256) {
        uint256 fee = tAmount.mul(_BNBFeeSell + _liquidityFeeSell).div(10**2);
        uint256 tTransferAmount = tAmount.sub(fee);
        return tTransferAmount;
    }

    function removeAllFee() private {
        if(_BNBFeeBuy == 0 && _liquidityFeeBuy == 0 && _liquidityFeeSell == 0 && _BNBFeeSell == 0) return;
        
        _previousBNBFeeSell = _BNBFeeSell;
        _previousLiquidityFeeSell = _liquidityFeeSell;
        
        _previousBNBFeeBuy = _BNBFeeBuy;
        _previousLiquidityFeeBuy = _liquidityFeeBuy;

        _BNBFeeSell = 0;
        _liquidityFeeSell = 0;

        _BNBFeeBuy = 0;
        _liquidityFeeBuy = 0;
    }
    
    function restoreAllFee() private {
        _BNBFeeBuy = _previousBNBFeeBuy;
        _liquidityFeeBuy = _previousLiquidityFeeBuy;
        
        _BNBFeeSell = _previousBNBFeeSell;
        _liquidityFeeSell = _previousLiquidityFeeSell;
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
        if (to == pancakeswapV2Pair && balanceOf(pancakeswapV2Pair) == 0) {
            require(presaleEnded == true, "You are not allowed to add liquidity before presale is ended");
        }
        if(
            !_isExcludedFromFee[from] && 
            !_isExcludedFromFee[to] && 
            balanceOf(pancakeswapV2Pair) > 0 && 
            !inSwapAndLiquify &&
            from != address(pancakeswapV2Router) && 
            (from == pancakeswapV2Pair || to == pancakeswapV2Pair)
        ) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");          
        }

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancakeswap pair.
        uint256 tokenBalance = balanceOf(address(this));
        if(tokenBalance >= _maxTxAmount)
        {
            tokenBalance = _maxTxAmount;
        }
        
        bool overMinTokenBalance = tokenBalance >= numTokensToSwap;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != pancakeswapV2Pair &&
            to == pancakeswapV2Pair &&
            swapAndLiquifyEnabled &&
            block.timestamp >= lastSwapTime + swapCoolDownTime 
        ) {
            uint256 _tokentoSell = amount.mul(swapPerc).div(10000);
             if(_tokentoSell >= tokenBalance)
              {
                _tokentoSell = tokenBalance;
              }
            swapAndChargeSell(_tokentoSell);
            lastSwapTime = block.timestamp;
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = false;
        if (balanceOf(pancakeswapV2Pair) > 0 &&  (from == pancakeswapV2Pair || to == pancakeswapV2Pair) ) {
            takeFee = true;
        }
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapAndChargeSell(uint256 tokenBalance) private lockTheSwap {
         uint256 initialBalance = address(this).balance;

        uint256 liquidBalance = tokenBalance.mul(_liquidityFeeSell).div(_liquidityFeeSell + _BNBFeeSell).div(2);
        tokenBalance = tokenBalance.sub(liquidBalance);
        swapTokensForEth(tokenBalance); 

        uint256 newBalance = address(this).balance.sub(initialBalance);
        uint256 bnbForLiquid = newBalance.mul(liquidBalance).div(tokenBalance);
        if(_liquidityFeeSell > 0){
        addLiquidity(liquidBalance, bnbForLiquid);
        }
    

        (bool success, ) = payable(bnbPoolAddress).call{value: address(this).balance}("");
        require(success == true, "Transfer failed.");
        emit SwapAndCharged(tokenBalance, liquidBalance, address(this).balance, bnbForLiquid);
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

   
     function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeswapV2Router), tokenAmount);

        // add the liquidity
        pancakeswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }


    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        uint256 tTransferAmount = amount ; 
        if(takeFee && sender == pancakeswapV2Pair){
            tTransferAmount = _getBuyFeeValues(amount);
        }
        if(takeFee && recipient == pancakeswapV2Pair){
            tTransferAmount = _getSellFeeValues(amount);
        }
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(tTransferAmount);   
        _balances[address(this)] = _balances[address(this)].add(amount.sub(tTransferAmount));
        emit Transfer(sender, recipient, tTransferAmount);
        
        if(!takeFee)
            restoreAllFee();
    }
}