pragma solidity 0.5.8;

import "./USDTieredSTOProxy.sol";
import "../../UpgradableModuleFactory.sol";

/**
 * @title Factory for deploying CappedSTO module
 */
contract USDTieredSTOFactory is UpgradableModuleFactory {

    /**
     * @notice Constructor
     * @param _setupCost Setup cost of the module
     * @param _usageCost Usage cost of the module
     * @param _logicContract Contract address that contains the logic related to `description`
     * @param _polymathRegistry Address of the Polymath registry
     * @param _isCostInPoly true = cost in Poly, false = USD
     */
    constructor (
        uint256 _setupCost,
        uint256 _usageCost,
        address _logicContract,
        address _polymathRegistry,
        bool _isCostInPoly
    )
        public
        UpgradableModuleFactory("3.1.0", _setupCost, _usageCost, _logicContract, _polymathRegistry, _isCostInPoly)
    {
        name = "USDTieredSTO";
        title = "Tiered STO";
        /*solium-disable-next-line max-len*/
        description = "It allows both accredited and non-accredited investors to contribute into the STO. Non-accredited investors will be capped at a maximum investment limit (as a default or specific to their jurisdiction). Tokens will be sold according to tiers sequentially & each tier has its own price and volume of tokens to sell. Upon receipt of funds (ETH, POLY or DAI), security tokens will automatically transfer to investorâ€™s wallet address";
        typesData.push(3);
        typesData.push(8); // Extra type which will allow module to hold and send securityTokens without being added in KYC data
        typesData.push(5); // Allow burn type 
        typesData.push(9); // Auto whitelist treasury wallet
        tagsData.push("Tiered");
        tagsData.push("ETH");
        tagsData.push("POLY");
        tagsData.push("USD");
        tagsData.push("STO");
        compatibleSTVersionRange["lowerBound"] = VersionUtils.pack(uint8(3), uint8(0), uint8(0));
        compatibleSTVersionRange["upperBound"] = VersionUtils.pack(uint8(3), uint8(1), uint8(0));
    }

    /**
     * @notice Used to launch the Module with the help of factory
     * @return address Contract address of the Module
     */
    function deploy(bytes calldata _data) external returns(address) {
        address usdTieredSTO = address(new USDTieredSTOProxy(logicContracts[latestUpgrade].version, msg.sender, polymathRegistry.getAddress("PolyToken"), logicContracts[latestUpgrade].logicContract));
        _initializeModule(usdTieredSTO, _data);
        return usdTieredSTO;
    }

}
