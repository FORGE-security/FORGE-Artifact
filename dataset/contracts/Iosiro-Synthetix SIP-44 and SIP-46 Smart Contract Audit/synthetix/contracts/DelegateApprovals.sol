pragma solidity 0.4.25;

import "./EternalStorage.sol";
import "./Owned.sol";


// https://docs.synthetix.io/contracts/DelegateApprovals
contract DelegateApprovals is Owned {
    bytes32 public constant BURN_FOR_ADDRESS = "BurnForAddress";
    bytes32 public constant ISSUE_FOR_ADDRESS = "IssueForAddress";
    bytes32 public constant CLAIM_FOR_ADDRESS = "ClaimForAddress";
    bytes32 public constant EXCHANGE_FOR_ADDRESS = "ExchangeForAddress";
    bytes32 public constant APPROVE_ALL = "ApproveAll";

    /* ========== STATE VARIABLES ========== */
    EternalStorage public eternalStorage;

    /**
     * @dev Constructor
     * @param _owner The address which controls this contract.
     * @param _eternalStorage The eternalStorage address.
     */
    constructor(address _owner, EternalStorage _eternalStorage) public Owned(_owner) {
        eternalStorage = _eternalStorage;
    }

    /* ========== VIEWS ========== */

    // Move it to setter and associatedState

    // util to get key based on action name + address of authoriser + address for delegate
    function _getKey(bytes32 _action, address _authoriser, address _delegate) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_action, _authoriser, _delegate));
    }

    // hash of actionName + address of authoriser + address for the delegate
    function canBurnFor(address authoriser, address delegate) external view returns (bool) {
        return _checkApproval(BURN_FOR_ADDRESS, authoriser, delegate);
    }

    function canIssueFor(address authoriser, address delegate) external view returns (bool) {
        return _checkApproval(ISSUE_FOR_ADDRESS, authoriser, delegate);
    }

    function canClaimFor(address authoriser, address delegate) external view returns (bool) {
        return _checkApproval(CLAIM_FOR_ADDRESS, authoriser, delegate);
    }

    function canExchangeFor(address authoriser, address delegate) external view returns (bool) {
        return _checkApproval(EXCHANGE_FOR_ADDRESS, authoriser, delegate);
    }

    function _approvedAll(address authoriser, address delegate) internal view returns (bool) {
        return eternalStorage.getBooleanValue(_getKey(APPROVE_ALL, authoriser, delegate));
    }

    // internal function to check approval based on action
    // if approved for all actions then will return true
    // before checking specific approvals
    function _checkApproval(bytes32 action, address authoriser, address delegate) internal view returns (bool) {
        if (_approvedAll(authoriser, delegate)) return true;

        return eternalStorage.getBooleanValue(_getKey(action, authoriser, delegate));
    }

    /* ========== SETTERS ========== */

    // Approve All
    function approveAllDelegatePowers(address delegate) external {
        _setApproval(APPROVE_ALL, msg.sender, delegate);
    }

    function removeAllDelegatePowers(address delegate) external {
        _withdrawApproval(APPROVE_ALL, msg.sender, delegate);
    }

    // Burn on behalf
    function approveBurnOnBehalf(address delegate) external {
        _setApproval(BURN_FOR_ADDRESS, msg.sender, delegate);
    }

    function removeBurnOnBehalf(address delegate) external {
        _withdrawApproval(BURN_FOR_ADDRESS, msg.sender, delegate);
    }

    // Issue on behalf
    function approveIssueOnBehalf(address delegate) external {
        _setApproval(ISSUE_FOR_ADDRESS, msg.sender, delegate);
    }

    function removeIssueOnBehalf(address delegate) external {
        _withdrawApproval(ISSUE_FOR_ADDRESS, msg.sender, delegate);
    }

    // Claim on behalf
    function approveClaimOnBehalf(address delegate) external {
        _setApproval(CLAIM_FOR_ADDRESS, msg.sender, delegate);
    }

    function removeClaimOnBehalf(address delegate) external {
        _withdrawApproval(CLAIM_FOR_ADDRESS, msg.sender, delegate);
    }

    // Exchange on behalf
    function approveExchangeOnBehalf(address delegate) external {
        _setApproval(EXCHANGE_FOR_ADDRESS, msg.sender, delegate);
    }

    function removeExchangeOnBehalf(address delegate) external {
        _withdrawApproval(EXCHANGE_FOR_ADDRESS, msg.sender, delegate);
    }

    function _setApproval(bytes32 action, address authoriser, address delegate) internal {
        require(delegate != address(0), "Can't delegate to address(0)");
        eternalStorage.setBooleanValue(_getKey(action, authoriser, delegate), true);
        emit Approval(authoriser, delegate, action);
    }

    function _withdrawApproval(bytes32 action, address authoriser, address delegate) internal {
        eternalStorage.deleteBooleanValue(_getKey(action, authoriser, delegate));
        emit WithdrawApproval(authoriser, delegate, action);
    }

    function setEternalStorage(EternalStorage _eternalStorage) external onlyOwner {
        eternalStorage = _eternalStorage;
        emit EternalStorageUpdated(eternalStorage);
    }

    /* ========== EVENTS ========== */
    event Approval(address indexed authoriser, address delegate, bytes32 action);
    event WithdrawApproval(address indexed authoriser, address delegate, bytes32 action);
    event EternalStorageUpdated(address newEternalStorage);
}
