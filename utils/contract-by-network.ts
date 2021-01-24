type ContractName = "uniswap" | "drc" | "wbtc" | "paxg" | "usdc";
type NetworkType = "test" | "mainnet";
export type Network = "development" | "ropsten" | "mainnet";

type ContractAddresses = Record<ContractName, Record<NetworkType, string>>;

const contractAddresses: ContractAddresses = {
  uniswap: {
    test: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
    mainnet: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
  },
  drc: {
    test: "0x6D38D09eb9705A5Fb1b8922eA80ea89d438159C7",
    mainnet: "0xa150Db9b1Fa65b44799d4dD949D922c0a33Ee606",
  },
  wbtc: {
    test: "0x0B6D10102bbB04a0CA2Dc49d1b38bD9A788832FD",
    mainnet: "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599",
  },
  paxg: {
    test: "0x478640c8D01CAc92Ffcd4a15EaC1408Be52BA47A",
    mainnet: "0x45804880De22913dAFE09f4980848ECE6EcbAf78",
  },
  usdc: {
    test: "0x87c00648150d89651FB6C5C5993338DCfcA3Ff7B",
    mainnet: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
  },
};

export const getContractAddress = (
  name: ContractName,
  network: Network
): string => {
  const networkType: NetworkType = network === "mainnet" ? "mainnet" : "test";
  return contractAddresses[name][networkType];
};
