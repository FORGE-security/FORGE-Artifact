// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

// File @pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol@v0.0.4

pragma solidity >=0.4.0;

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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}


// File @pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol@v0.0.4

pragma solidity >=0.4.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol@v0.0.4

pragma solidity >=0.4.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File @pancakeswap/pancake-swap-lib/contracts/utils/ReentrancyGuard.sol@v0.0.4

pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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

    constructor () internal {
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


// File @pancakeswap/pancake-swap-lib/contracts/utils/Address.sol@v0.0.4

pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, 'Address: low-level call failed');
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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


// File @pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol@v0.0.4

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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


// File @pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol@v0.0.4

pragma solidity ^0.6.0;



/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}


// File contracts/BRTStaking.sol

pragma solidity ^0.6.12;
// import "hardhat/console.sol";

contract BRTStaking is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    /*********** STATE VARIABLES ***********/

    // Info of the user
    struct UserInfo {
        uint256 amount;      // How many tokens user has provided
        uint256 lastUpdated; // When did he staked his amount
        uint256 rewardPaid;  // How much reward is paid to user
    }

    enum ActionType {
        Stake,
        UnStake,
        Harvest,
        Compound
    }

    // Token Instance
    IBEP20 public token;

    // Dev address
    address public dev;

    // Seconds in a year
    uint256 internal constant SECONDS_IN_ONE_YEAR = 31536000;

    // Deployment Timestamp
    uint256 public deploymentTimestamp;

    // Halving Timestamp
    uint256 public halvingTimestamp;

    // Total value locked
    uint256 public totalValueLocked;

    // Reward tokens per year
    uint256 public rewardTokensPerYear = 1825000 * 1e18;

    // Token reward per second
    uint256 private _rewardTokensPerSec;

    // Stake fee
    uint256 public stakeFee = 0.0023 * 1e18;

    // UnStake fee
    uint256 public unStakeFee = 0.0039 * 1e18;

    // Harvest fee
    uint256 public harvestFee = 0.0015 * 1e18;

    // Compound fee
    uint256 public compoundFee = 0.0015 * 1e18;

    // Fee share percentages
    // 75% of stakeFee, unStakeFee & harvestFee
    uint256 public ownerSharePercent = 75 * 1e18;
    // 25% of stakeFee, unStakeFee & harvestFee
    uint256 public devSharePercent = 25 * 1e18;

    // Info of each user that stakes tokens
    mapping(address => UserInfo) public userInfo;


    /*********** EVENTS ***********/
    
    event Staked(
        address indexed user,
        uint256 amount,
        uint256 stakeFee
    );

    event UnStaked(
        address indexed user,
        uint256 amount,
        uint256 unStakeFee,
        uint256 reward
    );

    event Harvested(
        address indexed user,
        uint256 amount,
        uint256 amountHarvested,
        uint256 rewardsPaid,
        uint256 harvestFee
    );

    event Compounded(
        address indexed user,
        uint256 amount,
        uint256 amountCompounded,
        uint256 rewardsPaid,
        uint256 compoundFee
    );

    event ShareClaimed(
        address indexed user,
        uint256 amount
    );

    event HalvingExecuted(
        address indexed owner,
        uint256 prevHalvingTimestamp,
        uint256 newHalvingTimestamp,
        uint256 prevRewardTokensPerYear,
        uint256 newRewardTokensPerYear
    );

    event NewStakeFee(
        uint256 prevStakeFee,
        uint256 newStakeFee
    );

    event NewUnStakeFee(
        uint256 prevUnStakeFee,
        uint256 newUnStakeFee
    );

    event NewHarvestFee(
        uint256 prevHarvestFee,
        uint256 newHarvestFee
    );

    event NewCompoundFee(
        uint256 prevCompoundFee,
        uint256 newCompoundFee
    );

    event NewDev(
        address prevDev,
        address newDev
    );

    event NewOwnerSharePercent(
        uint256 prevOwnerSharePercent,
        uint256 newOwnerSharePercent
    );

    event NewDevSharePercent(
        uint256 prevDevSharePercent,
        uint256 newDevSharePercent
    );


    /*********** CONSTRUCTOR ***********/

    constructor(
        IBEP20 _token,
        address _dev
    ) public {
        require(address(_token) != address(0), "token address cannot be zero address");
        require(_dev != address(0), "dev address cannot be zero address");

        token = _token;
        dev = _dev;
        deploymentTimestamp = block.timestamp;
        halvingTimestamp = deploymentTimestamp.add(SECONDS_IN_ONE_YEAR);
        // 57870370370370370 wei --> 0.05787037037037037 bnb
        _rewardTokensPerSec = rewardTokensPerYear.div(SECONDS_IN_ONE_YEAR);
    }


    /*********** FALLBACK FUNCTIONS ***********/

    receive() external payable {
        handleFee(msg.value);
    }


    /*********** READ FUNCTIONS ***********/

    function balanceOf(address _beneficiary)
        public
        view
        returns (uint256)
    {
        return userInfo[_beneficiary].amount;
    }

    function getRewardTokensPerSec()
        public
        view
        returns (uint256)
    {
        return _rewardTokensPerSec;
    }

    function calculateReward(address _beneficiary, uint256 _amount)
        public
        view
        returns (uint256)
    {
        UserInfo memory _user = userInfo[_beneficiary];
        require(
            _amount <= _user.amount,
            "calculateReward: Amount must be less than or equal to stake"
        );
        if(totalValueLocked == 0) return 0;
        uint256 _noOfSec = calculateTime(block.timestamp, _user.lastUpdated);
        uint256 _userPercentageOfShare = _amount.mul(1e18).div(totalValueLocked);
        return (_userPercentageOfShare.mul(_rewardTokensPerSec).mul(_noOfSec)).div(1e18);
    }


    /*********** WRITE FUNCTIONS ***********/

    function stake(uint256 _amount) public payable {
        uint256 _stakeFee = msg.value;

        require(_amount > 0, "Stake: Amount not valid");
        require(_stakeFee == stakeFee, "Stake: Stake Fee amount not valid");

        handleFee(_stakeFee);

        _stake(msg.sender, _amount);

        emit Staked(msg.sender, _amount, _stakeFee);
    }

    function unstake(uint256 _amount) public payable {
        uint256 _unStakeFee = msg.value;
        UserInfo storage user = userInfo[msg.sender];

        require(_amount <= user.amount, "UnStake: Amount not valid");
        require(_unStakeFee == unStakeFee, "UnStake: UnStake Fee amount not valid");

        handleFee(_unStakeFee);

        uint256 _reward = calculateReward(msg.sender, _amount);

        // Transfer reward and staked amount to user
        token.safeTransfer(address(msg.sender), _reward.add(_amount));

        // Update user info
        _updateUserInfo (
            msg.sender,
            _amount,
            _reward,
            ActionType.UnStake
        );

        emit UnStaked(msg.sender, _amount, _unStakeFee, _reward);
    }

    function harvest(uint256 _rewardAmountToWithdraw) public payable {
        uint256 _harvestFee = msg.value;
        UserInfo storage user = userInfo[msg.sender];
        uint256 _totalCurrentReward = calculateReward(msg.sender, user.amount);

        require(
            _harvestFee == harvestFee, 
            "Harvest: Harvest Fee amount not valid"
        );
        require(
            _rewardAmountToWithdraw <= _totalCurrentReward, 
            "Harvest: Amount exceeds your actual amount"
        );

        handleFee(_harvestFee);

        uint256 _restakeAmount = _totalCurrentReward.sub(_rewardAmountToWithdraw);
        token.safeTransfer(address(msg.sender), _rewardAmountToWithdraw);

        // Update user info
        _updateUserInfo (
            msg.sender,
            _restakeAmount,
            _rewardAmountToWithdraw,
            ActionType.Harvest
        );

        emit Harvested(
            msg.sender,
            user.amount,
            _restakeAmount,
            _rewardAmountToWithdraw,
            _harvestFee
        );
    }

    function compound(uint256 _rewardAmountToRestake) public payable {
        uint256 _compoundFee = msg.value;
        UserInfo storage user = userInfo[msg.sender];
        uint256 _totalCurrentReward = calculateReward(msg.sender, user.amount);

        require(
            _compoundFee == compoundFee,
            "Compound: Compound Fee amount not valid"
        );
        require(
            _rewardAmountToRestake <= _totalCurrentReward, 
            "Compound: Amount exceeds your actual amount"
        );

        handleFee(_compoundFee);

        // Transfer _totalCurrentReward - _rewardAmountToRestake to user
        uint256 _rewardsPaid = _totalCurrentReward.sub(_rewardAmountToRestake);
        token.safeTransfer(address(msg.sender), _rewardsPaid);

        // Update user info
        _updateUserInfo (
            msg.sender,
            _rewardAmountToRestake,
            _rewardsPaid,
            ActionType.Compound
        );

        emit Compounded(
            msg.sender,
            user.amount,
            _rewardAmountToRestake,
            _rewardsPaid,
            _compoundFee
        );
    }

    /*********** INTERNAL FUNCTIONS ***********/

    function calculateTime(uint256 _to, uint256 _from) 
        internal 
        pure 
        returns (uint256) 
    {
        return _to.sub(_from);
    }

    function _updateUserInfo(
        address _beneficiary,
        uint256 _amount,
        uint256 _reward,
        ActionType _actionType
    ) internal {
        UserInfo storage user = userInfo[_beneficiary];

        user.lastUpdated = block.timestamp;

        if (
            _actionType == ActionType.Stake ||
            _actionType == ActionType.Harvest ||
            _actionType == ActionType.Compound
        ) {
            user.amount = user.amount.add(_amount);
            totalValueLocked = totalValueLocked.add(_amount);
        }

        if (
            _actionType == ActionType.Harvest ||
            _actionType == ActionType.Compound
        ) {
            user.rewardPaid = user.rewardPaid.add(_reward);
        }

        if (_actionType == ActionType.UnStake) {
            user.amount = user.amount.sub(_amount);
            user.rewardPaid = user.rewardPaid.add(_reward);
            totalValueLocked = totalValueLocked.sub(_amount);
        }
    }

    function handleFee(uint256 _fee) internal {
        // Transfer fee to owner
        uint256 _ownerAmount = (ownerSharePercent.mul(_fee)).div(1e20);
        payable(owner()).transfer(_ownerAmount);
        emit ShareClaimed(owner(), _ownerAmount);

        // Transfer fee to dev
        uint256 _devAmount = (devSharePercent.mul(_fee)).div(1e20);
        payable(dev).transfer(_devAmount);
        emit ShareClaimed(dev, _devAmount);
    }
    
    function _stake(address _beneficiary, uint256 _amount) internal {
        // Transfer the tokens to this contract
        token.safeTransferFrom(
            address(_beneficiary), 
            address(this), _amount
        );

        // Update user info
        _updateUserInfo (
            _beneficiary,
            _amount,
            0,
            ActionType.Stake
        );
    }


    /*********** ONLY-OWNER FUNCTIONS ***********/

    function executeHalving() external onlyOwner() {
        require(
            block.timestamp >= halvingTimestamp,
            "Execution of Halving Mechanism not applicable"
        );
        uint256 _prevHalvingTimestamp = halvingTimestamp;
        uint256 _prevRewardTokensPerYear = rewardTokensPerYear;

        halvingTimestamp = _prevHalvingTimestamp.add(SECONDS_IN_ONE_YEAR);
        rewardTokensPerYear = rewardTokensPerYear.div(2);
        _rewardTokensPerSec = rewardTokensPerYear.div(SECONDS_IN_ONE_YEAR);

        emit HalvingExecuted(
            msg.sender,
            _prevHalvingTimestamp,
            halvingTimestamp,
            _prevRewardTokensPerYear,
            rewardTokensPerYear
        );
    }

    function setStakeFee(uint256 _stakeFee) 
        external 
        onlyOwner() 
    {
        require(
            _stakeFee > 0,
            "setstakeFee: Amount not valid"
        );
        uint256 _prevStakeFee = stakeFee;
        stakeFee = _stakeFee;

        emit NewStakeFee(
            _prevStakeFee,
            _stakeFee
        );
    }

    function setUnStakeFee(uint256 _unStakeFee) 
        external 
        onlyOwner() 
    {
        require(
            _unStakeFee > 0,
            "setunStakeFee: Amount not valid"
        );
        uint256 _prevUnStakeFee = unStakeFee;
        unStakeFee = _unStakeFee;

        emit NewUnStakeFee(
            _prevUnStakeFee,
            _unStakeFee
        );
    }

    function setHarvestFee(uint256 _harvestFee) 
        external 
        onlyOwner() 
    {
        require(
            _harvestFee > 0,
            "setharvestFee: Amount not valid"
        );
        uint256 _prevHarvestFee = harvestFee;
        harvestFee = _harvestFee;

        emit NewHarvestFee(
            _prevHarvestFee,
            _harvestFee
        );
    }

    function setCompoundFee(uint256 _compoundFee) 
        external 
        onlyOwner() 
    {
        require(
            _compoundFee > 0,
            "setharvestFee: Amount not valid"
        );
        uint256 _prevCompoundFee = compoundFee;
        compoundFee = _compoundFee;

        emit NewCompoundFee(
            _prevCompoundFee,
            _compoundFee
        );
    }

    function setDev(address _dev) 
        external 
        onlyOwner() 
    {
        require(
            _dev != address(0),
            "setDev: address not valid"
        );
        address _prevDev = dev;
        dev = _dev;

        emit NewDev(
            _prevDev,
            _dev
        );
    }

    function setOwnerSharePercent(uint256 _ownerSharePercent) 
        external 
        onlyOwner() 
    {
        require(
            _ownerSharePercent > 0,
            "setOwnerSharePercent: Amount not valid"
        );
        uint256 _prevOwnerSharePercent = ownerSharePercent;
        ownerSharePercent = _ownerSharePercent;

        emit NewOwnerSharePercent(
            _prevOwnerSharePercent,
            _ownerSharePercent
        );
    }

    function setDevSharePercent(uint256 _devSharePercent) 
        external 
        onlyOwner() 
    {
        require(
            _devSharePercent > 0,
            "setDevSharePercent: Amount not valid"
        );
        uint256 _prevDevSharePercent = devSharePercent;
        devSharePercent = _devSharePercent;

        emit NewDevSharePercent(
            _prevDevSharePercent,
            _devSharePercent
        ); 
    }
}