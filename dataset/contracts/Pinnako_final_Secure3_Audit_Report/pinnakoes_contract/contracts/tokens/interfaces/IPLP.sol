// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPLP {
    // function mint(address _account, uint256 _amount) external;
    // function burn(address _account, uint256 _amount) external;
    function updateStakingAmount(address _account, uint256 _amount) external;
    function claimForAccount(address _account) external returns (uint256);
    function claimable(address _account) external view returns (uint256);
    function vault() external  returns (address);
}
