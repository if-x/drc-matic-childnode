# Digital Reserve

Digital Reserve (DR) is an online platform where DRC token holders will be able to get easy exposure to a basket of the most efficient store of value (SoV) assets to preserve their capital and hedge inflation risks.

## How it works

Digital Reserve contract converts user's DRC into a set of SoV assets using Uniswap contract, and hold these assets for it's users. When user initiate a withdrawal action, the contract converts a share of the vault, that the user is requesting, to DRC and sends it back to their wallet.

## Deposit

### Before making a deposit
Before making a deposit, the user needs to approve the contract address to spend the amount of DRC they want to deposit.

### Step 1: Transfer user's DRC to the contract
When making the deposit, the user needs to enter an amount of DRC that they want to deposit to the vault.

The contract will check:
- If user owns the entered amount in their wallet
- If user has granted the contract to spend their entered amount of DRC

If the conditions are met, the contract will transfer user entered amount of DRC to the contract itself and start the conversions.

### Step 2: Convert DRC and provide Proof of Deposit

Before converting to other tokens, the contract will calculate the current Proof of Deposit(DR-POD) unit price to help evaluate how much DR-POD the new deposit should worth. (DR-POD unit price calculation method is provided here) // TODO: add link to pod calc section

User's deposit will first be converted to WETH via Uniswap router. Then the WETH will be divided by the portfolio assets' allocation percentages, and be converted to portfolio assets via Uniswap router.

New assets' total worth then are calculated. New DR-POD total would be the new worth divided by current unit price. The newly minted amount then would be given to the user as their Proof of Deposit.

## Withdrawal

There are two methods that support user's withdrawal:
- Withdraw by entering an amount of DRC
- Withdraw by entering a percentage of holding

To withdraw all user's holding, it's recommended to withdraw by percentage, and enter 100 percent.

For both methods, the contract will calculate the share of assets user is withdrawing and convert that to WETH, then to DRC and transfer to them. Details below:

### Method 1: Withdraw a certain amount of DRC

User can enter an amount of DRC they want to withdraw from DR. Note: the total amount of DRC user can withdraw is accessible through `getUserVaultInDrc()` function provided by the contract, which could be used to guide the user to input an amount that's below or equal to their assets worth.

The contract will check the user's total assets value in DRC, and find out the fraction of their total they are withdrawing.

The fraction of their DR-POD holding will then be withdrawed. The contract will calculate the amount of DR-POD will be burned and proceed the withdraw by the DR-POD amount. Details of DR-POD withdrawal is here. // TODO: link to DR-POD withdraw

### Method 2: Withdraw a certain percentage of user's holding

User can enter a percentage of their holding they want to withdraw from the DR vault.

The percentage of their DR-POD holding will then be withdrawed. The contract will calculate the amount of DR-POD will be burned and proceed the withdraw by the DR-POD amount. Details of DR-POD withdrawal is here. // TODO: link to DR-POD withdraw

### Internal function: Withdraw by DR-POD amount

Both withdrawal methods are using the DR-POD amount to withdraw users holding.

The function takes the input amount of DR-POD, and calculates the fraction it is to the total amount of DR-POD in the vault. And this is the value of the fraction of each portfolio asset will be withdrawed.

For each portfolio asset, the withdrawal fraction of it will first be converted to WETH. The WETH will then be further converted to DRC and send to the user.

Note: A 1% fee will be applied at the time of withdrawal, which helps fund the portfolio strategy rebalancing and development of the Digital Reserve. Fees are sent to the DRC Foundation Fund Multi-sig Wallet.

## Set and change strategy

The contract owner can set and change the portfolio assets and their allocations.

Once the contract is deployed, owner can set the portfolio assets by providing the tokenized assets' addresses and the percentage allocations of each asset.

The contract will make sure:
- At least 1 asset address is set
- The percentage allocations add to exactly 100%

The percentage allocations will be used in the deposit process and rebalancing process.

Once the portfolio assets and their allocations are set, they aren't expected to be changed except for the following possible conditions:
- One of the underlying asset has a better tokenized version
- One of the tokenized asset has a potential security issue
- The market volatility of a certain asset is harming the stablility of the vault that DRC holders and DR-POD holders have voted to change the allocations.

When changing strategy, the contract will convert all the current portfolio assets to WETH. Then the WETH will be divided by the new portfolio assets' allocation percentages, and be converted to portfolio assets.

Set and change strategy function is only executable by contract owner - the DRC Foundation Fund Multi-sig Wallet. // TODO: Add a section to explain contract owner.

## Rebalancing

Rebalancing is the process of realigning the weighting of a portfolio of assets to the strategy allocation that is defined.

When rebalancing, the contract will convert all the current portfolio assets to WETH. Then the WETH will be divided by the portfolio assets' allocation percentages, and be converted to portfolio assets.

Rebalancing is only executable by contract owner - the DRC Foundation Fund Multi-sig Wallet. // TODO: Add a section to explain contract owner.

## Proof of Deposit

Upon deposit, Proof of Deposit (DR-POD) is provided to users as a representation of their holdings.

The unit price of DR-POD equals to the total vault holding worth in ETH divided by the total supply of DR-POD.

When new assets are stored in DR, the new total supply becomes the new total assets worth divided by the DR-POD unit price. And the newly minted DR-POD goes to the depositor.

When a new DR is created, the total supply of DR-POD is 0. When the first DRC deposit comes in, the first batch of DR-POD would be minted. And the inital minted amount equals to 1/1000 of the DRC amount of the first deposit.

Users' DR-POD are burned when they withdraw DRC from the vault. When withdrawing a fraction or 100% of their holdings, the exact fraction of their DR-POD balance will be burned.

The Proof of Deposit (DR-POD) matches the ERC20 token standard. It has 18 decimals. The following actions are supported:
- Transfer DR-POD to other addresses
- Grant other addresses to transfer your DR-POD

**Note**: transfer DR-POD to another address means that address can withdraw DRC from the DR. It is a real representation of your holding. Don't transfer or approve spending to any address you don't trust.

The Proof of Deposit's net unit worth is publicly available through function `getProofOfDepositPrice()`. Trading action is not enouraged by DRC Foundation.

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

## Storage and functions reference


## Testing in Ropsten testnet

For testing on Ropsten network

Paste this in constructor
"0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D","0x9493193586338679486747baADc5231621fa9ad0"

Approve the contract with Drc before depositing

Paste this for changing strategy
["0x8ee9335eD219Fb26B57AE7038047D59aBe702365","0x2A367CeEDc96Ed94878A1264aDb21498c10B31db"],[50,50],2,"1610373999"

This is the DRC contract
0x9493193586338679486747baADc5231621fa9ad0

WETH
0xc778417e063141139fce010982780140aa0cd5ab

DRC/WETH Pair
"0xc48aCe48a979C9b3F59951f8bF1d58b75186f011"