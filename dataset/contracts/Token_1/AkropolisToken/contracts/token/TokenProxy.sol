pragma solidity ^0.4.24;

import "./dataStorage/TokenStorage.sol";
import "zos-lib/contracts/upgradeability/UpgradeabilityProxy.sol";
import '../helpers/Ownable.sol';

/**
* @title TokenProxy
* @notice A proxy contract that serves the latest implementation of TokenProxy.
*/
contract TokenProxy is UpgradeabilityProxy, TokenStorage, Ownable {

    string public name;   //name of Token                
    uint8  public decimals;        //decimals of Token        
    string public symbol;   //Symbol of Token

    constructor(address _implementation, address _balances, address _allowances, string _name, uint8 _decimals, string _symbol) 
    UpgradeabilityProxy(_implementation) 
    TokenStorage(_balances, _allowances) public {
        name = _name;
        decimals = _decimals;
        symbol = _symbol;
    }

    /**
    * @dev Upgrade the backing implementation of the proxy.
    * Only the admin can call this function.
    * @param newImplementation Address of the new implementation.
    */
    function upgradeTo(address newImplementation) public onlyOwner {
        _upgradeTo(newImplementation);
    }

    /**
    * @return The address of the implementation.
    */
    function implementation() public view returns (address) {
        return _implementation();
    }
}