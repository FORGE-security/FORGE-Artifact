/*

// website: https://www.paycoincard.com
// telegram: https://t.me/paycoin_crypto

*/
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface Token {
  function transferFrom(
    address,
    address,
    uint256
  ) external returns (bool);

  function transfer(address, uint256) external returns (bool);
}

interface IUniswapV2Factory {
  function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}

interface IUniswapV2Router02 {
  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }
}

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    return c;
  }
}

contract Ownable is Context {
  address private _owner;
  address private _previousOwner;

  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  function transferOwnership(address newOwner) public virtual onlyOwner {
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract PayCoin is Context, IERC20, Ownable {
  using SafeMath for uint256;
  mapping(address => uint256) private _rOwned;
  mapping(address => uint256) private _tOwned;
  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(address => bool) private _isExcludedFromFee;

  uint256 private constant MAX = ~uint256(0);
  uint256 private constant _tTotal = 1000 * 10**6 * 10**9;
  uint256 private _rTotal = (MAX - (MAX % _tTotal));
  uint256 private _tFeeTotal;

  uint256 public _redisFeeOnBuy = 2;
  uint256 public _taxFeeOnBuy = 3;

  uint256 public _redisFeeOnSell = 3;
  uint256 public _taxFeeOnSell = 6;

  uint256 private _redisFee;
  uint256 private _taxFee;

  string private constant _name = "PayCoin";
  string private constant _symbol = "PAY";
  uint8 private constant _decimals = 9;

  address payable private _developmentAddress =
    payable(0xABAF57B948A072A3CFF04405687C10255Dd818c0);
  address payable private _marketingAddress =
    payable(0x99BD0aA06177209387dDF5a7C1025eAAecE9Ff93);
  address payable private _cardFundAddress =
    payable(0xe6bf6f70968640fF4e1EA3dA38a9D71fe8EfC6B2);

  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;

  bool private inSwap = false;
  bool private feeSwap = true;

  modifier lockTheSwap() {
    inSwap = true;
    _;
    inSwap = false;
  }

  constructor() {
    _rOwned[_msgSender()] = _rTotal;

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
      0x10ED43C718714eb63d5aA57B78B54704E256024E
    );
    uniswapV2Router = _uniswapV2Router;
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
      address(this),
      _uniswapV2Router.WETH()
    );

    _isExcludedFromFee[owner()] = true;
    _isExcludedFromFee[address(this)] = true;
    _isExcludedFromFee[_developmentAddress] = true;
    _isExcludedFromFee[_marketingAddress] = true;
    _isExcludedFromFee[_cardFundAddress] = true;

    emit Transfer(
      address(0x0000000000000000000000000000000000000000),
      _msgSender(),
      _tTotal
    );
  }

  modifier onlyDev() {
    require(
      owner() == _msgSender() || _developmentAddress == _msgSender(),
      "Caller is not the dev"
    );
    _;
  }

  function name() public pure returns (string memory) {
    return _name;
  }

  function symbol() public pure returns (string memory) {
    return _symbol;
  }

  function decimals() public pure returns (uint8) {
    return _decimals;
  }

  function totalSupply() public pure override returns (uint256) {
    return _tTotal;
  }

  function balanceOf(address account) public view override returns (uint256) {
    return tokenFromReflection(_rOwned[account]);
  }

  function transfer(address recipient, uint256 amount)
    public
    override
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender)
    public
    view
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount)
    public
    override
    returns (bool)
  {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(
        amount,
        "ERC20: transfer amount exceeds allowance"
      )
    );
    return true;
  }

  function tokenFromReflection(uint256 rAmount) private view returns (uint256) {
    require(rAmount <= _rTotal, "Amount must be less than total reflections");
    uint256 currentRate = _getRate();
    return rAmount.div(currentRate);
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) private {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) private {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");

    _redisFee = 0;
    _taxFee = 0;

    if (from != owner() && to != owner()) {
      uint256 contractTokenBalance = balanceOf(address(this));
      if (
        !inSwap && from != uniswapV2Pair && feeSwap && contractTokenBalance > 0
      ) {
        swapTokensForEth(contractTokenBalance);
        uint256 contractETHBalance = address(this).balance;
        if (contractETHBalance > 0) {
          sendETHToFee(address(this).balance);
        }
      }

      if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
        _redisFee = _redisFeeOnBuy;
        _taxFee = _taxFeeOnBuy;
      }

      if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
        _redisFee = _redisFeeOnSell;
        _taxFee = _taxFeeOnSell;
      }

      if (
        (_isExcludedFromFee[from] || _isExcludedFromFee[to]) ||
        (from != uniswapV2Pair && to != uniswapV2Pair)
      ) {
        _redisFee = 0;
        _taxFee = 0;
      }
    }

    _tokenTransfer(from, to, amount);
  }

  function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0,
      path,
      address(this),
      block.timestamp
    );
  }

  function sendETHToFee(uint256 amount) private {
    _developmentAddress.transfer(amount.div(3));
    _cardFundAddress.transfer(amount.div(3));
    _marketingAddress.transfer(amount.div(3));
  }

  function _tokenTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) private {
    _transferStandard(sender, recipient, amount);
  }

  event devAddressUpdated(address indexed previous, address indexed adr);

  function setdevAddress(address payable dev) public onlyDev {
    emit devAddressUpdated(_developmentAddress, dev);
    _developmentAddress = dev;
    _isExcludedFromFee[_developmentAddress] = true;
  }

  event marketingAddressUpdated(address indexed previous, address indexed adr);

  function setmarketingAddress(address payable markt) public onlyDev {
    emit marketingAddressUpdated(_marketingAddress, markt);
    _marketingAddress = markt;
    _isExcludedFromFee[_marketingAddress] = true;
  }

  event cardFundAddressUpdated(address indexed previous, address indexed adr);

  function setcardFundAddress(address payable cardf) public onlyDev {
    emit cardFundAddressUpdated(_cardFundAddress, cardf);
    _cardFundAddress = cardf;
    _isExcludedFromFee[_cardFundAddress] = true;
  }

  function _transferStandard(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    (
      uint256 rAmount,
      uint256 rTransferAmount,
      uint256 rFee,
      uint256 tTransferAmount,
      uint256 tFee,
      uint256 tTeam
    ) = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeTeam(tTeam);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _takeTeam(uint256 tTeam) private {
    uint256 currentRate = _getRate();
    uint256 rTeam = tTeam.mul(currentRate);
    _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
  }

  function _reflectFee(uint256 rFee, uint256 tFee) private {
    _rTotal = _rTotal.sub(rFee);
    _tFeeTotal = _tFeeTotal.add(tFee);
  }

  receive() external payable {}

  function _getValues(uint256 tAmount)
    private
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(
      tAmount,
      _redisFee,
      _taxFee
    );
    uint256 currentRate = _getRate();
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
      tAmount,
      tFee,
      tTeam,
      currentRate
    );
    return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
  }

  function _getTValues(
    uint256 tAmount,
    uint256 taxFee,
    uint256 TeamFee
  )
    private
    pure
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 tFee = tAmount.mul(taxFee).div(100);
    uint256 tTeam = tAmount.mul(TeamFee).div(100);
    uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
    return (tTransferAmount, tFee, tTeam);
  }

  function _getRValues(
    uint256 tAmount,
    uint256 tFee,
    uint256 tTeam,
    uint256 currentRate
  )
    private
    pure
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 rAmount = tAmount.mul(currentRate);
    uint256 rFee = tFee.mul(currentRate);
    uint256 rTeam = tTeam.mul(currentRate);
    uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
    return (rAmount, rTransferAmount, rFee);
  }

  function _getRate() private view returns (uint256) {
    (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
    return rSupply.div(tSupply);
  }

  function _getCurrentSupply() private view returns (uint256, uint256) {
    uint256 rSupply = _rTotal;
    uint256 tSupply = _tTotal;
    if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
    return (rSupply, tSupply);
  }

  function manualswap() external {
    require(
      _msgSender() == _developmentAddress ||
        _msgSender() == _cardFundAddress ||
        _msgSender() == owner()
    );
    uint256 contractBalance = balanceOf(address(this));
    swapTokensForEth(contractBalance);
  }

  function manualsend() external {
    require(
      _msgSender() == _developmentAddress ||
        _msgSender() == _cardFundAddress ||
        _msgSender() == owner()
    );
    uint256 contractETHBalance = address(this).balance;
    sendETHToFee(contractETHBalance);
  }

  function setFee(
    uint256 redisFeeOnBuy,
    uint256 redisFeeOnSell,
    uint256 taxFeeOnBuy,
    uint256 taxFeeOnSell
  ) public onlyDev {
    require(redisFeeOnBuy < 13, "Redis cannot be more than 13.");
    require(redisFeeOnSell < 13, "Redis cannot be more than 13.");
    require(taxFeeOnBuy < 12, "Tax cannot be more than 12.");
    require(taxFeeOnSell < 12, "Tax cannot be more than 12.");
    _redisFeeOnBuy = redisFeeOnBuy;
    _redisFeeOnSell = redisFeeOnSell;
    _taxFeeOnBuy = taxFeeOnBuy;
    _taxFeeOnSell = taxFeeOnSell;
  }

  function toggleSwap(bool _feeSwap) public onlyDev {
    feeSwap = _feeSwap;
  }

  function excludeMultipleAccountsFromFees(
    address[] calldata accounts,
    bool excluded
  ) public onlyDev {
    for (uint256 i = 0; i < accounts.length; i++) {
      _isExcludedFromFee[accounts[i]] = excluded;
    }
  }
}