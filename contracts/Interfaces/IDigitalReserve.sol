// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.0;

interface IDigitalReserve {
    function strategyTokenCount() external view returns (uint8);

    function strategyTokens(uint8 index) external view returns (address);

    function tokenPercentage(address tokenAddress) external view returns (uint8);

    function feePercentage() external view returns (uint8);

    function priceDecimals() external view returns (uint8);

    function totalTokenStored() external view returns (uint256[] memory);

    function getUserVaultInDrc(address user) external view returns (uint256, uint256, uint256);

    function getProofOfDepositPrice() external view returns (uint256);

    function depositDrc(uint256 drcAmount, uint32 deadline) external;

    function withdrawDrc(uint256 drcAmount, uint32 deadline) external;

    function withdrawPercentage(uint8 percentage, uint32 deadline) external;

    event StrategyChange(address[] oldTokens, uint8[] oldPercentage, address[] newTokens, uint8[] newPercentage);
    event Rebalance(address[] strategyTokens, uint8[] tokenPercentage);
    event Deposit(address user, uint256 amount, uint256 podMinted, uint256 podTotalSupply);
    event Withdraw(address user, uint256 amount, uint256 fees, uint256 podBurned, uint256 podTotalSupply);
}
