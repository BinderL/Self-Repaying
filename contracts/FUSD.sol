
// SPDX-License-Identifier: CC

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FUSD is ERC20 {
    constructor(uint256 initialSupply) ERC20("fake USD", "fUSD") {
        _mint(msg.sender, initialSupply);
    }
}

