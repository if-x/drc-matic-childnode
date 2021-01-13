pragma solidity ^0.6.0;

import './SafeMath.sol';
import './IUniswapV2Router02.sol';
import './IERC20.sol';
import './IWETH.sol';
import './TransferHelper.sol';
import './IUniswapV2Pair.sol';
import './Storage.sol';

contract DigitalReserve is Storage {

	using SafeMath for uint256;
	
	constructor(address _router,address _drcAddress,address _pairAddress) public {
		owner = msg.sender;
		router = _router;
	    drcAddress = _drcAddress;
	    pair = IUniswapV2Pair(_pairAddress);
	}

    function isEnoughReserves(uint _amount) internal view returns (bool) {
        if (pair.token0() == drcAddress) {
            (uint reserves,,) = pair.getReserves();
            if (reserves >= _amount) {
                return true;
            }
        } else {
            (,,uint reserves) = pair.getReserves();
            if (reserves >= _amount) {
                return true;
            }
        }
        return false;
    }
    
	function changeStatus(bool _status) external {
		require(msg.sender == owner);
		enabled = _status;
	}

	function changeFee(uint _amount) external {
		require(msg.sender == owner);
		require(_amount <= 100);
		fee = _amount;
	}

	function changeOwner(address _newOwner) external {
		require(msg.sender == owner);
		require(owner != _newOwner);
		owner = _newOwner;
	}

    function getUserVaultInToken(address _token,address _user) public view returns(uint) {
    	uint podPrice = getTotalVaultInToken(IUniswapV2Router02(router).WETH()).mul(1e18).div(totalPod);
        address[] memory path = new address[](2);
        path[0] = IUniswapV2Router02(router).WETH();
        path[1] = _token;
        if (_token == IUniswapV2Router02(router).WETH()) {
            return userPod[_user].mul(podPrice).div(1e18);
        }
        return IUniswapV2Router02(router).getAmountsOut(userPod[_user].mul(podPrice).div(1e18),path)[1].mul(1000).div(997);
    }

    function getTotalVaultInToken(address _token) public view returns(uint) {
        uint tokens = 0;
        address[] memory path = new address[](2);
        path[1] = IUniswapV2Router02(router).WETH();
        for (uint i = 0;i < strategyTokens.length;i++) {
            path[0] = strategyTokens[i];
            uint amount;
            if (path[0] == _token) {
                amount = totalTokenStored[i];
            } else {
                amount = IUniswapV2Router02(router).getAmountsOut(totalTokenStored[i],path)[1].mul(1000).div(997);
            }
            tokens = tokens.add(amount);
        }
        address[] memory path2 = new address[](2);
        path2[0] = IUniswapV2Router02(router).WETH();
        path2[1] = _token;
        if (path2[0] == path2[1]) {
            return tokens;
        }
        return IUniswapV2Router02(router).getAmountsOut(tokens,path2)[1].mul(1000).div(997);
    }
        
	function depositDrc(uint _amount,uint deadline) external {
		require(enabled);
		require(IERC20(drcAddress).balanceOf(msg.sender) >= _amount);
		require(IERC20(drcAddress).allowance(msg.sender,address(this)) >= _amount);
	    TransferHelper.safeTransferFrom(drcAddress,msg.sender,address(this),_amount);
		uint256 ethSwapped = convertTokenToEth(_amount,drcAddress,deadline);
		uint[] memory strategyAmount = new uint[](strategyTokens.length);
		strategyAmount = convertEthToStrategyTokens(ethSwapped,deadline);
		if (totalPod == 0) {
		    totalTokenStored = strategyAmount;
		    totalPod = _amount.mul(1e18);
		    userPod[msg.sender] = _amount.mul(1e18);
		    uint podPrice = getTotalVaultInToken(IUniswapV2Router02(router).WETH()).mul(1e18).div(totalPod);
		    emit Deposit(msg.sender,_amount,totalPod,userPod[msg.sender],totalPod,podPrice);
		} else {
			uint podPrice = getTotalVaultInToken(IUniswapV2Router02(router).WETH()).mul(1e18).div(totalPod);
	    	totalTokenStored = addTwoArrays(totalTokenStored,strategyAmount);
	    	uint thisPod = ethSwapped.mul(1e18).div(podPrice);
	    	userPod[msg.sender] = userPod[msg.sender].add(thisPod);
	    	totalPod = totalPod.add(thisPod);
	    	emit Deposit(msg.sender,_amount,totalPod,userPod[msg.sender],thisPod,podPrice);
		}
	}	

	function withdrawDrc(uint drcAmount,uint deadline) external {
		require(enabled);
		require(getUserVaultInToken(drcAddress,msg.sender) >= drcAmount);
		require(drcAmount >= 10);
		uint podFraction = drcAmount.mul(1e18).div(getUserVaultInToken(drcAddress,msg.sender));
		uint[] memory amount = new uint[](strategyTokens.length);
		for (uint i = 0;i < strategyTokens.length;i++) {
		    amount[i] = getUserVaultInToken(strategyTokens[i],msg.sender).mul(tokenPercentage[strategyTokens[i]]).div(100).mul(podFraction).div(1e18);
		}
		uint ethSwapped = convertStrategyTokensToEth(amount,deadline);
	    uint podPrice = getTotalVaultInToken(IUniswapV2Router02(router).WETH()).mul(1e18).div(totalPod);
		uint thisPod = ethSwapped.mul(1e18).div(podPrice);
		totalPod = totalPod.sub(thisPod);
		userPod[msg.sender] = userPod[msg.sender].sub(thisPod);
		totalTokenStored = subTwoArrays(totalTokenStored,amount);
        if (!isEnoughReserves(drcAmount)) {
			uint fees = ethSwapped.mul(fee).div(100);
		    TransferHelper.safeTransfer(IUniswapV2Router02(router).WETH(),msg.sender,ethSwapped.sub(fees));
		    TransferHelper.safeTransfer(IUniswapV2Router02(router).WETH(),owner,fees);
			emit Withdraw(msg.sender,ethSwapped.sub(fees),fees,"ETH",totalPod,userPod[msg.sender],thisPod,podPrice);
		} else {
			uint _amount = convertEthToToken(ethSwapped,drcAddress,deadline);
			uint fees = _amount.mul(fee).div(100);
		    TransferHelper.safeTransfer(drcAddress,msg.sender,_amount.sub(fees));
		    TransferHelper.safeTransfer(drcAddress,owner,fees);
			emit Withdraw(msg.sender,_amount,fees,"DRC",totalPod,userPod[msg.sender],thisPod,podPrice);
		}
	}
	
	function withdrawChange(uint deadline) external {
	    require(enabled);
	    require(getUserVaultInToken(IUniswapV2Router02(router).WETH(),msg.sender) > 0);
	    require(getUserVaultInToken(drcAddress,msg.sender) < 10);
	    uint[] memory amount = new uint[](strategyTokens.length);
	    for (uint i = 0;i < strategyTokens.length;i++) {
	        amount[i] = getUserVaultInToken(strategyTokens[i],msg.sender).mul(tokenPercentage[strategyTokens[i]]).div(100);
	    }
	    uint ethSwapped = convertStrategyTokensToEth(amount,deadline);
	    uint podPrice = getTotalVaultInToken(IUniswapV2Router02(router).WETH()).mul(1e18).div(totalPod);
		uint thisPod = ethSwapped.mul(1e18).div(podPrice);
		totalPod = totalPod.sub(thisPod);
		userPod[msg.sender] = userPod[msg.sender].sub(thisPod);
		totalTokenStored = subTwoArrays(totalTokenStored,amount);
	    uint fees = ethSwapped.mul(fee).div(100);
		TransferHelper.safeTransfer(IUniswapV2Router02(router).WETH(),msg.sender,ethSwapped.sub(fees));
		TransferHelper.safeTransfer(IUniswapV2Router02(router).WETH(),owner,fees);
		emit Withdraw(msg.sender,ethSwapped.sub(fees),fees,"ETH",totalPod,userPod[msg.sender],thisPod,podPrice);
	}

	function changeStrategy(address[] calldata _strategyTokens,uint[] calldata _tokenPercentage,uint deadline) external {
		require(msg.sender == owner);
		require(_strategyTokens.length >= 1);
		require(_tokenPercentage.length == _strategyTokens.length);
		uint totalPercentage = 0;
		for (uint i = 0;i < _tokenPercentage.length;i++) {
			totalPercentage = totalPercentage.add(_tokenPercentage[i]);
		}
		for (uint i = 0;i < strategyTokens.length;i++) {
		   if (IERC20(strategyTokens[i]).balanceOf(address(this)) > totalTokenStored[i]) {
		       TransferHelper.safeTransfer(strategyTokens[i],owner,IERC20(strategyTokens[i]).balanceOf(address(this)) - totalTokenStored[i]);
		   }
		}
		require(totalPercentage == 100);
		uint oldlength = strategyTokens.length;
		uint[] memory oldPercentage = new uint[](strategyTokens.length);
		for (uint i = 0;i < strategyTokens.length;i++) {
			oldPercentage[i] = tokenPercentage[strategyTokens[i]];
		}
		emit StrategyChange(strategyTokens,oldPercentage,_strategyTokens,_tokenPercentage);
		uint totalEthTokens;
		if (oldlength > 0) {
		    totalEthTokens = convertStrategyTokensToEth(totalTokenStored,deadline);
		}
		totalTokenStored = fillArrays(0,_strategyTokens.length);
		strategyTokens = _strategyTokens;
		for (uint i = 0;i < strategyTokens.length;i++) {
		    tokenPercentage[strategyTokens[i]] = _tokenPercentage[i];
		}
		if (oldlength > 0) {
		    totalTokenStored = convertEthToStrategyTokens(totalEthTokens,deadline);
		}
	}
	
	function addTwoArrays(uint[] memory array1,uint[] memory array2) internal pure returns(uint[] memory) {
		uint[] memory array3 = new uint[](array1.length);
		for (uint i = 0;i < array1.length;i++) {
		    array3[i] = array1[i].add(array2[i]);
		}
		return array3;
	}

	function subTwoArrays(uint[] memory array1,uint[] memory array2) internal pure returns(uint[] memory) {
		uint[] memory array3 = new uint[](array1.length);
		for (uint i = 0;i < array1.length;i++) {
			array3[i] = array1[i].sub(array2[i]);
		}
		return array3;
	}

	function fillArrays(uint num,uint length) internal pure returns(uint[] memory) {
		uint[] memory array = new uint[](length);
		for (uint i = 0;i < length;i++) {
			array[i] = num;
		}
		return array;
	}
	
	function convertTokenToEth(uint _amount,address _tokenAddress,uint deadline) internal returns(uint) {
		if (_tokenAddress == IUniswapV2Router02(router).WETH()) {
			return _amount;
		}
		address[] memory path = new address[](2);
		path[0] = _tokenAddress;
		path[1] = IUniswapV2Router02(router).WETH();
	    TransferHelper.safeApprove(path[0],router,_amount);
		uint amountOut = IUniswapV2Router02(router).getAmountsOut(_amount,path)[1];
		IUniswapV2Router02(router).swapExactTokensForTokens(_amount,amountOut,path,address(this),deadline);
		return amountOut;
	}

	function convertEthToToken(uint _amount,address _tokenAddress,uint deadline) internal returns(uint) {
		if (_tokenAddress == IUniswapV2Router02(router).WETH()) {
			return _amount;
		}
		address[] memory path = new address[](2);
		path[0] = IUniswapV2Router02(router).WETH();
		path[1] = _tokenAddress;
	    TransferHelper.safeApprove(path[0],router,_amount);
		uint amountOut = IUniswapV2Router02(router).getAmountsOut(_amount,path)[1];
		IUniswapV2Router02(router).swapExactTokensForTokens(_amount,amountOut,path,address(this),deadline);
		return amountOut;
	}

	function convertEthToStrategyTokens(uint amount,uint deadline) internal returns(uint[] memory) {
		uint[] memory amountConverted = new uint[](strategyTokens.length);
		for (uint i = 0;i < strategyTokens.length;i++) {
			address currentToken = strategyTokens[i];
			uint amountToConvert = amount.mul(tokenPercentage[currentToken]).div(100);
			amountConverted[i] = convertEthToToken(amountToConvert,currentToken,deadline);
		}
		return amountConverted;
	}

	function convertStrategyTokensToEth(uint[] memory amountToConvert,uint deadline) internal returns(uint) {
		uint ethConverted;
		for (uint i = 0;i < strategyTokens.length;i++) {
			uint amountConverted = convertTokenToEth(amountToConvert[i],strategyTokens[i],deadline);
			ethConverted = ethConverted.add(amountConverted);
		}
		return ethConverted;
	}
	
}
