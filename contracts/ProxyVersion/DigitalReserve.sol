// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.0;

import "../Interfaces/Uniswap/IERC20.sol";
import "../Interfaces/Uniswap/IUniswapV2Router02.sol";
import "../Interfaces/Uniswap/IUniswapV2Pair.sol";
import "../Interfaces/Uniswap/IWETH.sol";

import "../Libraries/ArrayHelper.sol";
import "../Libraries/SafeMath.sol";
import "../Libraries/TransferHelper.sol";

import "./Storage.sol";

contract DigitalReserve is Storage {
    using SafeMath for uint256;

    constructor(
        address _router,
        address _drcAddress,
        address _pairAddress
    ) public {
        owner = msg.sender;
        drcAddress = _drcAddress;
        router = _router;
        drcEthPair = IUniswapV2Pair(_pairAddress);
        uniswapRouter = IUniswapV2Router02(_router);
    }

    function changeDepositStatus(bool _status) external {
        require(msg.sender == owner);
        depositEnabled = _status;
    }

    function changeWithdrawalStatus(bool _status) external {
        require(msg.sender == owner);
        withdrawalEnabled = _status;
    }

    function changeFee(uint8 _feePercentage) external {
        require(msg.sender == owner);
        require(_feePercentage <= 100);
        feePercentage = _feePercentage;
    }

    function changeOwner(address _newOwner) external {
        require(msg.sender == owner);
        require(owner != _newOwner);
        owner = _newOwner;
    }

    function getUserVaultInDrc(address _user) public view returns (uint256, uint256) {
        uint256 userVaultWorthInEth = userProofOfDeposit[_user].mul(getProofOfDepositPrice()).div(1e18);

        uint256 fees = userVaultWorthInEth.mul(feePercentage).div(100);
        uint256 drcAmount = _getEthToTokenAmountOut(userVaultWorthInEth.sub(fees), drcAddress);

        return (drcAmount, fees);
    }

    function getTotalVaultInToken(address _token) public view returns (uint256) {
        // Get total token worth in ETH
        uint256 totalTokenAmountInEth = _getStrategyTokensInEth(totalTokenStored);
        // Return total token worth from ETH to output token address
        return _getEthToTokenAmountOut(totalTokenAmountInEth, _token);
    }

    function getProofOfDepositPrice() public view returns (uint256) {
        uint256 proofOfDepositPrice;
        if (totalProofOfDeposit > 0) {
            proofOfDepositPrice = _getStrategyTokensInEth(totalTokenStored).mul(1e18).div(totalProofOfDeposit);
        }

        return proofOfDepositPrice;
    }

    function depositDrc(uint256 _amount, uint32 deadline) external {
        require(depositEnabled);

        // Step 1: transfer users DRC to this contract
        require(IERC20(drcAddress).balanceOf(msg.sender) >= _amount);
        require(IERC20(drcAddress).allowance(msg.sender, address(this)) >= _amount);
        TransferHelper.safeTransferFrom(drcAddress, msg.sender, address(this), _amount);

        // Step 2: Swap DRC to ETH, then swap ETH to strategy tokens
        uint256 ethSwapped = convertTokenToEth(_amount, drcAddress, deadline);
        uint256[] memory strategyAmount = new uint256[](strategyTokenCount);
        strategyAmount = convertEthToStrategyTokens(ethSwapped, deadline);

        // Step 3: Calculate how many new POD is minted, and update Vault states
        uint256 podToMint = 0;

        //  When total Proof Of Deposit is 0
        if (totalProofOfDeposit == 0) {
            totalTokenStored = strategyAmount;
            // Set initial POD amount to first DRC deposit amount with 18 decimals
            podToMint = _amount.mul(1e18);
        } else {
            // Get current unit price before adding tokens to vault
            uint256 currentPodUnitPrice = getProofOfDepositPrice();

            // Add tokens to vault
            totalTokenStored = ArrayHelper.addTwoArrays(totalTokenStored, strategyAmount);

            // Get new total worth in ETH
            uint256 vaultTotalInEth = _getStrategyTokensInEth(totalTokenStored);
            // Get new total amount of POD there should be
            uint256 newPodTotal = vaultTotalInEth.mul(1e18).div(currentPodUnitPrice);
            // Get new total amount of POD there should be
            podToMint = newPodTotal.sub(totalProofOfDeposit);
        }

        // Update vault states
        userProofOfDeposit[msg.sender] = userProofOfDeposit[msg.sender].add(podToMint);
        totalProofOfDeposit = totalProofOfDeposit.add(podToMint);

        // Send deposit event
        emit Deposit(msg.sender, _amount, totalProofOfDeposit, userProofOfDeposit[msg.sender], podToMint);
    }

    function withdrawDrc(uint256 drcAmount, uint32 deadline) external {
        require(withdrawalEnabled);

        // Check if they can withdraw this much DRC or not
        (uint256 userVaultInDrc, ) = getUserVaultInDrc(msg.sender);
        require(userVaultInDrc >= drcAmount);

        // get fraction of drc to total drc can withdraw
        uint256 amountFraction = drcAmount.mul(1e10).div(userVaultInDrc);

        // get pod to withdraw by fraction
        uint256 podToBurn = userProofOfDeposit[msg.sender].mul(amountFraction).div(1e10);
        // get strategy tokens to withdraw by pod to withdraw
        uint256[] memory strategyTokensToWithdraw = new uint256[](strategyTokenCount);
        strategyTokensToWithdraw = _getPodAmountInTokens(podToBurn);

        // Reduce user holding by withdrawed amount in pod and strategy tokens
        userProofOfDeposit[msg.sender] = userProofOfDeposit[msg.sender].sub(podToBurn);
        totalProofOfDeposit = totalProofOfDeposit.sub(podToBurn);

        // Remove tokens from vault
        totalTokenStored = ArrayHelper.subTwoArrays(totalTokenStored, strategyTokensToWithdraw);

        // Swap tokens to ETH
        uint256 ethSwapped = convertStrategyTokensToEth(strategyTokensToWithdraw, deadline);
        // Calculate 1% fees in ETH
        uint256 fees = ethSwapped.mul(feePercentage).div(100);

        if (!isEnoughDrcReserve(drcAmount)) {
            TransferHelper.safeTransfer(uniswapRouter.WETH(), msg.sender, ethSwapped.sub(fees));
            TransferHelper.safeTransfer(uniswapRouter.WETH(), owner, fees);
            emit Withdraw(
                msg.sender,
                ethSwapped.sub(fees),
                fees,
                "ETH",
                totalProofOfDeposit,
                userProofOfDeposit[msg.sender],
                podToBurn
            );
        } else {
            uint256 _drcAmount = convertEthToToken(ethSwapped.sub(fees), drcAddress, deadline);
            TransferHelper.safeTransfer(drcAddress, msg.sender, _drcAmount);
            TransferHelper.safeTransfer(uniswapRouter.WETH(), owner, fees);
            emit Withdraw(
                msg.sender,
                _drcAmount,
                fees,
                "DRC",
                totalProofOfDeposit,
                userProofOfDeposit[msg.sender],
                podToBurn
            );
        }
    }

    // TODO: Add a rebalancing function without input other than deadline
    function changeStrategy(
        address[] calldata _strategyTokens,
        uint8[] calldata _tokenPercentage,
        uint8 _strategyTokenCount,
        uint32 deadline
    ) external {
        require(msg.sender == owner);
        require(_strategyTokenCount >= 1);
        require(_strategyTokens.length == _strategyTokenCount);
        require(_tokenPercentage.length == _strategyTokenCount);

        uint8 totalPercentage = 0;
        for (uint8 i = 0; i < _strategyTokenCount; i++) {
            totalPercentage += _tokenPercentage[i];
        }
        require(totalPercentage == 100);

        uint8[] memory oldPercentage = new uint8[](strategyTokenCount);
        for (uint8 i = 0; i < strategyTokenCount; i++) {
            oldPercentage[i] = tokenPercentage[strategyTokens[i]];
            delete tokenPercentage[strategyTokens[i]];
        }

        emit StrategyChange(strategyTokens, oldPercentage, _strategyTokens, _tokenPercentage);

        // Before mutate strategyTokens, convert current tokens to ETH
        uint256 totalEthTokens = convertStrategyTokensToEth(totalTokenStored, deadline);

        // Update strategyTokens
        strategyTokens = _strategyTokens;
        strategyTokenCount = _strategyTokenCount;

        for (uint8 i = 0; i < strategyTokenCount; i++) {
            tokenPercentage[strategyTokens[i]] = _tokenPercentage[i];
        }

        // Convert ETH to new strategy tokens
        delete totalTokenStored;
        totalTokenStored = ArrayHelper.fillArrays(0, strategyTokenCount);
        totalTokenStored = convertEthToStrategyTokens(totalEthTokens, deadline);
    }

    function withdrawExtraTokens() external {
        require(msg.sender == owner);

        for (uint8 i = 0; i < strategyTokenCount; i++) {
            uint256 tokenBalance = IERC20(strategyTokens[i]).balanceOf(address(this));
            if (tokenBalance > totalTokenStored[i]) {
                TransferHelper.safeTransfer(strategyTokens[i], owner, tokenBalance.sub(totalTokenStored[i]));
            }
        }
    }

    function isEnoughDrcReserve(uint256 _amount) internal view returns (bool) {
        if (drcEthPair.token0() == drcAddress) {
            (uint112 reserves, , ) = drcEthPair.getReserves();
            if (reserves >= _amount) {
                return true;
            }
        }
        return false;
    }

    function _getEthToTokenAmountOut(uint256 _amount, address _tokenAddress) internal view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = _tokenAddress;

        if (path[0] == path[1] || _amount == 0) {
            return _amount;
        }
        return uniswapRouter.getAmountsOut(_amount, path)[1];
    }

    function _getTokenToEthAmountOut(uint256 _amount, address _tokenAddress) internal view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = _tokenAddress;
        path[1] = uniswapRouter.WETH();

        if (path[0] == path[1] || _amount == 0) {
            return _amount;
        }
        return uniswapRouter.getAmountsOut(_amount, path)[1];
    }

    // Get strategy tokens worth in ETH
    function _getStrategyTokensInEth(uint256[] memory _strategyTokensBalance) internal view returns (uint256) {
        uint256 amountOut;
        address[] memory path = new address[](2);
        path[1] = uniswapRouter.WETH();

        for (uint8 i = 0; i < strategyTokenCount; i++) {
            address tokenAddress = strategyTokens[i];
            path[0] = tokenAddress;
            uint256 tokenAmount = _strategyTokensBalance[i];
            uint256 tokenAmountInEth = _getTokenToEthAmountOut(tokenAmount, tokenAddress);

            amountOut = amountOut.add(tokenAmountInEth);
        }
        return amountOut;
    }

    function _getPodAmountInTokens(uint256 _amount) internal view returns (uint256[] memory) {
        uint256[] memory strategyTokenAmount = new uint256[](strategyTokenCount);

        uint256 podFraction = _amount.mul(1e10).div(totalProofOfDeposit);
        for (uint8 i = 0; i < strategyTokenCount; i++) {
            strategyTokenAmount[i] = totalTokenStored[i].mul(podFraction).div(1e10);
        }
        return strategyTokenAmount;
    }

    function convertTokenToEth(
        uint256 _amount,
        address _tokenAddress,
        uint32 deadline
    ) internal returns (uint256) {
        if (_tokenAddress == uniswapRouter.WETH() || _amount == 0) {
            return _amount;
        }
        address[] memory path = new address[](2);
        path[0] = _tokenAddress;
        path[1] = uniswapRouter.WETH();
        TransferHelper.safeApprove(path[0], router, _amount);
        uint256 amountOut = uniswapRouter.getAmountsOut(_amount, path)[1];
        uniswapRouter.swapExactTokensForTokens(_amount, amountOut, path, address(this), deadline);
        return amountOut;
    }

    function convertEthToToken(
        uint256 _amount,
        address _tokenAddress,
        uint32 deadline
    ) internal returns (uint256) {
        if (_tokenAddress == uniswapRouter.WETH() || _amount == 0) {
            return _amount;
        }
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = _tokenAddress;
        TransferHelper.safeApprove(path[0], router, _amount);
        uint256 amountOut = uniswapRouter.getAmountsOut(_amount, path)[1];
        uniswapRouter.swapExactTokensForTokens(_amount, amountOut, path, address(this), deadline);
        return amountOut;
    }

    function convertEthToStrategyTokens(uint256 amount, uint32 deadline) internal returns (uint256[] memory) {
        uint256[] memory amountConverted = new uint256[](strategyTokenCount);
        for (uint8 i = 0; i < strategyTokenCount; i++) {
            address currentToken = strategyTokens[i];
            uint256 amountToConvert = amount.mul(tokenPercentage[currentToken]).div(100);
            amountConverted[i] = convertEthToToken(amountToConvert, currentToken, deadline);
        }
        return amountConverted;
    }

    function convertStrategyTokensToEth(uint256[] memory amountToConvert, uint32 deadline) internal returns (uint256) {
        uint256 ethConverted;
        for (uint8 i = 0; i < strategyTokenCount; i++) {
            address currentToken = strategyTokens[i];
            uint256 amountConverted = convertTokenToEth(amountToConvert[i], currentToken, deadline);
            ethConverted = ethConverted.add(amountConverted);
        }
        return ethConverted;
    }
}
