// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.7.6;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
    

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyGovernance`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function burn(uint256 amount) external returns(bool);

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

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }
    
    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata =
            address(token).functionCall(
                data,
                "SafeERC20: low-level call failed"
            );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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

contract DevilVaultV2 is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardTokenBusd;
    IERC20 public stakingToken;
    IERC20 public WBNB;

    uint256 public periodFinish = 0;
    uint256 public rewardRateBusd = 0;
    uint256 public rewardRateDevl = 0;
    uint256 public rewardsDuration = 1 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStoredBusd;
    uint256 public rewardPerTokenStoredDevl;
    uint256 public allocatedRewardBusd;
    uint256 public allocatedRewardDevl;
    uint256 public numberOfStakers;
    uint256 public minNumBusdToDist = 1000000000000000000;
    uint256 public minNumDevlToDist = 1000000000000000000;
    bool public depositsEnabled = true;
    bool public swapEnabled = true;

    mapping(address => uint256) public userRewardPerTokenPaidBusd;
    mapping (address => uint256) public userRewardPerTokenPaidDevl;
    mapping(address => uint256) public rewardsBusd;
    mapping(address => uint256) public rewardsDevl;
    mapping(address=> UserRewardSaved) public userInfo;
    uint256 private totalStaked;
    mapping(address => uint256) private userStaked;

    struct UserRewardSaved {
        uint256 lifetimeBusdRewarded;
        uint256 lifetimeDevlRewarded;
    }
 
    //Pancake Testnet: 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 Pancaketest WBNB: 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd 
    //Pancake Main: 0x10ED43C718714eb63d5aA57B78B54704E256024E Pancake WBNB: 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
    IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(address(0x10ED43C718714eb63d5aA57B78B54704E256024E));

    /* ========== CONSTRUCTOR ========== */

    constructor(address _rewardToken, address _stakingToken) {
        rewardTokenBusd = IERC20(address(_rewardToken));
        stakingToken = IERC20(address(_stakingToken));
        WBNB = IERC20(address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c));
    }

    /* ========== VIEWS ========== */

    function getTotalStaked() external view returns (uint256) {
        return totalStaked;
    }

    function getUserStaked(address account) external view returns (uint256) {
        return userStaked[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerTokenBusd() public view returns (uint256) {
        if (totalStaked == 0) {
            return(rewardPerTokenStoredBusd);
        }
        return
            rewardPerTokenStoredBusd.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRateBusd).mul(1e18).div(totalStaked)
            );
    }

    function rewardPerTokenDevl() public view returns (uint256) {
        if (totalStaked == 0) {
            return(rewardPerTokenStoredDevl);
        }
        return
            rewardPerTokenStoredDevl.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRateDevl).mul(1e18).div(totalStaked)
            );
    }

    function earnedBusd(address account) public view returns (uint256) {
        return userStaked[account].mul(rewardPerTokenBusd().sub(userRewardPerTokenPaidBusd[account])).div(1e18).add(rewardsBusd[account]);
    }

    function earnedDevl(address account) public view returns (uint256) {
        return userStaked[account].mul(rewardPerTokenDevl().sub(userRewardPerTokenPaidDevl[account])).div(1e18).add(rewardsDevl[account]);
    }

    function getRewardForDurationBusd() external view returns (uint256) {
        return rewardRateBusd.mul(rewardsDuration);
    }

    function getRewardForDurationDevl() external view returns (uint256) {
        return rewardRateDevl.mul(rewardsDuration);
    }

    function getRewardTokenBusdBalance() external view returns (uint256) {
        uint256 rewardTokenBal = rewardTokenBusd.balanceOf(address(this));
        return(rewardTokenBal);
    }

    function getReflectedRewardsBalance() external view returns (uint256) {
        uint256 reflectedBal = stakingToken.balanceOf(address(this)).sub(totalStaked).sub(allocatedRewardDevl);
        if(reflectedBal > 0) {
            return(reflectedBal);
        } else {
            return(0);
        }
    }

    function getNumOfStakers() external view returns (uint256){
        return(numberOfStakers);
    }

    function getAllocatedRewardDevl() external view returns (uint256){
        return(allocatedRewardDevl);
    }

    function getUserRewardsBUSD(address account) external view returns (uint256){
        return(rewardsBusd[account]);
    }

    function getUserRewardsDEVL(address account) external view returns (uint256){
        return(rewardsDevl[account]);
    }

    function getLifetimeRewards() external view returns (uint256, uint256) {
        uint256 lifetimeBusd = userInfo[msg.sender].lifetimeBusdRewarded;
        uint256 lifetimeDevl = userInfo[msg.sender].lifetimeDevlRewarded;
        return(lifetimeBusd, lifetimeDevl);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        require(depositsEnabled == true);
        require(stakingToken.balanceOf(msg.sender) >= amount, "You don't have the tokens!");
        if(userStaked[msg.sender] == 0) {
            numberOfStakers += 1;
        }
        totalStaked = totalStaked.add(amount);
        userStaked[msg.sender] = userStaked[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        totalStaked = totalStaked.sub(amount);
        userStaked[msg.sender] = userStaked[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        if(userStaked[msg.sender] == 0) {
            numberOfStakers -= 1;
        }
        emit Withdrawn(msg.sender, amount);
    }

    function claim() public nonReentrant updateReward(msg.sender) {
        uint256 rewardBusd = rewardsBusd[msg.sender];
        if (rewardBusd > 0) {
            rewardsBusd[msg.sender] = 0;
            allocatedRewardBusd = allocatedRewardBusd.sub(rewardBusd);
            rewardTokenBusd.safeTransfer(msg.sender, rewardBusd);
            userInfo[msg.sender].lifetimeBusdRewarded = (userInfo[msg.sender].lifetimeBusdRewarded).add(rewardBusd); 
            emit RewardPaidBusd(msg.sender, rewardBusd);
        }
        uint256 rewardDevl = rewardsDevl[msg.sender];
        if (rewardDevl > 0) {
            // userStaked[msg.sender] = userStaked[msg.sender].add(rewardDevl);
            // totalStaked = totalStaked.add(rewardDevl);
            allocatedRewardDevl = allocatedRewardDevl.sub(rewardDevl);
            rewardsDevl[msg.sender] = 0;
            stakingToken.safeTransfer(msg.sender, rewardDevl);
            userInfo[msg.sender].lifetimeDevlRewarded = (userInfo[msg.sender].lifetimeBusdRewarded).add(rewardDevl);
            emit RewardPaidDevl(msg.sender, rewardDevl);
        }
    }


    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmountBusd(uint256 reward) internal updateReward(address(0)) {
        rewardRateBusd = reward.div(rewardsDuration);
        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        uint balance = rewardTokenBusd.balanceOf(address(this)).sub(allocatedRewardBusd);
        if (rewardRateBusd <= balance.div(rewardsDuration)) {
            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp.add(rewardsDuration);
            emit RewardAddedBusd(reward);
        } else {
            emit BusdNotifyCongested(rewardRateBusd, balance);
        }
    }

    function notifyRewardAmountDevl(uint256 reward) internal updateReward(address(0)) {
        if( reward == 0) {
            rewardRateDevl = 0;
        } else {
            rewardRateDevl = reward.div(rewardsDuration);
        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions
        uint256 totalUnavailableDevl = totalStaked.add(allocatedRewardDevl);
        uint balance = stakingToken.balanceOf(address(this)).sub(totalUnavailableDevl);
        if (rewardRateDevl <= balance.div(rewardsDuration)) {
            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp.add(rewardsDuration);
            emit RewardAddedDevl(reward);
            } else {
                emit DevlNotifyCongested(rewardRateDevl, balance);
            }
        }
    }

    function distributeRewards() internal {
            //FIRST BUSD. Check available by removing allocated busd to prevent re-rewarding unclaimed busd. 
            //Make sure we're only notifying rewards if there's more than 1 token for maths.
        if (block.timestamp >= periodFinish) {
            uint256 availableRewardBusd = (rewardTokenBusd.balanceOf(address(this))).sub(allocatedRewardBusd);
            if(availableRewardBusd > minNumBusdToDist) {
                notifyRewardAmountBusd(availableRewardBusd);
                allocatedRewardBusd = allocatedRewardBusd.add(availableRewardBusd);
            } else {
                notifyRewardAmountBusd(0);
            }

            //Do the same for DEVL, but ensure available tokens are not staked or allocated.
            uint256 devilBalance = stakingToken.balanceOf(address(this));
            uint256 totalUnavailableDevl = totalStaked.add(allocatedRewardDevl);
            if(devilBalance > totalUnavailableDevl && totalStaked != 0) {
                uint256 availableRewardDevl = devilBalance.sub(totalUnavailableDevl);
                if(availableRewardDevl > minNumDevlToDist){
                    notifyRewardAmountDevl(availableRewardDevl);
                    allocatedRewardDevl = allocatedRewardDevl.add(availableRewardDevl);
                }
            } else {
                notifyRewardAmountDevl(0);
            }
        }
    }

    //Allows owner to call dist rewards if automatic call from swaps paused
    function callDistributeRewards() external onlyOwner {
        distributeRewards();
    }

    //Recover tokens stuck in contract other than staking token
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(stakingToken), "Cannot withdraw the staking token");
        IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    function emergencyPauseDeposits(bool _status) external onlyOwner {
        depositsEnabled = _status;
    }

    function emergencyPauseSwap(bool _status) external onlyOwner {
        swapEnabled = _status;
    }

    function setMinNumTokensToDist(uint256 _minNumBusdToDist, uint256 _minNumDevlToDist) external onlyOwner {
        minNumBusdToDist = _minNumBusdToDist;
        minNumDevlToDist = _minNumDevlToDist;
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStoredBusd = rewardPerTokenBusd();
        rewardPerTokenStoredDevl = rewardPerTokenDevl();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewardsBusd[account] = earnedBusd(account);
            userRewardPerTokenPaidBusd[account] = rewardPerTokenStoredBusd;
            rewardsDevl[account] = earnedDevl(account);
            userRewardPerTokenPaidDevl[account] = rewardPerTokenStoredDevl;
        }
        _;
    }

     /*
    ========== SWAP FUNCTIONS ==========
    */
    
    //Allows contract to receive BNB and call the swap function on receipt
    receive() external payable {
        vaultSwap();
    }
     
    function vaultSwap() public payable {
        uint256 amountToSwap = address(this).balance;
        if(swapEnabled == true && amountToSwap > 0){
        require(address(rewardTokenBusd) != address(0), "Quote Token should not be zero address");
        address [] memory path = new address[](2);
        path[0] = address(WBNB);
        path[1] = address(rewardTokenBusd);
    
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountToSwap}(
            0,
            path,
            address(this),
            block.timestamp + 1000
        );
        distributeRewards();
        emit Swapped(msg.value);
        }
    }

    function manualVaultSwap() external onlyOwner {
        require(address(rewardTokenBusd) != address(0), "Quote Token should not be zero address");
        address [] memory path = new address[](2);
        path[0] = address(WBNB);
        path[1] = address(rewardTokenBusd);
    
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: address(this).balance}(
            0,
            path,
            address(this),
            block.timestamp + 1000
        );
        distributeRewards();
        emit Swapped(address(this).balance);
    }

    /* ========== EVENTS ========== */

    event RewardAddedBusd(uint256 reward);
    event RewardAddedDevl(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaidBusd(address indexed user, uint256 reward);
    event RewardPaidDevl(address indexed user, uint256 reward);
    event Swapped(uint256 _amountBnbSwapped);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
    event BusdNotifyCongested(uint256 rewardRateBusd, uint256 balance);
    event DevlNotifyCongested(uint256 rewardRateBusd, uint256 balance);
}