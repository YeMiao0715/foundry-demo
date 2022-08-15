pragma solidity ^0.8.0;

import "./common/Accounts.sol";
import "./common/Stake.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./common/Swap.sol";

contract YeStake is Accounts, Ownable, Stake, Swap {

    IERC20Extends public token;

    constructor(address _token, address pair, address router2) {
        token = IERC20Extends(_token);
        _setSwapAddress(msg.sender);
        _setPair(pair);
        _setRouter(router2);
    }

    function _withdrawToken() internal virtual view override returns(IERC20Extends) {
        return token;
    }

    function setRootAccount(address account) external onlyOwner {
        _setRootAccount(account);
    }

    function batchSetBalances(address[] memory _account, uint256[] memory _amounts) external onlyOwner {
        _batchSetBalances(msg.sender, _account, _amounts);
    }

    function addLiquidity(IERC20Extends token, uint256 amount) external onlyOwner {
        _addLiquidity(token, amount);
    }

}
