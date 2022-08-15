// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IAccounts {

    event BindParent(address account, address parent);

    function accountLength() external view returns(uint256);
    function isRegister(address account) external view returns(bool);
    function bindParent(address parent) external returns(bool);
    function myParent(address account) external view returns(address);
    function myChildren(address account) external view returns(address[] memory);
}

abstract contract Accounts is IAccounts {
    
    uint256 private _accountLength = 0;
    mapping(address => bool) private _isRegister;
    mapping(address => address) private _parent;
    mapping(address => address[]) private _children;

    function _setRootAccount(address account) internal virtual {
        _bindParent(account, address(0));
    }
    
    function isRegister(address account) external view override returns(bool) {
        return _isRegister[account];
    }

    function accountLength() external view override returns(uint256) {
        return _accountLength;
    }

    function _bindParent(address account, address parent) internal {
        require(_isRegister[account] == false, "Accounts: already bind parent");
        _parent[account] = parent;
        _isRegister[account] = true;
        _children[parent].push(account);
        _accountLength += 1;
        emit BindParent(account, account);
    }

    function bindParent(address parent) external override returns(bool) {
        require(parent != address(0), "Accounts: parent address is zero");
        _bindParent(msg.sender, parent);
        return true;
    }

    function myParent(address account) external view override returns (address) {
        return _parent[account];
    }
    
    function myChildren(address account) external view override returns(address[] memory) {
        return _children[account];
    }
}
