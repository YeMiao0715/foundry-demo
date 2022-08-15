pragma solidity ^0.8.0;

import "./common/Accounts.sol";
import "@openzeppelin-contracts/contracts/access/Ownable.sol";

contract YeStake is Accounts, Ownable {

    function setRootAccount(address account) external onlyOwner {
        _setRootAccount();
    }

}
