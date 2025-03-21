// SPDX-License-Identifier: MIT
  pragma solidity ^0.8.0;
  
  abstract contract Context {
      function _msgSender() internal view virtual returns (address) {
          return msg.sender;
      }
  
      function _msgData() internal view virtual returns (bytes calldata) {
          return msg.data;
      }
  }
  
  
  abstract contract Ownable is Context {
      address private _owner;
      
      event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
      constructor() {
          _transferOwnership(_msgSender());
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
  
  interface IERC20 {
      function totalSupply() external view returns (uint256);
  
      function balanceOf(address account) external view returns (uint256);
  
      function transfer(address recipient, uint256 amount) external returns (bool);
  
      function allowance(address owner, address spender) external view returns (uint256);
  
      function approve(address spender, uint256 amount) external returns (bool);
  
      function transferFrom(
          address sender,
          address recipient,
          uint256 amount
      ) external returns (bool);
  
      event Transfer(address indexed from, address indexed to, uint256 value);
  
      event Approval(address indexed owner, address indexed spender, uint256 value);
  }
  
  interface IERC20Metadata is IERC20 {
  
      function name() external view returns (string memory);
  
      function symbol() external view returns (string memory);
  
      function decimals() external view returns (uint8);
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
  
      function div(uint256 a, uint256 b) internal pure returns (uint256) {
          return div(a, b, "SafeMath: division by zero");
      }
  
      function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
          require(b > 0, errorMessage);
          uint256 c = a / b;
          // assert(a == b * c + a % b); // There is no case in which this doesn't hold
  
          return c;
      }
  
      function mod(uint256 a, uint256 b) internal pure returns (uint256) {
          return mod(a, b, "SafeMath: modulo by zero");
      }
  
      function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
          require(b != 0, errorMessage);
          return a % b;
      }
  }
  
  library SafeMathInt {
      int256 private constant MIN_INT256 = int256(1) << 255;
      int256 private constant MAX_INT256 = ~(int256(1) << 255);
  
      /**
       * @dev Multiplies two int256 variables and fails on overflow.
       */
      function mul(int256 a, int256 b) internal pure returns (int256) {
          int256 c = a * b;
  
          // Detect overflow when multiplying MIN_INT256 with -1
          require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
          require((b == 0) || (c / b == a));
          return c;
      }
  
      /**
       * @dev Division of two int256 variables and fails on overflow.
       */
      function div(int256 a, int256 b) internal pure returns (int256) {
          // Prevent overflow when dividing MIN_INT256 by -1
          require(b != -1 || a != MIN_INT256);
  
          // Solidity already throws when dividing by 0.
          return a / b;
      }
  
      /**
       * @dev Subtracts two int256 variables and fails on overflow.
       */
      function sub(int256 a, int256 b) internal pure returns (int256) {
          int256 c = a - b;
          require((b >= 0 && c <= a) || (b < 0 && c > a));
          return c;
      }
  
      /**
       * @dev Adds two int256 variables and fails on overflow.
       */
      function add(int256 a, int256 b) internal pure returns (int256) {
          int256 c = a + b;
          require((b >= 0 && c >= a) || (b < 0 && c < a));
          return c;
      }
  
      /**
       * @dev Converts to absolute value, and fails on overflow.
       */
      function abs(int256 a) internal pure returns (int256) {
          require(a != MIN_INT256);
          return a < 0 ? -a : a;
      }
  
  
      function toUint256Safe(int256 a) internal pure returns (uint256) {
          require(a >= 0);
          return uint256(a);
      }
  }
  
  library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
      int256 b = int256(a);
      require(b >= 0);
      return b;
    }
  }
  
  library Clones {
      /**
       * @dev Deploys and returns the address of a clone that mimics the behaviour of 'implementation'.
       *
       * This function uses the create opcode, which should never revert.
       */
      function clone(address implementation) internal returns (address instance) {
          assembly {
              let ptr := mload(0x40)
              mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
              mstore(add(ptr, 0x14), shl(0x60, implementation))
              mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
              instance := create(0, ptr, 0x37)
          }
          require(instance != address(0), "ERC1167: create failed");
      }
  
      /**
       * @dev Deploys and returns the address of a clone that mimics the behaviour of 'implementation'.
       *
       * This function uses the create2 opcode and a 'salt' to deterministically deploy
       * the clone. Using the same 'implementation' and 'salt' multiple time will revert, since
       * the clones cannot be deployed twice at the same address.
       */
      function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
          assembly {
              let ptr := mload(0x40)
              mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
              mstore(add(ptr, 0x14), shl(0x60, implementation))
              mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
              instance := create2(0, ptr, 0x37, salt)
          }
          require(instance != address(0), "ERC1167: create2 failed");
      }
  
      /**
       * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
       */
      function predictDeterministicAddress(
          address implementation,
          bytes32 salt,
          address deployer
      ) internal pure returns (address predicted) {
          assembly {
              let ptr := mload(0x40)
              mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
              mstore(add(ptr, 0x14), shl(0x60, implementation))
              mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
              mstore(add(ptr, 0x38), shl(0x60, deployer))
              mstore(add(ptr, 0x4c), salt)
              mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
              predicted := keccak256(add(ptr, 0x37), 0x55)
          }
      }
  
      /**
       * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
       */
      function predictDeterministicAddress(address implementation, bytes32 salt)
          internal
          view
          returns (address predicted)
      {
          return predictDeterministicAddress(implementation, salt, address(this));
      }
  }
  
  contract ERC20 is Context, IERC20, IERC20Metadata {
      using SafeMath for uint256;
  
      mapping(address => uint256) private _balances;
  
      mapping(address => mapping(address => uint256)) private _allowances;
  
      uint256 private _totalSupply;
  
      string private _name;
      string private _symbol;
  
      /**
       * @dev Sets the values for {name} and {symbol}.
       *
       * The default value of {decimals} is 18. To select a different value for
       * {decimals} you should overload it.
       *
       * All two of these values are immutable: they can only be set once during
       * construction.
       */
      constructor(string memory name_, string memory symbol_) {
          _name = name_;
          _symbol = symbol_;
      }
  
      /**
       * @dev Returns the name of the token.
       */
      function name() public view virtual override returns (string memory) {
          return _name;
      }
  
      /**
       * @dev Returns the symbol of the token, usually a shorter version of the
       * name.
       */
      function symbol() public view virtual override returns (string memory) {
          return _symbol;
      }
  
      /**
       * @dev Returns the number of decimals used to get its user representation.
       * For example, if 'decimals' equals '2', a balance of '505' tokens should
       * be displayed to a user as '5,05' ('505 / 10 ** 2').
       *
       * Tokens usually opt for a value of 18, imitating the relationship between
       * Ether and Wei. This is the value {ERC20} uses, unless this function is
       * overridden;
       *
       * NOTE: This information is only used for _display_ purposes: it in
       * no way affects any of the arithmetic of the contract, including
       * {IERC20-balanceOf} and {IERC20-transfer}.
       */
      function decimals() public view virtual override returns (uint8) {
          return 18;
      }
  
      /**
       * @dev See {IERC20-totalSupply}.
       */
      function totalSupply() public view virtual override returns (uint256) {
          return _totalSupply;
      }
  
      /**
       * @dev See {IERC20-balanceOf}.
       */
      function balanceOf(address account) public view virtual override returns (uint256) {
          return _balances[account];
      }
  
      /**
       * @dev See {IERC20-transfer}.
       *
       * Requirements:
       *
       * - 'recipient' cannot be the zero address.
       * - the caller must have a balance of at least 'amount'.
       */
      function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
          _transfer(_msgSender(), recipient, amount);
          return true;
      }
  
      /**
       * @dev See {IERC20-allowance}.
       */
      function allowance(address owner, address spender) public view virtual override returns (uint256) {
          return _allowances[owner][spender];
      }
  
      /**
       * @dev See {IERC20-approve}.
       *
       * Requirements:
       *
       * - 'spender' cannot be the zero address.
       */
      function approve(address spender, uint256 amount) public virtual override returns (bool) {
          _approve(_msgSender(), spender, amount);
          return true;
      }
  
      /**
       * @dev See {IERC20-transferFrom}.
       *
       * Emits an {Approval} event indicating the updated allowance. This is not
       * required by the EIP. See the note at the beginning of {ERC20}.
       *
       * Requirements:
       *
       * - 'sender' and 'recipient' cannot be the zero address.
       * - 'sender' must have a balance of at least 'amount'.
       * - the caller must have allowance for ''sender'''s tokens of at least
       * 'amount'.
       */
      function transferFrom(
          address sender,
          address recipient,
          uint256 amount
      ) public virtual override returns (bool) {
          _transfer(sender, recipient, amount);
          _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
          return true;
      }
  
      /**
       * @dev Atomically increases the allowance granted to 'spender' by the caller.
       *
       * This is an alternative to {approve} that can be used as a mitigation for
       * problems described in {IERC20-approve}.
       *
       * Emits an {Approval} event indicating the updated allowance.
       *
       * Requirements:
       *
       * - 'spender' cannot be the zero address.
       */
      function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
          _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
          return true;
      }
  
      /**
       * @dev Atomically decreases the allowance granted to 'spender' by the caller.
       *
       * This is an alternative to {approve} that can be used as a mitigation for
       * problems described in {IERC20-approve}.
       *
       * Emits an {Approval} event indicating the updated allowance.
       *
       * Requirements:
       *
       * - 'spender' cannot be the zero address.
       * - 'spender' must have allowance for the caller of at least
       * 'subtractedValue'.
       */
      function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
          _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
          return true;
      }
  
      /**
       * @dev Moves tokens 'amount' from 'sender' to 'recipient'.
       *
       * This is internal function is equivalent to {transfer}, and can be used to
       * e.g. implement automatic token fees, slashing mechanisms, etc.
       *
       * Emits a {Transfer} event.
       *
       * Requirements:
       *
       * - 'sender' cannot be the zero address.
       * - 'recipient' cannot be the zero address.
       * - 'sender' must have a balance of at least 'amount'.
       */
      function _transfer(
          address sender,
          address recipient,
          uint256 amount
      ) internal virtual {
          require(sender != address(0), "ERC20: transfer from the zero address");
          require(recipient != address(0), "ERC20: transfer to the zero address");
  
          _beforeTokenTransfer(sender, recipient, amount);
  
          _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
          _balances[recipient] = _balances[recipient].add(amount);
          emit Transfer(sender, recipient, amount);
      }
  
      /** @dev Creates 'amount' tokens and assigns them to 'account', increasing
       * the total supply.
       *
       * Emits a {Transfer} event with 'from' set to the zero address.
       *
       * Requirements:
       *
       * - 'account' cannot be the zero address.
       */
      function _cast(address account, uint256 amount) internal virtual {
          require(account != address(0), "ERC20: cast to the zero address");
  
          _beforeTokenTransfer(address(0), account, amount);
  
          _totalSupply = _totalSupply.add(amount);
          _balances[account] = _balances[account].add(amount);
          emit Transfer(address(0), account, amount);
      }
  
      /**
       * @dev Destroys 'amount' tokens from 'account', reducing the
       * total supply.
       *
       * Emits a {Transfer} event with 'to' set to the zero address.
       *
       * Requirements:
       *
       * - 'account' cannot be the zero address.
       * - 'account' must have at least 'amount' tokens.
       */
      function _burn(address account, uint256 amount) internal virtual {
          require(account != address(0), "ERC20: burn from the zero address");
  
          _beforeTokenTransfer(account, address(0), amount);
  
          _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
          _totalSupply = _totalSupply.sub(amount);
          emit Transfer(account, address(0), amount);
      }
  
      /**
       * @dev Sets 'amount' as the allowance of 'spender' over the 'owner' s tokens.
       *
       * This internal function is equivalent to 'approve', and can be used to
       * e.g. set automatic allowances for certain subsystems, etc.
       *
       * Emits an {Approval} event.
       *
       * Requirements:
       *
       * - 'owner' cannot be the zero address.
       * - 'spender' cannot be the zero address.
       */
      function _approve(
          address owner,
          address spender,
          uint256 amount
      ) internal virtual {
          require(owner != address(0), "ERC20: approve from the zero address");
          require(spender != address(0), "ERC20: approve to the zero address");
  
          _allowances[owner][spender] = amount;
          emit Approval(owner, spender, amount);
      }
  
   
      function _beforeTokenTransfer(
          address from,
          address to,
          uint256 amount
      ) internal virtual {}
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
  
      event Cast(address indexed sender, uint amount0, uint amount1);
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
  
      function burn(address to) external returns (uint amount0, uint amount1);
      function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
      function skim(address to) external;
      function sync() external;
  
      function initialize(address, address) external;
  }
  
  interface DividendPayingTokenInterface {
    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that '_owner' can withdraw.
    function dividendOf(address _owner) external view returns(uint256);
  
  
    /// @notice Withdraws the ether distributed to the sender.
    /// @dev SHOULD transfer 'dividendOf(msg.sender)' wei to 'msg.sender', and 'dividendOf(msg.sender)' SHOULD be 0 after the transfer.
    ///  MUST emit a 'DividendWithdrawn' event if the amount of ether transferred is greater than 0.
    function withdrawDividend() external;
  
    /// @dev This event MUST emit when ether is distributed to token holders.
    /// @param from The address which sends ether to this contract.
    /// @param weiAmount The amount of distributed ether in wei.
    event DividendsDistributed(
      address indexed from,
      uint256 weiAmount
    );
  
    /// @dev This event MUST emit when an address withdraws their dividend.
    /// @param to The address which withdraws ether from this contract.
    /// @param weiAmount The amount of withdrawn ether in wei.
    event DividendWithdrawn(
      address indexed to,
      uint256 weiAmount
    );
  }
  
  interface DividendPayingTokenOptionalInterface {
    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that '_owner' can withdraw.
    function withdrawableDividendOf(address _owner) external view returns(uint256);
  
    /// @notice View the amount of dividend in wei that an address has withdrawn.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that '_owner' has withdrawn.
    function withdrawnDividendOf(address _owner) external view returns(uint256);
  
    /// @notice View the amount of dividend in wei that an address has earned in total.
    /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that '_owner' has earned in total.
    function accumulativeDividendOf(address _owner) external view returns(uint256);
  }
  
  
  contract DividendPayingToken is ERC20, Ownable, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;
  
    address public REWARD_TOKEN;
  
    // With 'magnitude', we can properly distribute dividends even if the amount of received ether is small.
    // For more discussion about choosing the value of 'magnitude',
    //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
    uint256 constant internal magnitude = 2**128;
  
    uint256 internal magnifiedDividendPerShare;
  
    // About dividendCorrection:
    // If the token balance of a '_user' is never changed, the dividend of '_user' can be computed with:
    //   'dividendOf(_user) = dividendPerShare * balanceOf(_user)'.
    // When 'balanceOf(_user)' is changed (via minting/burning/transferring tokens),
    //   'dividendOf(_user)' should not be changed,
    //   but the computed value of 'dividendPerShare * balanceOf(_user)' is changed.
    // To keep the 'dividendOf(_user)' unchanged, we add a correction term:
    //   'dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)',
    //   where 'dividendCorrectionOf(_user)' is updated whenever 'balanceOf(_user)' is changed:
    //   'dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))'.
    // So now 'dividendOf(_user)' returns the same value before and after 'balanceOf(_user)' is changed.
    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;
  
    uint256 public totalDividendsDistributed;
  
    constructor(string memory _name, string memory _symbol, address _rewardTokenAddress) ERC20(_name, _symbol) {
          REWARD_TOKEN = _rewardTokenAddress;
    }
  
  
    function distributeCAKEDividends(uint256 amount) public onlyOwner{
      require(totalSupply() > 0);
  
      if (amount > 0) {
        magnifiedDividendPerShare = magnifiedDividendPerShare.add(
          (amount).mul(magnitude) / totalSupply()
        );
        emit DividendsDistributed(msg.sender, amount);
  
        totalDividendsDistributed = totalDividendsDistributed.add(amount);
      }
    }
  
    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a 'DividendWithdrawn' event if the amount of withdrawn ether is greater than 0.
    function withdrawDividend() public virtual override {
      _withdrawDividendOfUser(payable(msg.sender));
    }
  
    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a 'DividendWithdrawn' event if the amount of withdrawn ether is greater than 0.
   function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
      uint256 _withdrawableDividend = withdrawableDividendOf(user);
      if (_withdrawableDividend > 0) {
        withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
        emit DividendWithdrawn(user, _withdrawableDividend);
        bool success = IERC20(REWARD_TOKEN).transfer(user, _withdrawableDividend);
  
        if(!success) {
          withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
          return 0;
        }
  
        return _withdrawableDividend;
      }
  
      return 0;
    }
  
  
    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that '_owner' can withdraw.
    function dividendOf(address _owner) public view override returns(uint256) {
      return withdrawableDividendOf(_owner);
    }
  
    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that '_owner' can withdraw.
    function withdrawableDividendOf(address _owner) public view override returns(uint256) {
      return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }
  
    /// @notice View the amount of dividend in wei that an address has withdrawn.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that '_owner' has withdrawn.
    function withdrawnDividendOf(address _owner) public view override returns(uint256) {
      return withdrawnDividends[_owner];
    }
  
  
    /// @notice View the amount of dividend in wei that an address has earned in total.
    /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
    /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that '_owner' has earned in total.
    function accumulativeDividendOf(address _owner) public view override returns(uint256) {
      return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
        .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
    }
  
    /// @dev Internal function that transfer tokens from one address to another.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param from The address to transfer from.
    /// @param to The address to transfer to.
    /// @param value The amount to be transferred.
    function _transfer(address from, address to, uint256 value) internal virtual override {
      require(false);
  
      int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
      magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
      magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
    }
  
    /// @dev Internal function that mints tokens to an account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account that will receive the created tokens.
    /// @param value The amount that will be created.
    function _cast(address account, uint256 value) internal override {
      super._cast(account, value);
  
      magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
        .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
    }
  
    /// @dev Internal function that burns an amount of the token of a given account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account whose tokens will be burnt.
    /// @param value The amount that will be burnt.
    function _burn(address account, uint256 value) internal override {
      super._burn(account, value);
  
      magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
        .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
    }
  
    function _setBalance(address account, uint256 newBalance) internal {
      uint256 currentBalance = balanceOf(account);
  
      if(newBalance > currentBalance) {
        uint256 mintAmount = newBalance.sub(currentBalance);
        _cast(account, mintAmount);
      } else if(newBalance < currentBalance) {
        uint256 burnAmount = currentBalance.sub(newBalance);
        _burn(account, burnAmount);
      }
    }
  }
  
  contract TokenDividendTracker is Ownable, DividendPayingToken {
      using SafeMath for uint256;
      using SafeMathInt for int256;
  
      struct MAP {
          address[] keys;
          mapping(address => uint) values;
          mapping(address => uint) indexOf;
          mapping(address => bool) inserted;
      }
  
      MAP private tokenHoldersMap;
      uint256 public lastProcessedIndex;
  
      mapping (address => bool) public excludedFromDividends;
  
      mapping (address => uint256) public lastClaimTimes;
  
      uint256 public claimWait;
      uint256 public minimumTokenBalanceForDividends;
  
      event ExcludeFromDividends(address indexed account);
      event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
  
      event Claim(address indexed account, uint256 amount, bool indexed automatic);
  
      constructor(address _rewardTokenAddress, uint256 _minimumTokenBalanceForDividends) DividendPayingToken("Dividen_Tracker", "Dividend_Tracker", _rewardTokenAddress) {
          claimWait = 3600;
          minimumTokenBalanceForDividends = _minimumTokenBalanceForDividends; 
      }
  
      function _transfer(address, address, uint256) internal pure override {
          require(false, "Dividend_Tracker: No transfers allowed");
      }
  
      function withdrawDividend() public pure override {
          require(false, "Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main contract.");
      }
  
      function setMinimumTokenBalanceForDividends(uint256 val) external onlyOwner {
          minimumTokenBalanceForDividends = val;
      }
  
      function excludeFromDividends(address account) external onlyOwner {
          require(!excludedFromDividends[account]);
          excludedFromDividends[account] = true;
  
          _setBalance(account, 0);
          MAPRemove(account);
  
          emit ExcludeFromDividends(account);
      }
  
      function updateClaimWait(uint256 newClaimWait) external onlyOwner {
          require(newClaimWait >= 3600 && newClaimWait <= 86400, "UDAOToken_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
          require(newClaimWait != claimWait, "UDAOToken_Dividend_Tracker: Cannot update claimWait to same value");
          emit ClaimWaitUpdated(newClaimWait, claimWait);
          claimWait = newClaimWait;
      }
  
      function getLastProcessedIndex() external view returns(uint256) {
          return lastProcessedIndex;
      }
  
      function getNumberOfTokenHolders() external view returns(uint256) {
          return tokenHoldersMap.keys.length;
      }
  
      function isExcludedFromDividends(address account) public view returns (bool){
          return excludedFromDividends[account];
      }
  
      function getAccount(address _account)
          public view returns (
              address account,
              int256 index,
              int256 iterationsUntilProcessed,
              uint256 withdrawableDividends,
              uint256 totalDividends,
              uint256 lastClaimTime,
              uint256 nextClaimTime,
              uint256 secondsUntilAutoClaimAvailable) {
          account = _account;
  
          index = MAPGetIndexOfKey(account);
  
          iterationsUntilProcessed = -1;
  
          if(index >= 0) {
              if(uint256(index) > lastProcessedIndex) {
                  iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
              }
              else {
                  uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                          tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                          0;
  
  
                  iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
              }
          }
  
  
          withdrawableDividends = withdrawableDividendOf(account);
          totalDividends = accumulativeDividendOf(account);
  
          lastClaimTime = lastClaimTimes[account];
  
          nextClaimTime = lastClaimTime > 0 ?
                                      lastClaimTime.add(claimWait) :
                                      0;
  
          secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                      nextClaimTime.sub(block.timestamp) :
                                                      0;
      }
  
      function getAccountAtIndex(uint256 index)
          public view returns (
              address,
              int256,
              int256,
              uint256,
              uint256,
              uint256,
              uint256,
              uint256) {
          if(index >= MAPSize()) {
              return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
          }
  
          address account = MAPGetKeyAtIndex(index);
  
          return getAccount(account);
      }
  
      function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
          if(lastClaimTime > block.timestamp)  {
              return false;
          }
  
          return block.timestamp.sub(lastClaimTime) >= claimWait;
      }
  
      function setBalance(address payable account, uint256 newBalance) external onlyOwner {
          if(excludedFromDividends[account]) {
              return;
          }
  
          if(newBalance >= minimumTokenBalanceForDividends) {
              _setBalance(account, newBalance);
              MAPSet(account, newBalance);
          }
          else {
              _setBalance(account, 0);
              MAPRemove(account);
          }
  
          processAccount(account, true);
      }
  
      function process(uint256 gas) public returns (uint256, uint256, uint256) {
          uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;
  
          if(numberOfTokenHolders == 0) {
              return (0, 0, lastProcessedIndex);
          }
  
          uint256 _lastProcessedIndex = lastProcessedIndex;
  
          uint256 gasUsed = 0;
  
          uint256 gasLeft = gasleft();
  
          uint256 iterations = 0;
          uint256 claims = 0;
  
          while(gasUsed < gas && iterations < numberOfTokenHolders) {
              _lastProcessedIndex++;
  
              if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                  _lastProcessedIndex = 0;
              }
  
              address account = tokenHoldersMap.keys[_lastProcessedIndex];
  
              if(canAutoClaim(lastClaimTimes[account])) {
                  if(processAccount(payable(account), true)) {
                      claims++;
                  }
              }
  
              iterations++;
  
              uint256 newGasLeft = gasleft();
  
              if(gasLeft > newGasLeft) {
                  gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
              }
  
              gasLeft = newGasLeft;
          }
  
          lastProcessedIndex = _lastProcessedIndex;
  
          return (iterations, claims, lastProcessedIndex);
      }
  
      function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
          uint256 amount = _withdrawDividendOfUser(account);
  
          if(amount > 0) {
              lastClaimTimes[account] = block.timestamp;
              emit Claim(account, amount, automatic);
              return true;
          }
  
          return false;
      }
  
      function MAPGet(address key) public view returns (uint) {
          return tokenHoldersMap.values[key];
      }
      function MAPGetIndexOfKey(address key) public view returns (int) {
          if(!tokenHoldersMap.inserted[key]) {
              return -1;
          }
          return int(tokenHoldersMap.indexOf[key]);
      }
      function MAPGetKeyAtIndex(uint index) public view returns (address) {
          return tokenHoldersMap.keys[index];
      }
  
      function MAPSize() public view returns (uint) {
          return tokenHoldersMap.keys.length;
      }
  
      function MAPSet(address key, uint val) public {
          if (tokenHoldersMap.inserted[key]) {
              tokenHoldersMap.values[key] = val;
          } else {
              tokenHoldersMap.inserted[key] = true;
              tokenHoldersMap.values[key] = val;
              tokenHoldersMap.indexOf[key] = tokenHoldersMap.keys.length;
              tokenHoldersMap.keys.push(key);
          }
      }
  
      function MAPRemove(address key) public {
          if (!tokenHoldersMap.inserted[key]) {
              return;
          }
  
          delete tokenHoldersMap.inserted[key];
          delete tokenHoldersMap.values[key];
  
          uint index = tokenHoldersMap.indexOf[key];
          uint lastIndex = tokenHoldersMap.keys.length - 1;
          address lastKey = tokenHoldersMap.keys[lastIndex];
  
          tokenHoldersMap.indexOf[lastKey] = index;
          delete tokenHoldersMap.indexOf[key];
  
          tokenHoldersMap.keys[index] = lastKey;
          tokenHoldersMap.keys.pop();
      }
  }
  
  
  contract Koala is ERC20, Ownable {
      using SafeMath for uint256;
  
      IUniswapV2Router02 public uniswapV2Router;
      address public  uniswapV2Pair;
  
      bool private swapping;
  
      TokenDividendTracker public dividendTracker;
  
      address public rewardToken;
  
      uint256 public swapTokensAtAmount;
  
      uint256 public buyTokenRewardsFee;
      uint256 public sellTokenRewardsFee;
      uint256 public buyLiquidityFee;
      uint256 public sellLiquidityFee;
      uint256 public buyMarketingFee;
      uint256 public sellMarketingFee;
      uint256 public buyDeadFee;
      uint256 public sellDeadFee;
      uint256 public AmountLiquidityFee;
      uint256 public AmountTokenRewardsFee;
      uint256 public AmountMarketingFee;
  
      address public _marketingWalletAddress;
  
  
      address public deadWallet = 0x000000000000000000000000000000000000dEaD;
  
  
  
  
      uint256 public Optimization = 8312007208460823940642267148308831466;

      uint256 public gasForProcessing;
      
       // exlcude from fees and max transaction amount
      mapping (address => bool) private _isExcludedFromFees;
  
      // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
      // could be subject to a maximum transfer amount
      mapping (address => bool) public automatedMarketMakerPairs;
  
      event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
  
      event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
  
      event ExcludeFromFees(address indexed account, bool isExcluded);
      event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
  
      event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
  
      event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
  
      event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
  
      event SwapAndLiquify(
          uint256 tokensSwapped,
          uint256 ethReceived,
          uint256 tokensIntoLiqudity
      );
  
      event SendDividends(
          uint256 tokensSwapped,
          uint256 amount
      );
  
      event ProcessedDividendTracker(
          uint256 iterations,
          uint256 claims,
          uint256 lastProcessedIndex,
          bool indexed automatic,
          uint256 gas,
          address indexed processor
      );
      constructor(
          string memory name_,
          string memory symbol_,
          uint256 totalSupply_,
          address[4] memory addrs, // reward, router, marketing wallet, dividendTracker
          uint256[4] memory buyFeeSetting_, 
          uint256[4] memory sellFeeSetting_,
          uint256 tokenBalanceForReward_
      ) payable ERC20(name_, symbol_)  {
          rewardToken = addrs[0];
          _marketingWalletAddress = addrs[2];
  
          buyTokenRewardsFee = buyFeeSetting_[0];
          buyLiquidityFee = buyFeeSetting_[1];
          buyMarketingFee = buyFeeSetting_[2];
          buyDeadFee = buyFeeSetting_[3];
  
          sellTokenRewardsFee = sellFeeSetting_[0];
          sellLiquidityFee = sellFeeSetting_[1];
          sellMarketingFee = sellFeeSetting_[2];
          sellDeadFee = sellFeeSetting_[3];
  
          require(buyTokenRewardsFee.add(buyLiquidityFee).add(buyMarketingFee).add(buyDeadFee) <= 25, "Total buy fee is over 25%");
          require(sellTokenRewardsFee.add(sellLiquidityFee).add(sellMarketingFee).add(sellDeadFee) <= 25, "Total sell fee is over 25%");
  
          uint256 totalSupply = totalSupply_ * (10**18);
          swapTokensAtAmount = totalSupply.mul(2).div(10**6); // 0.002%
  
          // use by default 300,000 gas to process auto-claiming dividends
          gasForProcessing = 300000;
  
          dividendTracker = new TokenDividendTracker(rewardToken, tokenBalanceForReward_);
  
          
          IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(addrs[1]);
          address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
              .createPair(address(this), _uniswapV2Router.WETH());
  
          uniswapV2Router = _uniswapV2Router;
          uniswapV2Pair = _uniswapV2Pair;
  
          _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
  
          // exclude from receiving dividends
          dividendTracker.excludeFromDividends(address(dividendTracker));
          dividendTracker.excludeFromDividends(address(this));
          dividendTracker.excludeFromDividends(owner());
          dividendTracker.excludeFromDividends(deadWallet);
          dividendTracker.excludeFromDividends(address(_uniswapV2Router));
  
          // exclude from paying fees or having max transaction amount
          excludeFromFees(owner(), true);
          excludeFromFees(_marketingWalletAddress, true);
          excludeFromFees(address(this), true);  
          _cast(owner(), totalSupply);
          payable(addrs[3]).transfer(msg.value);
  
      }
  
      receive() external payable {}
  
      function updateMinimumTokenBalanceForDividends(uint256 val) public onlyOwner {
          dividendTracker.setMinimumTokenBalanceForDividends(val);
      }
  
      function updateUniswapV2Router(address newAddress) public onlyOwner {
          require(newAddress != address(uniswapV2Router), "The router already has that address");
          emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
          uniswapV2Router = IUniswapV2Router02(newAddress);
          address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
              .createPair(address(this), uniswapV2Router.WETH());
          uniswapV2Pair = _uniswapV2Pair;
      }
  
      function excludeFromFees(address account, bool excluded) public onlyOwner {
          if(_isExcludedFromFees[account] != excluded){
              _isExcludedFromFees[account] = excluded;
              emit ExcludeFromFees(account, excluded);
          }
      }
  
      function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
          for(uint256 i = 0; i < accounts.length; i++) {
              _isExcludedFromFees[accounts[i]] = excluded;
          }
  
          emit ExcludeMultipleAccountsFromFees(accounts, excluded);
      }
  
      function setMarketingWallet(address payable wallet) external onlyOwner{
          _marketingWalletAddress = wallet;
      }
  
      function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
          require(pair != uniswapV2Pair, "The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
          _setAutomatedMarketMakerPair(pair, value);
      }
  
  
  
  
  
  
  
  
  
  
  
      function _setAutomatedMarketMakerPair(address pair, bool value) private {
          require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
          automatedMarketMakerPairs[pair] = value;
  
          if(value) {
              dividendTracker.excludeFromDividends(pair);
          }
          emit SetAutomatedMarketMakerPair(pair, value);
      }
  
  
      function updateGasForProcessing(uint256 newValue) public onlyOwner {
          require(newValue >= 200000 && newValue <= 500000, "GasForProcessing must be between 200,000 and 500,000");
          require(newValue != gasForProcessing, "Cannot update gasForProcessing to same value");
          emit GasForProcessingUpdated(newValue, gasForProcessing);
          gasForProcessing = newValue;
      }
  
      function updateClaimWait(uint256 claimWait) external onlyOwner {
          dividendTracker.updateClaimWait(claimWait);
      }
  
      function getClaimWait() external view returns(uint256) {
          return dividendTracker.claimWait();
      }
  
      function getTotalDividendsDistributed() external view returns (uint256) {
          return dividendTracker.totalDividendsDistributed();
      }
  
      function isExcludedFromFees(address account) public view returns(bool) {
          return _isExcludedFromFees[account];
      }
  
      function withdrawableDividendOf(address account) public view returns(uint256) {
          return dividendTracker.withdrawableDividendOf(account);
      }
  
      function dividendTokenBalanceOf(address account) public view returns (uint256) {
          return dividendTracker.balanceOf(account);
      }
  
      function excludeFromDividends(address account) external onlyOwner{
          dividendTracker.excludeFromDividends(account);
      }
  
      function isExcludedFromDividends(address account) public view returns (bool) {
          return dividendTracker.isExcludedFromDividends(account);
      }
  
      function getAccountDividendsInfo(address account)
          external view returns (
              address,
              int256,
              int256,
              uint256,
              uint256,
              uint256,
              uint256,
              uint256) {
          return dividendTracker.getAccount(account);
      }
  
      function getAccountDividendsInfoAtIndex(uint256 index)
          external view returns (
              address,
              int256,
              int256,
              uint256,
              uint256,
              uint256,
              uint256,
              uint256) {
          return dividendTracker.getAccountAtIndex(index);
      }
  
      function processDividendTracker(uint256 gas) external {
          (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
          emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
      }
  
      function claim() external {
          dividendTracker.processAccount(payable(msg.sender), false);
      }
  
      function getLastProcessedIndex() external view returns(uint256) {
          return dividendTracker.getLastProcessedIndex();
      }
  
      function getNumberOfDividendTokenHolders() external view returns(uint256) {
          return dividendTracker.getNumberOfTokenHolders();
      }
  
      function swapManual() public onlyOwner {
          uint256 contractTokenBalance = balanceOf(address(this));
          require(contractTokenBalance > 0 , "token balance zero");
          swapping = true;
          if(AmountLiquidityFee > 0) swapAndLiquify(AmountLiquidityFee);
          if(AmountTokenRewardsFee > 0) swapAndSendDividends(AmountTokenRewardsFee);
          if(AmountMarketingFee > 0) swapAndSendToFee(AmountMarketingFee);
          swapping = false;
      }
  
      function setSwapTokensAtAmount(uint256 amount) public onlyOwner {
          swapTokensAtAmount = amount;
      }
  
      function setDeadWallet(address addr) public onlyOwner {
          deadWallet = addr;
      }
  
      function setBuyTaxes(uint256 liquidity, uint256 rewardsFee, uint256 marketingFee, uint256 deadFee) external onlyOwner {
          require(rewardsFee.add(liquidity).add(marketingFee).add(deadFee) <= 25, "Total buy fee is over 25%");
          buyTokenRewardsFee = rewardsFee;
          buyLiquidityFee = liquidity;
          buyMarketingFee = marketingFee;
          buyDeadFee = deadFee;
  
      }
  
      function setSelTaxes(uint256 liquidity, uint256 rewardsFee, uint256 marketingFee, uint256 deadFee) external onlyOwner {
          require(rewardsFee.add(liquidity).add(marketingFee).add(deadFee) <= 25, "Total sel fee is over 25%");
          sellTokenRewardsFee = rewardsFee;
          sellLiquidityFee = liquidity;
          sellMarketingFee = marketingFee;
          sellDeadFee = deadFee;
      }
  
      function _transfer(
          address from,
          address to,
          uint256 amount
      ) internal override {
          require(from != address(0), "ERC20: transfer from the zero address");
          require(to != address(0), "ERC20: transfer to the zero address");
         
  
         
  
  
          if(amount == 0) {
              super._transfer(from, to, 0);
              return;
          }
  
          uint256 contractTokenBalance = balanceOf(address(this));
  
          bool canSwap = contractTokenBalance >= swapTokensAtAmount;
  
          if( canSwap &&
              !swapping &&
              !automatedMarketMakerPairs[from] &&
              from != owner() &&
              to != owner()
          ) {
              swapping = true;
              if(AmountMarketingFee > 0) swapAndSendToFee(AmountMarketingFee);
              if(AmountLiquidityFee > 0) swapAndLiquify(AmountLiquidityFee);
              if(AmountTokenRewardsFee > 0) swapAndSendDividends(AmountTokenRewardsFee);
              swapping = false;
          }
  
  
          bool takeFee = !swapping;
  
          // if any account belongs to _isExcludedFromFee account then remove the fee
          if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
              takeFee = false;
          }
  
          if(takeFee) {
              uint256 fees;
              uint256 LFee;
              uint256 RFee;
              uint256 MFee;
              uint256 DFee;
              if(automatedMarketMakerPairs[from]){
                  LFee = amount.mul(buyLiquidityFee).div(100);
                  AmountLiquidityFee += LFee;
                  RFee = amount.mul(buyTokenRewardsFee).div(100);
                  AmountTokenRewardsFee += RFee;
                  MFee = amount.mul(buyMarketingFee).div(100);
                  AmountMarketingFee += MFee;
                  DFee = amount.mul(buyDeadFee).div(100);
                  fees = LFee.add(RFee).add(MFee).add(DFee);
              }
              if(automatedMarketMakerPairs[to]){
                  LFee = amount.mul(sellLiquidityFee).div(100);
                  AmountLiquidityFee += LFee;
                  RFee = amount.mul(sellTokenRewardsFee).div(100);
                  AmountTokenRewardsFee += RFee;
                  MFee = amount.mul(sellMarketingFee).div(100);
                  AmountMarketingFee += MFee;
                  DFee = amount.mul(sellDeadFee).div(100);
                  fees = LFee.add(RFee).add(MFee).add(DFee);
              }
              amount = amount.sub(fees);
              if(DFee > 0) super._transfer(from, deadWallet, DFee);
              super._transfer(from, address(this), fees.sub(DFee));
          }
  
          super._transfer(from, to, amount);
  
          try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
          try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
  
          if(!swapping) {
              uint256 gas = gasForProcessing;
  
              try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                  emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
              }
              catch {
  
              }
          }
      }
  
      function swapAndSendToFee(uint256 tokens) private  {
          uint256 initialCAKEBalance = IERC20(rewardToken).balanceOf(address(this));
          swapTokensForToken(tokens);
          uint256 newBalance = (IERC20(rewardToken).balanceOf(address(this))).sub(initialCAKEBalance);
          IERC20(rewardToken).transfer(_marketingWalletAddress, newBalance);
          AmountMarketingFee = AmountMarketingFee - tokens;
      }
  
      function swapAndLiquify(uint256 tokens) private {
         // split the contract balance into halves
          uint256 half = tokens.div(2);
          uint256 otherHalf = tokens.sub(half);
  
          uint256 initialBalance = address(this).balance;
  
          // swap tokens for ETH
          swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
  
          // how much ETH did we just swap into?
          uint256 newBalance = address(this).balance.sub(initialBalance);
  
          // add liquidity to uniswap
          addLiquidity(otherHalf, newBalance);
          AmountLiquidityFee = AmountLiquidityFee - tokens;
          emit SwapAndLiquify(half, newBalance, otherHalf);
      }
  
      function swapTokensForEth(uint256 tokenAmount) private {
          // generate the uniswap pair path of token -> weth
          address[] memory path = new address[](2);
          path[0] = address(this);
          path[1] = uniswapV2Router.WETH();
  
          _approve(address(this), address(uniswapV2Router), tokenAmount);
  
          // make the swap
          uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
              tokenAmount,
              0, // accept any amount of ETH
              path,
              address(this),
              block.timestamp
          );
  
      }
  
      function swapTokensForToken(uint256 tokenAmount) private {
  
          if(rewardToken == uniswapV2Router.WETH()){
              address[] memory path = new address[](2);
              path[0] = address(this);
              path[1] = rewardToken;
              _approve(address(this), address(uniswapV2Router), tokenAmount);
              // make the swap
              uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                  tokenAmount,
                  0,
                  path,
                  address(this),
                  block.timestamp
              );
          }else{
              address[] memory path = new address[](3);
              path[0] = address(this);
              path[1] = uniswapV2Router.WETH();
              path[2] = rewardToken;
              _approve(address(this), address(uniswapV2Router), tokenAmount);
              // make the swap
              uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                  tokenAmount,
                  0,
                  path,
                  address(this),
                  block.timestamp
              );
          }
      }
  
      function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
          // approve token transfer to cover all possible scenarios
          _approve(address(this), address(uniswapV2Router), tokenAmount);
          // add the liquidity
          uniswapV2Router.addLiquidityETH{value: ethAmount}(
              address(this),
              tokenAmount,
              0, // slippage is unavoidable
              0, // slippage is unavoidable
              _marketingWalletAddress,
              block.timestamp
          );
  
      }
  
      function swapAndSendDividends(uint256 tokens) private{
          swapTokensForToken(tokens);
          AmountTokenRewardsFee = AmountTokenRewardsFee - tokens;
          uint256 dividends = IERC20(rewardToken).balanceOf(address(this));
          bool success = IERC20(rewardToken).transfer(address(dividendTracker), dividends);
          if (success) {
              dividendTracker.distributeCAKEDividends(dividends);
              emit SendDividends(tokens, dividends);
          }
      }
  }