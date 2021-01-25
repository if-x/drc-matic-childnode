import { Contract } from "web3-eth-contract";
import { AbiItem } from "web3-utils";
import { DigitalReserveInstance } from "../../types/truffle-contracts";
import { getUnixTimeAfterMins } from "../../utils/timestamp";
import IERC20 from "../../build/contracts/IERC20.json";
import IUniswapV2Router02 from "../../build/contracts/IUniswapV2Router02.json";
import { Network, getContractAddress } from "../../utils/contract-by-network";
import { Deposit } from "../../types/truffle-contracts/DigitalReserve";
import { getTokensWorth } from "../test-helpers/get-tokens-worth";

const DigitalReserve = artifacts.require("DigitalReserve");

export const testSecondDeposit = async (accounts: Truffle.Accounts) => {
  let instance: DigitalReserveInstance;

  let drcContract: Contract;
  let uniRouter: Contract;
  let newtworkType: Network;

  before(async () => {
    instance = await DigitalReserve.deployed();

    newtworkType = (await web3.eth.net.getNetworkType()) as Network;

    drcContract = new web3.eth.Contract(
      IERC20.abi as AbiItem[],
      getContractAddress("drc", newtworkType)
    );
    uniRouter = new web3.eth.Contract(
      IUniswapV2Router02.abi as AbiItem[],
      getContractAddress("uniswap", newtworkType)
    );
  });

  it("Should be able to deposit 1000000 DRC and mint DR-POD", async () => {
    await instance.changeDepositStatus(true);

    await drcContract.methods
      .approve(instance.address, 1000000)
      .send({ from: accounts[0] });

    const allowance = Number(
      await drcContract.methods.allowance(accounts[0], instance.address).call()
    );

    assert.equal(allowance, 1000000);

    const depositResult = await instance.depositDrc(
      1000000,
      getUnixTimeAfterMins(10)
    );

    const depositLog = depositResult.logs.find(
      (log) => log.event === "Deposit"
    ) as Deposit | undefined;

    assert.exists(depositLog);

    if (depositLog) {
      assert.equal(depositLog.args.amount.toNumber(), 1000000);
      assert.isAbove(
        Number(web3.utils.fromWei(depositLog.args.podMinted)),
        990
      );
      assert.equal(
        Number(web3.utils.fromWei(depositLog.args.podTotalSupply)),
        Number(web3.utils.fromWei(depositLog.args.podMinted)) + 1
      );
      assert.equal(depositLog.args.user, accounts[0]);
    }
  });

  it("Should have correct token balances", async () => {
    const totalSupply = await instance.totalSupply();
    assert.isAbove(Number(web3.utils.fromWei(totalSupply)), 990);

    const userBalance = await instance.balanceOf(accounts[0]);
    assert.isAbove(Number(web3.utils.fromWei(userBalance)), 990);
  });

  it("Should match designed percentage", async () => {
    const { tokenPercentage } = await getTokensWorth(
      instance,
      uniRouter,
      newtworkType
    );

    assert.equal(tokenPercentage[0], 40);
    assert.equal(tokenPercentage[1], 40);
    assert.equal(tokenPercentage[2], 20);
  });

  it("Should have proof of deposit price above 0", async () => {
    const drPodPrice = (await instance.getProofOfDepositPrice()).toNumber();
    assert.isAbove(drPodPrice, 0);
  });
};
