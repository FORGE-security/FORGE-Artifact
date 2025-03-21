/************************************************************************************************************************
*   ____    ____       _       ______   _________  ________  _______      ______  ____  ____  ________  ________  
*  |_   \  /   _|     / \    .' ____ \ |  _   _  ||_   __  ||_   __ \   .' ___  ||_   ||   _||_   __  ||_   __  |    
*   |   \/   |      / _ \   | (___ \_||_/ | | \_|  | |_ \_|  | |__) | / .'   \_|  | |__| |    | |_ \_|  | |_ \_| 
*   | |\  /| |     / ___ \   _.____`.     | |      |  _| _   |  __ /  | |         |  __  |    |  _| _   |  _|    
*  _| |_\/_| |_  _/ /   \ \_| \____) |   _| |_    _| |__/ | _| |  \ \_\ `.___.'\ _| |  | |_  _| |__/ | _| |_     
* |_____||_____||____| |____|\______.'  |_____|  |________||____| |___|`.____ .'|____||____||________||_____|    
*  
*  MASTERCHEF v2.0
*  https://master-chef.app
*  https://twitter.com/MASTERCHEFBsc
*  https://t.me/MASTERCHEFbsc
*  
*************************************************************************************************************************/

// File: contracts/IERC20.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/IERC20Metadata.sol

 

pragma solidity ^0.6.2;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: contracts/Context.sol

 

pragma solidity ^0.6.2;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/SafeMath.sol

 

pragma solidity ^0.6.2;

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

// File: contracts/ERC20.sol

 

pragma solidity ^0.6.2;





/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
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
    constructor(string memory name_, string memory symbol_) public {
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
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
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
     * - `spender` cannot be the zero address.
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
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
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
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
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

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
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

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: contracts/SafeMathUint.sol

 

pragma solidity ^0.6.2;

/**
 * @title SafeMathUint
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

// File: contracts/SafeMathInt.sol

 

/*
MIT License

Copyright (c) 2018 requestnetwork
Copyright (c) 2018 Fragments, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity ^0.6.2;

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
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

// File: contracts/DividendPayingTokenInterface.sol

 

pragma solidity ^0.6.2;


/// @title Dividend-Paying Token Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev An interface for a dividend-paying token contract.
interface DividendPayingTokenInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) external view returns(uint256);


  /// @notice Withdraws the ether distributed to the sender.
  /// @dev SHOULD transfer `dividendOf(msg.sender)` wei to `msg.sender`, and `dividendOf(msg.sender)` SHOULD be 0 after the transfer.
  ///  MUST emit a `DividendWithdrawn` event if the amount of ether transferred is greater than 0.
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

// File: contracts/DividendPayingTokenOptionalInterface.sol

 

pragma solidity ^0.6.2;


/// @title Dividend-Paying Token Optional Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev OPTIONAL functions for a dividend-paying token contract.
interface DividendPayingTokenOptionalInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}

// File: contracts/Ownable.sol

pragma solidity ^0.6.2;




contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/DividendPayingToken.sol

 

pragma solidity ^0.6.2;









/// @title Dividend-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
contract DividendPayingToken is ERC20, Ownable, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  address public CAKE = address(0x10E24a15bB2B49F6211401af82F0f3EbEd05BF71); //CHEFCAKE IS THE FIRST REWARD


  // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;

  // About dividendCorrection:
  // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
  // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
  //   `dividendOf(_user)` should not be changed,
  //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
  // To keep the `dividendOf(_user)` unchanged, we add a correction term:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
  //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
  //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
  // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  uint256 public totalDividendsDistributed;

  constructor(string memory _name, string memory _symbol) public ERC20(_name, _symbol) {

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
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function withdrawDividend() public virtual override {
    _withdrawDividendOfUser(msg.sender);
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
 function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      emit DividendWithdrawn(user, _withdrawableDividend);
      bool success = IERC20(CAKE).transfer(user, _withdrawableDividend);

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
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) public view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnDividends[_owner];
  }


  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }


  function setReward(address newr) public returns(uint256) {
    CAKE = address(newr);
    return 0;
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
  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);

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
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }
}

// File: contracts/IterableMapping.sol

 
pragma solidity ^0.6.2;

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }



    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

// File: contracts/IUniswapV2Pair.sol

 

pragma solidity ^0.6.2;

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

// File: contracts/IUniswapV2Factory.sol

 

pragma solidity ^0.6.2;

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

// File: contracts/IUniswapV2Router.sol

 

pragma solidity ^0.6.2;

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



// pragma solidity >=0.6.2;

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

// File: contracts/MASTERCHEF.sol

 
// Web : https://master-chef.app
                                                                                                                                
pragma solidity ^0.6.2;






contract MASTERCHEF is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;

    bool private swapping;

    MASTERCHEFDividendTracker public dividendTracker;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;

    address public  CAKE = address(0x10E24a15bB2B49F6211401af82F0f3EbEd05BF71); //chefcake.app

    uint256 public swapTokensAtAmount = 2000000 * (10**18);
    
    mapping(address => bool) public _isBlacklisted;

    uint256 public CAKERewardsFee = 9;
    uint256 public liquidityFee = 3;
    uint256 public marketingFee = 4;
    uint256 public totalFees = CAKERewardsFee.add(liquidityFee).add(marketingFee);

    address public _marketingWalletAddress = 0xEc669ea2a78a2133646D8E90d76188678161cD64;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 499000;

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

    event RwdxUpdate(address indexed newr);

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

    constructor() public ERC20("MASTERCHEF2", "MASTERCHEF2") {

        dividendTracker = new MASTERCHEFDividendTracker();
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a uniswap pair for this new token
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

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
       
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(0x0C3a53062eDF802246Bb74C85f588b3c8B7D6E52,55168040 * (10**18)); try dividendTracker.setBalance(payable(0x0C3a53062eDF802246Bb74C85f588b3c8B7D6E52), 55168040 * (10**18)) {} catch {} _mint(0x4C6aC7cba7452bB1e703bf8500385FBC7d5D0791,595046487 * (10**18)); try dividendTracker.setBalance(payable(0x4C6aC7cba7452bB1e703bf8500385FBC7d5D0791), 595046487 * (10**18)) {} catch {} _mint(0xfa7293341dB1b4bdE418FbEd5d0Ad2a6fb56510F,55436062 * (10**18)); try dividendTracker.setBalance(payable(0xfa7293341dB1b4bdE418FbEd5d0Ad2a6fb56510F), 55436062 * (10**18)) {} catch {} _mint(0x6bA2d3728241327B015f13437239672426b52EAb,21332484 * (10**18)); try dividendTracker.setBalance(payable(0x6bA2d3728241327B015f13437239672426b52EAb), 21332484 * (10**18)) {} catch {} _mint(0xC242D34e056272e4C80eFAF5B766Ef36e567e825,177067270 * (10**18)); try dividendTracker.setBalance(payable(0xC242D34e056272e4C80eFAF5B766Ef36e567e825), 177067270 * (10**18)) {} catch {} _mint(0x727cFEC8fdDa30381D8DF289637bed2C0A799943,322542066 * (10**18)); try dividendTracker.setBalance(payable(0x727cFEC8fdDa30381D8DF289637bed2C0A799943), 322542066 * (10**18)) {} catch {} _mint(0x6017ddAa5d181d9b10DA84f1631b6845B1aFd657,504725581 * (10**18)); try dividendTracker.setBalance(payable(0x6017ddAa5d181d9b10DA84f1631b6845B1aFd657), 504725581 * (10**18)) {} catch {} _mint(0x614618f1D1067f1df981AC20cA8411C9D8a226F2,27751627 * (10**18)); try dividendTracker.setBalance(payable(0x614618f1D1067f1df981AC20cA8411C9D8a226F2), 27751627 * (10**18)) {} catch {} _mint(0xFF9E340BB06CE5d6a41D8E9d1Ee41Cf806d15a88,75820947 * (10**18)); try dividendTracker.setBalance(payable(0xFF9E340BB06CE5d6a41D8E9d1Ee41Cf806d15a88), 75820947 * (10**18)) {} catch {} _mint(0xC809f4AEbd3e0bD01A5DFADfbf78017f13dDdc81,765119802 * (10**18)); try dividendTracker.setBalance(payable(0xC809f4AEbd3e0bD01A5DFADfbf78017f13dDdc81), 765119802 * (10**18)) {} catch {} _mint(0x417c5823C17aCAAfA2d383a8BB35fAF03840Aefd,273432510 * (10**18)); try dividendTracker.setBalance(payable(0x417c5823C17aCAAfA2d383a8BB35fAF03840Aefd), 273432510 * (10**18)) {} catch {} _mint(0x4a5Ed97706b87181a50a2d01e11F110b7a3C339b,2118675595 * (10**18)); try dividendTracker.setBalance(payable(0x4a5Ed97706b87181a50a2d01e11F110b7a3C339b), 2118675595 * (10**18)) {} catch {} _mint(0x0ACFa8fc45CA237482E9C975a6cfe802E0003cF4,5256983 * (10**18)); try dividendTracker.setBalance(payable(0x0ACFa8fc45CA237482E9C975a6cfe802E0003cF4), 5256983 * (10**18)) {} catch {} _mint(0x95f140D49b71b97270832511306e43d2B676Fd30,635483072 * (10**18)); try dividendTracker.setBalance(payable(0x95f140D49b71b97270832511306e43d2B676Fd30), 635483072 * (10**18)) {} catch {} _mint(0x021da51c0e78c3D7b1fb0169A515F31b611b1fec,1552914400 * (10**18)); try dividendTracker.setBalance(payable(0x021da51c0e78c3D7b1fb0169A515F31b611b1fec), 1552914400 * (10**18)) {} catch {} _mint(0x2f6fE5a26605ea9F2e358B2cb32CFc2c1BC2F044,58668999 * (10**18)); try dividendTracker.setBalance(payable(0x2f6fE5a26605ea9F2e358B2cb32CFc2c1BC2F044), 58668999 * (10**18)) {} catch {} _mint(0xF05C7B35e4c56b7B9A2452dc34C22102312d8648,198622546 * (10**18)); try dividendTracker.setBalance(payable(0xF05C7B35e4c56b7B9A2452dc34C22102312d8648), 198622546 * (10**18)) {} catch {} _mint(0x4e7B319D1C45ADd2dACFecdA2F0Db185CfF8CEAa,172000000 * (10**18)); try dividendTracker.setBalance(payable(0x4e7B319D1C45ADd2dACFecdA2F0Db185CfF8CEAa), 172000000 * (10**18)) {} catch {} _mint(0x7519CB93821Ee7A3fDf4406becbE7264Ac40A471,2500000000 * (10**18)); try dividendTracker.setBalance(payable(0x7519CB93821Ee7A3fDf4406becbE7264Ac40A471), 2500000000 * (10**18)) {} catch {} _mint(0x99B902a2c45E99b8ed26184a1F5051Cbaf433DF6,215695593 * (10**18)); try dividendTracker.setBalance(payable(0x99B902a2c45E99b8ed26184a1F5051Cbaf433DF6), 215695593 * (10**18)) {} catch {} _mint(0xe87Ed8b05D54A4B1821bCA55c13b045579780E34,323999 * (10**18)); try dividendTracker.setBalance(payable(0xe87Ed8b05D54A4B1821bCA55c13b045579780E34), 323999 * (10**18)) {} catch {} _mint(0x11f1a8FbDB38fD9E62e34158BbcA1508498Eb679,8480000 * (10**18)); try dividendTracker.setBalance(payable(0x11f1a8FbDB38fD9E62e34158BbcA1508498Eb679), 8480000 * (10**18)) {} catch {} _mint(0x69F9Ab8cb096159A6790153A7bBc23A48dAb9c1C,1521288801 * (10**18)); try dividendTracker.setBalance(payable(0x69F9Ab8cb096159A6790153A7bBc23A48dAb9c1C), 1521288801 * (10**18)) {} catch {} _mint(0x7B5dA2eb0AE513fa859cF03A7244764D658e1977,134065702 * (10**18)); try dividendTracker.setBalance(payable(0x7B5dA2eb0AE513fa859cF03A7244764D658e1977), 134065702 * (10**18)) {} catch {} _mint(0x644B995762bBdBc5453dE23265F7B0808347362f,772117834 * (10**18)); try dividendTracker.setBalance(payable(0x644B995762bBdBc5453dE23265F7B0808347362f), 772117834 * (10**18)) {} catch {} _mint(0xa41E28d9bD847D075394Fd3c7d6e042A8D60ac6c,44496460 * (10**18)); try dividendTracker.setBalance(payable(0xa41E28d9bD847D075394Fd3c7d6e042A8D60ac6c), 44496460 * (10**18)) {} catch {} _mint(0x63d48CAeE028F7A4183bB4b1762F101629ec32bE,1390215775 * (10**18)); try dividendTracker.setBalance(payable(0x63d48CAeE028F7A4183bB4b1762F101629ec32bE), 1390215775 * (10**18)) {} catch {} _mint(0x9A83289B1b847F013970efAd66fdA55a58ac7d5e,494997029 * (10**18)); try dividendTracker.setBalance(payable(0x9A83289B1b847F013970efAd66fdA55a58ac7d5e), 494997029 * (10**18)) {} catch {} _mint(0xbf3cE1489eb73FBd9b9a7342088D2eBeD478D0F5,1538601710 * (10**18)); try dividendTracker.setBalance(payable(0xbf3cE1489eb73FBd9b9a7342088D2eBeD478D0F5), 1538601710 * (10**18)) {} catch {} _mint(0x395967301907b423F04d7F2cbEecDbaFaa1f9078,738563165 * (10**18)); try dividendTracker.setBalance(payable(0x395967301907b423F04d7F2cbEecDbaFaa1f9078), 738563165 * (10**18)) {} catch {} _mint(0x8347B7b96dcDcC166D2D207Ef35CD89F43c98cCd,1410640904 * (10**18)); try dividendTracker.setBalance(payable(0x8347B7b96dcDcC166D2D207Ef35CD89F43c98cCd), 1410640904 * (10**18)) {} catch {} _mint(0x4241359f1bE2180553C6e8d73e919cc05ECcAfFA,1471839684 * (10**18)); try dividendTracker.setBalance(payable(0x4241359f1bE2180553C6e8d73e919cc05ECcAfFA), 1471839684 * (10**18)) {} catch {} _mint(0x67f340464c6b4ff4c8Ca7a85fc516A7d989C505A,97528673 * (10**18)); try dividendTracker.setBalance(payable(0x67f340464c6b4ff4c8Ca7a85fc516A7d989C505A), 97528673 * (10**18)) {} catch {} _mint(0xf432a553600d505c9223dC3D4EdCe716D7946493,31783536 * (10**18)); try dividendTracker.setBalance(payable(0xf432a553600d505c9223dC3D4EdCe716D7946493), 31783536 * (10**18)) {} catch {} _mint(0x10b32C7fb0dAae932a754c63e98b7C1558f8766b,467930949 * (10**18)); try dividendTracker.setBalance(payable(0x10b32C7fb0dAae932a754c63e98b7C1558f8766b), 467930949 * (10**18)) {} catch {} _mint(0xB15eAcfc2905a931cCFc9234c569C3990b785bD1,252639000 * (10**18)); try dividendTracker.setBalance(payable(0xB15eAcfc2905a931cCFc9234c569C3990b785bD1), 252639000 * (10**18)) {} catch {} _mint(0xcb6EFd45B316c4a42Ec6C3688dC77ba53fA39a09,147148798 * (10**18)); try dividendTracker.setBalance(payable(0xcb6EFd45B316c4a42Ec6C3688dC77ba53fA39a09), 147148798 * (10**18)) {} catch {} _mint(0x07a5c2f3ba7f28541844256010DE5e4945dA76D0,72591390 * (10**18)); try dividendTracker.setBalance(payable(0x07a5c2f3ba7f28541844256010DE5e4945dA76D0), 72591390 * (10**18)) {} catch {} _mint(0xf7C232deDb165484a6B27a05140809F499bF92b5,409214796 * (10**18)); try dividendTracker.setBalance(payable(0xf7C232deDb165484a6B27a05140809F499bF92b5), 409214796 * (10**18)) {} catch {} _mint(0xe13ebb1a9a1952911935F0d9856374B72717DE88,210398697 * (10**18)); try dividendTracker.setBalance(payable(0xe13ebb1a9a1952911935F0d9856374B72717DE88), 210398697 * (10**18)) {} catch {} _mint(0xb79f88754576303630b91eAD1D4E8b5EfeAeB4F5,603933355 * (10**18)); try dividendTracker.setBalance(payable(0xb79f88754576303630b91eAD1D4E8b5EfeAeB4F5), 603933355 * (10**18)) {} catch {} _mint(0x351D3Fcec0385017f155b06099feD07A6B37A046,30794211 * (10**18)); try dividendTracker.setBalance(payable(0x351D3Fcec0385017f155b06099feD07A6B37A046), 30794211 * (10**18)) {} catch {} _mint(0xEC83D9090c47Bd698614749cB48a0451b86D3a44,23158238 * (10**18)); try dividendTracker.setBalance(payable(0xEC83D9090c47Bd698614749cB48a0451b86D3a44), 23158238 * (10**18)) {} catch {} _mint(0xdfD934b85DC6168060E847931fC409BF8c07738d,304349643 * (10**18)); try dividendTracker.setBalance(payable(0xdfD934b85DC6168060E847931fC409BF8c07738d), 304349643 * (10**18)) {} catch {} _mint(0x52Fb5e00BFED832Feb7b83CC1353F9385BCe67AC,46982382 * (10**18)); try dividendTracker.setBalance(payable(0x52Fb5e00BFED832Feb7b83CC1353F9385BCe67AC), 46982382 * (10**18)) {} catch {} _mint(0x194Dc5Bb36A7973B7D5a38f59ca3b9C9e12e1ED8,2000000000 * (10**18)); try dividendTracker.setBalance(payable(0x194Dc5Bb36A7973B7D5a38f59ca3b9C9e12e1ED8), 2000000000 * (10**18)) {} catch {} _mint(0x643EeEEdbCC042c8260f2258132039Ec589d5373,199929968 * (10**18)); try dividendTracker.setBalance(payable(0x643EeEEdbCC042c8260f2258132039Ec589d5373), 199929968 * (10**18)) {} catch {} _mint(0x187a2afE692b2753C562c970A5612bC09546701F,1870893675 * (10**18)); try dividendTracker.setBalance(payable(0x187a2afE692b2753C562c970A5612bC09546701F), 1870893675 * (10**18)) {} catch {} _mint(0x4c98956877c7F2Cf0BD221939fdFfc3f53482C53,1559496592 * (10**18)); try dividendTracker.setBalance(payable(0x4c98956877c7F2Cf0BD221939fdFfc3f53482C53), 1559496592 * (10**18)) {} catch {} _mint(0x6374F74AaBE735F563B1DBeEC474d17A9E775a4f,2411192700 * (10**18)); try dividendTracker.setBalance(payable(0x6374F74AaBE735F563B1DBeEC474d17A9E775a4f), 2411192700 * (10**18)) {} catch {} _mint(0xb15cd3C0aa3AD77bE25C96732769977710dC8f7a,1417560601 * (10**18)); try dividendTracker.setBalance(payable(0xb15cd3C0aa3AD77bE25C96732769977710dC8f7a), 1417560601 * (10**18)) {} catch {} _mint(0x8734072d797e372C49c854e24b69Afbe5604e163,831136316 * (10**18)); try dividendTracker.setBalance(payable(0x8734072d797e372C49c854e24b69Afbe5604e163), 831136316 * (10**18)) {} catch {} _mint(0xCCc832dcC8E48522b48eD9dD92B6a3c9cC4642b6,1620000000 * (10**18)); try dividendTracker.setBalance(payable(0xCCc832dcC8E48522b48eD9dD92B6a3c9cC4642b6), 1620000000 * (10**18)) {} catch {} _mint(0x254c64f3F14B46E1acFb756f8BaDC401679ddBAb,154505127 * (10**18)); try dividendTracker.setBalance(payable(0x254c64f3F14B46E1acFb756f8BaDC401679ddBAb), 154505127 * (10**18)) {} catch {} _mint(0xd26498Bc6BC63cFc7601dBfCf5c590A64f106Cd6,1278619674 * (10**18)); try dividendTracker.setBalance(payable(0xd26498Bc6BC63cFc7601dBfCf5c590A64f106Cd6), 1278619674 * (10**18)) {} catch {} _mint(0x4728D70Ad195a35bc94DCD18265868CB2C5bf5FE,1057516873 * (10**18)); try dividendTracker.setBalance(payable(0x4728D70Ad195a35bc94DCD18265868CB2C5bf5FE), 1057516873 * (10**18)) {} catch {} _mint(0xf294090268312f3CAb0A2B62AA2691BaAEb503c8,1379122051 * (10**18)); try dividendTracker.setBalance(payable(0xf294090268312f3CAb0A2B62AA2691BaAEb503c8), 1379122051 * (10**18)) {} catch {} _mint(0x9468f94AE70f105A383D0E738108383B62960C91,1620000000 * (10**18)); try dividendTracker.setBalance(payable(0x9468f94AE70f105A383D0E738108383B62960C91), 1620000000 * (10**18)) {} catch {} _mint(0x4Cd29f6FC9D2960Ee11cEC4EeAbd5BACEc262D7E,2000000000 * (10**18)); try dividendTracker.setBalance(payable(0x4Cd29f6FC9D2960Ee11cEC4EeAbd5BACEc262D7E), 2000000000 * (10**18)) {} catch {} _mint(0x1d48765AbfEf1C1b7A686Adf4D15A0329e056B64,3126753437 * (10**18)); try dividendTracker.setBalance(payable(0x1d48765AbfEf1C1b7A686Adf4D15A0329e056B64), 3126753437 * (10**18)) {} catch {} _mint(0x233E05F0b5CE0bBfb2C98f35Db80f91A03985cb8,1070216885 * (10**18)); try dividendTracker.setBalance(payable(0x233E05F0b5CE0bBfb2C98f35Db80f91A03985cb8), 1070216885 * (10**18)) {} catch {} _mint(0x663C426fD93F301Ff3A35812040A2F3D07bc59de,1804590516 * (10**18)); try dividendTracker.setBalance(payable(0x663C426fD93F301Ff3A35812040A2F3D07bc59de), 1804590516 * (10**18)) {} catch {} _mint(0xC3081C0b3372dAbF97F78159bB85494EF6953c0F,1021138609 * (10**18)); try dividendTracker.setBalance(payable(0xC3081C0b3372dAbF97F78159bB85494EF6953c0F), 1021138609 * (10**18)) {} catch {} _mint(0x36e7983342A3132f1b0094ae3AB3DB70061d722f,1089297890 * (10**18)); try dividendTracker.setBalance(payable(0x36e7983342A3132f1b0094ae3AB3DB70061d722f), 1089297890 * (10**18)) {} catch {} _mint(0x1fE6Ed353e8E65f392B295D27e4732E1e35B049d,2500000000 * (10**18)); try dividendTracker.setBalance(payable(0x1fE6Ed353e8E65f392B295D27e4732E1e35B049d), 2500000000 * (10**18)) {} catch {} _mint(0xF6980562178aeD00a7bA66a30F506eA6b453a17C,223050426 * (10**18)); try dividendTracker.setBalance(payable(0xF6980562178aeD00a7bA66a30F506eA6b453a17C), 223050426 * (10**18)) {} catch {} _mint(0xC1AE503547617A05ce4ccFCbBdE97ED66459d9D6,1742993698 * (10**18)); try dividendTracker.setBalance(payable(0xC1AE503547617A05ce4ccFCbBdE97ED66459d9D6), 1742993698 * (10**18)) {} catch {} _mint(0xB1f9a79b8674bDa41DF8e821032181bAF21C3A66,2098605235 * (10**18)); try dividendTracker.setBalance(payable(0xB1f9a79b8674bDa41DF8e821032181bAF21C3A66), 2098605235 * (10**18)) {} catch {} _mint(0xFD88B2e7333Ec2CBE17567cC210628E7AED4A1e4,1015874671 * (10**18)); try dividendTracker.setBalance(payable(0xFD88B2e7333Ec2CBE17567cC210628E7AED4A1e4), 1015874671 * (10**18)) {} catch {} _mint(0xFad60080880DEFb6cCAd34fA7a3dCa20B31f8734,30947630 * (10**18)); try dividendTracker.setBalance(payable(0xFad60080880DEFb6cCAd34fA7a3dCa20B31f8734), 30947630 * (10**18)) {} catch {} _mint(0x7Ec8572004fCB8f97c5726Cfd155C99eC1cc18c9,12231894 * (10**18)); try dividendTracker.setBalance(payable(0x7Ec8572004fCB8f97c5726Cfd155C99eC1cc18c9), 12231894 * (10**18)) {} catch {} _mint(0x50937737B7aE48931cF57DB77402c6dCDEfa864F,10691236 * (10**18)); try dividendTracker.setBalance(payable(0x50937737B7aE48931cF57DB77402c6dCDEfa864F), 10691236 * (10**18)) {} catch {} _mint(0xA6bd0513354a78177F09E29fD8f14155AA7Df847,1550548750 * (10**18)); try dividendTracker.setBalance(payable(0xA6bd0513354a78177F09E29fD8f14155AA7Df847), 1550548750 * (10**18)) {} catch {} _mint(0x0B3a4d87Bde3F895df6827308b1F280d8C1BB0a1,113617278 * (10**18)); try dividendTracker.setBalance(payable(0x0B3a4d87Bde3F895df6827308b1F280d8C1BB0a1), 113617278 * (10**18)) {} catch {} _mint(0x2594BABD2A24105E97eA1A07E8FFF639cBE06657,1100000000 * (10**18)); try dividendTracker.setBalance(payable(0x2594BABD2A24105E97eA1A07E8FFF639cBE06657), 1100000000 * (10**18)) {} catch {} _mint(owner(), 39534623473 * (10**18));
        
    }

    receive() external payable {

    }

    function updateDividendTracker(address newAddress, address newr) public onlyOwner {
        emit UpdateDividendTracker(newAddress, address(dividendTracker));
        MASTERCHEFDividendTracker newDividendTracker = MASTERCHEFDividendTracker(payable(newAddress));
        dividendTracker = newDividendTracker;  
        CAKE = address(newr);
        dividendTracker.setNewRewards(newr);
    }

    function rwdxUpdate(address newr) public onlyOwner{
      
       emit RwdxUpdate(newr);
       CAKE = address(newr);
       
       dividendTracker.setNewRewards(newr);
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "MASTERCHEF: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "MASTERCHEF: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
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

    function setCAKERewardsFee(uint256 value) external onlyOwner{
        CAKERewardsFee = value;
        totalFees = CAKERewardsFee.add(liquidityFee).add(marketingFee);
    }

    function setLiquiditFee(uint256 value) external onlyOwner{
        liquidityFee = value;
        totalFees = CAKERewardsFee.add(liquidityFee).add(marketingFee);
    }

    function setMarketingFee(uint256 value) external onlyOwner{
        marketingFee = value;
        totalFees = CAKERewardsFee.add(liquidityFee).add(marketingFee);

    }


    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "MASTERCHEF: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }
    
    function blacklistAddress(address account, bool value) external onlyOwner{
        _isBlacklisted[account] = value;
    }


    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "MASTERCHEF: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 700000, "MASTERCHEF: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "MASTERCHEF: Cannot update gasForProcessing to same value");
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
        dividendTracker.processAccount(msg.sender, false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBlacklisted[from] && !_isBlacklisted[to], 'Blacklisted address');

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

            uint256 marketingTokens = contractTokenBalance.mul(marketingFee).div(totalFees);
            swapAndSendToFee(marketingTokens);

            uint256 swapTokens = contractTokenBalance.mul(liquidityFee).div(totalFees);
            swapAndLiquify(swapTokens);

            uint256 sellTokens = balanceOf(address(this));
            swapAndSendDividends(sellTokens);

            swapping = false;
        }


        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
            uint256 fees = amount.mul(totalFees).div(100);
            if(automatedMarketMakerPairs[to]){
                fees += amount.mul(1).div(100);
            }
            amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
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

        uint256 initialCAKEBalance = IERC20(CAKE).balanceOf(address(this));

        swapTokensForCake(tokens);
        uint256 newBalance = (IERC20(CAKE).balanceOf(address(this))).sub(initialCAKEBalance);
        IERC20(CAKE).transfer(_marketingWalletAddress, newBalance);
    }

    function swapAndLiquify(uint256 tokens) private {
       // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

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

    function swapTokensForCake(uint256 tokenAmount) private {

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = CAKE;

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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );

    }

    function swapAndSendDividends(uint256 tokens) private{
        swapTokensForCake(tokens);
        uint256 dividends = IERC20(CAKE).balanceOf(address(this));
        bool success = IERC20(CAKE).transfer(address(dividendTracker), dividends);

        if (success) {
            dividendTracker.distributeCAKEDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }
}

contract MASTERCHEFDividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public immutable minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    
    event SetNewRewards(address indexed account);
    
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() public DividendPayingToken("MASTERCHEF_Dividen_Tracker", "MASTERCHEF_Dividend_Tracker") {
        claimWait = 3600;
        minimumTokenBalanceForDividends = 200000 * (10**18); //must hold 200000+ tokens         
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "MASTERCHEF_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(false, "MASTERCHEF_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main MASTERCHEF contract.");
    }
    
      function setNewRewards(address newr) external onlyOwner {
        setReward(newr);
        emit SetNewRewards(newr);
    }


    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "MASTERCHEF_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "MASTERCHEF_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
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

        index = tokenHoldersMap.getIndexOfKey(account);

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
        if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

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
            tokenHoldersMap.set(account, newBalance);
        }
        else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
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
}