pragma solidity ^0.4.23;

/**
 * @title ERC20Basic
 * @notice Simpler version of ERC20 interface
 * @notice see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @notice see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeMath
 * @notice Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @notice Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @notice Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @notice Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @notice Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Basic token
 * @notice Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @notice total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @notice transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @notice Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

/**
 * @title Standard ERC20 token
 *
 * @notice Implementation of the basic standard token.
 * @notice https://github.com/ethereum/EIPs/issues/20
 * @notice Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @notice Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @notice Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @notice Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @notice Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  function DetailedERC20(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

contract IST20 is StandardToken, DetailedERC20 {

    // off-chain hash
    string public tokenDetails;

    //transfer, transferFrom must respect use respect the result of verifyTransfer
    function verifyTransfer(address _from, address _to, uint256 _amount) public returns (bool success);

    /**
     * @notice mints new tokens and assigns them to the target _investor.
     * Can only be called by the STO attached to the token (Or by the ST owner if there's no STO attached yet)
     */
    function mint(address _investor, uint256 _amount) public returns (bool success);

    /**
     * @notice Burn function used to burn the securityToken
     * @param _value No. of token that get burned     
     */
    function burn(uint256 _value) public;

    event Minted(address indexed to, uint256 amount);
    event Burnt(address indexed _burner, uint256 _value);

}

/**
 * @title Ownable
 * @notice The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @notice The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @notice Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @notice Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ISecurityToken is IST20, Ownable {

    uint8 public constant PERMISSIONMANAGER_KEY = 1;
    uint8 public constant TRANSFERMANAGER_KEY = 2;
    uint8 public constant STO_KEY = 3;
    uint8 public constant CHECKPOINT_KEY = 4;
    uint256 public granularity;
    // Total number of non-zero token holders
    uint256 public investorCount;

    // Permissions this to a Permission module, which has a key of 1
    // If no Permission return false - note that IModule withPerm will allow ST owner all permissions anyway
    // this allows individual modules to override this logic if needed (to not allow ST owner all permissions)
    function checkPermission(address _delegate, address _module, bytes32 _perm) public view returns(bool);

    /**
     * @notice returns module list for a module type
     * @param _moduleType is which type of module we are trying to remove
     * @param _moduleIndex is the index of the module within the chosen type
     */
    function getModule(uint8 _moduleType, uint _moduleIndex) public view returns (bytes32, address, bool);

    /**
     * @notice returns module list for a module name - will return first match
     * @param _moduleType is which type of module we are trying to remove
     * @param _name is the name of the module within the chosen type
     */
    function getModuleByName(uint8 _moduleType, bytes32 _name) public view returns (bytes32, address, bool);

    /**
     * @notice Queries totalSupply as of a defined checkpoint
     * @param _checkpointId Checkpoint ID to query as of
     */
    function totalSupplyAt(uint256 _checkpointId) public view returns(uint256);

    /**
     * @notice Queries balances as of a defined checkpoint
     * @param _investor Investor to query balance for
     * @param _checkpointId Checkpoint ID to query as of
     */
    function balanceOfAt(address _investor, uint256 _checkpointId) public view returns(uint256);

}

//Simple interface that any module contracts should implement
contract IModuleFactory is Ownable {

    ERC20 public polyToken;

    /**
     * @notice Constructor
     * @param _polyAddress Address of the polytoken
     */
    constructor (address _polyAddress) public {
      polyToken = ERC20(_polyAddress);
    }

    //Should create an instance of the Module, or throw
    function deploy(bytes _data) external returns(address);

    /**
     * @notice Type of the Module factory
     */
    function getType() public view returns(uint8);

    /**
     * @notice Get the name of the Module
     */
    function getName() public view returns(bytes32);

    //Return the cost (in POLY) to use this factory
    function getCost() public view returns(uint256);

    /**
     * @notice Get the description of the Module 
     */
    function getDescription() public view returns(string);

    /**
     * @notice Get the title of the Module
     */
    function getTitle() public view returns(string);

    /**
     * @notice Get the Instructions that helped to used the module
     */
    function getInstructions() public view returns (string);
    
    /**
     * @notice Get the tags related to the module factory
     */
    function getTags() public view returns (bytes32[]);

    //Pull function sig from _data
    function getSig(bytes _data) internal pure returns (bytes4 sig) {
        uint len = _data.length < 4 ? _data.length : 4;
        for (uint i = 0; i < len; i++) {
            sig = bytes4(uint(sig) + uint(_data[i]) * (2 ** (8 * (len - 1 - i))));
        }
    }

}

//Simple interface that any module contracts should implement
contract IModule {

    address public factory;

    address public securityToken;

    bytes32 public FEE_ADMIN = "FEE_ADMIN";

    ERC20 public polyToken;

    /**
     * @notice Constructor
     * @param _securityToken Address of the security token
     * @param _polyAddress Address of the polytoken
     */
    constructor (address _securityToken, address _polyAddress) public {
        securityToken = _securityToken;
        factory = msg.sender;
        polyToken = ERC20(_polyAddress);
    }

    /**
     * @notice This function returns the signature of configure function 
     */
    function getInitFunction() public returns (bytes4);

    //Allows owner, factory or permissioned delegate
    modifier withPerm(bytes32 _perm) {
        bool isOwner = msg.sender == ISecurityToken(securityToken).owner();
        bool isFactory = msg.sender == factory;
        require(isOwner||isFactory||ISecurityToken(securityToken).checkPermission(msg.sender, address(this), _perm), "Permission check failed");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == ISecurityToken(securityToken).owner(), "Sender is not owner");
        _;
    }

    modifier onlyFactory {
        require(msg.sender == factory, "Sender is not factory");
        _;
    }

    modifier onlyFactoryOwner {
        require(msg.sender == IModuleFactory(factory).owner(), "Sender is not factory owner");
        _;
    }

    /**
     * @notice Return the permissions flag that are associated with Module
     */
    function getPermissions() public view returns(bytes32[]);

    /**
     * @notice used to withdraw the fee by the factory owner
     */
    function takeFee(uint256 _amount) public withPerm(FEE_ADMIN) returns(bool) {
        require(polyToken.transferFrom(address(this), IModuleFactory(factory).owner(), _amount), "Unable to take fee");
        return true;
    }
}

//Simple interface that any module contracts should implement
contract IModuleRegistry {

    /**
     * @notice Called by a security token to notify the registry it is using a module
     * @param _moduleFactory is the address of the relevant module factory
     */
    function useModule(address _moduleFactory) external;

    /**
     * @notice Called by moduleFactory owner to register new modules for SecurityToken to use
     * @param _moduleFactory is the address of the module factory to be registered
     */
    function registerModule(address _moduleFactory) external returns(bool);

    /**
     * @notice Use to get all the tags releated to the functionality of the Module Factory.
     * @param _moduleType Type of module
     */
    function getTagByModuleType(uint8 _moduleType) public view returns(bytes32[]);

}

contract ITransferManager is IModule {

    //If verifyTransfer returns:
    //  INVALID, then the transfer should not be allowed regardless of other TM results
    //  NA, then the result from this TM is ignored
    //  VALID, then the transfer is valid for this TM
    enum Result {INVALID, NA, VALID}

    function verifyTransfer(address _from, address _to, uint256 _amount, bool _isTransfer) public returns(Result);

    event Pause(uint256 _timestammp);
    event Unpause(uint256 _timestamp);

    bool public paused = false;

    /**
    * @notice called by the owner to pause, triggers stopped state
    */
    function pause() onlyOwner public {
      require(!paused);
      paused = true;
      emit Pause(now);
    }

    /**
    * @notice called by the owner to unpause, returns to normal state
    */
    function unpause() onlyOwner public {
      require(paused);
      paused = false;
      emit Unpause(now);
    }

}

contract IPermissionManager is IModule {

    function checkPermission(address _delegate, address _module, bytes32 _perm) public view returns(bool);

    function changePermission(address _delegate, address _module, bytes32 _perm, bool _valid) public returns(bool);

    function getDelegateDetails(address _delegate) public view returns(bytes32);

}

contract ISecurityTokenRegistry {

    address public polyAddress;

    address public moduleRegistry;
    address public tickerRegistry;

    bytes32 public protocolVersion = "0.0.1";
    mapping (bytes32 => address) public protocolVersionST;

    struct SecurityTokenData {
        string symbol;
        string tokenDetails;
    }

    mapping(address => SecurityTokenData) securityTokens;
    mapping(string => address) symbols;

    /**
     * @notice Creates a new Security Token and saves it to the registry
     * @param _name Name of the token
     * @param _symbol Ticker symbol of the security token
     * @param _tokenDetails off-chain details of the token
     */
    function generateSecurityToken(string _name, string _symbol, string _tokenDetails, bool _divisible) public;

    function setProtocolVersion(address _stVersionProxyAddress, bytes32 _version) public;

    //////////////////////////////
    ///////// Get Functions
    //////////////////////////////
    /**
     * @notice Get security token address by ticker name
     * @param _symbol Symbol of the Scurity token
     * @return address _symbol
     */
    function getSecurityTokenAddress(string _symbol) public view returns (address);

     /**
     * @notice Get security token data by its address
     * @param _securityToken Address of the Scurity token
     * @return string, address, bytes32
     */
    function getSecurityTokenData(address _securityToken) public view returns (string, address, string);

    /**
    * @notice Check that Security Token is registered
    * @param _securityToken Address of the Scurity token
    * @return bool
    */
    function isSecurityToken(address _securityToken) public view returns (bool);
}

interface ITokenBurner {

    function burn(address _burner, uint256  _value ) external returns(bool);

}

/**
* @title SecurityToken
* @notice SecurityToken is an ERC20 token with added capabilities:
* - Implements the ST-20 Interface
* - Transfers are restricted
* - Modules can be attached to it to control its behaviour
* - ST should not be deployed directly, but rather the SecurityTokenRegistry should be used
*/
contract SecurityToken is ISecurityToken {
    using SafeMath for uint256;

    bytes32 public securityTokenVersion = "0.0.1";

    // Reference to token burner contract
    ITokenBurner public tokenBurner;

    // Use to halt all the transactions
    bool public freeze = false;
    // Reference to the POLY token.
    ERC20 public polyToken;

    struct ModuleData {
        bytes32 name;
        address moduleAddress;
    }

    // Structures to maintain checkpoints of balances for governance / dividends
    struct Checkpoint {
        uint256 checkpointId;
        uint256 value;
    }

    mapping (address => Checkpoint[]) public checkpointBalances;
    Checkpoint[] public checkpointTotalSupply;
    uint256 public currentCheckpointId;

    address public moduleRegistry;

    mapping (bytes4 => bool) transferFunctions;

    // Module list should be order agnostic!
    mapping (uint8 => ModuleData[]) public modules;
    mapping (uint8 => bool) public modulesLocked;

    uint8 public constant MAX_MODULES = 20;

    // Emit at the time when module get added
    event LogModuleAdded(
        uint8 indexed _type,
        bytes32 _name,
        address _moduleFactory,
        address _module,
        uint256 _moduleCost,
        uint256 _budget,
        uint256 _timestamp
    );

    // Emit when the token details get updated
    event LogUpdateTokenDetails(string _oldDetails, string _newDetails);
    // Emit when the granularity get changed
    event LogGranularityChanged(uint256 _oldGranularity, uint256 _newGranularity);
    // Emit when Module get removed from the securityToken
    event LogModuleRemoved(uint8 indexed _type, address _module, uint256 _timestamp);
    event LogModuleBudgetChanged(uint8 indexed _moduleType, address _module, uint256 _budget);
    // Emit when all the transfers get freeze
    event LogFreezeTransfers(bool _freeze, uint256 _timestamp);
    // Emit when new checkpoint created
    event LogCheckpointCreated(uint256 _checkpointId, uint256 _timestamp);

    //if _fallback is true, then we only allow the module if it is set, if it is not set we only allow the owner
    modifier onlyModule(uint8 _moduleType, bool _fallback) {
      //Loop over all modules of type _moduleType
        bool isModuleType = false;
        for (uint8 i = 0; i < modules[_moduleType].length; i++) {
            isModuleType = isModuleType || (modules[_moduleType][i].moduleAddress == msg.sender);
        }
        if (_fallback && !isModuleType) {
            require(msg.sender == owner, "Sender is not owner");
        } else {
            require(isModuleType, "Sender is not correct module type");
        }
        _;
    }

    modifier checkGranularity(uint256 _amount) {
        require(_amount.div(granularity).mul(granularity) == _amount, "Unable to modify token balances at this granularity");
        _;
    }

    /**
     * @notice Constructor
     * @param _name Name of the SecurityToken
     * @param _symbol Symbol of the Token
     * @param _decimals Decimals for the securityToken
     * @param _granularity granular level of the token
     * @param _tokenDetails Details of the token that are stored off-chain (IPFS hash)
     * @param _securityTokenRegistry Contract address of the security token registry
     */
    constructor (
        string _name,
        string _symbol,
        uint8 _decimals,
        uint256 _granularity,
        string _tokenDetails,
        address _securityTokenRegistry
    )
    public
    DetailedERC20(_name, _symbol, _decimals)
    {
        //When it is created, the owner is the STR
        moduleRegistry = ISecurityTokenRegistry(_securityTokenRegistry).moduleRegistry();
        polyToken = ERC20(ISecurityTokenRegistry(_securityTokenRegistry).polyAddress());
        tokenDetails = _tokenDetails;
        granularity = _granularity;
        transferFunctions[bytes4(keccak256("transfer(address,uint256)"))] = true;
        transferFunctions[bytes4(keccak256("transferFrom(address,address,uint256)"))] = true;
        transferFunctions[bytes4(keccak256("mint(address,uint256)"))] = true;
        transferFunctions[bytes4(keccak256("burn(uint256)"))] = true;
    }

    /**
     * @notice Function used to attach the module in security token
     * @param _moduleFactory Contract address of the module factory that needs to be attached
     * @param _data Data used for the intialization of the module factory variables
     * @param _maxCost Maximum cost of the Module factory
     * @param _budget Budget of the Module factory
     * @param _locked whether or not the module is supposed to be locked
     */
    function addModule(
        address _moduleFactory,
        bytes _data,
        uint256 _maxCost,
        uint256 _budget,
        bool _locked
    ) external onlyOwner {
        _addModule(_moduleFactory, _data, _maxCost, _budget, _locked);
    }

    /**
    * @notice _addModule handles the attachment (or replacement) of modules for the ST
    * E.G.: On deployment (through the STR) ST gets a TransferManager module attached to it
    * to control restrictions on transfers.
    * @param _moduleFactory is the address of the module factory to be added
    * @param _data is data packed into bytes used to further configure the module (See STO usage)
    * @param _maxCost max amount of POLY willing to pay to module. (WIP)
    * @param _locked whether or not the module is supposed to be locked
    */
    //You are allowed to add a new moduleType if:
    //  - there is no existing module of that type yet added
    //  - the last member of the module list is replacable
    function _addModule(address _moduleFactory, bytes _data, uint256 _maxCost, uint256 _budget, bool _locked) internal {
        //Check that module exists in registry - will throw otherwise
        IModuleRegistry(moduleRegistry).useModule(_moduleFactory);
        IModuleFactory moduleFactory = IModuleFactory(_moduleFactory);
        require(modules[moduleFactory.getType()].length < MAX_MODULES, "Limit of MAX MODULES is reached");
        uint256 moduleCost = moduleFactory.getCost();
        require(moduleCost <= _maxCost, "Max Cost is always be greater than module cost");
        //Check that this module has not already been set as locked
        require(!modulesLocked[moduleFactory.getType()], "Module has already been set as locked");
        //Approve fee for module
        require(polyToken.approve(_moduleFactory, moduleCost), "Not able to approve the module cost");
        //Creates instance of module from factory
        address module = moduleFactory.deploy(_data);
        //Approve ongoing budget
        require(polyToken.approve(module, _budget), "Not able to approve the budget");
        //Add to SecurityToken module map
        modules[moduleFactory.getType()].push(ModuleData(moduleFactory.getName(), module));
        modulesLocked[moduleFactory.getType()] = _locked;
        //Emit log event
        emit LogModuleAdded(moduleFactory.getType(), moduleFactory.getName(), _moduleFactory, module, moduleCost, _budget, now);
    }

    /**
    * @notice removes a module attached to the SecurityToken
    * @param _moduleType is which type of module we are trying to remove
    * @param _moduleIndex is the index of the module within the chosen type
    */
    function removeModule(uint8 _moduleType, uint8 _moduleIndex) external onlyOwner {
        require(_moduleIndex < modules[_moduleType].length,
        "Module index doesn't exist as per the choosen module type");
        require(modules[_moduleType][_moduleIndex].moduleAddress != address(0),
        "Module contract address should not be 0x");
        require(!modulesLocked[_moduleType], "Module should not be locked");
        //Take the last member of the list, and replace _moduleIndex with this, then shorten the list by one
        emit LogModuleRemoved(_moduleType, modules[_moduleType][_moduleIndex].moduleAddress, now);
        modules[_moduleType][_moduleIndex] = modules[_moduleType][modules[_moduleType].length - 1];
        modules[_moduleType].length = modules[_moduleType].length - 1;
    }

    /**
     * @notice returns module list for a module type
     * @param _moduleType is which type of module we are trying to remove
     * @param _moduleIndex is the index of the module within the chosen type
     */
    function getModule(uint8 _moduleType, uint _moduleIndex) public view returns (bytes32, address, bool) {
        if (modules[_moduleType].length > 0) {
            return (
                modules[_moduleType][_moduleIndex].name,
                modules[_moduleType][_moduleIndex].moduleAddress,
                modulesLocked[_moduleType]
            );
        } else {
            return ("", address(0), false);
        }

    }

    /**
     * @notice returns module list for a module name - will return first match
     * @param _moduleType is which type of module we are trying to remove
     * @param _name is the name of the module within the chosen type
     */
    function getModuleByName(uint8 _moduleType, bytes32 _name) public view returns (bytes32, address, bool) {
        if (modules[_moduleType].length > 0) {
            for (uint256 i = 0; i < modules[_moduleType].length; i++) {
                if (modules[_moduleType][i].name == _name) {
                  return (
                      modules[_moduleType][i].name,
                      modules[_moduleType][i].moduleAddress,
                      modulesLocked[_moduleType]
                  );
                }
            }
            return ("", address(0), false);
        } else {
            return ("", address(0), false);
        }
    }

    /**
    * @notice allows the owner to withdraw unspent POLY stored by them on the ST.
    * Owner can transfer POLY to the ST which will be used to pay for modules that require a POLY fee.
    */
    function withdrawPoly(uint256 _amount) public onlyOwner {
        require(polyToken.transfer(owner, _amount), "In-sufficient balance");
    }

    /**
    * @notice allows owner to approve more POLY to one of the modules
    */
    function changeModuleBudget(uint8 _moduleType, uint8 _moduleIndex, uint256 _budget) public onlyOwner {
        require(_moduleType != 0, "Module type cannot be zero");
        require(_moduleIndex < modules[_moduleType].length, "Incorrrect module index");
        require(polyToken.approve(modules[_moduleType][_moduleIndex].moduleAddress, _budget), "Insufficient balance to approve");
        emit LogModuleBudgetChanged(_moduleType, modules[_moduleType][_moduleIndex].moduleAddress, _budget);
    }

    /**
     * @notice change the tokenDetails
     */
    function updateTokenDetails(string _newTokenDetails) public onlyOwner {
        emit LogUpdateTokenDetails(tokenDetails, _newTokenDetails);
        tokenDetails = _newTokenDetails;
    }

    /**
    * @notice allows owner to change token granularity
    */
    function changeGranularity(uint256 _granularity) public onlyOwner {
        require(_granularity != 0, "Granularity can not be 0");
        emit LogGranularityChanged(granularity, _granularity);
        granularity = _granularity;
    }

    /**
    * @notice keeps track of the number of non-zero token holders
    */
    function adjustInvestorCount(address _from, address _to, uint256 _value) internal {
        if ((_value == 0) || (_from == _to)) {
            return;
        }
        // Check whether receiver is a new token holder
        if ((balanceOf(_to) == 0) && (_to != address(0))) {
            investorCount = investorCount.add(1);
        }
        // Check whether sender is moving all of their tokens
        if (_value == balanceOf(_from)) {
            investorCount = investorCount.sub(1);
        }
    }

    /**
     * @notice freeze all the transfers
     */
    function freezeTransfers() public onlyOwner {
        require(!freeze);
        freeze = true;
        emit LogFreezeTransfers(freeze, now);
    }

    /**
     * @notice un-freeze all the transfers
     */
    function unfreezeTransfers() public onlyOwner {
        require(freeze);
        freeze = false;
        emit LogFreezeTransfers(freeze, now);
    }

    function adjustTotalSupplyCheckpoints() internal {
      //No checkpoints set yet
      if (currentCheckpointId == 0) {
          return;
      }
      //No previous checkpoint data - add current balance against checkpoint
      if (checkpointTotalSupply.length == 0) {
          checkpointTotalSupply.push(
              Checkpoint({
                  checkpointId: currentCheckpointId,
                  value: totalSupply()
              })
          );
          return;
      }
      //No new checkpoints since last update
      if (checkpointTotalSupply[checkpointTotalSupply.length - 1].checkpointId == currentCheckpointId) {
          return;
      }
      //New checkpoint, so record balance
      checkpointTotalSupply.push(
          Checkpoint({
              checkpointId: currentCheckpointId,
              value: totalSupply()
          })
      );
    }

    function adjustBalanceCheckpoints(address _investor) internal {
        //No checkpoints set yet
        if (currentCheckpointId == 0) {
            return;
        }
        //No previous checkpoint data - add current balance against checkpoint
        if (checkpointBalances[_investor].length == 0) {
            checkpointBalances[_investor].push(
                Checkpoint({
                    checkpointId: currentCheckpointId,
                    value: balanceOf(_investor)
                })
            );
            return;
        }
        //No new checkpoints since last update
        if (checkpointBalances[_investor][checkpointBalances[_investor].length - 1].checkpointId == currentCheckpointId) {
            return;
        }
        //New checkpoint, so record balance
        checkpointBalances[_investor].push(
            Checkpoint({
                checkpointId: currentCheckpointId,
                value: balanceOf(_investor)
            })
        );
    }

    /**
     * @notice Overloaded version of the transfer function
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        adjustInvestorCount(msg.sender, _to, _value);
        require(verifyTransfer(msg.sender, _to, _value), "Transfer is not valid");
        adjustBalanceCheckpoints(msg.sender);
        adjustBalanceCheckpoints(_to);
        require(super.transfer(_to, _value));
        return true;
    }

    /**
     * @notice Overloaded version of the transferFrom function
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        adjustInvestorCount(_from, _to, _value);
        require(verifyTransfer(_from, _to, _value), "Transfer is not valid");
        adjustBalanceCheckpoints(_from);
        adjustBalanceCheckpoints(_to);
        require(super.transferFrom(_from, _to, _value));
        return true;
    }

    // Permissions this to a TransferManager module, which has a key of 2
    // If no TransferManager return true
    function verifyTransfer(address _from, address _to, uint256 _amount) public checkGranularity(_amount) returns (bool) {
        if (!freeze) {
            bool isTransfer = false;
            if (transferFunctions[getSig(msg.data)]) {
              isTransfer = true;
            }
            if (modules[TRANSFERMANAGER_KEY].length == 0) {
                return true;
            }
            bool success = false;
            for (uint8 i = 0; i < modules[TRANSFERMANAGER_KEY].length; i++) {
                ITransferManager.Result valid = ITransferManager(modules[TRANSFERMANAGER_KEY][i].moduleAddress).verifyTransfer(_from, _to, _amount, isTransfer);
                if (valid == ITransferManager.Result.INVALID) {
                    return false;
                }
                if (valid == ITransferManager.Result.VALID) {
                    success = true;
                }
            }
            return success;
      }
      return false;
    }

    /**
     * @notice mints new tokens and assigns them to the target _investor.
     * Can only be called by the STO attached to the token (Or by the ST owner if there's no STO attached yet)
     * @param _investor Address to whom the minted tokens will be dilivered
     * @param _amount Number of tokens get minted
     * @return success
     */
    function mint(address _investor, uint256 _amount) public onlyModule(STO_KEY, true) checkGranularity(_amount) returns (bool success) {
        adjustInvestorCount(address(0), _investor, _amount);
        require(verifyTransfer(address(0), _investor, _amount), "Transfer is not valid");
        adjustTotalSupplyCheckpoints();
        totalSupply_ = totalSupply_.add(_amount);
        balances[_investor] = balances[_investor].add(_amount);
        emit Minted(_investor, _amount);
        emit Transfer(address(0), _investor, _amount);
        return true;
    }

    /**
     * @notice mints new tokens and assigns them to the target _investor.
     * Can only be called by the STO attached to the token (Or by the ST owner if there's no STO attached yet)
     * @param _investors A list of addresses to whom the minted tokens will be dilivered
     * @param _amounts A list of number of tokens get minted and transfer to corresponding address of the investor from _investor[] list
     * @return success
     */
    function mintMulti(address[] _investors, uint256[] _amounts) public onlyModule(STO_KEY, true) returns (bool success) {
        require(_investors.length == _amounts.length, "Mis-match in the length of the arrays");
        for (uint256 i = 0; i < _investors.length; i++) {
            mint(_investors[i], _amounts[i]);
        }
        return true;
    }

    // Permissions this to a Permission module, which has a key of 1
    // If no Permission return false - note that IModule withPerm will allow ST owner all permissions anyway
    // this allows individual modules to override this logic if needed (to not allow ST owner all permissions)
    function checkPermission(address _delegate, address _module, bytes32 _perm) public view returns(bool) {
        if (modules[PERMISSIONMANAGER_KEY].length == 0) {
            return false;
        }

        for (uint8 i = 0; i < modules[PERMISSIONMANAGER_KEY].length; i++) {
            if (IPermissionManager(modules[PERMISSIONMANAGER_KEY][i].moduleAddress).checkPermission(_delegate, _module, _perm)) {
                return true;
            }
        }
    }

    /**
     * @notice used to set the token Burner address. It only be called by the owner
     * @param _tokenBurner Address of the token burner contract
     */
    function setTokenBurner(address _tokenBurner) public onlyOwner {
        tokenBurner = ITokenBurner(_tokenBurner);
    }

    /**
     * @notice Burn function used to burn the securityToken
     * @param _value No. of token that get burned
     */
    function burn(uint256 _value) checkGranularity(_value) public {
        adjustInvestorCount(msg.sender, address(0), _value);
        require(tokenBurner != address(0), "Token Burner contract address is not set yet");
        require(verifyTransfer(msg.sender, address(0), _value), "Transfer is not valid");
        require(_value <= balances[msg.sender], "Value should no be greater than the balance of msg.sender");
        adjustTotalSupplyCheckpoints();
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        balances[msg.sender] = balances[msg.sender].sub(_value);
        require(tokenBurner.burn(msg.sender, _value), "Token burner process is not validated");
        totalSupply_ = totalSupply_.sub(_value);
        emit Burnt(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
    }

    //Pull function sig from _data
    function getSig(bytes _data) internal pure returns (bytes4 sig) {
        uint len = _data.length < 4 ? _data.length : 4;
        for (uint i = 0; i < len; i++) {
            sig = bytes4(uint(sig) + uint(_data[i]) * (2 ** (8 * (len - 1 - i))));
        }
    }

    /**
     * @notice Creates a checkpoint that can be used to query historical balances / totalSuppy
     */
    function createCheckpoint() public onlyModule(CHECKPOINT_KEY, true) {
        require(currentCheckpointId < 2**256 - 1);
        currentCheckpointId = currentCheckpointId + 1;
        emit LogCheckpointCreated(currentCheckpointId, now);
    }

    /**
     * @notice Queries totalSupply as of a defined checkpoint
     * @param _checkpointId Checkpoint ID to query as of
     */
    function totalSupplyAt(uint256 _checkpointId) public view returns(uint256) {
        return getValueAt(checkpointTotalSupply, _checkpointId, totalSupply());
    }

    function getValueAt(Checkpoint[] storage checkpoints, uint256 _checkpointId, uint256 _currentValue) internal view returns(uint256) {
        require(_checkpointId <= currentCheckpointId);
        //Checkpoint id 0 is when the token is first created - everyone has a zero balance
        if (_checkpointId == 0) {
          return 0;
        }
        if (checkpoints.length == 0) {
            return _currentValue;
        }
        if (checkpoints[0].checkpointId >= _checkpointId) {
            return checkpoints[0].value;
        }
        if (checkpoints[checkpoints.length - 1].checkpointId < _checkpointId) {
            return _currentValue;
        }
        if (checkpoints[checkpoints.length - 1].checkpointId == _checkpointId) {
            return checkpoints[checkpoints.length - 1].value;
        }
        uint256 min = 0;
        uint256 max = checkpoints.length - 1;
        while (max > min) {
            uint256 mid = (max + min) / 2;
            if (checkpoints[mid].checkpointId == _checkpointId) {
                max = mid;
                break;
            }
            if (checkpoints[mid].checkpointId < _checkpointId) {
                min = mid + 1;
            } else {
                max = mid;
            }
        }
        return checkpoints[max].value;
    }

    /**
     * @notice Queries balances as of a defined checkpoint
     * @param _investor Investor to query balance for
     * @param _checkpointId Checkpoint ID to query as of
     */
    function balanceOfAt(address _investor, uint256 _checkpointId) public view returns(uint256) {
        return getValueAt(checkpointBalances[_investor], _checkpointId, balanceOf(_investor));
    }

}

/**
* @title SecurityToken V2
* @notice Mockup of how an upgrade of SecurityToken would look like
*/
contract SecurityTokenV2 is SecurityToken {
    bytes32 public securityTokenVersion = "0.0.2";

     /**
     * @notice Constructor
     * @param _name Name of the SecurityToken
     * @param _symbol Symbol of the Token
     * @param _decimals Decimals for the securityToken
     * @param _granularity granular level of the token
     * @param _tokenDetails Details of the token that are stored offchain (IPFS hash)
     * @param _securityTokenRegistry Contract address of the security token registry
     */
    constructor (
        string _name,
        string _symbol,
        uint8 _decimals,
        uint256 _granularity,
        string _tokenDetails,
        address _securityTokenRegistry
    )
    public
    SecurityToken(
    _name,
    _symbol,
    _decimals,
    _granularity,
    _tokenDetails,
    _securityTokenRegistry)
    {
    }
}

contract ITickerRegistry {
    /**
    * @notice Check the validity of the symbol
    * @param _symbol token symbol
    * @param _owner address of the owner
    * @param _tokenName Name of the token
    * @return bool
    */
    function checkValidity(string _symbol, address _owner, string _tokenName) public returns(bool);

    /**
    * @notice Returns the owner and timestamp for a given symbol
    * @param _symbol symbol
    */
    function getDetails(string _symbol) public view returns (address, uint256, string, bytes32, bool);

    /**
     * @notice Check the symbol is reserved or not
     * @param _symbol Symbol of the token
     * @return bool 
     */
     function isReserved(string _symbol, address _owner, string _tokenName, bytes32 _swarmHash) public returns(bool);

}

contract ISTProxy {


    /**
     * @notice deploys the token and adds default modules like permission manager and transfer manager.
     * Future versions of the proxy can attach different modules or pass some other paramters.
     */
    function deployToken(string _name, string _symbol, uint8 _decimals, string _tokenDetails, address _issuer, bool _divisible)
        public returns (address);
}

contract Util {

   /**
    * @notice changes a string to upper case
    * @param _base string to change
    */
    function upper(string _base) internal pure returns (string) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            bytes1 b1 = _baseBytes[i];
            if (b1 >= 0x61 && b1 <= 0x7A) {
                b1 = bytes1(uint8(b1)-32);
            }
            _baseBytes[i] = b1;
        }
        return string(_baseBytes);
    }

}

contract SecurityTokenRegistry is Ownable, ISecurityTokenRegistry, Util {

    // Emit at the time of launching of new security token
    event LogNewSecurityToken(string _ticker, address indexed _securityTokenAddress, address _owner);
    event LogAddCustomSecurityToken(string _name, string _symbol, address _securityToken, uint256 _addedAt);
     /**
     * @notice Constructor used to set the essentials addresses to facilitate
     * the creation of the security token
     */
    constructor (
        address _polyAddress,
        address _moduleRegistry,
        address _tickerRegistry,
        address _stVersionProxy
    )
    public
    {
        polyAddress = _polyAddress;
        moduleRegistry = _moduleRegistry;
        tickerRegistry = _tickerRegistry;

        // By default, the STR version is set to 0.0.1
        setProtocolVersion(_stVersionProxy, "0.0.1");
    }

    /**
     * @notice Creates a new Security Token and saves it to the registry
     * @param _name Name of the token
     * @param _symbol Ticker symbol of the security token
     * @param _tokenDetails off-chain details of the token
     */
    function generateSecurityToken(string _name, string _symbol, string _tokenDetails, bool _divisible) public {
        require(bytes(_name).length > 0 && bytes(_symbol).length > 0, "Name and Symbol string length should be greater than 0");
        require(ITickerRegistry(tickerRegistry).checkValidity(_symbol, msg.sender, _name), "Trying to use non-valid symbol");
        string memory symbol = upper(_symbol);
        address newSecurityTokenAddress = ISTProxy(protocolVersionST[protocolVersion]).deployToken(
            _name,
            symbol,
            18,
            _tokenDetails,
            msg.sender,
            _divisible
        );

        securityTokens[newSecurityTokenAddress] = SecurityTokenData(symbol, _tokenDetails);
        symbols[symbol] = newSecurityTokenAddress;
        emit LogNewSecurityToken(symbol, newSecurityTokenAddress, msg.sender);
    }

    /**
     * @notice Add a new custom (Token should follow the ISecurityToken interface) Security Token and saves it to the registry
     * @param _name Name of the token
     * @param _symbol Ticker symbol of the security token
     * @param _securityToken Address of the securityToken
     * @param _tokenDetails off-chain details of the token
     * @param _swarmHash off-chain details about the issuer company
     */
    function addCustomSecurityToken(string _name, string _symbol, address _securityToken, string _tokenDetails, bytes32 _swarmHash) public onlyOwner {
        require(bytes(_name).length > 0 && bytes(_symbol).length > 0, "Name and Symbol string length should be greater than 0");
        require(_securityToken != address(0) && symbols[_symbol] == address(0), "Symbol is already at the polymath network or entered sencurity token address is 0x");
        require(!(ITickerRegistry(tickerRegistry).isReserved(_symbol, msg.sender, _name, _swarmHash)), "Trying to use non-valid symbol");
        symbols[_symbol] = _securityToken;
        securityTokens[_securityToken] = SecurityTokenData(_symbol, _tokenDetails);
        emit LogAddCustomSecurityToken(_name, _symbol, _securityToken, now);
    }
    /**
    * @notice Changes the protocol version and the SecurityToken contract that the registry points to
    * Used only by Polymath to upgrade the SecurityToken contract and add more functionalities to future versions
    * Changing versions does not affect existing tokens.
    */
    function setProtocolVersion(address _stVersionProxyAddress, bytes32 _version) public onlyOwner {
        protocolVersion = _version;
        protocolVersionST[_version] = _stVersionProxyAddress;
    }

    //////////////////////////////
    ///////// Get Functions
    //////////////////////////////
    /**
     * @notice Get security token address by ticker name
     * @param _symbol Symbol of the Scurity token
     * @return address _symbol
     */
    function getSecurityTokenAddress(string _symbol) public view returns (address) {
        string memory __symbol = upper(_symbol);
        return symbols[__symbol];
    }

     /**
     * @notice Get security token data by its address
     * @param _securityToken Address of the Scurity token
     * @return string, address, string
     */
    function getSecurityTokenData(address _securityToken) public view returns (string, address, string) {
        return (
            securityTokens[_securityToken].symbol,
            ISecurityToken(_securityToken).owner(),
            securityTokens[_securityToken].tokenDetails
        );
    }

    /**
    * @notice Check that Security Token is registered
    * @param _securityToken Address of the Scurity token
    * @return bool
    */
    function isSecurityToken(address _securityToken) public view returns (bool) {
        return (keccak256(securityTokens[_securityToken].symbol) != keccak256(""));
    }
}

contract STVersionProxy002 is ISTProxy {

    address public transferManagerFactory;

    //Shoud be set to false when we have more TransferManager options
    bool addTransferManager = true;

    constructor (address _transferManagerFactory) public {
        transferManagerFactory = _transferManagerFactory;
    }

    /**
     * @notice deploys the token and adds default modules like permission manager and transfer manager.
     * Future versions of the proxy can attach different modules or pass some other paramters.
     */
    function deployToken(string _name, string _symbol, uint8 _decimals, string _tokenDetails, address _issuer, bool _divisible)
    public returns (address)
    {
        address newSecurityTokenAddress = new SecurityTokenV2(
        _name,
        _symbol,
        _decimals,
        _divisible ? 1 : uint256(10)**_decimals,
        _tokenDetails,
        msg.sender
        );

        if (addTransferManager) {
            SecurityToken(newSecurityTokenAddress).addModule(transferManagerFactory, "", 0, 0, false);
        }

        SecurityToken(newSecurityTokenAddress).transferOwnership(_issuer);

        return newSecurityTokenAddress;
    }
}