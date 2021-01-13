pragma solidity ^0.6.0;

import './Storage.sol';

contract Proxy {
    
    address private dr;
    address private owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function setDr(address _dr) external {
        require(msg.sender == owner);
        dr = _dr;
    }
    
    fallback() external payable {
        address target = dr;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr,0,calldatasize())
            let result := delegatecall(gas(),target,ptr,calldatasize(),0,0)
            let size := returndatasize()
            returndatacopy(ptr,0,size)
            switch result case 0 {revert(ptr,size)} default {return(ptr,size)}
        }
    }
}