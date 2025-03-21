pragma solidity 0.5.10;

interface FundsInterface {
    function lender(bytes32) external view returns (address);
    function custom(bytes32) external view returns (bool);
    function deposit(bytes32, uint256) external;
    function decreaseTotalBorrow(uint256) external;
    function calcGlobalInterest() external;
    function withdraw(bytes32 fund, uint256 amount_) external;
    function withdrawTo(bytes32 fund, uint256 amount_, address recipient_) external;
}
