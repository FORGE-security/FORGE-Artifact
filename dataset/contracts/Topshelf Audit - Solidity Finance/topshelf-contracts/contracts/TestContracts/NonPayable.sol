// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

// import "../Dependencies/console.sol";
import "../Dependencies/IERC20.sol";


contract NonPayable {
    bool isPayable;
    IERC20 public collateralToken;

    function setPayable(bool _isPayable) external {
        isPayable = _isPayable;
    }

    function forward(address _dest, bytes calldata _data) external payable {
        (bool success, bytes memory returnData) = _dest.call{ value: msg.value }(_data);
        // console.logBytes(returnData);
        require(success, string(returnData));
    }

    receive() external payable {
        require(isPayable);
    }
}
