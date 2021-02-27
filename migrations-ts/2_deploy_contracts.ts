const DrcChildERC20 = artifacts.require("DRCChildERC20");

type Network = "development" | "ropsten" | "main";

module.exports = async (
  deployer: Truffle.Deployer,
  network: Network,
  // accounts: string[]
) => {
  await deployer.deploy(
    DrcChildERC20,
    "0x67667423dE274175338F238F0991feF92034fA28",
    "0x0446C2B191BCEb6E53b7c01A7135AfB550D3e8f6",
    "Digital Reserve Currency",
    "DRC",
    0
  );

  const drcChildERC20 = await DrcChildERC20.deployed();
  console.log(
    `Drc Child ERC20 deployed at ${drcChildERC20.address} in network: ${network}.`
  );
};

// because of https://stackoverflow.com/questions/40900791/cannot-redeclare-block-scoped-variable-in-unrelated-files
export {};
