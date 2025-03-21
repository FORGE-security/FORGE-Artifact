/*
╭╮╱╱╭┳━━━╮ ╭━━━┳━━━┳━━━┳╮╭━┳━━━┳━━━━╮
┃╰╮╭╯┃╭━╮┃ ┃╭━╮┃╭━╮┃╭━╮┃┃┃╭┫╭━━┫╭╮╭╮┃
╰╮╰╯╭┫┃╱┃┃ ┃╰━╯┃┃╱┃┃┃╱╰┫╰╯╯┃╰━━╋╯┃┃╰╯
╱╰╮╭╯┃┃╱┃┃ ┃╭╮╭┫┃╱┃┃┃╱╭┫╭╮┃┃╭━━╯╱┃┃
╱╱┃┃╱┃╰━╯┃ ┃┃┃╰┫╰━╯┃╰━╯┃┃┃╰┫╰━━╮╱┃┃
╱╱╰╯╱╰━━━╯ ╰╯╰━┻━━━┻━━━┻╯╰━┻━━━╯╱╰╯


🚀 YoRocket Features:

⌚️ YoTime - For one hour per day, buy taxes will be reduced to 1% (added to LP). 

🎁 YoRaffle - biweekly prizes

Top 19 holders 20 raffle tickets each 
20-250- holders 10 raffle tickets each 
251-500- holders 7 raffle tickets each 
501-750- holders 5 raffle tickets each 
751-last holder- holders 2 raffle tickets each 

♻️ YoStake- Investors can stake to earn double the YoRocket reflection tax! 

🤝 YoSell - Max 2% price impact per every 5 minutes. Min sell 0.01 BnB. 

🖼 YoNFT - Coming soon… 

🏆 Buy 8.0%:
♻️ 1% Reflection 
🌐 3% Marketing
🎁 3% Raffle 
💧 1% Liquidity Pool

🏆 Sell 12%:
♻️ 3% Reflection 
🌐 4% Marketing
🎁 4% Raffle 
💧 1% Liquidity Pool

Smart contract developed by Alex $Saint
Reach on telegram: @Alex_Saint_Dev
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
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
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

abstract contract IERC20Extented is IERC20 {
    function decimals() external view virtual returns (uint8);
    function name() external view virtual returns (string memory);
    function symbol() external view virtual returns (string memory);
}

contract YoRocket is Context, IERC20, IERC20Extented, Ownable {
    using SafeMath for uint256;
    string private constant _name = "YoRocket";
    string private constant _symbol = "$YO";
    uint8 private constant _decimals = 9;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;

    mapping(address => uint256) private sellcooldown;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isContract;
    mapping(address => uint256) private previousTransactionBlock;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000000 * 10**9; // 1 Trillion
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 public _priceImpact = 2;
    uint256 private _firstBlock;
    uint256 private _botBlocks;
    uint256 public _maxWalletAmount;
    uint256 private _maxSellAmountBNB = 5000000000000000000; // 5 BNB
    uint256 private _minBuyBNB = 10000000000000000; // 0.01 BNB
    uint256 private _minSellBNB = 10000000000000000; // 0.01 BNB
    uint256 private _yoTimeBlocks = 3600; // 1 hour
    uint256 private _cooldownBlocks = 300; // 5 min
    uint256 private _yoTimeWindowEnd; // block.timestamp + _taxFreeBlocks
    uint256 public _yoTimeStartBlock = 0;
    uint256 public _yoTimeStartTime = 56000; // 6pm est 
    bool public _yoTimeStarted = false;
    uint256 public minTokensToSwap = 10000000 * 10**9; // 0.001 % of supply

    //  buy fees
    uint256 public _buyRaffleFee = 3;
    uint256 private _previousBuyRaffleFee = _buyRaffleFee;
    uint256 public _buyMarketingFee = 3;
    uint256 private _previousBuyMarketingFee = _buyMarketingFee;
    uint256 public _buyReflectionFee = 1;
    uint256 private _previousBuyReflectionFee = _buyReflectionFee;
    uint256 public _buyLiquidityFee = 1;
    uint256 private _previousBuyLiquidityFee = _buyLiquidityFee;
    
    // sell fees
    uint256 public _sellRaffleFee = 4;
    uint256 private _previousSellRaffleFee = _sellRaffleFee;
    uint256 public _sellMarketingFee = 4;
    uint256 private _previousSellMarketingFee = _sellMarketingFee;
    uint256 public _sellReflectionFee = 3;
    uint256 private _previousSellReflectionFee = _sellReflectionFee;
    uint256 public _sellLiquidityFee = 1;
    uint256 private _previousSellLiquidityFee = _sellLiquidityFee;
  
    struct DynamicTax {
        uint256 buyRaffleFee;
        uint256 buyMarketingFee;
        uint256 buyReflectionFee;
        uint256 buyLiquidityFee;
        
        uint256 sellRaffleFee;
        uint256 sellMarketingFee;
        uint256 sellReflectionFee;
        uint256 sellLiquidityFee;
    }
    
    uint256 constant private _projectMaintainencePercent = 3;
    uint256 private _rafflePercent = 48;
    uint256 private _marketingPercent = 49;

    struct BuyBreakdown {
        uint256 tTransferAmount;
        uint256 tRaffle;
        uint256 tMarketing;
        uint256 tReflection;
        uint256 tLiquidity;
    }

    struct SellBreakdown {
        uint256 tTransferAmount;
        uint256 tRaffle;
        uint256 tMarketing;
        uint256 tReflection;
        uint256 tLiquidity;
    }
    
    struct FinalFees {
        uint256 tTransferAmount;
        uint256 tRaffle;
        uint256 tMarketing;
        uint256 tReflection;
        uint256 tLiquidity;
        uint256 rReflection;
        uint256 rTransferAmount;
        uint256 rAmount;
    }

    mapping(address => bool) private bots;
    address payable private _marketingAddress = payable(0x4e51bf85E4aEDE62205c8E5097B184e80bB13BCd);
    address payable private _raffleAddress = payable(0xe2a11509bf856A97FF983A4E761a3F0e2b1DA15a);
    address payable constant private _projectMaintainence = payable(0xe4c871834A8D4743aA6d6B62dE7A36a59C45b126);
    address payable constant private _burnAddress = payable(0x000000000000000000000000000000000000dEaD);
    address payable public stakingAddress = payable(0xE69E8cc2ec9245f63214B52537B44f4642701C3b);
    address private presaleRouter;
    address private presaleAddress;
    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    uint256 private _maxTxAmount;

    bool private tradingOpen = false;
    bool private inSwap = false;
    bool private presale = true;
    bool private pairSwapped = false;
    bool private autoYoTimeEnabled = false;
    bool public _sellCoolDownEnabled = true;
    bool public _priceImpactSellLimitEnabled = true;
    bool public _BNBsellLimitEnabled = false;
    bool public swapAndLiquifyEnabled = true;

    event EndedPresale(bool presale);
    event UpdatedAllowableDip(uint256 hundredMinusDipPercent);
    event UpdatedHighLowWindows(uint256 GTblock, uint256 LTblock, uint256 blockWindow);
    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    event SellOnlyUpdated(bool sellOnly);
    event PercentsUpdated(uint256 _marketingPercent, uint256 _buybackPercent, uint256 _devPercent);
    event FeesUpdated(uint256 _buyRaffleFee, uint256 _buyMarketingFee, uint256 _buyLiquidityFee, uint256 _buyReflectionFee, uint256 _sellRaffleFee, uint256 _sellMarketingFee, uint256 _sellLiquidityFee, uint256 _sellReflectionFee);
    event PriceImpactUpdated(uint256 _priceImpact);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);//ropstenn 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //bsc test 0xD99D1c33F9fC3444f8101754aBC46c52416550D1);//bsc main net 0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);

        _maxTxAmount = _tTotal; // start off transaction limit at 100% of total supply
        _maxWalletAmount = _tTotal.div(1); // 100%

        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isContract[0x021b4c03d51280E54678C88b1eACb612F299e6d9]; // v1 contract
        emit Transfer(address(0), _msgSender(), _tTotal);
    }
    
    function name() override external pure returns (string memory) {
        return _name;
    }

    function symbol() override external pure returns (string memory) {
        return _symbol;
    }

    function decimals() override external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function isBot(address account) public view returns (bool) {
        return bots[account];
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal,"Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function removeAllFee() private {
        if (_buyMarketingFee == 0 && _buyRaffleFee == 0 && _buyReflectionFee == 0 && _buyLiquidityFee == 0 && _sellMarketingFee == 0 && _sellRaffleFee == 0 && _sellReflectionFee == 0 && _sellLiquidityFee == 0) return;
        _previousBuyMarketingFee = _buyMarketingFee;
        _previousBuyRaffleFee = _buyRaffleFee;
        _previousBuyReflectionFee = _buyReflectionFee;
        _previousBuyLiquidityFee = _buyLiquidityFee;
        
        _previousSellMarketingFee = _sellMarketingFee;
        _previousSellRaffleFee = _sellRaffleFee;
        _previousSellReflectionFee = _sellReflectionFee;
        _previousSellLiquidityFee = _sellLiquidityFee;

        _buyMarketingFee = 0;
        _buyRaffleFee = 0;
        _buyReflectionFee = 0;
        _buyLiquidityFee = 0;

        _sellMarketingFee = 0;
        _sellRaffleFee = 0;
        _sellReflectionFee = 0;
        _sellLiquidityFee = 0;
    }

    function setBotFee() private {
        _previousBuyMarketingFee = _buyMarketingFee;
        _previousBuyRaffleFee = _buyRaffleFee;
        _previousBuyReflectionFee = _buyReflectionFee;
        _previousBuyLiquidityFee = _buyLiquidityFee;

        _previousSellMarketingFee = _sellMarketingFee;
        _previousSellRaffleFee = _sellRaffleFee;
        _previousSellReflectionFee = _sellReflectionFee;
        _previousSellLiquidityFee = _sellLiquidityFee;

        _buyMarketingFee = 45;
        _buyRaffleFee = 45;
        _buyReflectionFee = 0;
        _buyLiquidityFee = 0;

        _sellMarketingFee = 45;
        _sellRaffleFee = 45;
        _sellReflectionFee = 0;
        _sellLiquidityFee = 0;
    }
    
    function restoreAllFee() private {
        _buyMarketingFee = _previousBuyMarketingFee;
        _buyRaffleFee = _previousBuyRaffleFee;
        _buyReflectionFee = _previousBuyReflectionFee;
        _buyLiquidityFee = _previousBuyLiquidityFee;

        _sellMarketingFee = _previousSellMarketingFee;
        _sellRaffleFee = _previousSellRaffleFee;
        _sellReflectionFee = _previousSellReflectionFee;
        _sellLiquidityFee = _previousSellLiquidityFee;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // calculate price based on pair reserves
    function getTokenPriceBNB(uint256 amount) external view returns(uint256) {
        IERC20Extented token0 = IERC20Extented(IUniswapV2Pair(uniswapV2Pair).token0());//$YO
        IERC20Extented token1 = IERC20Extented(IUniswapV2Pair(uniswapV2Pair).token1());//bnb
        (uint112 Res0, uint112 Res1,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        if(pairSwapped) {
            token0 = IERC20Extented(IUniswapV2Pair(uniswapV2Pair).token1());//$YO
            token1 = IERC20Extented(IUniswapV2Pair(uniswapV2Pair).token0());//bnb
            (Res1, Res0,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        }

        uint res1 = Res1*(10**token0.decimals());
        return((amount*res1)/(Res0*(10**token0.decimals()))); // return amount of token1 needed to buy token0
    }
    
    function updateFee() private returns(DynamicTax memory) {
        
        DynamicTax memory currentTax;
        
        currentTax.buyRaffleFee = _buyRaffleFee;
        currentTax.buyMarketingFee = _buyMarketingFee;
        currentTax.buyLiquidityFee = _buyLiquidityFee;
        currentTax.buyReflectionFee = _buyReflectionFee;

        currentTax.sellRaffleFee = _sellRaffleFee;
        currentTax.sellMarketingFee = _sellMarketingFee;
        currentTax.sellLiquidityFee = _sellLiquidityFee;
        currentTax.sellReflectionFee = _sellReflectionFee;

        if(block.timestamp >= _yoTimeStartBlock && block.timestamp <= _yoTimeWindowEnd) {
            currentTax.buyRaffleFee = 0;
            currentTax.buyMarketingFee = 0;
            currentTax.buyLiquidityFee = 1;
            currentTax.buyReflectionFee = 0;
        }
        if (block.timestamp > _yoTimeWindowEnd && _yoTimeStarted) {
            _yoTimeStarted = false;
        }
        
        return currentTax;
    }
    
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool takeFee = true;
        
        DynamicTax memory currentTax;

        if (block.timestamp % 86400 >= _yoTimeStartTime && block.timestamp > _yoTimeStartBlock + (12 hours) && autoYoTimeEnabled) {
            _startYoTime();
        }
        if (from != owner() && to != owner() && !presale && from != address(this) && to != address(this) && !_isContract[from] && !_isContract[to]) {
            require(tradingOpen);
            if (from != presaleRouter && from != presaleAddress) {
                require(amount <= _maxTxAmount);
            }
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {//buys
                if (block.timestamp - previousTransactionBlock[to] <= _botBlocks) {
                    bots[to] = true;
                } else {
                    previousTransactionBlock[to] = block.timestamp;
                }

                if (block.timestamp <= _firstBlock.add(_botBlocks) && from != presaleRouter && from != presaleAddress) {
                    bots[to] = true;
                }
                
                uint256 bnbAmount = this.getTokenPriceBNB(amount);
                
                require(bnbAmount >= _minBuyBNB, "you must buy at least min BNB worth of token");
                require(balanceOf(to).add(amount) <= _maxWalletAmount, "wallet balance after transfer must be less than max wallet amount");
                
                currentTax = updateFee();
                
            }
            
            if (!inSwap && from != uniswapV2Pair) { //sells, transfers
                require(!bots[from] && !bots[to]);
                
                if (block.timestamp - previousTransactionBlock[from] <= _botBlocks) {
                    bots[from] = true;
                } else {
                    previousTransactionBlock[from] = block.timestamp;
                }
                
                if (to == uniswapV2Pair && _sellCoolDownEnabled) {
                    require(sellcooldown[from] < block.timestamp);
                    sellcooldown[from] = block.timestamp.add(_cooldownBlocks);
                }
                
                uint256 bnbAmount = this.getTokenPriceBNB(amount);
                require(bnbAmount >= _minSellBNB, "you must buy at least the min BNB worth of token");

                if (_BNBsellLimitEnabled) {
                    require(bnbAmount <= _maxSellAmountBNB, 'you cannot sell more than the max BNB amount per transaction');

                }
                
                else if (_priceImpactSellLimitEnabled) {
                    
                    require(amount <= balanceOf(uniswapV2Pair).mul(_priceImpact).div(100)); // price impact limit

                }
                
                if(to != uniswapV2Pair) {
                    require(balanceOf(to).add(amount) <= _maxWalletAmount, "wallet balance after transfer must be less than max wallet amount");
                }

                currentTax = updateFee();
                
                uint256 contractTokenBalance = balanceOf(address(this));
                if (contractTokenBalance > minTokensToSwap) {
                    contractTokenBalance = minTokensToSwap;
                }
                if (contractTokenBalance >= minTokensToSwap) {

                    swapAndLiquify(contractTokenBalance);
                
                }
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
                    
            }
        }

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || presale || _isContract[from] || _isContract[to]) {
            restoreAllFee();
            takeFee = false;
        }

        else if (bots[from] || bots[to]) {
            restoreAllFee();
            setBotFee();
            takeFee = true;
        }

        if (presale) {
            require(from == owner() || from == presaleRouter || from == presaleAddress || _isContract[from]);
        }
        
        _tokenTransfer(from, to, amount, takeFee, currentTax);
        restoreAllFee();
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
              address(this),
              tokenAmount,
              0, // slippage is unavoidable
              0, // slippage is unavoidable
              owner(),
              block.timestamp
          );
    }
  
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 autoLPamount = _sellLiquidityFee.mul(contractTokenBalance).div(_sellRaffleFee.add(_sellMarketingFee).add(_sellLiquidityFee));

        // split the contract balance into halves
        uint256 half =  autoLPamount.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForEth(otherHalf); // <- this breaks the BNB -> HATE swap when swap+liquify is triggered

        // how much BNB did we just swap into?
        uint256 newBalance = ((address(this).balance.sub(initialBalance)).mul(half)).div(half.add(otherHalf));

        // add liquidity to pancakeswap
        if (swapAndLiquifyEnabled) {
            addLiquidity(half, newBalance);
        }
    }

    function sendETHToFee(uint256 amount) private {
        if(block.timestamp < _firstBlock + (1 days)) {
            address payable addr = payable(0x16D6037b9976bE034d79b8cce863fF82d2BBbC67); // dev fee lasts for one day only
            addr.transfer(amount.mul(uint256(15)).div(100));
            _marketingAddress.transfer(amount.mul(uint256(41)).div(100));
            _raffleAddress.transfer(amount.mul(uint256(41)).div(100));
            _projectMaintainence.transfer(amount.mul(uint256(3)).div(100));
        }
        else {
            _marketingAddress.transfer(amount.mul(_marketingPercent).div(100));
            _raffleAddress.transfer(amount.mul(_rafflePercent).div(100));
            _projectMaintainence.transfer(amount.mul(_projectMaintainencePercent).div(100));
        }
    }

    function openTrading(uint256 botBlocks) private {
        _firstBlock = block.timestamp;
        _botBlocks = botBlocks;
        tradingOpen = true;
    }

    function manualswap() external {
        require(_msgSender() == _marketingAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external {
        require(_msgSender() == _marketingAddress);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee, DynamicTax memory currentTax) private {
        if (!takeFee) { 
                currentTax.buyRaffleFee = 0;
                currentTax.buyMarketingFee = 0;
                currentTax.buyLiquidityFee = 0;
                currentTax.buyReflectionFee = 0;

                currentTax.sellRaffleFee = 0;
                currentTax.sellMarketingFee = 0;
                currentTax.sellLiquidityFee = 0;
                currentTax.sellReflectionFee = 0;
        }
        if (sender == uniswapV2Pair){
            _transferStandardBuy(sender, recipient, amount, currentTax);
        }
        else {
            _transferStandardSell(sender, recipient, amount, currentTax);
        }
    }

    function _transferStandardBuy(address sender, address recipient, uint256 tAmount, DynamicTax memory currentTax) private {
        FinalFees memory buyFees;
        buyFees = _getValuesBuy(tAmount, currentTax);
        _rOwned[sender] = _rOwned[sender].sub(buyFees.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(buyFees.rTransferAmount);
        _takeRaffle(buyFees.tRaffle);
        _takeMarketing(buyFees.tMarketing);
        _reflectFee(buyFees.rReflection.div(3), buyFees.tReflection.div(3));
        _rOwned[stakingAddress] = _rOwned[stakingAddress].add((buyFees.rReflection.mul(2)).div(3));
        _takeLiquidity(buyFees.tLiquidity);
        emit Transfer(sender, recipient, buyFees.tTransferAmount);
    }

    function _transferStandardSell(address sender, address recipient, uint256 tAmount, DynamicTax memory currentTax) private {
        FinalFees memory sellFees;
        sellFees = _getValuesSell(tAmount, currentTax);
        _rOwned[sender] = _rOwned[sender].sub(sellFees.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(sellFees.rTransferAmount);
        if (recipient == _burnAddress) {
            _tOwned[recipient] = _tOwned[recipient].add(sellFees.tTransferAmount);
        }
        _takeRaffle(sellFees.tRaffle);
        _takeMarketing(sellFees.tMarketing);
        _reflectFee(sellFees.rReflection.div(3), sellFees.tReflection.div(3));
        _rOwned[stakingAddress] = _rOwned[stakingAddress].add((sellFees.rReflection.mul(2)).div(3));
        _takeLiquidity(sellFees.tLiquidity);
        emit Transfer(sender, recipient, sellFees.tTransferAmount);
    }

    function _reflectFee(uint256 rReflection, uint256 tReflection) private {
        _rTotal = _rTotal.sub(rReflection);
        _tFeeTotal = _tFeeTotal.add(tReflection);
    }

    function _takeRaffle(uint256 tRaffle) private {
        uint256 currentRate = _getRate();
        uint256 rRaffle = tRaffle.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rRaffle);
    }

    function _takeMarketing(uint256 tMarketing) private {
        uint256 currentRate = _getRate();
        uint256 rMarketing = tMarketing.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rMarketing);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
    }
    
    receive() external payable {}

    // Sell GetValues
    function _getValuesSell(uint256 tAmount, DynamicTax memory currentTax) private view returns (FinalFees memory) {
        SellBreakdown memory sellFees = _getTValuesSell(tAmount, currentTax.sellRaffleFee, currentTax.sellMarketingFee, currentTax.sellReflectionFee, currentTax.sellLiquidityFee);
        FinalFees memory finalFees;
        uint256 currentRate = _getRate();
        (finalFees.rAmount, finalFees.rTransferAmount, finalFees.rReflection) = _getRValuesSell(tAmount, sellFees.tRaffle, sellFees.tMarketing, sellFees.tReflection, sellFees.tLiquidity, currentRate);
        finalFees.tRaffle = sellFees.tRaffle;
        finalFees.tMarketing = sellFees.tMarketing;
        finalFees.tReflection = sellFees.tReflection;
        finalFees.tLiquidity = sellFees.tLiquidity;
        finalFees.tTransferAmount = sellFees.tTransferAmount;
        return (finalFees);
    }

    function _getTValuesSell(uint256 tAmount, uint256 raffleFee, uint256 marketingFee, uint256 reflectionFee, uint256 liquidityFee) private pure returns (SellBreakdown memory) {
        SellBreakdown memory tsellFees;
        tsellFees.tRaffle = tAmount.mul(raffleFee).div(100);
        tsellFees.tMarketing = tAmount.mul(marketingFee).div(100);
        tsellFees.tReflection = tAmount.mul(reflectionFee).div(100);
        tsellFees.tLiquidity = tAmount.mul(liquidityFee).div(100);
        tsellFees.tTransferAmount = tAmount.sub(tsellFees.tRaffle).sub(tsellFees.tMarketing);
        tsellFees.tTransferAmount -= tsellFees.tReflection;
        tsellFees.tTransferAmount -= tsellFees.tLiquidity;
        return (tsellFees);
    }

    function _getRValuesSell(uint256 tAmount, uint256 tRaffle, uint256 tMarketing, uint256 tReflection, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rRaffle = tRaffle.mul(currentRate);
        uint256 rMarketing = tMarketing.mul(currentRate);
        uint256 rReflection = tReflection.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rRaffle).sub(rMarketing).sub(rReflection);
        rTransferAmount -= rLiquidity;
        return (rAmount, rTransferAmount, rReflection);
    }

    // Buy GetValues
    function _getValuesBuy(uint256 tAmount, DynamicTax memory currentTax) private view returns (FinalFees memory) {
        BuyBreakdown memory buyFees = _getTValuesBuy(tAmount, currentTax.buyRaffleFee, currentTax.buyMarketingFee, currentTax.buyReflectionFee, currentTax.buyLiquidityFee);
        FinalFees memory finalFees;
        uint256 currentRate = _getRate();
        (finalFees.rAmount, finalFees.rTransferAmount, finalFees.rReflection) = _getRValuesBuy(tAmount, buyFees.tRaffle, buyFees.tMarketing, buyFees.tReflection, buyFees.tLiquidity, currentRate);
        finalFees.tRaffle = buyFees.tRaffle;
        finalFees.tMarketing = buyFees.tMarketing;
        finalFees.tReflection = buyFees.tReflection;
        finalFees.tLiquidity = buyFees.tLiquidity;
        finalFees.tTransferAmount = buyFees.tTransferAmount;
        return (finalFees);
    }

    function _getTValuesBuy(uint256 tAmount, uint256 raffleFee, uint256 marketingFee, uint256 reflectionFee, uint256 liquidityFee) private pure returns (BuyBreakdown memory) {
        BuyBreakdown memory tbuyFees;
        tbuyFees.tRaffle = tAmount.mul(raffleFee).div(100);
        tbuyFees.tMarketing = tAmount.mul(marketingFee).div(100);
        tbuyFees.tReflection = tAmount.mul(reflectionFee).div(100);
        tbuyFees.tLiquidity = tAmount.mul(liquidityFee).div(100);
        tbuyFees.tTransferAmount = tAmount.sub(tbuyFees.tRaffle).sub(tbuyFees.tMarketing);
        tbuyFees.tTransferAmount -= tbuyFees.tReflection;
        tbuyFees.tTransferAmount -= tbuyFees.tLiquidity;
        return (tbuyFees);
    }

    function _getRValuesBuy(uint256 tAmount, uint256 tRaffle, uint256 tMarketing, uint256 tReflection, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rRaffle = tRaffle.mul(currentRate);
        uint256 rMarketing = tMarketing.mul(currentRate);
        uint256 rReflection = tReflection.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rRaffle).sub(rMarketing).sub(rReflection);
        rTransferAmount -= rLiquidity;
        return (rAmount, rTransferAmount, rReflection);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (_rOwned[_burnAddress] > rSupply || _tOwned[_burnAddress] > tSupply) return (_rTotal, _tTotal);
        rSupply = rSupply.sub(_rOwned[_burnAddress]);
        tSupply = tSupply.sub(_tOwned[_burnAddress]);
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function excludeFromFee(address account) public onlyOwner() {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner() {
        _isExcludedFromFee[account] = false;
    }
    
    function includeInContract(address account) external onlyOwner() {
        _isContract[account] = true;
    }
    
    function excludeFromContract(address account) external onlyOwner() {
        _isContract[account] = false;
    }
    
    function removeBot(address account) external onlyOwner() {
        bots[account] = false;
    }

    function addBot(address account) external onlyOwner() {
        bots[account] = true;
    }
    
    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        require(maxTxAmount > _tTotal.div(10000), "Amount must be greater than 0.01% of supply");
        require(maxTxAmount <= _tTotal, "Amount must be less than or equal to totalSupply");
        _maxTxAmount = maxTxAmount;
        emit MaxTxAmountUpdated(_maxTxAmount);
    }

    function setMaxWalletAmount(uint256 maxWalletAmount) external onlyOwner() {
        require(maxWalletAmount > 0, "Amount must be greater than 0");
        require(maxWalletAmount <= _tTotal, "Amount must be less than or equal to totalSupply");
        _maxWalletAmount = maxWalletAmount;
    }

    function setTaxes(uint256 buyMarketingFee, uint256 buyRaffleFee, uint256 buyReflectionFee, uint256 buyLiquidityFee, uint256 sellMarketingFee, uint256 sellRaffleFee, uint256 sellReflectionFee, uint256 sellLiquidityFee) external onlyOwner() {
        uint256 buyTax = buyMarketingFee.add(buyRaffleFee).add(buyReflectionFee);
        buyTax += buyLiquidityFee;
        uint256 sellTax = sellMarketingFee.add(sellRaffleFee).add(sellReflectionFee);
        sellTax += sellLiquidityFee;
        require(buyTax < 50, "Sum of sell fees must be less than 50");
        require(sellTax < 50, "Sum of buy fees must be less than 50");
        _buyMarketingFee = buyMarketingFee;
        _buyRaffleFee = buyRaffleFee;
        _buyReflectionFee = buyReflectionFee;
        _buyLiquidityFee = buyLiquidityFee;
        _sellMarketingFee = sellMarketingFee;
        _sellRaffleFee = sellRaffleFee;
        _sellReflectionFee = sellReflectionFee;
        _sellLiquidityFee = sellLiquidityFee;

        _previousBuyMarketingFee = _buyMarketingFee;
        _previousBuyRaffleFee = _buyRaffleFee;
        _previousBuyReflectionFee = _buyReflectionFee;
        _previousBuyLiquidityFee = _buyLiquidityFee;
        _previousSellMarketingFee = _sellMarketingFee;
        _previousSellRaffleFee = _sellRaffleFee;
        _previousSellReflectionFee = _sellReflectionFee;
        _previousSellLiquidityFee = _sellLiquidityFee;

        emit FeesUpdated(_buyRaffleFee, _buyMarketingFee, _buyLiquidityFee, _buyReflectionFee, _sellRaffleFee, _sellMarketingFee, _sellLiquidityFee, _sellReflectionFee);
    }

    function setPriceImpact(uint256 priceImpact) external onlyOwner() {
        require(priceImpact <= 100, "max price impact must be less than or equal to 100");
        require(priceImpact > 0, "cant prevent sells, choose value greater than 0");
        _priceImpact = priceImpact;
        emit PriceImpactUpdated(_priceImpact);
    }

    function setPresaleRouterAndAddress(address router, address wallet) external onlyOwner() {
        presaleRouter = router;
        presaleAddress = wallet;
        excludeFromFee(presaleRouter);
        excludeFromFee(presaleAddress);
    }

    function endPresale(uint256 botBlocks) external onlyOwner() {
        require(presale == true, "presale already ended");
        presale = false;
        openTrading(botBlocks);
        emit EndedPresale(presale);
    }
    
    function updateYoTimeBlocks(uint256 yoTimeBlocks) external onlyOwner() {
        _yoTimeBlocks = yoTimeBlocks;
    }

    function updatePairSwapped(bool swapped) external onlyOwner() {
        pairSwapped = swapped;
    }
    
    function updateMinBuySellBNB(uint256 minBuyBNB, uint256 minSellBNB) external onlyOwner() {
        require(minBuyBNB <= 100000000000000000, "cant make the limit higher than 0.1 BNB");
        require(minSellBNB <= 100000000000000000, "cant make the limit higher than 0.1 BNB");
        _minBuyBNB = minBuyBNB;
        _minSellBNB = minSellBNB;
    }
    
    function updateMaxSellAmountBNB(uint256 maxSellBNB) external onlyOwner() {
        require(maxSellBNB >= 1000000000000000000, "cant make the limit lower than 1 BNB");
        _maxSellAmountBNB = maxSellBNB;
    }
    
    function _startYoTime() private {
        _yoTimeStartBlock = block.timestamp;
        _yoTimeStarted = true;
        _yoTimeWindowEnd = block.timestamp.add(_yoTimeBlocks);
    }
    
    function startYoTime() external onlyOwner() {
        _yoTimeStartBlock = block.timestamp;
        _yoTimeStarted = true;
        _yoTimeWindowEnd = block.timestamp.add(_yoTimeBlocks);
    }
    
    function manualStartYoTime() external onlyOwner() {
        _yoTimeStartBlock = block.timestamp;
        _yoTimeStarted = true;
        _yoTimeWindowEnd = block.timestamp.add(_yoTimeBlocks);
    }

    function enableSellCoolDown() external onlyOwner() {
        require(!_sellCoolDownEnabled, "already enabled");
        _sellCoolDownEnabled = true;
    }
    
    function disableSellCoolDown() external onlyOwner() {
        require(_sellCoolDownEnabled, "already disabled");
        _sellCoolDownEnabled = false;
    }
    
    function setCoolDownBlocks(uint256 cooldownBlocks) external onlyOwner() {
        require(cooldownBlocks <= 86400, "cannot limit sells for longer than 1 day");
        _cooldownBlocks = cooldownBlocks;
    }
    
    function updateRaffleAddress(address payable raffleAddress) external onlyOwner() {
        _raffleAddress = raffleAddress;
    }
    
    function updateMarketingAddress(address payable marketingAddress) external onlyOwner() {
        _marketingAddress = marketingAddress;
    }
    
    function updateStakingAddress(address payable _stakingAddress) external onlyOwner() {
        stakingAddress = _stakingAddress;
    }
    
    function setYoStartTime(uint256 yoTimeStartTime) external onlyOwner() {
        require(yoTimeStartTime <= 86400, "Must be less than or equal to 86400 (1 day)");
        _yoTimeStartTime = yoTimeStartTime;
    }
    
    function enableAutoYoTime() external onlyOwner() {
        require(autoYoTimeEnabled == false, 'Already enabled');
        autoYoTimeEnabled = true;
    }
    
    function disableAutoYoTime() external onlyOwner() {
        require(autoYoTimeEnabled == true, 'Alread disabled');
        autoYoTimeEnabled = false;
    }
    
    function enableBNBsellLimit() external onlyOwner() {
        require(_BNBsellLimitEnabled == false, "already enabled");
        _BNBsellLimitEnabled = true;
        _priceImpactSellLimitEnabled = false;
    }
    
    function disableBNBsellLimit() external onlyOwner() {
        require(_BNBsellLimitEnabled == true, "already disabled");
        _BNBsellLimitEnabled = false;
    }
    
    function enablePriceImpactSellLimit() external onlyOwner() {
        require(_priceImpactSellLimitEnabled == false, "already enabled");
        _priceImpactSellLimitEnabled = true;
        _BNBsellLimitEnabled = false;
    }
    
    function disablePriceImpactSellLimit() external onlyOwner() {
        require(_priceImpactSellLimitEnabled == true, "already disabled");
        _priceImpactSellLimitEnabled = false;
    }
    
    function disableSwapAndLiquify() external onlyOwner() {
        require(swapAndLiquifyEnabled == true, 'already disabled');
        swapAndLiquifyEnabled = false;
    }
    
    function enableSwapAndLiquify() external onlyOwner() {
        require(swapAndLiquifyEnabled == false, 'already enabled');
        swapAndLiquifyEnabled = true;
    }
    function updateMinTokensToSwap(uint256 _minTokenToSwap) external onlyOwner() {
        minTokensToSwap = _minTokenToSwap;
    }
}