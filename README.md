# Digital Reserve

Digital Reserve (DR) is an online platform where DRC token holders will be able to get easy exposure to a basket of the most efficient store of value (SoV) assets to preserve their capital and hedge inflation risks.

## How it works

Digital Reserve contract converts user's DRC into a set of SoV assets using the Uniswap router, and hold these assets for it's users. When users initiate a withdrawal action, the contract converts a share of the vault, that the user is requesting, to DRC and sends it back to their wallet.

## Deposit

### Before making a deposit
Before making a deposit, the user will need to approve the contract address to spend the amount of DRC they are going to deposit.

### Step 1: Transfer user's DRC to the contract
When making the deposit, the user will need to enter an amount of DRC that they want to deposit to the vault.

The contract will check:
- If the user owns the entered amount of DRC in their wallet
- If the user has granted the contract to spend their entered amount of DRC

If the conditions are met, the contract will transfer the entered amount of DRC to the contract itself and start the conversions.

### Step 2: Convert DRC and provide Proof of Deposit

Before converting DRC into other tokens, the contract will calculate the current Proof of Deposit (DR-POD) unit price to help evaluate how much DR-POD the new deposit is worth. DR-POD unit price calculation method is provided [here](#proof-of-deposit).

The deposited DRC will first be converted to WETH via the Uniswap router. Then the WETH will be divided by the portfolio assets' allocation percentages, and be converted to portfolio assets.

The new assets' total worth then are calculated. The new DR-POD total would be the new total worth divided by the current unit price. The newly minted amount of DR-POD will then be given to the user as their Proof of Deposit.

## Withdrawal

There are two methods that support withdrawal:
- Withdraw by entering an amount of DRC
- Withdraw by entering a percentage of holding

To withdraw all of a user's holding, it's recommended to use withdraw by percentage, and enter 100 percent.

For both methods, the contract will calculate the share of the assets the user is withdrawing and convert that to WETH, then to further convert to DRC and transfer to the user. Details below:

### Method 1: Withdraw a certain amount of DRC

Users can enter an amount of DRC that they want to withdraw from DR. Note: the total amount of DRC a user can withdraw is accessible through `getUserVaultInDrc()` function provided by the contract, which could be used to guide the user to input an amount that is below or equal to the maximum amount of DRC they can withdraw.

The contract will check the user's total assets value in DRC, and find out the fraction of their total they are withdrawing.

That fraction of their DR-POD holding will then be withdrawn. The contract will calculate the amount of DR-POD will be burned and proceed the withdrawal of the DR-POD amount. Details of DR-POD withdrawal are [here](#internal-function-withdraw-by-dr-pod-amount).

### Method 2: Withdraw a certain percentage of user's holding

User can also enter a percentage of their holding they want to withdraw from the DR vault.

The percentage of their DR-POD holding will then be withdrawn. The contract will calculate the amount of DR-POD will be burned and proceed the withdrawal of the DR-POD amount. Details of DR-POD withdrawal are [here](#internal-function-withdraw-by-dr-pod-amount).

### Internal function: Withdraw by DR-POD amount

Both withdrawal methods are using the DR-POD amount to withdraw users holding.

The function takes the input amount of DR-POD, and calculates the fraction of the total amount of DR-POD in the vault. This is the value of the corresponding fraction of each asset in the portfolio that will be withdrawn.

For each portfolio asset, the withdrawal fraction of it will first be converted to WETH. Then the WETH will be further converted to DRC and sent to the user.

Note: A 1% fee will be applied at the time of withdrawal, which helps fund the portfolio strategy rebalancing and development of the Digital Reserve. Fees are sent to the DRC Foundation Fund Multi-sig Wallet.

## Set and change strategy

The contract owner can set and change the portfolio assets and their allocations.

Once the contract is deployed, owner can set the portfolio assets by providing the tokenized assets' addresses and the percentage allocations of each asset.

The contract will make sure:
- At least 1 asset address is set
- The percentage allocations add up to exactly 100%

The percentage allocations will be used in the deposit process and rebalancing process.

Once the portfolio assets and their allocations are set, they are not expected to be changed except for the following possible conditions:
- One of the underlying asset has a better tokenized version
- One of the tokenized asset has a potential security issue
- The performance and market volatility of a certain asset is harming the stability of the vault that DRC holders and DR-POD holders have voted to change the allocations.

When changing strategy, the contract will convert all the current portfolio assets to WETH. Then the WETH will be divided by the new portfolio assets' allocation percentages, and be converted to portfolio assets.

Set and change strategy function is only executable by contract owner - [the DRC Foundation Fund Multi-sig Wallet](#digital-reserve-contract-owner).

## Rebalancing

Rebalancing is the process of realigning the weighting of a portfolio of assets to the strategy allocation that is defined.

When rebalancing, the contract will convert all the current portfolio assets to WETH. Then the WETH will be divided by the portfolio assets' allocation percentages, and be converted to portfolio assets.

Rebalancing is only executable by contract owner - [the DRC Foundation Fund Multi-sig Wallet](#digital-reserve-contract-owner).

## Proof of Deposit

Upon deposit, Proof of Deposit (DR-POD) is provided to users as a representation of their holdings.

The unit price of DR-POD equals to the total vault holding worth in ETH divided by the total supply of DR-POD.

When new assets are stored in DR, the new total supply becomes the new total assets worth divided by the DR-POD unit price. And the newly minted DR-POD goes to the depositor.

When a new DR is created, the total supply of DR-POD is 0. When the first DRC deposit comes in, the first batch of DR-POD would be minted. And the initial minted amount equals to 1/1000 of the DRC amount of the first deposit.

Users' DR-POD are burned when they withdraw DRC from the vault. When withdrawing a fraction or 100% of their holdings, the exact fraction of their DR-POD balance will be burned.

The Proof of Deposit (DR-POD) matches the ERC20 token standard. It has 18 decimals. The following actions are supported:
- Transfer DR-POD to other addresses
- Grant other addresses to transfer your DR-POD

**Note**: transfer DR-POD to another address means that address can withdraw DRC from the DR. It is a real representation of your holding. Don't transfer or approve spending to any address you don't trust.

The Proof of Deposit's net unit worth is publicly available through function `getProofOfDepositPrice()`. Trading action is not encouraged by DRC Foundation.

## Digital Reserve contract owner

The Digital Reserve contracts are owned by the DRC Foundation Fund Multi-sig Wallet.

The DRC Foundation wallet is a secure, industry grade multi-signature wallet managed by community elected DRC Representatives. A policy is set requiring 3 of the 5 Representatives to authorize and sign any transaction. Any changes to the management of the wallet will also require 3 Representatives to sign and authorise those changes.

The contract owner can execute the following functions:
- Turn deposit on/off - To protect users' fund if there's any security issue or assist DR upgrade
- Turn withdraw on/off - To protect users' fund if there's any security issue
- Rebalancing
- Set/change strategy
- Change withdrawal fee
- Change contract owner - If better governance tool is available and the Foundation wallet address is changed

## Functions and events reference

### Readonly functions:

#### strategyTokenCount

```JS
function strategyTokenCount() external view returns (uint8);
```

Returns length of the portfolio asset tokens. Can be used to get token addresses and percentage allocations.

#### strategyTokens

```JS
function strategyTokens(uint8 index) external view returns (address);
```

Returns strategy token address at `index`.

#### tokenPercentage

```JS
function tokenPercentage(address tokenAddress) external view returns (uint8);
```

Returns strategy token percentage allocation.

#### feePercentage

```JS
function feePercentage() external view returns (uint8);
```

Returns withdrawal fee percentage.

#### priceDecimals

```JS
function priceDecimals() external view returns (uint8);
```

Returns Proof of Deposit price decimal `18`.

#### totalTokenStored

```JS
function totalTokenStored() external view returns (uint256[] memory);
```

Returns total strategy tokens stored.

#### getUserVaultInDrc

```JS
function getUserVaultInDrc(address user) external view returns (uint256, uint256, uint256);
```

Returns how much user's vault share in DRC amount. The first output is total worth in DRC, second one is total DRC could withdraw (exclude fees), and last output is fees in wei.

#### getUserVaultInDrc

```JS
function getProofOfDepositPrice() external view returns (uint256);
```

Returns Proof of Deposit net unit worth.

### State-Changing Functions

#### depositDrc

```JS
function depositDrc(uint256 _amount, uint32 deadline) external;
```

Deposit DRC to DR. deadline	is Unix timestamp after which the transaction will revert.

#### withdrawDrc

```JS
function withdrawDrc(uint256 drcAmount, uint32 deadline) external;
```

Withdraw DRC from DR. deadline	is Unix timestamp after which the transaction will revert.

#### withdrawPercentage

```JS
function withdrawPercentage(uint8 percentage, uint32 deadline) external;
```

Withdraw a percentage of holding from DR. deadline	is Unix timestamp after which the transaction will revert.

### Events

#### StrategyChange

```JS
event StrategyChange(address[] oldTokens, uint8[] oldPercentage, address[] newTokens, uint8[] newPercentage);
```

Emit when strategy set or change function is called by owner.

#### Rebalance

```JS
event Rebalance(address[] strategyTokens, uint8[] tokenPercentage);
```

Emit each time a rebalance function is called by owner.

#### Deposit

```JS
event Deposit(address user, uint256 amount, uint256 podMinted, uint256 podTotalSupply);
```

Emit each time a deposit action happened.

#### Withdraw

```JS
event Withdraw(address user, uint256 amount, uint256 fees, uint256 podBurned, uint256 podTotalSupply);
```

Emit each time a withdraw action happened.

## Testing in Ropsten testnet

For testing on Ropsten network

Paste this in constructor
"0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D","0x6D38D09eb9705A5Fb1b8922eA80ea89d438159C7"

Approve the contract with Drc before depositing

Paste this for changing strategy
["0x0B6D10102bbB04a0CA2Dc49d1b38bD9A788832FD","0x8ee9335eD219Fb26B57AE7038047D59aBe702365","0x87c00648150d89651FB6C5C5993338DCfcA3Ff7B"],
[40,40,20],3,"1610373999"

This is the DRC contract
0x6D38D09eb9705A5Fb1b8922eA80ea89d438159C7

WETH
0xc778417e063141139fce010982780140aa0cd5ab

PAXG
0x478640c8D01CAc92Ffcd4a15EaC1408Be52BA47A

WBTC
0x0B6D10102bbB04a0CA2Dc49d1b38bD9A788832FD

USDC
0x87c00648150d89651FB6C5C5993338DCfcA3Ff7B
