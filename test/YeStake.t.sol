// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/YeStake.sol";

contract YeStakeTest is Test{
    YeStake public yeStake;
    function setUp() public {
        counter = new YeStake();
    }

    function testSetRootAccount() public {
        yeStake.setRootAccount(address(0));
        yeStake.isRegister(address(0));
    }

}
