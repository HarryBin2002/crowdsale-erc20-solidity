// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract HoBiToken is ERC20 {
    // Total Supply: 100,000,000
    uint256 _totalSupply = 100000000 * (10 ** 18);

    constructor() ERC20("HoBiToken", "HBT") {
        _mint(msg.sender, _totalSupply);
    }
}