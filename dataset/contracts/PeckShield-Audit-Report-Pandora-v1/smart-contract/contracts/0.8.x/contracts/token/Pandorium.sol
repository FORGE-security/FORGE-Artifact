//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Pandorium is ERC20Burnable, Ownable {
    uint256 public totalBurned;
    EnumerableSet.AddressSet private minters;
    address public devFund;
    uint256 public devFundPercent = 10;

    constructor(address _devFund) ERC20('Pandorium', 'PAN'){
        devFund = _devFund;
    }

    /*----------------------------EXTERNAL FUNCTIONS----------------------------*/

    function burn(uint256 _amount) public override {
        totalBurned += _amount;
        ERC20Burnable.burn(_amount);
    }

    function burnFrom(address _account, uint256 _amount)  public override {
        totalBurned += _amount;
        ERC20Burnable.burnFrom(_account, _amount);
    }

    function mint(address _account, uint256 _amount) public onlyMinter {
        uint256 _toDev = _amount * devFundPercent / 100;
        _mint(devFund, _toDev);
        _mint(_account, _amount - _toDev);
    }

    /*----------------------------RESTRICT FUNCTIONS----------------------------*/

    function changeDevFundPercent(uint256 _newPercent) external onlyOwner {
        devFundPercent = _newPercent;
    }

    function changeDevFund(address _newAddr) external onlyOwner {
        devFund = _newAddr;
    }

    function addMinter(address _addMinter) external onlyOwner returns (bool) {
        require(_addMinter != address(0), "Token: _addMinter is the zero address");
        return EnumerableSet.add(minters, _addMinter);
    }

    function delMinter(address _delMinter) external onlyOwner returns (bool) {
        require(_delMinter != address(0), "Token: _delMinter is the zero address");
        return EnumerableSet.remove(minters, _delMinter);
    }

    function getMinterLength() internal view returns (uint256) {
        return EnumerableSet.length(minters);
    }

    function isMinter(address account) public view returns (bool) {
        return EnumerableSet.contains(minters, account);
    }

    function getMinter(uint256 _index) external view onlyOwner returns (address) {
        require(_index <= getMinterLength() - 1, "Token: index out of bounds");
        return EnumerableSet.at(minters, _index);
    }
    // modifier for mint function
    modifier onlyMinter() {
        require(isMinter(msg.sender), "caller is not the minter");
        _;
    }
}