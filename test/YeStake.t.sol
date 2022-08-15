// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../src/YeStake.sol";
import "../src/Ye.sol";
import "../src/Usdt.sol";
import "lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "lib/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "lib/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract YeStakeTest is Test {
    Ye public ye;
    Usdt public usdt;
    YeStake public yeStake;
    IUniswapV2Router02 public router2 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory public factory;
    IUniswapV2Pair public ye_usdt;

    function setUp() public {
        ye = new Ye();
        usdt = new Usdt();

        factory = IUniswapV2Factory(router2.factory());
        ye_usdt = IUniswapV2Pair(factory.createPair(address(ye),address(usdt)));

        yeStake = new YeStake(address(ye), address(ye_usdt), address(router2));
        yeStake.token();
        ye.transfer(address(yeStake), 10000 * 10 ** 18);
        usdt.transfer(address(yeStake), 10000 * 10 ** 18);

        ye.approve(address(router2), 10000 * 10 ** 18);
        usdt.approve(address(router2), 10000 * 10 ** 18);

        router2.addLiquidity(
            address(ye),
            address(usdt),
            10000 * 10 ** 18,
            10000 * 10 ** 18,
            0,
            0,
            msg.sender,
            block.timestamp + 300
        );
    }

    function test1YeUsdt() public {
//        ye_usdt.token0();
//        ye_usdt.token1();

        yeStake.token0();
        yeStake.token1();

        usdt.approve(address(yeStake), type(uint256).max);
        ye.approve(address(yeStake), type(uint256).max);

        yeStake.addLiquidity(IERC20Extends(address(ye)), 1000 * 10 ** 18);

        yeStake.balanceOfLpByToken0(address(this));
        yeStake.balanceOfLpByToken1(address(this));
        yeStake.balanceOfLp(address(this));
        yeStake.token().balanceOf(address(this));
        yeStake.balanceOfToken0(address(this));
        yeStake.balanceOfToken1(address(this));

        yeStake.token0().name();
        yeStake.token1().name();
    }

    function test2SetRootAccount() public {
        yeStake.owner();
        yeStake.setRootAccount(vm.addr(1));
        yeStake.myChildren(address(0));
    }

    function test3BatchSetBalances() public {
        uint length = 5;
        address[] memory accounts = new address[](length);
        uint256[] memory amounts = new uint256[](length);

        for (uint i = 0; i < length; i++) {
            accounts[i] = vm.addr(i+1);
            amounts[i] = 10 ** 18;
        }
        yeStake.batchSetBalances(accounts, amounts);

        yeStake.balanceOf(vm.addr(1));
        vm.prank(vm.addr(1));
        yeStake.withdrawAll();
        yeStake.totalSupply();
        yeStake.mintTotal();
    }

}
