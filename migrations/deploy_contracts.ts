type Network = "development" | "ropsten" | "mainnet";

export default (artifacts: Truffle.Artifacts, web3: Web3) => {
  return async (
    deployer: Truffle.Deployer,
    network: Network,
    accounts: string[]
  ) => {
    const DigitalReserve = artifacts.require("DigitalReserve");

    await deployer.deploy(
      DigitalReserve,
      "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
      "0x9493193586338679486747baADc5231621fa9ad0",
      "Digital Reserve",
      "DR-POD"
    );

    const digitalReserve = await DigitalReserve.deployed();
    console.log(
      `DigitalReserve deployed at ${digitalReserve.address} in network: ${network}.`
    );
  };
};
