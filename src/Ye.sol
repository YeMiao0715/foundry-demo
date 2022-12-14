// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract Ye is ERC20 {

    constructor() ERC20("ye", "ye") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }

}