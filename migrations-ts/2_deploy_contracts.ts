import { getContractAddress } from "../utils/contract-by-network";

const DigitalReserve = artifacts.require("DigitalReserve");

type Network = "development" | "ropsten" | "mainnet";

module.exports = async (
  deployer: Truffle.Deployer,
  network: Network,
  accounts: string[]
) => {
  await deployer.deploy(
    DigitalReserve,
    getContractAddress("uniswap", network),
    getContractAddress("drc", network),
    "Digital Reserve"
  );

  const digitalReserve = await DigitalReserve.deployed();
  console.log(
    `DigitalReserve deployed at ${digitalReserve.address} in network: ${network}.`
  );
};

// because of https://stackoverflow.com/questions/40900791/cannot-redeclare-block-scoped-variable-in-unrelated-files
export {};
