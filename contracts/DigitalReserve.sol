// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Interfaces/Uniswap/IUniswapV2Router02.sol";
import "./Interfaces/Uniswap/IUniswapV2Pair.sol";
import "./Interfaces/Uniswap/IWETH.sol";

contract DigitalReserve is Ownable {
    using SafeMath for uint256;

    constructor(
        address _router,
        address _drcAddress,
        address _pairAddress
    ) public {
        drcAddress = _drcAddress;
        router = _router;
        drcEthPair = IUniswapV2Pair(_pairAddress);
        uniswapRouter = IUniswapV2Router02(_router);
    }

    uint8 public strategyTokenCount; // Number of strategy tokens
    address[] public strategyTokens; // Token addresses of vault strategy tokens
    mapping(address => uint8) private tokenPercentage; // Vault strategy tokens percentage allocation

    uint8 public proofOfDepositDecimals = 18;
    uint256 public totalProofOfDeposit;
    mapping(address => uint256) public userProofOfDeposit;

    address private router;
    address private drcAddress;

    bool private depositEnabled = false;
    bool private withdrawalEnabled = true;
    uint8 private feePercentage = 1;

    IUniswapV2Pair private drcEthPair;
    IUniswapV2Router02 private uniswapRouter;

    event StrategyChange(address[] oldTokens, uint8[] oldPercentage, address[] newTokens, uint8[] newPercentage);
    event Rebalance(address[] strategyTokens, uint8[] tokenPercentage);
    event Deposit(
        address user,
        uint256 amount,
        uint256 totalProofOfDeposit,
        uint256 userProofOfDeposit,
        uint256 podMinted
    );
    event Withdraw(
        address user,
        uint256 amount,
        uint256 fees,
        string tokenName,
        uint256 totalProofOfDeposit,
        uint256 userProofOfDeposit,
        uint256 podBurned
    );

    function changeDepositStatus(bool _status) external onlyOwner {
        depositEnabled = _status;
    }

    function changeWithdrawalStatus(bool _status) external onlyOwner {
        withdrawalEnabled = _status;
    }

    function changeFee(uint8 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100);
        feePercentage = _feePercentage;
    }

    function totalTokenStored() public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](strategyTokenCount);
        for (uint8 i = 0; i < strategyTokenCount; i++) {
            amounts[i] = IERC20(strategyTokens[i]).balanceOf(address(this));
        }
        return amounts;
    }

    function getUserVaultInDrc(address _user) public view returns (uint256, uint256, uint256) {
        uint256 userVaultWorthInEth = userProofOfDeposit[_user].mul(getProofOfDepositPrice()).div(1e18);

        uint256 fees = userVaultWorthInEth.mul(feePercentage).div(100);
        uint256 drcAmount = _getEthToTokenAmountOut(userVaultWorthInEth, drcAddress);
        uint256 drcAmountExcludeFees = _getEthToTokenAmountOut(userVaultWorthInEth.sub(fees), drcAddress);

        return (drcAmount, drcAmountExcludeFees, fees);
    }

    function getProofOfDepositPrice() public view returns (uint256) {
        uint256 proofOfDepositPrice;
        if (totalProofOfDeposit > 0) {
            proofOfDepositPrice = _getStrategyTokensInEth(totalTokenStored()).mul(1e18).div(totalProofOfDeposit);
        }

        return proofOfDepositPrice;
    }

    function depositDrc(uint256 _amount, uint32 deadline) external {
        require(depositEnabled);

        // Step 1: transfer users DRC to this contract
        require(IERC20(drcAddress).balanceOf(msg.sender) >= _amount);
        require(IERC20(drcAddress).allowance(msg.sender, address(this)) >= _amount);
        SafeERC20.safeTransferFrom(IERC20(drcAddress), msg.sender, address(this), _amount);

        // Get current unit price before adding tokens to vault
        uint256 currentPodUnitPrice = getProofOfDepositPrice();

        // Step 2: Swap DRC to ETH, then swap ETH to strategy tokens
        _convertTokenToEth(_amount, drcAddress, deadline);
        _convertEthToStrategyTokens(IERC20(uniswapRouter.WETH()).balanceOf(address(this)), deadline);

        // Step 3: Calculate how many new POD is minted, and update Vault states
        uint256 podToMint = 0;

        if (totalProofOfDeposit == 0) {
            // Set initial POD amount to 1/1000 of the first DRC deposit amount
            podToMint = _amount.mul(1e15);
        } else {
            uint256 vaultTotalInEth = _getStrategyTokensInEth(totalTokenStored());
            uint256 newPodTotal = vaultTotalInEth.mul(1e18).div(currentPodUnitPrice);
            podToMint = newPodTotal.sub(totalProofOfDeposit);
        }

        // Update vault states
        userProofOfDeposit[msg.sender] = userProofOfDeposit[msg.sender].add(podToMint);
        totalProofOfDeposit = totalProofOfDeposit.add(podToMint);

        emit Deposit(msg.sender, _amount, totalProofOfDeposit, userProofOfDeposit[msg.sender], podToMint);
    }

    function withdrawDrc(uint256 drcAmount, uint32 deadline) external {
        require(withdrawalEnabled);

        (, uint256 userVaultInDrc, ) = getUserVaultInDrc(msg.sender);
        require(userVaultInDrc >= drcAmount);

        uint256 amountFraction = drcAmount.mul(1e10).div(userVaultInDrc);
        uint256 podToBurn = userProofOfDeposit[msg.sender].mul(amountFraction).div(1e10);
        _withdrawProofOfDeposit(podToBurn, deadline);
    }

    function withdrawPercentage(uint8 percentage, uint32 deadline) external {
        require(withdrawalEnabled);
        require(percentage >= 100);

        uint256 podToBurn = userProofOfDeposit[msg.sender].mul(percentage).div(100);
        _withdrawProofOfDeposit(podToBurn, deadline);
    }

    function changeStrategy(
        address[] calldata _strategyTokens,
        uint8[] calldata _tokenPercentage,
        uint8 _strategyTokenCount,
        uint32 deadline
    ) external onlyOwner {
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
        _convertStrategyTokensToEth(totalTokenStored(), deadline);

        // Update strategyTokens
        strategyTokens = _strategyTokens;
        strategyTokenCount = _strategyTokenCount;

        for (uint8 i = 0; i < strategyTokenCount; i++) {
            tokenPercentage[strategyTokens[i]] = _tokenPercentage[i];
        }

        _convertEthToStrategyTokens(IERC20(uniswapRouter.WETH()).balanceOf(address(this)), deadline);
    }

    function rebalance(uint32 deadline) external onlyOwner {
        require(strategyTokenCount > 0);

        uint8[] memory percentageArray = new uint8[](strategyTokenCount);
        for (uint8 i = 0; i < strategyTokenCount; i++) {
            percentageArray[i] += tokenPercentage[strategyTokens[i]];
        }

        emit Rebalance(strategyTokens, percentageArray);

        _convertStrategyTokensToEth(totalTokenStored(), deadline);
        _convertEthToStrategyTokens(IERC20(uniswapRouter.WETH()).balanceOf(address(this)), deadline);
    }

    function _withdrawProofOfDeposit(uint256 podToBurn, uint32 deadline) private {
        require(withdrawalEnabled);

        // get strategy tokens to withdraw by pod to withdraw
        uint256[] memory strategyTokensToWithdraw = new uint256[](strategyTokenCount);
        strategyTokensToWithdraw = _getPodAmountInTokens(podToBurn);

        // Reduce user holding by withdrawed amount in pod and strategy tokens
        userProofOfDeposit[msg.sender] = userProofOfDeposit[msg.sender].sub(podToBurn);
        totalProofOfDeposit = totalProofOfDeposit.sub(podToBurn);

        // Remove tokens from vault
        _convertStrategyTokensToEth(strategyTokensToWithdraw, deadline);
        uint256 ethSwapped = IERC20(uniswapRouter.WETH()).balanceOf(address(this));
        uint256 fees = ethSwapped.mul(feePercentage).div(100);
        uint256 drcAmount = _getEthToTokenAmountOut(ethSwapped.sub(fees), drcAddress);

        if (!_isEnoughDrcReserve(drcAmount)) {
            SafeERC20.safeTransfer(IERC20(uniswapRouter.WETH()), msg.sender, ethSwapped.sub(fees));
            SafeERC20.safeTransfer(IERC20(uniswapRouter.WETH()), owner(), fees);
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
            _convertEthToToken(ethSwapped.sub(fees), drcAddress, deadline);
            uint256 _drcAmount = IERC20(uniswapRouter.WETH()).balanceOf(address(this));
            SafeERC20.safeTransfer(IERC20(drcAddress), msg.sender, _drcAmount);
            SafeERC20.safeTransfer(IERC20(uniswapRouter.WETH()), owner(), fees);
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

    function addTwoArrays(uint256[] memory array1, uint256[] memory array2) private pure returns (uint256[] memory) {
        uint256[] memory array3 = new uint256[](array1.length);
        for (uint256 i = 0; i < array1.length; i++) {
            array3[i] = array1[i].add(array2[i]);
        }
        return array3;
    }

    function subTwoArrays(uint256[] memory array1, uint256[] memory array2) private pure returns (uint256[] memory) {
        uint256[] memory array3 = new uint256[](array1.length);
        for (uint256 i = 0; i < array1.length; i++) {
            array3[i] = array1[i].sub(array2[i]);
        }
        return array3;
    }

    function _isEnoughDrcReserve(uint256 _amount) private view returns (bool) {
        if (drcEthPair.token0() == drcAddress) {
            (uint112 reserves, , ) = drcEthPair.getReserves();
            if (reserves >= _amount) {
                return true;
            }
        }
        return false;
    }

    function _getEthToTokenAmountOut(uint256 _amount, address _tokenAddress) private view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = _tokenAddress;

        if (path[0] == path[1] || _amount == 0) {
            return _amount;
        }
        return uniswapRouter.getAmountsOut(_amount, path)[1];
    }

    function _getTokenToEthAmountOut(uint256 _amount, address _tokenAddress) private view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = _tokenAddress;
        path[1] = uniswapRouter.WETH();

        if (path[0] == path[1] || _amount == 0) {
            return _amount;
        }
        return uniswapRouter.getAmountsOut(_amount, path)[1];
    }

    function _getStrategyTokensInEth(uint256[] memory _strategyTokensBalance) private view returns (uint256) {
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

    function _getPodAmountInTokens(uint256 _amount) private view returns (uint256[] memory) {
        uint256[] memory strategyTokenAmount = new uint256[](strategyTokenCount);

        uint256 podFraction = _amount.mul(1e10).div(totalProofOfDeposit);
        for (uint8 i = 0; i < strategyTokenCount; i++) {
            strategyTokenAmount[i] = IERC20(strategyTokens[i]).balanceOf(address(this)).mul(podFraction).div(1e10);
        }
        return strategyTokenAmount;
    }

    function _convertTokenToEth(
        uint256 _amount,
        address _tokenAddress,
        uint32 deadline
    ) private returns (uint256) {
        if (_tokenAddress == uniswapRouter.WETH() || _amount == 0) {
            return _amount;
        }
        address[] memory path = new address[](2);
        path[0] = _tokenAddress;
        path[1] = uniswapRouter.WETH();
        SafeERC20.safeApprove(IERC20(path[0]), router, _amount);
        uint256 amountOut = uniswapRouter.getAmountsOut(_amount, path)[1];
        uniswapRouter.swapExactTokensForTokens(_amount, amountOut, path, address(this), deadline);
        return amountOut;
    }

    function _convertEthToToken(
        uint256 _amount,
        address _tokenAddress,
        uint32 deadline
    ) private returns (uint256) {
        if (_tokenAddress == uniswapRouter.WETH() || _amount == 0) {
            return _amount;
        }
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = _tokenAddress;
        SafeERC20.safeApprove(IERC20(path[0]), router, _amount);
        uint256 amountOut = uniswapRouter.getAmountsOut(_amount, path)[1];
        uniswapRouter.swapExactTokensForTokens(_amount, amountOut, path, address(this), deadline);
        return amountOut;
    }

    function _convertEthToStrategyTokens(uint256 amount, uint32 deadline) private returns (uint256[] memory) {
        uint256[] memory amountConverted = new uint256[](strategyTokenCount);
        for (uint8 i = 0; i < strategyTokenCount; i++) {
            address currentToken = strategyTokens[i];
            uint256 amountToConvert = amount.mul(tokenPercentage[currentToken]).div(100);
            amountConverted[i] = _convertEthToToken(amountToConvert, currentToken, deadline);
        }
        return amountConverted;
    }

    function _convertStrategyTokensToEth(uint256[] memory amountToConvert, uint32 deadline) private returns (uint256) {
        uint256 ethConverted;
        for (uint8 i = 0; i < strategyTokenCount; i++) {
            address currentToken = strategyTokens[i];
            uint256 amountConverted = _convertTokenToEth(amountToConvert[i], currentToken, deadline);
            ethConverted = ethConverted.add(amountConverted);
        }
        return ethConverted;
    }
}
