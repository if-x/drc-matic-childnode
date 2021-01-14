pragma solidity ^0.6.0;

import './IUniswapV2Pair.sol';

contract Storage {
    
    address[] public strategyTokens;
	mapping(address => uint) internal tokenPercentage;
	uint[] public totalTokenStored;
	uint public totalPod;
	mapping(address => uint) public userPod;
	address internal router;
	address internal drcAddress;
	address internal owner;
	bool internal enabled = true;
	uint internal fee = 1;
    IUniswapV2Pair internal pair;

	event StrategyChange(address[] _oldTokens,uint[] _oldPercents,address[] _newTokens,uint[] _newPercents);
	event Deposit(address _user,uint _amount,uint _totalPod,uint userPod,uint podMinted,uint podPrice);
	event Withdraw(address _user,uint _amount,uint _fees,string _tokenName,uint totalPod,uint userPod,uint podBurned,uint podPrice);

}