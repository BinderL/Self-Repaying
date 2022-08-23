
// SPDX-License-Identifier: CC

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IfAlchemistV2
/// @author binderl

interface IfAlchemistV2 is IERC20{

  function get_accounts(address owner)external view returns (uint balance,uint256 debt);

  function deposit(uint amount, address owner)external;

  function craft_debt(uint amount, address owner)external returns(uint);

  function liquidate(address owner) external returns (uint256 sharesLiquidated);
   
}





