pragma solidity ^0.4.24;

import '../../contracts/PoaNetworkConsensus.sol';
import '../../contracts/interfaces/IProxyStorage.sol';


contract PoaNetworkConsensusMock is PoaNetworkConsensus {
    constructor(
        address _moc,
        address[] validators
    ) PoaNetworkConsensus(
        _moc,
        validators
    ) public {
    }

    function setSystemAddress(address _newAddress) public {
        systemAddress = _newAddress;
    }

    function setProxyStorageMock(address _newAddress) public {
        proxyStorage = IProxyStorage(_newAddress);
    }

    function setMoCMock(address _newAddress) public {
        _moc = _newAddress;
    }

    function setIsMasterOfCeremonyInitializedMock(bool _status) public {
        isMasterOfCeremonyInitialized = _status;
    }

    function setCurrentValidatorsLength(uint256 _newNumber) public {
        currentValidators.length = _newNumber;
    }
}