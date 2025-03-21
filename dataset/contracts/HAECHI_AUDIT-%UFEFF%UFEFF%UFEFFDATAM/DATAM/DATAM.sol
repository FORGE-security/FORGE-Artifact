pragma solidity 0.4.21;

library SafeMath {

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {

    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 public totalSupply_;

    function totalSupply() public view returns (uint256) {

        return totalSupply_;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function Time_call() public view returns (uint256){
        return now;
    }

}

contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

    function approve(address _spender, uint256 _value) public returns (bool) {

        require(_value==0||allowed[msg.sender][_spender]==0);
        require(msg.data.length>=(2*32)+4);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;

    }

    function allowance(address _owner, address _spender) public view returns (uint256) {

        return allowed[_owner][_spender];

    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

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

}

contract Ownable {
    
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        require(newOwner != owner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract PausableToken is StandardToken, Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

contract BurnableToken is BasicToken, Ownable {

  event Burn(address indexed burner, uint256 value);

  function burn(uint256 _value) onlyOwner public {
    burnAddress(msg.sender, _value);
  }

  function burnAddress(address _who, uint256 _value) onlyOwner public {
    require(_value <= balances[_who]);
    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }

}

contract MintableToken is StandardToken, Ownable {

    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    function mint(address _to, uint256 _amount) public returns (bool) {
        require(msg.sender == owner);
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

}

contract FreezingToken is PausableToken {
    struct freeze {
        uint256 amount;
        uint256 when;
    }

    mapping (address => freeze) freezedTokens;
    mapping (address => bool) frozen; 

    function setFrozen(address _target,bool _flag) onlyOwner public {
        frozen[_target]=_flag;
        emit FrozenStatus(_target,_flag);
    }

    function freezedTokenOf(address _target) public view returns (uint256 amount){
        freeze storage _freeze = freezedTokens[_target];
        if(_freeze.when < now) return 0;
        return _freeze.amount;
    }

    function defrostDate(address _target) public view returns (uint256 Date) {
        freeze storage _freeze = freezedTokens[_target];
        if(_freeze.when < now) return 0;
        return _freeze.when;
    }

    function freezeTokens(address _target, uint256 _amount, uint256 _when) onlyOwner public {
        require(msg.sender == owner);
        freeze storage _freeze = freezedTokens[_target];
        _freeze.amount = _amount;
        _freeze.when = _when;
    }

    function unFreezeTokens(address _target) onlyOwner public {
        require(msg.sender == owner);
        freeze storage _freeze = freezedTokens[_target];
        _freeze.amount = 0;
        _freeze.when = 0;
    }

    function transferAndFreeze(address _target, uint256 _amount, uint256 _when) external {
        require(freezedTokenOf(_target) == 0);
        if(_when > 0){
            freeze storage _freeze = freezedTokens[_target];
            _freeze.amount = _amount;
            _freeze.when = _when;
        }
        transfer(_target,_amount);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf(msg.sender) >= freezedTokenOf(msg.sender).add(_value));
        require(frozen[msg.sender]==false);
        return super.transfer(_to,_value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(balanceOf(_from) >= freezedTokenOf(_from).add(_value));
        require(frozen[msg.sender]==false);
        return super.transferFrom( _from,_to,_value);
    }
    event FrozenStatus(address _target,bool _flag);
}

contract DATAM is BurnableToken, FreezingToken, MintableToken {

    string public constant name = "DATAM";
    string public constant symbol = "DATAM";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 369369369 * (10 ** uint256(decimals));

    function DATAM() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }
}