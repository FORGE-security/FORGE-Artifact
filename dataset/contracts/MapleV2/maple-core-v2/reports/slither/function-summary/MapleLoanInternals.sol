
Contract MapleLoanInternals
Contract vars: ['FACTORY_SLOT', 'IMPLEMENTATION_SLOT', 'SCALED_ONE', '_borrower', '_lender', '_pendingBorrower', '_pendingLender', '_collateralAsset', '_fundsAsset', '_gracePeriod', '_paymentInterval', '_interestRate', '_earlyFeeRate', '_lateFeeRate', '_lateInterestPremium', '_collateralRequired', '_principalRequested', '_endingPrincipal', '_drawableFunds', '_claimableFunds', '_collateral', '_nextPaymentDueDate', '_paymentsRemaining', '_principal', '_refinanceCommitment', '_refinanceInterest', '_delegateFee', '_treasuryFee']
Inheritance:: ['MapleProxiedInternals', 'ProxiedInternals', 'SlotManipulatable']
 
+------------------------------------------------------------------------------------------------------+------------+-----------+-------------------------------------------------+-------------------------------------------------+------------------------------------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------+
|                                               Function                                               | Visibility | Modifiers |                       Read                      |                      Write                      |                       Internal Calls                       |                                                                  External Calls                                                                  |
+------------------------------------------------------------------------------------------------------+------------+-----------+-------------------------------------------------+-------------------------------------------------+------------------------------------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------+
|                                       _migrate(address,bytes)                                        |  internal  |     []    |                        []                       |                        []                       |                             []                             |                                                      ['migrator_.delegatecall(arguments_)']                                                      |
|                                         _setFactory(address)                                         |  internal  |     []    |                 ['FACTORY_SLOT']                |                        []                       |                     ['_setSlotValue']                      |                                                                        []                                                                        |
|                                     _setImplementation(address)                                      |  internal  |     []    |             ['IMPLEMENTATION_SLOT']             |                        []                       |                     ['_setSlotValue']                      |                                                                        []                                                                        |
|                                              _factory()                                              |  internal  |     []    |                 ['FACTORY_SLOT']                |                        []                       |                     ['_getSlotValue']                      |                                                                        []                                                                        |
|                                          _implementation()                                           |  internal  |     []    |             ['IMPLEMENTATION_SLOT']             |                        []                       |                     ['_getSlotValue']                      |                                                                        []                                                                        |
|                                _getReferenceTypeSlot(bytes32,bytes32)                                |  internal  |     []    |                        []                       |                        []                       |         ['abi.encodePacked()', 'keccak256(bytes)']         |                                                         ['abi.encodePacked(key_,slot_)']                                                         |
|                                        _getSlotValue(bytes32)                                        |  internal  |     []    |                        []                       |                        []                       |                     ['sload(uint256)']                     |                                                                        []                                                                        |
|                                    _setSlotValue(bytes32,bytes32)                                    |  internal  |     []    |                        []                       |                        []                       |                ['sstore(uint256,uint256)']                 |                                                                        []                                                                        |
|                                        _clearLoanAccounting()                                        |  internal  |     []    |                        []                       |        ['_delegateFee', '_earlyFeeRate']        |                             []                             |                                                                        []                                                                        |
|                                                                                                      |            |           |                                                 |       ['_endingPrincipal', '_gracePeriod']      |                                                            |                                                                                                                                                  |
|                                                                                                      |            |           |                                                 |        ['_interestRate', '_lateFeeRate']        |                                                            |                                                                                                                                                  |
|                                                                                                      |            |           |                                                 | ['_lateInterestPremium', '_nextPaymentDueDate'] |                                                            |                                                                                                                                                  |
|                                                                                                      |            |           |                                                 |    ['_paymentInterval', '_paymentsRemaining']   |                                                            |                                                                                                                                                  |
|                                                                                                      |            |           |                                                 |          ['_principal', '_treasuryFee']         |                                                            |                                                                                                                                                  |
|                   _initialize(address,address[2],uint256[3],uint256[3],uint256[4])                   |  internal  |     []    |                  ['_borrower']                  |        ['_borrower', '_collateralAsset']        |     ['_setEstablishmentFees', 'require(bool,string)']      |                                                                        []                                                                        |
|                                                                                                      |            |           |                                                 |     ['_collateralRequired', '_earlyFeeRate']    |                                                            |                                                                                                                                                  |
|                                                                                                      |            |           |                                                 |       ['_endingPrincipal', '_fundsAsset']       |                                                            |                                                                                                                                                  |
|                                                                                                      |            |           |                                                 |        ['_gracePeriod', '_interestRate']        |                                                            |                                                                                                                                                  |
|                                                                                                      |            |           |                                                 |     ['_lateFeeRate', '_lateInterestPremium']    |                                                            |                                                                                                                                                  |
|                                                                                                      |            |           |                                                 |    ['_paymentInterval', '_paymentsRemaining']   |                                                            |                                                                                                                                                  |
|                                                                                                      |            |           |                                                 |             ['_principalRequested']             |                                                            |                                                                                                                                                  |
|                                             _closeLoan()                                             |  internal  |     []    |      ['_claimableFunds', '_drawableFunds']      |      ['_claimableFunds', '_drawableFunds']      | ['_processEstablishmentFees', '_getEarlyPaymentBreakdown'] |                                                                        []                                                                        |
|                                                                                                      |            |           |      ['_fundsAsset', '_nextPaymentDueDate']     |              ['_refinanceInterest']             |     ['_getUnaccountedAmount', 'require(bool,string)']      |                                                                                                                                                  |
|                                                                                                      |            |           |               ['block.timestamp']               |                                                 |                  ['_clearLoanAccounting']                  |                                                                                                                                                  |
|                                   _drawdownFunds(uint256,address)                                    |  internal  |     []    |        ['_drawableFunds', '_fundsAsset']        |                ['_drawableFunds']               |    ['_isCollateralMaintained', 'require(bool,string)']     |                                            ['ERC20Helper.transfer(_fundsAsset,destination_,amount_)']                                            |
|                                            _makePayment()                                            |  internal  |     []    |      ['_claimableFunds', '_drawableFunds']      |      ['_claimableFunds', '_drawableFunds']      |    ['_clearLoanAccounting', '_getNextPaymentBreakdown']    |                                                                        []                                                                        |
|                                                                                                      |            |           |      ['_fundsAsset', '_nextPaymentDueDate']     |  ['_nextPaymentDueDate', '_paymentsRemaining']  |   ['_getUnaccountedAmount', '_processEstablishmentFees']   |                                                                                                                                                  |
|                                                                                                      |            |           |    ['_paymentInterval', '_paymentsRemaining']   |       ['_principal', '_refinanceInterest']      |                                                            |                                                                                                                                                  |
|                                                                                                      |            |           |                  ['_principal']                 |                                                 |                                                            |                                                                                                                                                  |
|                                          _postCollateral()                                           |  internal  |     []    |       ['_collateral', '_collateralAsset']       |                 ['_collateral']                 |                 ['_getUnaccountedAmount']                  |                                                                        []                                                                        |
|                              _proposeNewTerms(address,uint256,bytes[])                               |  internal  |     []    |             ['_refinanceCommitment']            |             ['_refinanceCommitment']            |                ['_getRefinanceCommitment']                 |                                                                        []                                                                        |
|                                  _removeCollateral(uint256,address)                                  |  internal  |     []    |       ['_collateral', '_collateralAsset']       |                 ['_collateral']                 |    ['_isCollateralMaintained', 'require(bool,string)']     |                                         ['ERC20Helper.transfer(_collateralAsset,destination_,amount_)']                                          |
|                                            _returnFunds()                                            |  internal  |     []    |        ['_drawableFunds', '_fundsAsset']        |                ['_drawableFunds']               |                 ['_getUnaccountedAmount']                  |                                                                        []                                                                        |
|                               _acceptNewTerms(address,uint256,bytes[])                               |  internal  |     []    |       ['_delegateFee', '_endingPrincipal']      | ['_nextPaymentDueDate', '_refinanceCommitment'] |  ['_getRefinanceInterestParams', 'require(bool,string)']   |                                                     ['refinancer_.delegatecall(calls_[i])']                                                      |
|                                                                                                      |            |           |        ['_interestRate', '_lateFeeRate']        |              ['_refinanceInterest']             |         ['code(address)', '_setEstablishmentFees']         |                                                                                                                                                  |
|                                                                                                      |            |           | ['_lateInterestPremium', '_nextPaymentDueDate'] |                                                 |   ['_getRefinanceCommitment', '_isCollateralMaintained']   |                                                                                                                                                  |
|                                                                                                      |            |           |    ['_paymentInterval', '_paymentsRemaining']   |                                                 |                                                            |                                                                                                                                                  |
|                                                                                                      |            |           |      ['_principal', '_refinanceCommitment']     |                                                 |                                                            |                                                                                                                                                  |
|                                                                                                      |            |           |      ['_refinanceInterest', '_treasuryFee']     |                                                 |                                                            |                                                                                                                                                  |
|                                                                                                      |            |           |               ['block.timestamp']               |                                                 |                                                            |                                                                                                                                                  |
|                                     _claimFunds(uint256,address)                                     |  internal  |     []    |        ['_claimableFunds', '_fundsAsset']       |               ['_claimableFunds']               |                  ['require(bool,string)']                  |                                            ['ERC20Helper.transfer(_fundsAsset,destination_,amount_)']                                            |
|                                          _fundLoan(address)                                          |  internal  |     []    |      ['_fundsAsset', '_nextPaymentDueDate']     |          ['_drawableFunds', '_lender']          |     ['_getUnaccountedAmount', 'require(bool,string)']      |                                                                        []                                                                        |
|                                                                                                      |            |           |    ['_paymentInterval', '_paymentsRemaining']   |      ['_nextPaymentDueDate', '_principal']      |                                                            |                                                                                                                                                  |
|                                                                                                      |            |           |      ['_principal', '_principalRequested']      |                                                 |                                                            |                                                                                                                                                  |
|                                                                                                      |            |           |               ['block.timestamp']               |                                                 |                                                            |                                                                                                                                                  |
|                              _processEstablishmentFees(uint256,uint256)                              |  internal  |     []    |          ['_claimableFunds', '_lender']         |               ['_claimableFunds']               |               ['_sendFee', '_mapleGlobals']                |                                                                        []                                                                        |
|                               _rejectNewTerms(address,uint256,bytes[])                               |  internal  |     []    |             ['_refinanceCommitment']            |             ['_refinanceCommitment']            |    ['_getRefinanceCommitment', 'require(bool,string)']     |                                                                        []                                                                        |
|                                   _sendFee(address,bytes4,uint256)                                   |  internal  |     []    |                 ['_fundsAsset']                 |                        []                       |        ['abi.encodeWithSelector()', 'abi.decode()']        |                          ['abi.encodeWithSelector(selector_)', 'ERC20Helper.transfer(_fundsAsset,destination,amount_)']                          |
|                                                                                                      |            |           |                                                 |                                                 |                                                            |                                ['abi.decode(data,(address))', 'lookup_.call(abi.encodeWithSelector(selector_))']                                 |
|                        _setEstablishmentFees(uint256,uint256,uint256,uint256)                        |  internal  |     []    |                        []                       |         ['_delegateFee', '_treasuryFee']        |                     ['_mapleGlobals']                      |                                                ['globals.investorFee()', 'globals.treasuryFee()']                                                |
|                                         _repossess(address)                                          |  internal  |     []    |       ['_collateralAsset', '_fundsAsset']       |        ['_claimableFunds', '_collateral']       |     ['_clearLoanAccounting', '_getUnaccountedAmount']      | ['ERC20Helper.transfer(fundsAsset,destination_,fundsRepossessed_)', 'ERC20Helper.transfer(collateralAsset,destination_,collateralRepossessed_)'] |
|                                                                                                      |            |           |     ['_gracePeriod', '_nextPaymentDueDate']     |                ['_drawableFunds']               |                  ['require(bool,string)']                  |                                                                                                                                                  |
|                                                                                                      |            |           |               ['block.timestamp']               |                                                 |                                                            |                                                                                                                                                  |
|                                      _isCollateralMaintained()                                       |  internal  |     []    |      ['_collateral', '_collateralRequired']     |                        []                       |               ['_getCollateralRequiredFor']                |                                                                        []                                                                        |
|                                                                                                      |            |           |         ['_drawableFunds', '_principal']        |                                                 |                                                            |                                                                                                                                                  |
|                                                                                                      |            |           |             ['_principalRequested']             |                                                 |                                                            |                                                                                                                                                  |
|                                     _getEarlyPaymentBreakdown()                                      |  internal  |     []    |          ['SCALED_ONE', '_delegateFee']         |                        []                       |                             []                             |                                                                        []                                                                        |
|                                                                                                      |            |           |     ['_earlyFeeRate', '_paymentsRemaining']     |                                                 |                                                            |                                                                                                                                                  |
|                                                                                                      |            |           |       ['_principal', '_refinanceInterest']      |                                                 |                                                            |                                                                                                                                                  |
|                                                                                                      |            |           |                 ['_treasuryFee']                |                                                 |                                                            |                                                                                                                                                  |
|                                      _getNextPaymentBreakdown()                                      |  internal  |     []    |       ['_delegateFee', '_endingPrincipal']      |                        []                       |                  ['_getPaymentBreakdown']                  |                                                                        []                                                                        |
|                                                                                                      |            |           |        ['_interestRate', '_lateFeeRate']        |                                                 |                                                            |                                                                                                                                                  |
|                                                                                                      |            |           | ['_lateInterestPremium', '_nextPaymentDueDate'] |                                                 |                                                            |                                                                                                                                                  |
|                                                                                                      |            |           |    ['_paymentInterval', '_paymentsRemaining']   |                                                 |                                                            |                                                                                                                                                  |
|                                                                                                      |            |           |       ['_principal', '_refinanceInterest']      |                                                 |                                                            |                                                                                                                                                  |
|                                                                                                      |            |           |       ['_treasuryFee', 'block.timestamp']       |                                                 |                                                            |                                                                                                                                                  |
|                                    _getUnaccountedAmount(address)                                    |  internal  |     []    |        ['_claimableFunds', '_collateral']       |                        []                       |                             []                             |                              ['IERC20(asset_).balanceOf(address(this))', 'IERC20(asset_).balanceOf(address(this))']                              |
|                                                                                                      |            |           |      ['_collateralAsset', '_drawableFunds']     |                                                 |                                                            |                              ['IERC20(asset_).balanceOf(address(this))', 'IERC20(asset_).balanceOf(address(this))']                              |
|                                                                                                      |            |           |             ['_fundsAsset', 'this']             |                                                 |                                                            |                                                                                                                                                  |
|                                           _mapleGlobals()                                            |  internal  |     []    |                        []                       |                        []                       |                        ['_factory']                        |                                                 ['IMapleLoanFactory(_factory()).mapleGlobals()']                                                 |
|                      _getCollateralRequiredFor(uint256,uint256,uint256,uint256)                      |  internal  |     []    |                        []                       |                        []                       |                             []                             |                                                                        []                                                                        |
|                       _getInstallment(uint256,uint256,uint256,uint256,uint256)                       |  internal  |     []    |                  ['SCALED_ONE']                 |                        []                       |        ['_getInterest', '_getPeriodicInterestRate']        |                                                                        []                                                                        |
|                                                                                                      |            |           |                                                 |                                                 |                    ['_scaledExponent']                     |                                                                                                                                                  |
|                                _getInterest(uint256,uint256,uint256)                                 |  internal  |     []    |                  ['SCALED_ONE']                 |                        []                       |                ['_getPeriodicInterestRate']                |                                                                        []                                                                        |
|    _getPaymentBreakdown(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)     |  internal  |     []    |                        []                       |                        []                       |          ['_getLateInterest', '_getInstallment']           |                                                                        []                                                                        |
| _getRefinanceInterestParams(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256) |  internal  |     []    |                        []                       |                        []                       |          ['_getLateInterest', '_getInstallment']           |                                                                        []                                                                        |
|                  _getLateInterest(uint256,uint256,uint256,uint256,uint256,uint256)                   |  internal  |     []    |                  ['SCALED_ONE']                 |                        []                       |                      ['_getInterest']                      |                                                                        []                                                                        |
|                              _getPeriodicInterestRate(uint256,uint256)                               |  internal  |     []    |                        []                       |                        []                       |                             []                             |                                                                        []                                                                        |
|                           _getRefinanceCommitment(address,uint256,bytes[])                           |  internal  |     []    |                        []                       |                        []                       |            ['abi.encode()', 'keccak256(bytes)']            |                                                   ['abi.encode(refinancer_,deadline_,calls_)']                                                   |
|                               _scaledExponent(uint256,uint256,uint256)                               |  internal  |     []    |                        []                       |                        []                       |                             []                             |                                                                        []                                                                        |
|                                slitherConstructorConstantVariables()                                 |  internal  |     []    |                        []                       |     ['FACTORY_SLOT', 'IMPLEMENTATION_SLOT']     |                             []                             |                                                                        []                                                                        |
|                                                                                                      |            |           |                                                 |                  ['SCALED_ONE']                 |                                                            |                                                                                                                                                  |
+------------------------------------------------------------------------------------------------------+------------+-----------+-------------------------------------------------+-------------------------------------------------+------------------------------------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------+

+-----------+------------+------+-------+----------------+----------------+
| Modifiers | Visibility | Read | Write | Internal Calls | External Calls |
+-----------+------------+------+-------+----------------+----------------+
+-----------+------------+------+-------+----------------+----------------+


Contract IMapleLoanFactory
Contract vars: []
Inheritance:: ['IMapleProxyFactory', 'IDefaultImplementationBeacon']
 
+-------------------------------------------------+------------+-----------+------+-------+----------------+----------------+
|                     Function                    | Visibility | Modifiers | Read | Write | Internal Calls | External Calls |
+-------------------------------------------------+------------+-----------+------+-------+----------------+----------------+
|                 defaultVersion()                |  external  |     []    |  []  |   []  |       []       |       []       |
|                  mapleGlobals()                 |  external  |     []    |  []  |   []  |       []       |       []       |
|      upgradeEnabledForPath(uint256,uint256)     |  external  |     []    |  []  |   []  |       []       |       []       |
|          createInstance(bytes,bytes32)          |  external  |     []    |  []  |   []  |       []       |       []       |
|    enableUpgradePath(uint256,uint256,address)   |  external  |     []    |  []  |   []  |       []       |       []       |
|       disableUpgradePath(uint256,uint256)       |  external  |     []    |  []  |   []  |       []       |       []       |
| registerImplementation(uint256,address,address) |  external  |     []    |  []  |   []  |       []       |       []       |
|            setDefaultVersion(uint256)           |  external  |     []    |  []  |   []  |       []       |       []       |
|               setGlobals(address)               |  external  |     []    |  []  |   []  |       []       |       []       |
|          upgradeInstance(uint256,bytes)         |  external  |     []    |  []  |   []  |       []       |       []       |
|        getInstanceAddress(bytes,bytes32)        |  external  |     []    |  []  |   []  |       []       |       []       |
|            implementationOf(uint256)            |  external  |     []    |  []  |   []  |       []       |       []       |
|         migratorForPath(uint256,uint256)        |  external  |     []    |  []  |   []  |       []       |       []       |
|                versionOf(address)               |  external  |     []    |  []  |   []  |       []       |       []       |
|             defaultImplementation()             |  external  |     []    |  []  |   []  |       []       |       []       |
|                 isLoan(address)                 |  external  |     []    |  []  |   []  |       []       |       []       |
+-------------------------------------------------+------------+-----------+------+-------+----------------+----------------+

+-----------+------------+------+-------+----------------+----------------+
| Modifiers | Visibility | Read | Write | Internal Calls | External Calls |
+-----------+------------+------+-------+----------------+----------------+
+-----------+------------+------+-------+----------------+----------------+


Contract ILenderLike
Contract vars: []
Inheritance:: []
 
+----------------+------------+-----------+------+-------+----------------+----------------+
|    Function    | Visibility | Modifiers | Read | Write | Internal Calls | External Calls |
+----------------+------------+-----------+------+-------+----------------+----------------+
| poolDelegate() |  external  |     []    |  []  |   []  |       []       |       []       |
+----------------+------------+-----------+------+-------+----------------+----------------+

+-----------+------------+------+-------+----------------+----------------+
| Modifiers | Visibility | Read | Write | Internal Calls | External Calls |
+-----------+------------+------+-------+----------------+----------------+
+-----------+------------+------+-------+----------------+----------------+


Contract IMapleGlobalsLike
Contract vars: []
Inheritance:: []
 
+------------------+------------+-----------+------+-------+----------------+----------------+
|     Function     | Visibility | Modifiers | Read | Write | Internal Calls | External Calls |
+------------------+------------+-----------+------+-------+----------------+----------------+
|  globalAdmin()   |  external  |     []    |  []  |   []  |       []       |       []       |
|    governor()    |  external  |     []    |  []  |   []  |       []       |       []       |
|  investorFee()   |  external  |     []    |  []  |   []  |       []       |       []       |
| mapleTreasury()  |  external  |     []    |  []  |   []  |       []       |       []       |
| protocolPaused() |  external  |     []    |  []  |   []  |       []       |       []       |
|  treasuryFee()   |  external  |     []    |  []  |   []  |       []       |       []       |
+------------------+------------+-----------+------+-------+----------------+----------------+

+-----------+------------+------+-------+----------------+----------------+
| Modifiers | Visibility | Read | Write | Internal Calls | External Calls |
+-----------+------------+------+-------+----------------+----------------+
+-----------+------------+------+-------+----------------+----------------+


Contract ERC20Helper
Contract vars: []
Inheritance:: []
 
+-----------------------------------------------+------------+-----------+------+-------+---------------------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------+
|                    Function                   | Visibility | Modifiers | Read | Write |             Internal Calls            |                                                                    External Calls                                                                   |
+-----------------------------------------------+------------+-----------+------+-------+---------------------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------+
|       transfer(address,address,uint256)       |  internal  |     []    |  []  |   []  | ['abi.encodeWithSelector()', '_call'] |                                         ['abi.encodeWithSelector(IERC20Like.transfer.selector,to_,amount_)']                                        |
| transferFrom(address,address,address,uint256) |  internal  |     []    |  []  |   []  | ['abi.encodeWithSelector()', '_call'] |                                    ['abi.encodeWithSelector(IERC20Like.transferFrom.selector,from_,to_,amount_)']                                   |
|        approve(address,address,uint256)       |  internal  |     []    |  []  |   []  | ['abi.encodeWithSelector()', '_call'] | ['abi.encodeWithSelector(IERC20Like.approve.selector,spender_,amount_)', 'abi.encodeWithSelector(IERC20Like.approve.selector,spender_,uint256(0))'] |
|              _call(address,bytes)             |  private   |     []    |  []  |   []  |   ['abi.decode()', 'code(address)']   |                                               ['token_.call(data_)', 'abi.decode(returnData,(bool))']                                               |
+-----------------------------------------------+------------+-----------+------+-------+---------------------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------+

+-----------+------------+------+-------+----------------+----------------+
| Modifiers | Visibility | Read | Write | Internal Calls | External Calls |
+-----------+------------+------+-------+----------------+----------------+
+-----------+------------+------+-------+----------------+----------------+


Contract IERC20Like
Contract vars: []
Inheritance:: []
 
+---------------------------------------+------------+-----------+------+-------+----------------+----------------+
|                Function               | Visibility | Modifiers | Read | Write | Internal Calls | External Calls |
+---------------------------------------+------------+-----------+------+-------+----------------+----------------+
|        approve(address,uint256)       |  external  |     []    |  []  |   []  |       []       |       []       |
|       transfer(address,uint256)       |  external  |     []    |  []  |   []  |       []       |       []       |
| transferFrom(address,address,uint256) |  external  |     []    |  []  |   []  |       []       |       []       |
+---------------------------------------+------------+-----------+------+-------+----------------+----------------+

+-----------+------------+------+-------+----------------+----------------+
| Modifiers | Visibility | Read | Write | Internal Calls | External Calls |
+-----------+------------+------+-------+----------------+----------------+
+-----------+------------+------+-------+----------------+----------------+


Contract IERC20
Contract vars: []
Inheritance:: []
 
+---------------------------------------------------------------+------------+-----------+------+-------+----------------+----------------+
|                            Function                           | Visibility | Modifiers | Read | Write | Internal Calls | External Calls |
+---------------------------------------------------------------+------------+-----------+------+-------+----------------+----------------+
|                    approve(address,uint256)                   |  external  |     []    |  []  |   []  |       []       |       []       |
|               decreaseAllowance(address,uint256)              |  external  |     []    |  []  |   []  |       []       |       []       |
|               increaseAllowance(address,uint256)              |  external  |     []    |  []  |   []  |       []       |       []       |
| permit(address,address,uint256,uint256,uint8,bytes32,bytes32) |  external  |     []    |  []  |   []  |       []       |       []       |
|                   transfer(address,uint256)                   |  external  |     []    |  []  |   []  |       []       |       []       |
|             transferFrom(address,address,uint256)             |  external  |     []    |  []  |   []  |       []       |       []       |
|                   allowance(address,address)                  |  external  |     []    |  []  |   []  |       []       |       []       |
|                       balanceOf(address)                      |  external  |     []    |  []  |   []  |       []       |       []       |
|                           decimals()                          |  external  |     []    |  []  |   []  |       []       |       []       |
|                       DOMAIN_SEPARATOR()                      |  external  |     []    |  []  |   []  |       []       |       []       |
|                             name()                            |  external  |     []    |  []  |   []  |       []       |       []       |
|                        nonces(address)                        |  external  |     []    |  []  |   []  |       []       |       []       |
|                       PERMIT_TYPEHASH()                       |  external  |     []    |  []  |   []  |       []       |       []       |
|                            symbol()                           |  external  |     []    |  []  |   []  |       []       |       []       |
|                         totalSupply()                         |  external  |     []    |  []  |   []  |       []       |       []       |
+---------------------------------------------------------------+------------+-----------+------+-------+----------------+----------------+

+-----------+------------+------+-------+----------------+----------------+
| Modifiers | Visibility | Read | Write | Internal Calls | External Calls |
+-----------+------------+------+-------+----------------+----------------+
+-----------+------------+------+-------+----------------+----------------+


Contract MapleProxiedInternals
Contract vars: ['FACTORY_SLOT', 'IMPLEMENTATION_SLOT']
Inheritance:: ['ProxiedInternals', 'SlotManipulatable']
 
+----------------------------------------+------------+-----------+-------------------------+-----------------------------------------+--------------------------------------------+----------------------------------------+
|                Function                | Visibility | Modifiers |           Read          |                  Write                  |               Internal Calls               |             External Calls             |
+----------------------------------------+------------+-----------+-------------------------+-----------------------------------------+--------------------------------------------+----------------------------------------+
|        _migrate(address,bytes)         |  internal  |     []    |            []           |                    []                   |                     []                     | ['migrator_.delegatecall(arguments_)'] |
|          _setFactory(address)          |  internal  |     []    |     ['FACTORY_SLOT']    |                    []                   |             ['_setSlotValue']              |                   []                   |
|      _setImplementation(address)       |  internal  |     []    | ['IMPLEMENTATION_SLOT'] |                    []                   |             ['_setSlotValue']              |                   []                   |
|               _factory()               |  internal  |     []    |     ['FACTORY_SLOT']    |                    []                   |             ['_getSlotValue']              |                   []                   |
|           _implementation()            |  internal  |     []    | ['IMPLEMENTATION_SLOT'] |                    []                   |             ['_getSlotValue']              |                   []                   |
| _getReferenceTypeSlot(bytes32,bytes32) |  internal  |     []    |            []           |                    []                   | ['abi.encodePacked()', 'keccak256(bytes)'] |    ['abi.encodePacked(key_,slot_)']    |
|         _getSlotValue(bytes32)         |  internal  |     []    |            []           |                    []                   |             ['sload(uint256)']             |                   []                   |
|     _setSlotValue(bytes32,bytes32)     |  internal  |     []    |            []           |                    []                   |        ['sstore(uint256,uint256)']         |                   []                   |
| slitherConstructorConstantVariables()  |  internal  |     []    |            []           | ['FACTORY_SLOT', 'IMPLEMENTATION_SLOT'] |                     []                     |                   []                   |
+----------------------------------------+------------+-----------+-------------------------+-----------------------------------------+--------------------------------------------+----------------------------------------+

+-----------+------------+------+-------+----------------+----------------+
| Modifiers | Visibility | Read | Write | Internal Calls | External Calls |
+-----------+------------+------+-------+----------------+----------------+
+-----------+------------+------+-------+----------------+----------------+


Contract IMapleProxyFactory
Contract vars: []
Inheritance:: ['IDefaultImplementationBeacon']
 
+-------------------------------------------------+------------+-----------+------+-------+----------------+----------------+
|                     Function                    | Visibility | Modifiers | Read | Write | Internal Calls | External Calls |
+-------------------------------------------------+------------+-----------+------+-------+----------------+----------------+
|             defaultImplementation()             |  external  |     []    |  []  |   []  |       []       |       []       |
|                 defaultVersion()                |  external  |     []    |  []  |   []  |       []       |       []       |
|                  mapleGlobals()                 |  external  |     []    |  []  |   []  |       []       |       []       |
|      upgradeEnabledForPath(uint256,uint256)     |  external  |     []    |  []  |   []  |       []       |       []       |
|          createInstance(bytes,bytes32)          |  external  |     []    |  []  |   []  |       []       |       []       |
|    enableUpgradePath(uint256,uint256,address)   |  external  |     []    |  []  |   []  |       []       |       []       |
|       disableUpgradePath(uint256,uint256)       |  external  |     []    |  []  |   []  |       []       |       []       |
| registerImplementation(uint256,address,address) |  external  |     []    |  []  |   []  |       []       |       []       |
|            setDefaultVersion(uint256)           |  external  |     []    |  []  |   []  |       []       |       []       |
|               setGlobals(address)               |  external  |     []    |  []  |   []  |       []       |       []       |
|          upgradeInstance(uint256,bytes)         |  external  |     []    |  []  |   []  |       []       |       []       |
|        getInstanceAddress(bytes,bytes32)        |  external  |     []    |  []  |   []  |       []       |       []       |
|            implementationOf(uint256)            |  external  |     []    |  []  |   []  |       []       |       []       |
|         migratorForPath(uint256,uint256)        |  external  |     []    |  []  |   []  |       []       |       []       |
|                versionOf(address)               |  external  |     []    |  []  |   []  |       []       |       []       |
+-------------------------------------------------+------------+-----------+------+-------+----------------+----------------+

+-----------+------------+------+-------+----------------+----------------+
| Modifiers | Visibility | Read | Write | Internal Calls | External Calls |
+-----------+------------+------+-------+----------------+----------------+
+-----------+------------+------+-------+----------------+----------------+


Contract ProxiedInternals
Contract vars: ['FACTORY_SLOT', 'IMPLEMENTATION_SLOT']
Inheritance:: ['SlotManipulatable']
 
+----------------------------------------+------------+-----------+-------------------------+-----------------------------------------+--------------------------------------------+----------------------------------------+
|                Function                | Visibility | Modifiers |           Read          |                  Write                  |               Internal Calls               |             External Calls             |
+----------------------------------------+------------+-----------+-------------------------+-----------------------------------------+--------------------------------------------+----------------------------------------+
| _getReferenceTypeSlot(bytes32,bytes32) |  internal  |     []    |            []           |                    []                   | ['abi.encodePacked()', 'keccak256(bytes)'] |    ['abi.encodePacked(key_,slot_)']    |
|         _getSlotValue(bytes32)         |  internal  |     []    |            []           |                    []                   |             ['sload(uint256)']             |                   []                   |
|     _setSlotValue(bytes32,bytes32)     |  internal  |     []    |            []           |                    []                   |        ['sstore(uint256,uint256)']         |                   []                   |
|        _migrate(address,bytes)         |  internal  |     []    |            []           |                    []                   |                     []                     | ['migrator_.delegatecall(arguments_)'] |
|          _setFactory(address)          |  internal  |     []    |     ['FACTORY_SLOT']    |                    []                   |             ['_setSlotValue']              |                   []                   |
|      _setImplementation(address)       |  internal  |     []    | ['IMPLEMENTATION_SLOT'] |                    []                   |             ['_setSlotValue']              |                   []                   |
|               _factory()               |  internal  |     []    |     ['FACTORY_SLOT']    |                    []                   |             ['_getSlotValue']              |                   []                   |
|           _implementation()            |  internal  |     []    | ['IMPLEMENTATION_SLOT'] |                    []                   |             ['_getSlotValue']              |                   []                   |
| slitherConstructorConstantVariables()  |  internal  |     []    |            []           | ['FACTORY_SLOT', 'IMPLEMENTATION_SLOT'] |                     []                     |                   []                   |
+----------------------------------------+------------+-----------+-------------------------+-----------------------------------------+--------------------------------------------+----------------------------------------+

+-----------+------------+------+-------+----------------+----------------+
| Modifiers | Visibility | Read | Write | Internal Calls | External Calls |
+-----------+------------+------+-------+----------------+----------------+
+-----------+------------+------+-------+----------------+----------------+


Contract SlotManipulatable
Contract vars: []
Inheritance:: []
 
+----------------------------------------+------------+-----------+------+-------+--------------------------------------------+----------------------------------+
|                Function                | Visibility | Modifiers | Read | Write |               Internal Calls               |          External Calls          |
+----------------------------------------+------------+-----------+------+-------+--------------------------------------------+----------------------------------+
| _getReferenceTypeSlot(bytes32,bytes32) |  internal  |     []    |  []  |   []  | ['abi.encodePacked()', 'keccak256(bytes)'] | ['abi.encodePacked(key_,slot_)'] |
|         _getSlotValue(bytes32)         |  internal  |     []    |  []  |   []  |             ['sload(uint256)']             |                []                |
|     _setSlotValue(bytes32,bytes32)     |  internal  |     []    |  []  |   []  |        ['sstore(uint256,uint256)']         |                []                |
+----------------------------------------+------------+-----------+------+-------+--------------------------------------------+----------------------------------+

+-----------+------------+------+-------+----------------+----------------+
| Modifiers | Visibility | Read | Write | Internal Calls | External Calls |
+-----------+------------+------+-------+----------------+----------------+
+-----------+------------+------+-------+----------------+----------------+


Contract IDefaultImplementationBeacon
Contract vars: []
Inheritance:: []
 
+-------------------------+------------+-----------+------+-------+----------------+----------------+
|         Function        | Visibility | Modifiers | Read | Write | Internal Calls | External Calls |
+-------------------------+------------+-----------+------+-------+----------------+----------------+
| defaultImplementation() |  external  |     []    |  []  |   []  |       []       |       []       |
+-------------------------+------------+-----------+------+-------+----------------+----------------+

+-----------+------------+------+-------+----------------+----------------+
| Modifiers | Visibility | Read | Write | Internal Calls | External Calls |
+-----------+------------+------+-------+----------------+----------------+
+-----------+------------+------+-------+----------------+----------------+

modules/loan-v301/contracts/MapleLoanInternals.sol analyzed (12 contracts)
