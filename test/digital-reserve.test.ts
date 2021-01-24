import { testSetStrategy } from "./test-cases/set-strategy";
import { testInitialDeposit } from "./test-cases/initial-deposit";
import { testInitialSupply } from "./test-cases/initial-supply";
import { testSecondDeposit } from "./test-cases/second-deposit";

contract("DigitalReserve", (accounts) => {
  describe("Initial supplies", async () => testInitialSupply());

  describe("Set Strategy", async () => testSetStrategy());

  describe("Deposit 1000 DRC", async () => testInitialDeposit(accounts));

  describe("Deposit 1000000 DRC", async () => testSecondDeposit(accounts));

  describe("Rebalance", async () => {});

  describe("Change Strategy", async () => {});

  describe("Withdrawal", async () => {});
});
