
// SPDX-License-Identifier: CC

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FAlchemistV2 is ERC20{

  address public token;
  address root;

  bool guard;

  struct Account {
      // A signed value which represents the current amount of debt or credit that the account has accrued.
      // Positive values indicate debt, negative values indicate credit.
      uint256 debt;
      // The share balances for each yield token.
      //mapping(address => uint256 balances;
      uint256 balances;

      // The last values recorded for accrued weights for each yield token.
      mapping(address => uint256) lastAccruedWeights;
      // The set of yield tokens that the account has deposited into the system.
      //Sets.AddressSet depositedTokens;
      // The allowances for mints.
      mapping(address => uint256) mintAllowances;
      // The allowances for withdrawals.
      mapping(address => mapping(address => uint256)) withdrawAllowances;
  }

  mapping(address => Account) private _accounts;

  event craftDebt(address );
  
  constructor(address _token) ERC20("YT", "yeild token") {
    token = _token;
    guard = false;
    root = msg.sender;
  }

  function get_accounts(address owner)
  external view
  returns (uint balance,uint256 debt){
    Account storage account = _accounts[owner];
    return (account.balances, account.debt);
  }

  function deposit(uint amount, address owner)
  external{
    if(!guard){
      guard=true;
      IERC20(token).transferFrom(owner, address(this), amount);
      _accounts[owner].balances = _accounts[owner].balances + amount;
      _mint(address(this), amount);
      guard=false;
    }
  }

  function craft_debt(uint amount, address owner)
  external returns(uint){
    require(_accounts[owner].balances > 0, "fAlchemistV2: excess limited debt allow");
    if(!guard){
      guard=true;

      IERC20(token).transfer(owner, amount);
      _burn(address(this), amount);
      _accounts[owner].debt = _accounts[owner].debt + amount;
      _accounts[owner].balances = _accounts[owner].balances - amount;
      guard=false;
    }
    return _accounts[owner].debt;
  }

  function update(uint amount) external{
    require(msg.sender == root, "fAlchemistV2: You're not access");
    if(!guard){
      guard = true;
      IERC20(token).transferFrom(msg.sender, address(this), amount);
      _mint(address(this), amount);
      guard = false;
    }
  }

  function liquidate(address owner) external returns (uint256 sharesLiquidated){
    uint _bal = _accounts[owner].balances;
    require(_bal * 2 -  _accounts[owner].debt + (totalSupply() - _bal)/1 > 0, "fAlchemistV2: no deposit");
    if(!guard){
      guard = true;
      uint amount = balanceOf(address(this)); 
      IERC20(token).transfer(owner, amount);
      _burn(address(this), amount);
      sharesLiquidated = amount;
      _accounts[owner].balances = 0;
      _accounts[owner].debt = 0;
      guard = false;
    }
    return sharesLiquidated;
  }

}

