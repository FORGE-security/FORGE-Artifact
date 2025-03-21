//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
import "../common/Interfaces/IERC677Receiver.sol";

contract MockERC677Receiver is IERC677Receiver {
    event OnTokenTransferEvent(address indexed _sender, uint256 _value, bytes _data);

    /// @dev Emit the OnTokenTransferEvent.
    /// @param _sender The address of the sender.
    /// @param _value The value sent with the tx.
    /// @param _data The data sent with the tx.
    function onTokenTransfer(
        address _sender,
        uint256 _value,
        bytes calldata _data
    ) external override {
        emit OnTokenTransferEvent(_sender, _value, _data);
    }
}
