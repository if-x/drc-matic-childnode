const Migrations = artifacts.require("Migrations");

module.exports = function (deployer, network, accounts) {
  console.log(web3.eth.getBalance(accounts[1]));

  deployer.deploy(Migrations);
} as Truffle.Migration;

// because of https://stackoverflow.com/questions/40900791/cannot-redeclare-block-scoped-variable-in-unrelated-files
export {};
