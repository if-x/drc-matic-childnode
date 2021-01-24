import { DigitalReserveInstance } from "../types/truffle-contracts";
import { StrategyChange } from "../types/truffle-contracts/DigitalReserve";
import { assertRevert } from "../utils/assertions";
import { getUnitTimeAfterMins } from "../utils/timestamp";

const DigitalReserve = artifacts.require("DigitalReserve");

contract("DigitalReserve", (accounts) => {
  let instance: DigitalReserveInstance;
  const owner = accounts[1];
  const userA = accounts[2];

  before(async () => {
    instance = await DigitalReserve.deployed();
  });

  it("Should have initial supply 0", async () => {
    const totalSupply = (await instance.totalSupply()).toNumber();
    assert.equal(totalSupply, 0);

    const strateyTokenCount = (await instance.strategyTokenCount()).toNumber();
    assert.equal(strateyTokenCount, 0);
  });

  it("Should set strategy correctly", async () => {
    await assertRevert(
      instance.changeStrategy([], [], 0, getUnitTimeAfterMins(10)),
      "Setting strategy to 0 tokens.",
      "Can't set strategy to empty array"
    );

    await assertRevert(
      instance.changeStrategy(
        [
          "0x0B6D10102bbB04a0CA2Dc49d1b38bD9A788832FD",
          "0x478640c8D01CAc92Ffcd4a15EaC1408Be52BA47A",
        ],
        [60, 40],
        3,
        getUnitTimeAfterMins(10)
      ),
      "Token count doesn't match tokens length.",
      "Can't set strategy count to wrong length"
    );

    await assertRevert(
      instance.changeStrategy(
        [
          "0x0B6D10102bbB04a0CA2Dc49d1b38bD9A788832FD",
          "0x478640c8D01CAc92Ffcd4a15EaC1408Be52BA47A",
        ],
        [50, 40],
        2,
        getUnitTimeAfterMins(10)
      ),
      "Total token percentage is not 100%.",
      "Wrong percentage"
    );

    const result = await instance.changeStrategy(
      [
        "0x0B6D10102bbB04a0CA2Dc49d1b38bD9A788832FD",
        "0x478640c8D01CAc92Ffcd4a15EaC1408Be52BA47A",
      ],
      [50, 50],
      2,
      getUnitTimeAfterMins(10)
    );

    console.log(result.tx);
    console.log(result.logs);

    const matchingLog = result.logs.find(
      (log) => log.event === "StrategyChange"
    ) as StrategyChange | undefined;

    assert.exists(matchingLog);

    if (matchingLog) {
      assert.equal(matchingLog.args.newTokens[0], '0x0B6D10102bbB04a0CA2Dc49d1b38bD9A788832FD');
      assert.equal(matchingLog.args.newTokens[1], '0x478640c8D01CAc92Ffcd4a15EaC1408Be52BA47A');
      assert.equal(matchingLog.args.newPercentage[0].toNumber(), 50);
      assert.equal(matchingLog.args.newPercentage[1].toNumber(), 50);
    }
  });
});
