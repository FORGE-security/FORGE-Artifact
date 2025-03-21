// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./interfaces/IPortfolio.sol";
import "./interfaces/ITradePairs.sol";

/**
*   @author "DEXALOT TEAM"
*   @title "Portfolio: a contract to implement portfolio functionality for all traders."
*   @dev "The main data structure, assets, is implemented as a nested map from an address and symbol to an AssetEntry struct."
*   @dev "Assets keeps track of all assets on DEXALOT per user address per symbol."
*/

contract Portfolio is Initializable, AccessControlEnumerableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, IPortfolio {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // version
    bytes32 constant public VERSION = bytes32('1.4.0');

    // denominator for rate calculations
    uint constant public TENK = 10000;

    // account collecting fees
    address public feeAddress;

    // bytes32 variable to hold native token of DEXALOT
    bytes32 constant public native = bytes32('AVAX'); //obsolete as of 4/24/22 CD

    // bytes32 array of all ERC20 tokens traded on DEXALOT
    EnumerableSetUpgradeable.Bytes32Set private tokenList;

    // structure to track an asset
    struct AssetEntry {
        uint total;
        uint available;
    }

    enum AssetType {NATIVE, ERC20, NONE}

    // bytes32 symbols to ERC20 token map
    mapping (bytes32 => IERC20Upgradeable) private tokenMap;

    // account address to assets map
    mapping (address => mapping (bytes32 => AssetEntry)) public assets;

    // boolean to control deposit functionality
    bool private allowDeposit;

    // numerator for rate % to be used with a denominator of 10000
    uint public depositFeeRate;
    uint public withdrawFeeRate;

    struct TokenDetails {
        ITradePairs.AuctionMode auctionMode;
    }

    // contract address to trust status
    mapping (address => bool) public trustedContracts;

    // contract address to integrator organization name
    mapping (address => string) public trustedContractToIntegrator;

    // auction status of each token
    mapping (bytes32 => TokenDetails) private tokenDetailsMap;

    // auction admin role
    bytes32 constant public AUCTION_ADMIN_ROLE = keccak256("AUCTION_ADMIN_ROLE");
    bytes32 private nativeToken;

    // contract address to internal status
    mapping (address => bool) public internalContracts;

    // contract address to contract name
    mapping (address => string) public internalContractToName;

    event ParameterUpdated(bytes32 indexed pair, string _param, uint _oldValue, uint _newValue);
    event AddressSet(string indexed name, string actionName, address oldAddress, address newAddress);

    function initialize() public initializer {
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        // intitialize the admins
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); // set deployment account to have DEFAULT_ADMIN_ROLE
        allowDeposit = true;
        depositFeeRate = 0;    // depositFeeRate=0 (0% = 0/10000)
        withdrawFeeRate = 0;   // withdrawFeeRate=0 (0% = 0/10000)
        nativeToken = bytes32('AVAX');
    }

    function owner() public view returns(address) {
        return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
    }

    function addAdmin(address _address) public override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "P-OACC-01");
        grantRole(DEFAULT_ADMIN_ROLE, _address);
        emit AddressSet("PORTFOLIO", "ADD-ADMIN", _address, _address);
    }

    function removeAdmin(address _address) public override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "P-OACC-02");
        require(getRoleMemberCount(DEFAULT_ADMIN_ROLE)>1, "P-ALOA-01");
        revokeRole(DEFAULT_ADMIN_ROLE, _address);
        emit AddressSet("PORTFOLIO", "REMOVE-ADMIN", _address, _address);
    }

    function isAdmin(address _address) public view returns(bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _address);
    }

    function setNative(bytes32 _symbol) public override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "P-OACC-17");
        nativeToken = _symbol;
    }

    function getNative() public override view returns(bytes32)  {
        return nativeToken;
    }

    function addAuctionAdmin(address _address) public override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "P-OACC-11");
        grantRole(AUCTION_ADMIN_ROLE, _address);
        emit AddressSet("PORTFOLIO", "ADD-AUCTIONADMIN", _address, _address);
    }

    function removeAuctionAdmin(address _address) public override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "P-OACC-12");
        revokeRole(AUCTION_ADMIN_ROLE, _address);
        emit AddressSet("PORTFOLIO", "REMOVE-AUCTIONADMIN", _address, _address);
    }

    function isAuctionAdmin(address _address) public view returns(bool) {
        return hasRole(AUCTION_ADMIN_ROLE, _address);
    }

    function pause() public override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "P-OACC-03");
        _pause();
    }

    function unpause() public override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "P-OACC-04");
        _unpause();
    }

    function pauseDeposit(bool _paused) public override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "P-OACC-05");
        allowDeposit = !_paused;
    }

    function setFeeAddress(address _feeAddress) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "P-OACC-06");
        emit AddressSet("PORTFOLIO", "SET_FEEADDRESS", feeAddress, _feeAddress);
        feeAddress = _feeAddress;
    }

    function getFeeAddress() public view returns(address) {
        return feeAddress;
    }

    function addTrustedContract(address _contract, string calldata _organization) external override {
        require(hasRole(AUCTION_ADMIN_ROLE, msg.sender), "P-OACC-13");
        trustedContracts[_contract] = true;
        trustedContractToIntegrator[_contract] = _organization;
        emit AddressSet(_organization, "P-ADD-TRUSTEDCONTRACT", _contract, _contract);
    }

    function isTrustedContract(address _contract) external view override returns(bool) {
        return trustedContracts[_contract];
    }

    function removeTrustedContract(address _contract) external override {
        require(hasRole(AUCTION_ADMIN_ROLE, msg.sender), "P-OACC-14");
        trustedContracts[_contract] = false;
        emit AddressSet(trustedContractToIntegrator[_contract], "P-REMOVE-TRUSTED-CONTRACT", _contract, _contract);
    }

    function addInternalContract(address _contract, string calldata _name) external override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "P-OACC-16");
        internalContracts[_contract] = true;
        internalContractToName[_contract] = _name;
        emit AddressSet(_name, "P-ADD-INTERNALCONTRACT", _contract, _contract);
    }

    function isInternalContract(address _contract) external view override returns(bool) {
        return internalContracts[_contract];
    }

    function removeInternalContract(address _contract) external override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "P-OACC-18");
        internalContracts[_contract] = false;
        emit AddressSet(internalContractToName[_contract], "P-REMOVE-INTERNAL-CONTRACT", _contract, _contract);
    }

    function updateTransferFeeRate(uint _rate, IPortfolio.Tx _rateType) public override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "P-OACC-07");
        if (_rateType == IPortfolio.Tx.WITHDRAW) {
            emit ParameterUpdated(bytes32("Portfolio"), "P-DEPFEE", depositFeeRate, _rate);
            depositFeeRate = _rate; // (_rate/100)% = _rate/10000: _rate=10 => 0.10%
        } else if (_rateType == IPortfolio.Tx.DEPOSIT) {
            emit ParameterUpdated(bytes32("Portfolio"), "P-WITFEE", withdrawFeeRate, _rate);
            withdrawFeeRate = _rate; // (_rate/100)% = _rate/10000: _rate=20 => 0.20%
        } else {
            revert("P-WRTT-01");
        }
    }

    function getDepositFeeRate() public view returns(uint) {
        return depositFeeRate;
    }

    function getWithdrawFeeRate() public view returns(uint) {
        return withdrawFeeRate;
    }

    // function to add an ERC20 token
    function addToken(bytes32 _symbol, IERC20Upgradeable _token, ITradePairs.AuctionMode _mode) public override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(AUCTION_ADMIN_ROLE, msg.sender), "P-OACC-08");
        if (!tokenList.contains(_symbol)) {
            tokenList.add(_symbol);
            tokenMap[_symbol] = _token;
            TokenDetails storage tokenDetails = tokenDetailsMap[_symbol];
            tokenDetails.auctionMode = _mode;
            emit ParameterUpdated(_symbol, "P-ADDTOKEN", 0, uint(_mode));
        }
    }

    // FRONTEND FUNCTION TO GET ERC20 TOKEN LIST
    function getTokenList() public view returns(bytes32[] memory) {
        bytes32[] memory tokens = new bytes32[](tokenList.length());
        for (uint i=0; i<tokenList.length(); i++) {
            tokens[i] = tokenList.at(i);
        }
        return tokens;
    }

    // FRONTEND FUNCTION TO GET AN ERC20 TOKEN
    function getToken(bytes32 _symbol) public view returns(IERC20Upgradeable) {
        return tokenMap[_symbol];
    }

    function setAuctionMode(bytes32 _symbol, ITradePairs.AuctionMode _mode) public override {
        require(hasRole(AUCTION_ADMIN_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "P-AUCT-01");
        uint oldValue = uint(tokenDetailsMap[_symbol].auctionMode);
        tokenDetailsMap[_symbol].auctionMode = _mode;
        emit ParameterUpdated(_symbol, "P-AUCTION", oldValue, uint(_mode));
    }

    // FRONTEND FUNCTION TO GET PORTFOLIO BALANCE FOR AN ACCOUNT AND TOKEN SYMBOL
    function getBalance(address _owner, bytes32 _symbol) public view
        returns(uint total, uint available, AssetType assetType) {
            assetType = AssetType.NONE;
            if (nativeToken == _symbol) {
                assetType = AssetType.NATIVE;
            }
            if (tokenList.contains(_symbol)) {
                assetType = AssetType.ERC20;
            }
            total = assets[_owner][_symbol].total;
            available = assets[_owner][_symbol].available;
            return (total, available, assetType);
    }

    // we revert transaction if a non-existing function is called
    fallback() external {
        revert();
    }

    function handleDepositNative(address payable _from, uint _value) private {
        uint _quantityLessFee = _value;
        uint feeCharged;
        if (depositFeeRate>0 && !internalContracts[_from]) {
            feeCharged = (_value * depositFeeRate) / TENK;
            transferFee(nativeToken, feeCharged);
            _quantityLessFee -= feeCharged;
        }
        safeIncrease(_from, nativeToken, _quantityLessFee, 0, IPortfolio.Tx.DEPOSIT);
        emitPortfolioEvent(_from, nativeToken, _value, feeCharged, IPortfolio.Tx.DEPOSIT);
    }

    // FRONTEND FUNCTION TO DEPOSIT NATIVE TOKEN VIA TRANSFER
    receive() external payable whenNotPaused nonReentrant {
        require(allowDeposit, "P-NTDP-01");
        handleDepositNative(payable(msg.sender), msg.value);
    }

    // FRONTEND FUNCTION TO DEPOSIT NATIVE TOKEN
    function depositNative(address payable _from) external override payable whenNotPaused nonReentrant {
        require(_from == msg.sender || internalContracts[msg.sender], "P-OOWN-02");
        require(allowDeposit, "P-NTDP-02");
        handleDepositNative(_from, msg.value);
    }

    // FRONTEND FUNCTION TO WITHDRAW A QUANTITY FROM PORTFOLIO BALANCE FOR AN ACCOUNT AND NATIVE SYMBOL
    function withdrawNative(address payable _to, uint _quantity) public override whenNotPaused nonReentrant {
        require(_to == msg.sender || internalContracts[msg.sender], "P-OOWN-01");
        safeDecrease(_to, nativeToken, _quantity, IPortfolio.Tx.WITHDRAW); // does not decrease if transfer fails
        uint _quantityLessFee = _quantity;
        uint feeCharged;
        if (withdrawFeeRate>0 && !internalContracts[msg.sender]) {
            feeCharged = (_quantity * withdrawFeeRate) / TENK;
            transferFee(nativeToken, feeCharged);
            _quantityLessFee -= feeCharged;
        }
        (bool success, ) = _to.call{value: _quantityLessFee}('');
        require(success, "P-WNF-01");
        emitPortfolioEvent(_to, nativeToken, _quantity, feeCharged, IPortfolio.Tx.WITHDRAW);
    }

    // handle ERC20 token deposit and withdrawal
    // FRONTEND FUNCTION TO DEPOSIT A QUANTITY TO PORTFOLIO BALANCE FOR AN ACCOUNT AND TOKEN SYMBOL
    function depositToken(address _from, bytes32 _symbol, uint _quantity) public override whenNotPaused nonReentrant {
        require(_from == msg.sender || internalContracts[msg.sender], "P-OODT-01");
        require(allowDeposit, "P-ETDP-01");
        require(_quantity > 0, "P-ZETD-01");
        require(tokenList.contains(_symbol), "P-ETNS-01");
        uint feeCharged;
        if (depositFeeRate>0 && !internalContracts[msg.sender]) {
            feeCharged = (_quantity * depositFeeRate) / TENK;
        }
        uint _quantityLessFee = _quantity - feeCharged;
        safeIncrease(_from, _symbol, _quantityLessFee, 0, IPortfolio.Tx.DEPOSIT); // reverts if transfer fails
        require(_quantity <= tokenMap[_symbol].balanceOf(_from), "P-NETD-01");
        tokenMap[_symbol].safeTransferFrom(_from, address(this), _quantity);
        if (depositFeeRate>0) {
            transferFee(_symbol, feeCharged);
        }
        emitPortfolioEvent(_from, _symbol, _quantity, feeCharged, IPortfolio.Tx.DEPOSIT);
    }

    function depositTokenFromContract(address _from, bytes32 _symbol, uint _quantity) public whenNotPaused nonReentrant override {
        require(trustedContracts[msg.sender], "P-AOTC-01");
        require(allowDeposit, "P-ETDP-02");
        require(_quantity > 0, "P-ZETD-02");
        require(tokenList.contains(_symbol), "P-ETNS-02");
        safeIncrease(_from, _symbol, _quantity, 0, IPortfolio.Tx.DEPOSIT); // reverts if transfer fails
        require(_quantity <= tokenMap[_symbol].balanceOf(_from), "P-NETD-02");
        tokenMap[_symbol].safeTransferFrom(_from, address(this), _quantity);
        emitPortfolioEvent(_from, _symbol, _quantity, 0, IPortfolio.Tx.DEPOSIT);
    }

    // FRONTEND FUNCTION TO WITHDRAW A QUANTITY FROM PORTFOLIO BALANCE FOR AN ACCOUNT AND TOKEN SYMBOL
    function withdrawToken(address _to, bytes32 _symbol, uint _quantity) public override whenNotPaused nonReentrant {
        require(_to == msg.sender || internalContracts[msg.sender], "P-OOWT-01");
        require(_quantity > 0, "P-ZTQW-01");
        require(tokenList.contains(_symbol), "P-ETNS-02");
        require(tokenDetailsMap[_symbol].auctionMode == ITradePairs.AuctionMode.OFF , "P-AUCT-02");
        safeDecrease(_to, _symbol, _quantity, IPortfolio.Tx.WITHDRAW); // does not decrease if transfer fails
        uint _quantityLessFee = _quantity;
        uint feeCharged;
        if (withdrawFeeRate>0 && !internalContracts[msg.sender]) {
            feeCharged = (_quantity * withdrawFeeRate) / TENK;
            transferFee(_symbol, feeCharged);
            _quantityLessFee -= feeCharged;
        }
        tokenMap[_symbol].safeTransfer(_to, _quantityLessFee);
        emitPortfolioEvent(_to, _symbol, _quantity, feeCharged, IPortfolio.Tx.WITHDRAW);
    }

    function emitPortfolioEvent(address _trader, bytes32 _symbol, uint _quantity, uint _feeCharged,  IPortfolio.Tx transaction) private {
        emit IPortfolio.PortfolioUpdated(transaction, _trader, _symbol, _quantity, _feeCharged, assets[_trader][_symbol].total, assets[_trader][_symbol].available);
    }

    // WHEN Increasing in addExectuion the amount is applied to both Total & Available(so SafeIncrease can be used) as opposed to
    // WHEN Decreasing in addExectuion the amount is only applied to Total.(SafeDecrease can NOT be used, so we have safeDecreaseTotal instead)
    // i.e. (USDT 100 Total, 50 Available after we send a BUY order of 10 avax @5$. Partial Exec 5@10. Total goes down to 75. Available stays at 50 )
    function addExecution(ITradePairs.Order memory _maker, address _takerAddr, bytes32 _baseSymbol, bytes32 _quoteSymbol,
                          uint _baseAmount, uint _quoteAmount, uint _makerfeeCharged, uint _takerfeeCharged)
            public override {
        // TRADEPAIRS SHOULD HAVE ADMIN ROLE TO INITIATE PORTFOLIO addExecution
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "P-OACC-10");
        // if _maker.side = BUY then _taker.side = SELL
        if (_maker.side == ITradePairs.Side.BUY) {
            // decrease maker quote and incrase taker quote
            safeDecreaseTotal(_maker.traderaddress, _quoteSymbol, _quoteAmount, IPortfolio.Tx.EXECUTION);
            safeIncrease(_takerAddr, _quoteSymbol, _quoteAmount, _takerfeeCharged, IPortfolio.Tx.EXECUTION);
            // increase maker base and decrase taker base
            safeIncrease(_maker.traderaddress, _baseSymbol, _baseAmount, _makerfeeCharged, IPortfolio.Tx.EXECUTION);
            safeDecrease(_takerAddr,_baseSymbol, _baseAmount, IPortfolio.Tx.EXECUTION);
        } else {
            // increase maker quote & decrease taker quote
            safeIncrease(_maker.traderaddress, _quoteSymbol, _quoteAmount, _makerfeeCharged, IPortfolio.Tx.EXECUTION);
            safeDecrease(_takerAddr, _quoteSymbol, _quoteAmount, IPortfolio.Tx.EXECUTION);
            // decrease maker base and incrase taker base
            safeDecreaseTotal(_maker.traderaddress, _baseSymbol, _baseAmount, IPortfolio.Tx.EXECUTION);
            safeIncrease(_takerAddr, _baseSymbol, _baseAmount, _takerfeeCharged, IPortfolio.Tx.EXECUTION);
        }
    }

    function adjustAvailable(IPortfolio.Tx _transaction, address _trader, bytes32 _symbol, uint _amount) public override  {
        // TRADEPAIRS SHOULD HAVE ADMIN ROLE TO INITIATE PORTFOLIO adjustAvailable
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "P-OACC-09");
        if (_transaction == IPortfolio.Tx.INCREASEAVAIL) {
            assets[_trader][_symbol].available += _amount;
        } else if (_transaction == IPortfolio.Tx.DECREASEAVAIL)  {
            require(_amount <= assets[_trader][_symbol].available, "P-AFNE-01");
            assets[_trader][_symbol].available -= _amount;
        } else {
            revert("P-WRTT-02");
        }
        emitPortfolioEvent(_trader, _symbol, _amount, 0, _transaction);
    }

    function safeTransferFee(bytes32 _symbol, uint _feeAccumulated) private {
        if (_feeAccumulated>0) {
            bool feesuccess = true;
            assets[feeAddress][_symbol].total -= _feeAccumulated;
            assets[feeAddress][_symbol].available -= _feeAccumulated;
            if (nativeToken == _symbol) {
                (feesuccess, ) = payable(feeAddress).call{value: _feeAccumulated}('');
                require(feesuccess, "P-STFF-01");
            } else {
                tokenMap[_symbol].safeTransfer(payable(feeAddress), _feeAccumulated);
            }
        }
    }

    function safeTransferFees() public override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "P-OACC-15");
        bytes32 symbol;
        safeTransferFee(nativeToken, assets[feeAddress][nativeToken].available);
        for (uint i=0; i<tokenList.length(); i++) {
            symbol = tokenList.at(i);
            safeTransferFee(symbol, assets[feeAddress][symbol].available);
        }
    }

    function transferFee(bytes32 _symbol, uint _feeCharged) private {
        assets[feeAddress][_symbol].total += _feeCharged;
        assets[feeAddress][_symbol].available += _feeCharged;
    }

    // Only called from addExecution
    function safeDecreaseTotal(address _trader, bytes32 _symbol, uint _amount, IPortfolio.Tx transaction) private {
      require(_amount <= assets[_trader][_symbol].total, "P-TFNE-01");
      assets[_trader][_symbol].total -= _amount;
      if (transaction ==  IPortfolio.Tx.EXECUTION) { // The methods that call safeDecrease are already emmiting this event anyways
        emitPortfolioEvent(_trader, _symbol,_amount, 0, transaction);
      }
    }

    // Only called from DEPOSIT/WITHDRAW
    function safeDecrease(address _trader, bytes32 _symbol, uint _amount, IPortfolio.Tx transaction) private {
      require(_amount <= assets[_trader][_symbol].available, "P-AFNE-02");
      assets[_trader][_symbol].available -= _amount;
      safeDecreaseTotal(_trader, _symbol, _amount, transaction);
    }

    // Called from DEPOSIT/ WITHDRAW AND ALL OTHER TX
    // WHEN called from DEPOSIT/ WITHDRAW emitEvent = false because for some reason the event has to be raised at the end of the
    // corresponding Deposit/ Withdraw functions to be able to capture the state change in the chain value.
    function safeIncrease(address _trader, bytes32 _symbol, uint _amount, uint _feeCharged, IPortfolio.Tx transaction) private {
      require(_amount > 0 && _amount >= _feeCharged, "P-TNEF-01");
      assets[_trader][_symbol].total += _amount - _feeCharged;
      assets[_trader][_symbol].available += _amount - _feeCharged;

      if (_feeCharged > 0 ) {
        transferFee(_symbol, _feeCharged);
      }
      if (transaction != IPortfolio.Tx.DEPOSIT && transaction != IPortfolio.Tx.WITHDRAW) {
        emitPortfolioEvent(_trader, _symbol, _amount, _feeCharged, transaction);
      }
    }

}
