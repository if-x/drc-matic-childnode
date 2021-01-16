// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Interfaces/Uniswap/IUniswapV2Router02.sol";

contract DigitalReserve is ERC20("Digital Reserve", "DR-POD"), Ownable {
    using SafeMath for uint256;

    constructor(address _router, address _drcAddress) public {
        drcAddress = _drcAddress;
        router = _router;
        uniswapRouter = IUniswapV2Router02(_router);
    }

    uint8 public strategyTokenCount;
    address[] public strategyTokens;
    mapping(address => uint8) public tokenPercentage;
    uint8 public feePercentage = 1;
    uint8 public priceDecimals = 18;

    address private router;
    address private drcAddress;

    bool private depositEnabled = false;
    bool private withdrawalEnabled = true;

    IUniswapV2Router02 private uniswapRouter;

    event StrategyChange(address[] oldTokens, uint8[] oldPercentage, address[] newTokens, uint8[] newPercentage);
    event Rebalance(address[] strategyTokens, uint8[] tokenPercentage);
    event Deposit(address user, uint256 amount);
    event Withdraw(address user, uint256 amount, uint256 fees);

    function changeDepositStatus(bool _status) external onlyOwner {
        depositEnabled = _status;
    }

    function changeWithdrawalStatus(bool _status) external onlyOwner {
        withdrawalEnabled = _status;
    }

    function changeFee(uint8 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Fee percentage exceeded 100.");
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
        uint256 userVaultWorthInEth = balanceOf(_user).mul(getProofOfDepositPrice()).div(1e18);

        uint256 fees = userVaultWorthInEth.mul(feePercentage).div(100);
        uint256 drcAmount = _getTokenAmountByEthAmount(userVaultWorthInEth, drcAddress);
        uint256 drcAmountExcludeFees = _getTokenAmountByEthAmount(userVaultWorthInEth.sub(fees), drcAddress);

        return (drcAmount, drcAmountExcludeFees, fees);
    }

    function getProofOfDepositPrice() public view returns (uint256) {
        uint256 proofOfDepositPrice;
        if (totalSupply() > 0) {
            proofOfDepositPrice = _getEthAmountByStrategyTokensAmount(totalTokenStored()).mul(1e18).div(totalSupply());
        }
        return proofOfDepositPrice;
    }

    function depositDrc(uint256 _amount, uint32 deadline) external {
        require(depositEnabled, "Deposit is disabled.");
        require(IERC20(drcAddress).allowance(msg.sender, address(this)) >= _amount, "Contract is not allowed to spend user's DRC.");
        require(IERC20(drcAddress).balanceOf(msg.sender) >= _amount, "Attempted to deposit more than balance.");

        SafeERC20.safeTransferFrom(IERC20(drcAddress), msg.sender, address(this), _amount);

        // Get current unit price before adding tokens to vault
        uint256 currentPodUnitPrice = getProofOfDepositPrice();

        uint256 ethConverted = _convertTokenToEth(_amount, drcAddress, deadline);
        _convertEthToStrategyTokens(ethConverted, deadline);

        uint256 podToMint = 0;
        if (totalSupply() == 0) {
            podToMint = _amount.mul(1e15);
        } else {
            uint256 vaultTotalInEth = _getEthAmountByStrategyTokensAmount(totalTokenStored());
            uint256 newPodTotal = vaultTotalInEth.mul(1e18).div(currentPodUnitPrice);
            podToMint = newPodTotal.sub(totalSupply());
        }

        _mint(msg.sender, podToMint);

        emit Deposit(msg.sender, _amount);
    }

    function withdrawDrc(uint256 drcAmount, uint32 deadline) external {
        require(withdrawalEnabled, "Withdraw is disabled.");

        (, uint256 userVaultInDrc, ) = getUserVaultInDrc(msg.sender);
        require(userVaultInDrc >= drcAmount, "Attempt to withdraw more than user's holding.");

        uint256 amountFraction = drcAmount.mul(1e10).div(userVaultInDrc);
        uint256 podToBurn = balanceOf(msg.sender).mul(amountFraction).div(1e10);
        _withdrawProofOfDeposit(podToBurn, deadline);
    }

    function withdrawPercentage(uint8 percentage, uint32 deadline) external {
        require(withdrawalEnabled, "Withdraw is disabled.");
        require(percentage <= 100, "Attempt to withdraw more than 100% of the asset");

        uint256 podToBurn = balanceOf(msg.sender).mul(percentage).div(100);
        _withdrawProofOfDeposit(podToBurn, deadline);
    }

    function changeStrategy(
        address[] calldata _strategyTokens,
        uint8[] calldata _tokenPercentage,
        uint8 _strategyTokenCount,
        uint32 deadline
    ) external onlyOwner {
        require(_strategyTokenCount >= 1, "Setting strategy to 0 tokens.");
        require(_strategyTokens.length == _strategyTokenCount, "Token count doesn't match tokens length");
        require(_tokenPercentage.length == _strategyTokenCount, "Token count doesn't match token percentages length");
        
        uint8 totalPercentage = 0;
        for (uint8 i = 0; i < _strategyTokenCount; i++) {
            require(_strategyTokens[i] != drcAddress, "Token can't be DRC.");
            totalPercentage += _tokenPercentage[i];
        }
        require(totalPercentage == 100, "Total token percentage exceeded 100%.");

        uint8[] memory oldPercentage = new uint8[](strategyTokenCount);
        for (uint8 i = 0; i < strategyTokenCount; i++) {
            oldPercentage[i] = tokenPercentage[strategyTokens[i]];
            delete tokenPercentage[strategyTokens[i]];
        }

        emit StrategyChange(strategyTokens, oldPercentage, _strategyTokens, _tokenPercentage);

        // Before mutate strategyTokens, convert current strategy tokens to ETH
        uint256 ethConverted = _convertStrategyTokensToEth(totalTokenStored(), deadline);

        strategyTokens = _strategyTokens;
        strategyTokenCount = _strategyTokenCount;
        for (uint8 i = 0; i < strategyTokenCount; i++) {
            tokenPercentage[strategyTokens[i]] = _tokenPercentage[i];
        }

        _convertEthToStrategyTokens(ethConverted, deadline);
    }

    function rebalance(uint32 deadline) external onlyOwner {
        require(strategyTokenCount > 0, "Strategy hasn't been set");

        uint8[] memory percentageArray = new uint8[](strategyTokenCount);
        for (uint8 i = 0; i < strategyTokenCount; i++) {
            percentageArray[i] += tokenPercentage[strategyTokens[i]];
        }

        emit Rebalance(strategyTokens, percentageArray);

        uint256 ethConverted = _convertStrategyTokensToEth(totalTokenStored(), deadline);
        _convertEthToStrategyTokens(ethConverted, deadline);
    }

    function _withdrawProofOfDeposit(uint256 podToBurn, uint32 deadline) private {
        uint256[] memory strategyTokensToWithdraw = _getStrateTokensByPodAmount(podToBurn);

        _burn(msg.sender, podToBurn);

        uint256 ethConverted = _convertStrategyTokensToEth(strategyTokensToWithdraw, deadline);
        uint256 fees = ethConverted.mul(feePercentage).div(100);

        uint256 drcAmount = _convertEthToToken(ethConverted.sub(fees), drcAddress, deadline);
        SafeERC20.safeTransfer(IERC20(drcAddress), msg.sender, drcAmount);
        SafeERC20.safeTransfer(IERC20(uniswapRouter.WETH()), owner(), fees);
        emit Withdraw(msg.sender, drcAmount, fees);
    }

    function _getTokenAmountByEthAmount(uint256 _amount, address _tokenAddress) private view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = _tokenAddress;

        if (path[0] != path[1] && _amount != 0) {
            return uniswapRouter.getAmountsOut(_amount, path)[1];
        }
    }

    function _getEthAmountByTokenAmount(uint256 _amount, address _tokenAddress) private view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = _tokenAddress;
        path[1] = uniswapRouter.WETH();

        if (path[0] != path[1] && _amount != 0) {
            return uniswapRouter.getAmountsOut(_amount, path)[1];
        }
    }

    function _getEthAmountByStrategyTokensAmount(uint256[] memory _strategyTokensBalance) private view returns (uint256) {
        uint256 amountOut;
        address[] memory path = new address[](2);
        path[1] = uniswapRouter.WETH();

        for (uint8 i = 0; i < strategyTokenCount; i++) {
            address tokenAddress = strategyTokens[i];
            path[0] = tokenAddress;
            uint256 tokenAmount = _strategyTokensBalance[i];
            uint256 tokenAmountInEth = _getEthAmountByTokenAmount(tokenAmount, tokenAddress);

            amountOut = amountOut.add(tokenAmountInEth);
        }
        return amountOut;
    }

    function _getStrateTokensByPodAmount(uint256 _amount) private view returns (uint256[] memory) {
        uint256[] memory strategyTokenAmount = new uint256[](strategyTokenCount);
        
        uint256 podFraction = _amount.mul(1e10).div(totalSupply());
        for (uint8 i = 0; i < strategyTokenCount; i++) {
            strategyTokenAmount[i] = IERC20(strategyTokens[i]).balanceOf(address(this)).mul(podFraction).div(1e10);
        }
        return strategyTokenAmount;
    }

    function _convertTokenToEth(uint256 _amount, address _tokenAddress,uint32 deadline) private returns (uint256) {
        if (_tokenAddress != uniswapRouter.WETH() && _amount != 0) {
            address[] memory path = new address[](2);
            path[0] = _tokenAddress;
            path[1] = uniswapRouter.WETH();
            SafeERC20.safeApprove(IERC20(path[0]), router, _amount);
            uint256 amountOut = uniswapRouter.getAmountsOut(_amount, path)[1];
            uniswapRouter.swapExactTokensForTokens(_amount, amountOut, path, address(this), deadline);
            return amountOut;
        }
    }

    function _convertEthToToken(uint256 _amount, address _tokenAddress, uint32 deadline) private returns (uint256) {
        if (_tokenAddress != uniswapRouter.WETH() && _amount != 0) {
            address[] memory path = new address[](2);
            path[0] = uniswapRouter.WETH();
            path[1] = _tokenAddress;
            SafeERC20.safeApprove(IERC20(path[0]), router, _amount);
            uint256 amountOut = uniswapRouter.getAmountsOut(_amount, path)[1];
            uniswapRouter.swapExactTokensForTokens(_amount, amountOut, path, address(this), deadline);
            return amountOut;
        }
    }

    function _convertEthToStrategyTokens(uint256 amount, uint32 deadline) private returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](strategyTokenCount);
        for (uint8 i = 0; i < strategyTokenCount; i++) {
            uint256 amountToConvert = amount.mul(tokenPercentage[strategyTokens[i]]).div(100);
            amounts[i] = _convertEthToToken(amountToConvert, strategyTokens[i], deadline);
        }
        return amounts;
    }

    function _convertStrategyTokensToEth(uint256[] memory amountToConvert, uint32 deadline) private returns (uint256) {
        uint256 ethConverted;
        for (uint8 i = 0; i < strategyTokenCount; i++) {
            uint256 amountConverted = _convertTokenToEth(amountToConvert[i], strategyTokens[i], deadline);
            ethConverted = ethConverted.add(amountConverted);
        }
        return ethConverted;
    }
}
