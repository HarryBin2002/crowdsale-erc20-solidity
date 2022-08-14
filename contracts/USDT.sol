// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDT is ERC20 {
    // total supply: 5000
    uint256 _totalSupply = 5000 * (10**18);

    constructor() ERC20("USDT", "USDT") {
        _mint(msg.sender, _totalSupply);
    }
}