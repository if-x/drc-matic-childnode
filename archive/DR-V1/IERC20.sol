pragma solidity ^0.6.2;

interface IERC20 {

    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

}
