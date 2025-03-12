// SPDX-License-Identifier: MIT


// Telegram : https://t.me/Neuralinkprotocol
// Twitter : https://twitter.com/Neuralinkpro
// Website : Neuralinkprotocol.io

pragma solidity ^0.8.4;

interface IERC20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address) { return msg.sender; }
  function _msgData() internal view virtual returns (bytes calldata) { return msg.data; }
}

contract Ownable is Context {
  address public _owner;
  address public _creator;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor() {
    _transferOwnership(_msgSender());
    _creator = _msgSender();
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

interface IFactory {
	event PairCreated(address indexed token0, address indexed token1, address pair, uint256);
	function feeTo() external view returns (address);
	function feeToSetter() external view returns (address);
	function getPair(address tokenA, address tokenB) external view returns (address pair);
	function allPairs(uint256) external view returns (address pair);
	function allPairsLength() external view returns (uint256);
	function createPair(address tokenA, address tokenB) external returns (address pair);
	function setFeeTo(address) external;
	function setFeeToSetter(address) external;
}

interface IRouter {
	function factory() external pure returns (address);
	function WETH() external pure returns (address);
	function addLiquidity(
		address tokenA,
		address tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountA, uint256 amountB, uint256 liquidity );
	function addLiquidityETH(
		address token,
		uint256 amountTokenDesired,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);
	function swapTokensForExactTokens(
		uint256 amountOut,
		uint256 amountInMax,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);
	function swapExactETHForTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);
	function swapTokensForExactETH(
		uint256 amountOut,
		uint256 amountInMax,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);
	function swapExactTokensForETH(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);
	function swapETHForExactTokens(
		uint256 amountOut,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);
	function quote(
		uint256 amountA,
		uint256 reserveA,
		uint256 reserveB
	) external pure returns (uint256 amountB);
	function getAmountOut(
		uint256 amountIn,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountOut);
	function getAmountIn(
		uint256 amountOut,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountIn);
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
	function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
	function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b; require(c >= a, "SafeMath: addition overflow"); return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) { return sub(a, b, "SafeMath: subtraction overflow"); }
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage); uint256 c = a - b; return c;
  }
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) { return 0; }
    uint256 c = a * b; require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) { return div(a, b, "SafeMath: division by zero"); }
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage); uint256 c = a / b; return c;
  }
}

contract TaxPool is Ownable {
  bool inSwap;
  modifier swapping() { inSwap = true; _; inSwap = false; }
  uint256 public balance;
  uint256 public maxPercent = 10000;

  uint256 public rndPercentage = 2000; address public rndWallet = 0xfCE863916F4130EC83A94117414164AB7636E0bD;
  function setRND (uint256 percent_, address wallet_) public onlyOwner { rndPercentage = percent_; rndWallet = wallet_; }
  
  uint256 public marketingPercentage = 6000; address public marketingWallet = 0x79B51d07D6fAca7d25D4e2d70b3F1f8fD2a3fD55;
  function setMarketing (uint256 percent_, address wallet_) public onlyOwner { marketingPercentage = percent_; marketingWallet = wallet_; }
  
  uint256 public buybackandburnPercentage = 2000; address public buybackandburnWallet = 0x9943F9B4A34Fbeeb53c08efD0CF0817c383216E8;
  function setBuyandburn (uint256 percent_, address wallet_) public onlyOwner { buybackandburnPercentage = percent_; buybackandburnWallet = wallet_; }

  receive() external payable { balance += msg.value; }
  function getBalance() public view returns (uint) { return balance; }

  function distribute() public onlyOwner swapping {
    require(rndPercentage + marketingPercentage + buybackandburnPercentage == maxPercent, "The sum of percentage isn't 100.");
    require(
         rndWallet != address(0)
      && marketingWallet != address(0)
      && buybackandburnWallet != address(0)
      ,
      "Cannot send to zero wallet."
    );
    uint256 amount = getBalance();
    (bool sent_1, ) = payable(rndWallet).call{value: (amount * rndPercentage / maxPercent), gas: 30000}(""); require(sent_1, "Transfer wallet_1 error."); balance = address(this).balance;
    (bool sent_2, ) = payable(marketingWallet).call{value: (amount * marketingPercentage / maxPercent), gas: 30000}(""); require(sent_2, "Transfer wallet_2 error."); balance = address(this).balance;
    (bool sent_3, ) = payable(buybackandburnWallet).call{value: (amount * buybackandburnPercentage / maxPercent), gas: 30000}(""); require(sent_3, "Transfer wallet_3 error."); balance = address(this).balance;
  }

  function kill() public onlyOwner { selfdestruct(payable(owner())); }
}

interface InterfaceTaxPool {
  function setRND (uint256 percent_, address wallet_) external;
  function setMarketing (uint256 percent_, address wallet_) external;
  function setBuyandburn (uint256 percent_, address wallet_) external;
  function getBalance() external view returns(uint256 balance_);
  function distribute() external;
  function kill () external;
  function transferOwnership(address newOwner) external; 
}

contract NEURA is 
  Context
  , Ownable
  , IERC20
  , IERC20Metadata
{
  using SafeMath for uint256;
  string private _name = "Neuralink Protocol";
  string private _symbol = "NEURA";
  uint8 private _decimals = 9;
  uint256 private _totalSupply;
  uint256 public _tax = 10;
  uint256 public _taxDivider = 100;
  address public _taxPool;
  function setTax(uint256 input_) public onlyOwner { _tax = input_; }
  function setTaxDivider(uint256 input_) public onlyOwner { _taxDivider = input_; }
  function setTaxPool(address input_) public onlyOwner { 
    require(input_ != address(0), "Zero Address."); 
    _taxPool = input_; 
    iTaxPool = InterfaceTaxPool(input_);
  }

  address DEAD = 0x000000000000000000000000000000000000dEaD;
  address ZERO = address(0);
  address ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
  address FACTORY = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
  address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
  address public _pair;
  IRouter public _router;
  bool public inSwap;
  modifier swapping() { inSwap = true; _; inSwap = false; }
  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(address => bool) public _excludedBuyFee;
  mapping(address => bool) public _excludedSellFee;
  function changeExcludeBuyFee (address input_) public onlyOwner { _excludedBuyFee[input_] = !_excludedBuyFee[input_]; }
  function changeExcludeSellFee (address input_) public onlyOwner { _excludedSellFee[input_] = !_excludedSellFee[input_]; }

  InterfaceTaxPool private iTaxPool;

  constructor() {
    emit OwnershipTransferred(address(0), _msgSender());
    _router = IRouter(ROUTER);
    _pair = IFactory(_router.factory()).createPair(WBNB, address(this));
    _excludedSellFee[owner()] = true;
    _excludedSellFee[address(this)] = true;
    _excludedSellFee[DEAD] = true;
    _excludedBuyFee[owner()] = true;
    _excludedBuyFee[address(this)] = true;
    _excludedBuyFee[DEAD] = true;
    _allowances[address(this)][address(_router)] = ~uint256(0);
    _mint(_msgSender(), 1000000000 * 10 ** uint256(_decimals));
  }

  receive() external payable {  }

  function name() public view virtual override returns (string memory) { return _name; }
  function symbol() public view virtual override returns (string memory) { return _symbol; }
  function decimals() public view virtual override returns (uint8) { return _decimals; }
  function totalSupply() public view virtual override returns (uint256) { return _totalSupply; }
  function balanceOf(address account) public view virtual override returns (uint256) { return _balances[account]; }
  function allowance(address owner, address spender) public view virtual override returns (uint256) { return _allowances[owner][spender]; }
  function currentBalance() public view returns(uint256) { return balanceOf(address(this)); }
  function contractBalance() public view returns(uint256) { return address(this).balance; }
  function taxBalance() public view onlyOwner returns(uint256) { return iTaxPool.getBalance(); }
  function distributeTax() public onlyOwner { iTaxPool.distribute(); }
  function setRndTax(uint256 percent_, address wallet_) public onlyOwner { iTaxPool.setRND(percent_, wallet_); }
  function setMarketingTax(uint256 percent_, address wallet_) public onlyOwner { iTaxPool.setMarketing(percent_, wallet_); }
  function setBuyandburnTax(uint256 percent_, address wallet_) public onlyOwner { iTaxPool.setBuyandburn(percent_, wallet_); }
  function setTaxTransferOwner(address newOwner_) public onlyOwner { iTaxPool.transferOwnership(newOwner_); }
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transferTax(_msgSender(), recipient, amount);
    return true;
  }
  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    if(_allowances[sender][_msgSender()] != ~uint256(0)){
      _allowances[sender][_msgSender()] = _allowances[sender][_msgSender()].sub(amount, "Insufficient allowance.");
    }

    _transferTax(sender, recipient, amount);

    return true;
  }
  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
    return true;
  }
  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(currentAllowance >= subtractedValue, "decreased allowance below zero");
    unchecked {
      _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }
    return true;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual returns(bool) {
    require(sender != address(0), "transfer from the zero address");
    require(recipient != address(0), "transfer to the zero address");
    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "transfer amount exceeds balance");

    unchecked {
       _balances[sender] = senderBalance - amount;
    }

    _balances[recipient] += amount;
    emit Transfer(sender, recipient, amount);
    return true;
  }

  function _transferTax(address sender, address recipient, uint256 amount) internal returns (bool) {
    if(inSwap) return _transfer(sender, recipient, amount);

    uint256 amountReceived = amount;

    if (sender == _pair) { 
      // buy
      _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
      if (!_excludedBuyFee[recipient]) {
        amountReceived = takeFee(amount);
      }
    } else if (recipient == _pair) { 
      // sell
      _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
      if (!_excludedSellFee[sender]) {
        amountReceived = takeFee(amount);
        distributeFee();
      }
    } else { 
      // normal transfer
      _transfer(sender, recipient, amount);
       return true;
    }
    _balances[recipient] = _balances[recipient].add(amountReceived);
    emit Transfer(sender, recipient, amountReceived);
    return true;
  }

  function takeFee (uint256 amount_) private returns(uint256){
    uint256 fee = _tax.mul(amount_).div(_taxDivider);
    _balances[address(this)] = _balances[address(this)].add(fee);
    return amount_.sub(fee);
  }

  function distributeFee () private swapping {
    uint256 swapAmount = _balances[address(this)];
    
    if (_balances[address(this)] > 0) {
      address[] memory path = new address[](2);
      path[0] = address(this);
      path[1] = address(WBNB);
      
      uint256 currentBNBBalance = address(this).balance;
      try _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
        swapAmount,
        0,
        path,
        address(this),
        block.timestamp
      ) {
        uint256 amountBNB = address(this).balance.sub(currentBNBBalance);
        (bool sent, ) = payable(_taxPool).call{value: amountBNB, gas: 30000}(""); require(sent, "Transfer error.");
      } catch Error(string memory e) { emit DistributeFailed(e); }
    }
  }
  event DistributeFailed(string message);


  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "mint to the zero address");

    _totalSupply += amount;
    _balances[account] += amount;
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "burn from the zero address");

    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, "burn amount exceeds balance");
    unchecked {
      _balances[account] = accountBalance - amount;
    }
    _totalSupply -= amount;

    emit Transfer(account, address(0), amount);
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), "approve from the zero address");
    require(spender != address(0), "approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
}