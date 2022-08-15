pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IERC20Extends is IERC20 {
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
}
