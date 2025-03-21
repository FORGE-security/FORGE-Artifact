// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

interface IController { 
    
    // --- Events ---
    event LUSDAddressChanged(address _lusdAddress);
    event GovernanceAddressChanged(address _governanceAddress);
    event TroveManagerAddressChanged(address _troveManagerAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);

    // --- Functions ---

    function totalDebt() external view returns (uint256);

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(address _sender,  address poolAddress, uint256 _amount) external;
}
