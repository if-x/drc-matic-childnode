// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.0;

import "../Interfaces/Uniswap/IUniswapV2Pair.sol";
import "../Interfaces/Uniswap/IUniswapV2Router02.sol";

contract Storage {
    address[] public strategyTokens; // Token addresses of vault strategy tokens
    mapping(address => uint8) internal tokenPercentage; // Vault strategy tokens percentage allocation

    uint256[] public totalTokenStored; // Vault tokens balance

    uint8 public proofOfDepositDecimals = 18;
    uint256 public totalProofOfDeposit;
    mapping(address => uint256) public userProofOfDeposit;

    address internal router;
    address internal drcAddress;
    address internal owner;

    bool internal depositEnabled = false;
    bool internal withdrawalEnabled = true;
    uint8 internal feePercentage = 1;

    IUniswapV2Pair internal drcEthPair;
    IUniswapV2Router02 internal uniswapRouter;

    event StrategyChange(address[] _oldTokens, uint8[] _oldPercents, address[] _newTokens, uint8[] _newPercents);
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
}
