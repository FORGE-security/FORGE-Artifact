pragma solidity 0.5.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

contract MockBPT is ERC20, ERC20Detailed, ERC20Mintable {

  constructor() public ERC20Detailed("Balancer Pool Token", "BPT", 18)  {
  }
}
