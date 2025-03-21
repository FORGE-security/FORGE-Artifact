// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IBEP20 {
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
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is still locked");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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

interface IUniswapV2Router01 {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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

contract FortuneCookieV2 is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    // User data
    struct userData {
        address userAddress;
        uint256 totalWon;
        uint256 lastWon;
        uint256 index;
        bool tokenOwner;
    }

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromLottery;
    mapping (address => bool) private _isExcluded;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromAutoLiquidity;
    mapping(address => userData) private userByAddress;
    mapping(uint256 => userData) private userByIndex;

    address[] private _excluded;
    address private constant _marketingWallet = 0xa1B01377fB1A7808f0e1211adA3867eBe211B142;

    // An address used to transiently store the pot.
    // We can store the pot in memory, but an address allows us
    // to use the existing fee transfer abstractions as-is.
    address private constant _potAddress = 0xf293cBd510b0875611cBc51225cE9A0790Ce168B;
    address public immutable _burnAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1 * 10**12 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name     = "Fortune Cookie v2";
    string private _symbol   = "COOKIE";
    uint8 private  _decimals = 9;

    uint256 public  _taxFee       = 0; // redistributed to holders
    uint256 public  _liquidityFee = 5; // kept for liquidity
    uint256 public  _marketingFee = 3; // marketing wallet
    uint256 public  _burnFee      = 2; // burned
    uint256 public  _potFee       = 10; // pot fees

    uint256 private _previousTaxFee       = _taxFee;
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint256 private _previousMarketingFee = _marketingFee;
    uint256 private _previousBurnFee      = _burnFee;
    uint256 private _previousPotFee       = _potFee;

    uint256 public _maxTxAmount = 5 * 10**9 * 10**9;
    uint256 private numTokensSellToAddToLiquidity = 500 * 10**6 * 10**9;
    uint256 private _maxWalletToken = 20 * 10**9 * 10**9;

    // Last person who won, and the amount.
    uint256 private lastWinner_value;
    address private lastWinner_address;

    // -- Global stats --
    uint256 private _allWon;
    uint256 private _countUsers = 0;
    uint8 private w_rt = 0;
    uint256 private _txCounter = 0;

    // Lottery variables.
    uint256 private transactionsSinceLastLottery = 0;
    uint256 private constant transactionsPerLottery = 50;

    // auto liquidity
    IUniswapV2Router02 public uniswapV2Router;
    address            public uniswapV2Pair;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event PotContributed(uint256 amount);
    event LotteryWon(address winner, uint256 amount, uint256 prevBalance, uint256 newBalance);
    event LotterySkipped(address skippedAddress, uint256 prevPot, uint256 newPot);

    // Custom Test
    event TransferToExcl();
    event TransferFromExcl();
    event TransferBothExcl();
    event TransferStandard();

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () {
        require(_msgSender() == owner(), "not being deployed by owner?");

        // Give owner all the tokens
        _rOwned[_msgSender()] = _rTotal;

        // uniswap
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        // exclude system contracts
        _isExcludedFromFee[owner()]          = true;
        _isExcludedFromFee[address(this)]    = true;
        _isExcludedFromFee[_marketingWallet] = true;

        _isExcluded[_potAddress] = true;

        _isExcludedFromAutoLiquidity[uniswapV2Pair]            = true;
        _isExcludedFromAutoLiquidity[address(uniswapV2Router)] = true;

        _isExcludedFromLottery[uniswapV2Pair] = true;
        _isExcludedFromLottery[address(this)] = true;
        _isExcludedFromLottery[_potAddress] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function isUser(address userAddress) private view returns(bool isIndeed)
    {
        isIndeed = false;
        if(userByAddress[userAddress].tokenOwner == true) {
            isIndeed = true;
        }
        return isIndeed;
    }

    function insertUser(address userAddress, uint winnings) public returns(uint256 index) {
        if (_isExcludedFromLottery[userAddress]) {
            return index;
        }

        userByAddress[userAddress] = userData(userAddress, winnings, winnings, _countUsers, true);
        userByIndex[_countUsers] = userData(userAddress, winnings, winnings, _countUsers, true);
        index = _countUsers;
        _countUsers += 1;

        return index;
    }

    function getUserAtIndex(uint index) private view returns(address userAddress)
    {
        return userByIndex[index].userAddress;
    }

    function getTotalWon(address userAddress) public view returns(uint totalWon) {
        return userByAddress[userAddress].totalWon;
    }

    function getLastWon(address userAddress) public view returns(uint lastWon) {
        return userByAddress[userAddress].lastWon;
    }

    function getTotalWon() public view returns(uint256) {
        return _allWon;
    }

    function getCirculatingSupply() public view returns(uint256){
        uint256 _bBurn = balanceOf(_burnAddress);
        return _tTotal.sub(_bBurn);
    }

    function addWinner(address userAddress, uint256 _lastWon) public returns (bool result) {
        result = false;

        lastWinner_value = _lastWon;
        lastWinner_address = userAddress;
        result = true;

        return result;
    }

    function getLastWinner() public view returns (address, uint256) {
        return (lastWinner_address, lastWinner_value);
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

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");

        feeData memory fd = _getValues(tAmount);

        _rOwned[sender] = _rOwned[sender].sub(fd.rAmount);
        _rTotal         = _rTotal.sub(fd.rAmount);
        _tFeeTotal      = _tFeeTotal.add(fd.tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");

        feeData memory fd = _getValues(tAmount);

        if (!deductTransferFee) {
            return fd.rAmount;
        } else {
            return fd.rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");

        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");

        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already excluded");

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner {
        _taxFee = taxFee;
        _previousTaxFee = taxFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        _liquidityFee = liquidityFee;
        _previousLiquidityFee = liquidityFee;
    }

    function setMarketingFeePercent(uint256 marketingFee) external onlyOwner {
        _marketingFee = marketingFee;
        _previousMarketingFee = marketingFee;
    }

    function setBurnFeePercent(uint256 burnFee) external onlyOwner {
        _burnFee = burnFee;
        _previousBurnFee = burnFee;
    }

    function setPotFeePercent(uint256 potFee) external onlyOwner {
        _potFee = potFee;
        _previousPotFee = potFee;
    }

    function setMaxTx(uint256 maxTx) external onlyOwner {
        _maxTxAmount = maxTx;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    receive() external payable {}

    function setUniswapRouter(address r) external onlyOwner {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(r);
        uniswapV2Router = _uniswapV2Router;
    }

    function setUniswapPair(address p) external onlyOwner {
        uniswapV2Pair = p;
    }

    function setExcludedFromAutoLiquidity(address a, bool b) external onlyOwner {
        _isExcludedFromAutoLiquidity[a] = b;
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal    = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function takeTransactionFee(address to, uint256 tAmount, uint256 currentRate) private {
        if (tAmount <= 0) { return; }

        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[to] = _rOwned[to].add(rAmount);
        if (_isExcluded[to]) {
            _tOwned[to] = _tOwned[to].add(tAmount);
        }
    }

    function calculateFee(uint256 amount, uint256 fee) private pure returns (uint256) {
        return amount.mul(fee).div(100);
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0) return;

        _previousTaxFee       = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousMarketingFee = _marketingFee;
        _previousBurnFee      = _burnFee;
        _previousPotFee      = _potFee;

        _taxFee       = 0;
        _liquidityFee = 0;
        _marketingFee = 0;
        _burnFee      = 0;
        _potFee       = 0;
    }

    function restoreAllFee() private {
        _taxFee       = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _marketingFee = _previousMarketingFee;
        _burnFee      = _previousBurnFee;
        _potFee       = _previousPotFee;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
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

        require(to != _potAddress, "Lottery: Cannot transfer to pot");
        require(to != _burnAddress, "Users cannot burn tokens themselves");

        if (from != owner() && to != owner()) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        if(from != owner() && to != owner() && to != address(1) && to != address(0xDEAD) && to != uniswapV2Pair){
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            uint256 contractBalanceRecepient = balanceOf(to);
            require(contractBalanceRecepient + amount <= _maxWalletToken, "Exceeds maximum wallet token amount");
        }

        /*
            - swapAndLiquify will be initiated when token balance of this contract
            has accumulated enough over the minimum number of tokens required.
            - don't get caught in a circular liquidity event.
            - don't swapAndLiquify if sender is uniswap pair.
        */
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        bool isOverMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            isOverMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            swapAndLiquify(contractTokenBalance);
        }


        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split contract balance into halves
        uint256 half      = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        /*
            capture the contract's current BNB balance.
            this is so that we can capture exactly the amount of BNB that
            the swap creates, and not make the liquidity event include any BNB
            that has been manually sent to the contract.
        */
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForBnb(half);

        // this is the amount of BNB that we just swapped into
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForBnb(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if (!takeFee) {
            removeAllFee();
        }

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);

        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);

        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);

        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);

        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee) {
            restoreAllFee();
        }
    }

    struct feeData {

        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rFee;
        uint256 rLiquidity;
        uint256 rMarketing;
        uint256 rBurn;
        uint256 rPot;

        uint256 tAmount;
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tLiquidity;
        uint256 tMarketing;
        uint256 tBurn;
        uint256 tPot;

        uint256 currentRate;
    }

    function _getValues(uint256 tAmount) private view returns (feeData memory) {
        feeData memory intermediate = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        feeData memory res = _getRValues(intermediate, currentRate);
        return res;
    }

    function _getTValues(uint256 tAmount) private view returns (feeData memory) {
        feeData memory fd;
        fd.tAmount = tAmount;
        fd.tFee       = calculateFee(tAmount, _taxFee);
        fd.tLiquidity = calculateFee(tAmount, _liquidityFee);
        fd.tMarketing = calculateFee(tAmount, _marketingFee);
        fd.tBurn      = calculateFee(tAmount, _burnFee);
        fd.tPot       = calculateFee(tAmount, _potFee);
        fd.tTransferAmount = tAmount.sub(fd.tFee);
        fd.tTransferAmount = fd.tTransferAmount.sub(fd.tLiquidity);
        fd.tTransferAmount = fd.tTransferAmount.sub(fd.tMarketing);
        fd.tTransferAmount = fd.tTransferAmount.sub(fd.tBurn);
        fd.tTransferAmount = fd.tTransferAmount.sub(fd.tPot);
        return fd;
    }

    function _getRValues(feeData memory fd, uint256 currentRate) private pure returns (feeData memory) {
        fd.currentRate = currentRate;
        fd.rAmount    = fd.tAmount.mul(fd.currentRate);
        fd.rFee       = fd.tFee.mul(fd.currentRate);
        fd.rLiquidity = fd.tLiquidity.mul(fd.currentRate);
        fd.rMarketing = fd.tMarketing.mul(fd.currentRate);
        fd.rBurn      = fd.tBurn.mul(fd.currentRate);
        fd.rPot       = fd.tPot.mul(fd.currentRate);
        fd.rTransferAmount = fd.rAmount.sub(fd.rFee);
        fd.rTransferAmount = fd.rTransferAmount.sub(fd.rLiquidity);
        fd.rTransferAmount = fd.rTransferAmount.sub(fd.rMarketing);
        fd.rTransferAmount = fd.rTransferAmount.sub(fd.rBurn);
        fd.rTransferAmount = fd.rTransferAmount.sub(fd.rPot);
        return fd;
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        feeData memory fd = _getValues(tAmount);

        _rOwned[sender]    = _rOwned[sender].sub(fd.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(fd.rTransferAmount);

        takeTransactionFee(address(this), fd.tLiquidity, fd.currentRate);
        takeTransactionFee(address(_marketingWallet), fd.tMarketing, fd.currentRate);
        takeTransactionFee(address(_burnAddress), fd.tBurn, fd.currentRate);
        _reflectFee(fd.rFee, fd.tFee);
        _handleLottery(recipient, fd.tPot, fd.currentRate);
        emit Transfer(sender, recipient, fd.tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        feeData memory fd = _getValues(tAmount);

        _tOwned[sender] = _tOwned[sender].sub(fd.tAmount);
        _rOwned[sender] = _rOwned[sender].sub(fd.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(fd.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(fd.rTransferAmount);

        takeTransactionFee(address(this), fd.tLiquidity, fd.currentRate);
        takeTransactionFee(address(_marketingWallet), fd.tMarketing, fd.currentRate);
        takeTransactionFee(address(_burnAddress), fd.tBurn, fd.currentRate);
        _reflectFee(fd.rFee, fd.tFee);
        _handleLottery(recipient, fd.tPot, fd.currentRate);
        emit Transfer(sender, recipient, fd.tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        feeData memory fd = _getValues(tAmount);

        _rOwned[sender] = _rOwned[sender].sub(fd.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(fd.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(fd.rTransferAmount);

        takeTransactionFee(address(this), fd.tLiquidity, fd.currentRate);
        takeTransactionFee(address(_marketingWallet), fd.tMarketing, fd.currentRate);
        takeTransactionFee(address(_burnAddress), fd.tBurn, fd.currentRate);
        _reflectFee(fd.rFee, fd.tFee);
        _handleLottery(recipient, fd.tPot, fd.currentRate);
        emit Transfer(sender, recipient, fd.tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        feeData memory fd = _getValues(tAmount);

        _tOwned[sender] = _tOwned[sender].sub(fd.tAmount);
        _rOwned[sender] = _rOwned[sender].sub(fd.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(fd.rTransferAmount);

        takeTransactionFee(address(this), fd.tLiquidity, fd.currentRate);
        takeTransactionFee(address(_marketingWallet), fd.tMarketing, fd.currentRate);
        takeTransactionFee(address(_burnAddress), fd.tBurn, fd.currentRate);
        _reflectFee(fd.rFee, fd.tFee);
        _handleLottery(recipient, fd.tPot, fd.currentRate);
        emit Transfer(sender, recipient, fd.tTransferAmount);
    }

    // Used to transfer from lottery pot to user.
    function _transferStandardWithoutFees(address sender, address recipient, uint256 tAmount) private {
        removeAllFee();

        // Copied from _transferFromExcluded
        // We try to avoid recursive calls.
        feeData memory fd = _getValues(tAmount);

        _tOwned[sender] = _tOwned[sender].sub(fd.tAmount);
        _rOwned[sender] = _rOwned[sender].sub(fd.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(fd.rTransferAmount);

        require(fd.tFee == 0, "tFee not zero");
        require(fd.tLiquidity == 0, "tLiquidity not zero");
        require(fd.tMarketing == 0, "tMarketing not zero");
        require(fd.tBurn == 0, "tBurn not zero");
        require(fd.tPot == 0, "tPot not zero");

        restoreAllFee();
    }

    function random(uint256 _totalPlayers, uint8 _w_rt) private view returns (uint256) {

        uint256 w_rnd_c_1 = block.number.add(_txCounter).add(_totalPlayers);
        uint256 w_rnd_c_2 = _tTotal.add(_allWon);
        uint256 _rnd = 0;
        if (_w_rt == 0) {
            _rnd = uint(keccak256(abi.encodePacked(blockhash(block.number.sub(1)), w_rnd_c_1, blockhash(block.number.sub(2)), w_rnd_c_2)));
        } else if (_w_rt == 1) {
            _rnd = uint(keccak256(abi.encodePacked(blockhash(block.number.sub(1)),blockhash(block.number.sub(2)), blockhash(block.number.sub(3)),w_rnd_c_1)));
        } else if (_w_rt == 2) {
            _rnd = uint(keccak256(abi.encodePacked(blockhash(block.number.sub(1)), blockhash(block.number.sub(2)), w_rnd_c_1, blockhash(block.number.sub(3)))));
        } else if (_w_rt == 3) {
            _rnd = uint(keccak256(abi.encodePacked(w_rnd_c_1, blockhash(block.number.sub(1)), blockhash(block.number.sub(3)), w_rnd_c_2)));
        } else if (_w_rt == 4) {
            _rnd = uint(keccak256(abi.encodePacked(w_rnd_c_1, blockhash(block.number.sub(1)), w_rnd_c_2, blockhash(block.number.sub(2)), blockhash(block.number.sub(3)))));
        } else if (_w_rt == 5) {
            _rnd = uint(keccak256(abi.encodePacked(blockhash(block.number.sub(1)), w_rnd_c_2, blockhash(block.number.sub(3)), w_rnd_c_1)));
        } else {
            _rnd = uint(keccak256(abi.encodePacked(blockhash(block.number.sub(1)), w_rnd_c_2, blockhash(block.number.sub(2)), w_rnd_c_1, blockhash(block.number.sub(2)))));
        }
        _rnd = _rnd % _totalPlayers;
        return _rnd;
    }

    function _handleLottery(address recipient, uint256 potContribution, uint256 currentRate) private returns (bool) {

        if (_countUsers == 0 || potContribution == 0) {
            // Register the user if needed.
            if(isUser(recipient) != true) {
                insertUser(recipient, 0);
            }

            _txCounter += 1;

            return true;
        }

        // -- Lottery time --

        // Add to the lottery pool
        takeTransactionFee(_potAddress, potContribution, currentRate);
        emit PotContributed(potContribution);

        // Increment counter
        transactionsSinceLastLottery = transactionsSinceLastLottery.add(1);


        uint256 _pot = balanceOf(_potAddress);

        // Lottery time, but for real this time though
        if (transactionsSinceLastLottery > 0 && transactionsSinceLastLottery.mod(transactionsPerLottery) == 0) {

            // Stick your hand into the jar of cookies.
            uint256 _randomWinner = random(_countUsers, w_rt);
            address _winnerAddress = getUserAtIndex(_randomWinner);
            uint256 _balanceWinner = balanceOf(_winnerAddress);

            // You can only win if you own COOKIE and have 2% of the pot.
            // If the pot is accumulated from multiple rounds, you need 2% / (the number of times the pot accumulated over)
            uint256 _minBalance = _pot
                .div(50) // You stand to win 50x.
                .div(transactionsSinceLastLottery.div(transactionsPerLottery));

            if (_balanceWinner >= 0 && _balanceWinner >= _minBalance) {

                // Regression from V1. Sorry folks :(
                // Check if the balance of the user truly changed.
                uint256 prevBalance = balanceOf(_winnerAddress);

                // Reward the winner handsomely.
                // We treat the pot amount as a "fee" from the pot to the user :)
                _transferStandardWithoutFees(_potAddress, _winnerAddress, _pot);

                uint256 newBalance = balanceOf(_winnerAddress);
                emit LotteryWon(_winnerAddress, _pot, prevBalance, newBalance);

                uint winnings = userByAddress[_winnerAddress].totalWon;
                uint256 totalWon = winnings.add(_pot);

                // Update user stats
                userByAddress[_winnerAddress].lastWon = _pot;
                userByAddress[_winnerAddress].totalWon = totalWon;
                uint256 _index = userByAddress[_winnerAddress].index;
                userByIndex[_index].lastWon = _pot;
                userByIndex[_index].totalWon = totalWon;

                // Update global stats
                addWinner(_winnerAddress, _pot);
                _allWon = _allWon.add(_pot);

                // Reset count and lottery pool.
                transactionsSinceLastLottery = 0;
            }
            else {
                // No one won, and the next winner is going to be even richer!
                emit LotterySkipped(_winnerAddress, _pot.sub(potContribution), _pot);
            }
        }

        // Register the user if needed.
        if(isUser(recipient) != true) {
            insertUser(recipient, 0);
        }

        _txCounter += 1;

        return true;
    }

    mapping (address => bool) public airdropReceived;
    event AirDropped (address[] _recipients, uint256[] _amounts, uint256 totalAirDropped);
    function airDrop(address[] memory _recipients, uint256[] memory _amounts) external onlyOwner {

        uint256 airdropped;

        require(_recipients.length == _amounts.length, "Number of recipients not the same as the number of amounts");

        for (uint256 index = 0; index < _recipients.length; index++) {
            if (!airdropReceived[_recipients[index]]) {
                airdropReceived[_recipients[index]] = true;
                transfer(_recipients[index], _amounts[index]);
                airdropped = airdropped.add(_amounts[index]);
            }
        }

        emit AirDropped(_recipients, _amounts, airdropped);
    }
}