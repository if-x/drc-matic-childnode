"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const DigitalReserve = artifacts.require("DigitalReserve");
module.exports = async (deployer, network, accounts) => {
    await deployer.deploy(DigitalReserve, "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", "0x6D38D09eb9705A5Fb1b8922eA80ea89d438159C7", "Digital Reserve");
    const digitalReserve = await DigitalReserve.deployed();
    console.log(`DigitalReserve deployed at ${digitalReserve.address} in network: ${network}.`);
};
