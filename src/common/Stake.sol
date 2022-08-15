// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IERC20Extends.sol";

interface IStake {
    event MintAmount(address caller, uint256 totalAmount);
    event Withdraw(address account, uint256 amount);
    function balanceOf(address account) external view returns(uint256);
    function totalSupply() external view returns(uint256);
    function decimals() external view returns(uint8);
    function withdraw(uint256 amount) external;
    function withdrawAll() external;
    function mintTotal() external view returns(uint256);
}

abstract contract Stake is IStake {
    mapping(address => uint256) _balances;
    uint256 private _totalSupply;
    uint256 private _mintTotal;
    
    function balanceOf(address account) external view override returns(uint256) {
        return _balances[account];
    }

    function totalSupply() external view override returns(uint256) {
        return _totalSupply;
    }

    function mintTotal() external view override returns(uint256) {
        return _mintTotal;
    }

    function decimals() external view override returns(uint8) {
        return _withdrawToken().decimals();
    }

    function _batchSetBalances(address caller, address[] memory _accounts, uint256[] memory _amounts) internal {
        require(_accounts.length == _amounts.length, "Stake: request length error");
        uint256 totalAmount = 0;
        for(uint i = 0; i < _accounts.length; i++) {
            _balances[_accounts[i]] = _amounts[i]; 
            totalAmount += _amounts[i];
        }
        _afterBatchSetBalances(totalAmount);
        emit MintAmount(caller, totalAmount);
    }

    function _afterBatchSetBalances(uint256 amount) internal virtual {
        _totalSupply += amount;
        _mintTotal += amount;
    }

    function _withdrawToken() internal virtual view returns(IERC20Extends) {
        return IERC20Extends(address(0));
    }

    function withdraw(uint256 amount) external override {
        _withdraw(msg.sender, amount);
    }

    function withdrawAll() external override {
        _withdraw(msg.sender, _balances[msg.sender]);
    }

    function _withdraw(address account, uint256 amount) internal virtual {
        require(_balances[account] > 0, "Stake: withdraw amount is zero");
        require(address(_withdrawToken()) != address(0), "Stake: withdraw token address is zero");
        require(_balances[account] >= amount, "Stake: account token balance is low");
        uint256 tokenBalance = _withdrawToken().balanceOf(address(this));
        require(tokenBalance >= amount, "Stake: contract token balance is low");
        _withdrawToken().transfer(account, amount);
        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Withdraw(account, amount);
    }
}