// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;


import "v2-core/interfaces/IUniswapV2Pair.sol";
import "v2-periphery/interfaces/IUniswapV2Router02.sol";
import "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import "./IERC20Extends.sol";

interface ISwap {
    event SwapToken(address swapAddress, address inToken, address outToken, uint256 amountIn, uint256 outAmount);
    event AddLiquidity(address swapAddress, uint256 amountADesired, uint256 amountBDesired);
    function balanceOfToken0(address account) external view returns(uint256);
    function balanceOfToken1(address account) external view returns(uint256);
    function balanceOfLp(address account) external view returns(uint256);
    function balanceOfLpByToken0(address account) external view returns(uint256);
    function balanceOfLpByToken1(address account) external view returns(uint256);
}

abstract contract Swap is ISwap {
    using SafeMath for uint256;

    IUniswapV2Router02 public router;
    IUniswapV2Pair public pair;
    IERC20Extends public token0;
    IERC20Extends public token1;
    address public swapAddress;

    function _setRouter(address addr) internal virtual {
        router = IUniswapV2Router02(addr);
    }

    function _setPair(address addr) internal virtual {
        pair = IUniswapV2Pair(addr);
        token0 = IERC20Extends(pair.token0());
        token1 = IERC20Extends(pair.token1());
    }

    function _setSwapAddress(address addr) internal virtual {
        swapAddress = addr;
    }

    function balanceOfToken0(address account) external view override returns(uint256) {
        return token0.balanceOf(account);
    }

    function balanceOfToken1(address account) external view override returns(uint256) {
        return token1.balanceOf(account);
    }

    function balanceOfLp(address account) external view override returns(uint256) {
        return pair.balanceOf(account);
    }

    function balanceOfLpByToken0(address account) external view override returns(uint256) {
        uint256 lpAmount = pair.balanceOf(account);
        uint256 lpTotal = pair.totalSupply();
        (uint256 reserve0,,) = pair.getReserves();
        return reserve0.mul(lpAmount.mul(1000).div(lpTotal)).div(1000);
    }

    function balanceOfLpByToken1(address account) external view override returns(uint256) {
        uint256 lpAmount = pair.balanceOf(account);
        uint256 lpTotal = pair.totalSupply();
        (,uint256 reserve1,) = pair.getReserves();
        return reserve1.mul(lpAmount.mul(1000).div(lpTotal)).div(1000);
    }

    function _addLiquidity(IERC20Extends token, uint256 amount) internal virtual {
        require(token == token0 || token == token1, "Swap: token not is token0 and token1");
        uint256 amountADesired = 0;
        uint256 amountBDesired = 0;
        uint256 otherAmount = 0;
        if (token == token0) {
            amountADesired = amount.div(2);
            otherAmount = amount.sub(amountADesired);
            amountBDesired = _swapToken(token0, otherAmount);
        }

        if (token == token1) {
            amountBDesired = amount.div(2);
            otherAmount = amount.sub(amountBDesired);
            amountADesired = _swapToken(token1, otherAmount);
        }

        uint256 beforeBalanceByToken0 = token0.balanceOf(address(this));
        uint256 afterBalanceByToken0 = 0;
        uint256 beforeBalanceByToken1 = token1.balanceOf(address(this));
        uint256 afterBalanceByToken1 = 0;

        require(token0.allowance(swapAddress, address(this)) >= amountADesired,
            "Swap: contract address token0 allowance low");
        token0.transferFrom(swapAddress, address(this), amountADesired);
        afterBalanceByToken0 = token0.balanceOf(address(this));
        amountADesired = afterBalanceByToken0.sub(beforeBalanceByToken0);

        require(token1.allowance(swapAddress, address(this)) >= amountBDesired,
            "Swap: contract address token1 allowance low");
        token1.transferFrom(swapAddress, address(this), amountBDesired);
        afterBalanceByToken1 = token1.balanceOf(address(this));
        amountBDesired = afterBalanceByToken1.sub(beforeBalanceByToken1);

        if (token0.allowance(address(this), address(router)) < amountADesired) {
            token0.approve(address(router), amountADesired);
        }

        if (token1.allowance(address(this), address(router)) < amountBDesired) {
            token1.approve(address(router), amountBDesired);
        }

        router.addLiquidity(
            address(token0),
            address(token1),
            amountADesired,
            amountBDesired,
            0,
            0,
            swapAddress,
            block.timestamp + 300
        );

        emit AddLiquidity(swapAddress, amountADesired, amountBDesired);

        afterBalanceByToken0 = token0.balanceOf(address(this));
        afterBalanceByToken1 = token1.balanceOf(address(this));
        uint256 remainingA = afterBalanceByToken0.sub(beforeBalanceByToken0);
        uint256 remainingB = afterBalanceByToken1.sub(beforeBalanceByToken1);
        if (remainingA > 0) {
            token0.transfer(swapAddress, remainingA);
        }
        if (remainingB > 0) {
            token1.transfer(swapAddress, remainingB);
        }
    }

    function _swapToken(IERC20Extends token, uint256 amount) internal virtual returns(uint256) {
        require(token == token0 || token == token1, "Swap: token not is token0 and token1");
        IERC20Extends actionToken;
        IERC20Extends outToken;
        address[] memory path = new address[](2);
        if (token == token0) {
            path[0] = address(token0);
            path[1] = address(token1);
            actionToken = token0;
            outToken = token1;
        }else{
            path[0] = address(token1);
            path[1] = address(token0);
            actionToken = token1;
            outToken = token0;
        }

        uint256 beforeBalance = actionToken.balanceOf(address(this));
        require(actionToken.allowance(swapAddress, address(this)) >= amount, "Swap: contract address allowance low");
        actionToken.transferFrom(swapAddress, address(this), amount);
        uint256 afterBalance = actionToken.balanceOf(address(this));
        amount = afterBalance.sub(beforeBalance);
        actionToken.approve(address(router), amount);

        uint256 outTokenBeforeBalance = outToken.balanceOf(swapAddress);

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            swapAddress,
            block.timestamp + 300
        );

        uint256 outTokenAfterBalance = outToken.balanceOf(swapAddress);

        uint256 outAmount = outTokenAfterBalance.sub(outTokenBeforeBalance);

        emit SwapToken(swapAddress, address(actionToken), address(outToken), amount, outAmount);
        return outAmount;
    }
}