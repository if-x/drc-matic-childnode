import { DigitalReserveInstance } from "../types/truffle-contracts";
import { StrategyChange } from "../types/truffle-contracts/DigitalReserve";
// import { assertRevert } from "../utils/assertions";
import { getUnitTimeAfterMins } from "../utils/timestamp";

const DigitalReserve = artifacts.require("DigitalReserve");

contract("DigitalReserve", (accounts) => {
  let instance: DigitalReserveInstance;
  const owner = accounts[1];
  const userA = accounts[2];

  before(async () => {
    instance = await DigitalReserve.deployed();
  });

  it("Should set strategy correctly", async () => {
    const result = await instance.changeStrategy(
      [
        "0x0B6D10102bbB04a0CA2Dc49d1b38bD9A788832FD",
        "0x478640c8D01CAc92Ffcd4a15EaC1408Be52BA47A",
        "0x87c00648150d89651FB6C5C5993338DCfcA3Ff7B",
      ],
      [40, 40, 20],
      3,
      getUnitTimeAfterMins(10)
    );

    const matchingLog = result.logs.find(
      (log) => log.event === "StrategyChange"
    ) as StrategyChange | undefined;

    assert.exists(matchingLog);

    if (matchingLog) {
      assert.equal(matchingLog.args.newTokens[0], '0x0B6D10102bbB04a0CA2Dc49d1b38bD9A788832FD');
      assert.equal(matchingLog.args.newTokens[1], '0x478640c8D01CAc92Ffcd4a15EaC1408Be52BA47A');
      assert.equal(matchingLog.args.newTokens[2], '0x87c00648150d89651FB6C5C5993338DCfcA3Ff7B');
      assert.equal(matchingLog.args.newPercentage[0].toNumber(), 40);
      assert.equal(matchingLog.args.newPercentage[1].toNumber(), 40);
      assert.equal(matchingLog.args.newPercentage[2].toNumber(), 20);
    }
  });
});
