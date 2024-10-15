import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const FlashloanArbitrage = await ethers.getContractFactory("FlashloanArbitrage");
  const flashloanArbitrage = await FlashloanArbitrage.deploy(
    "0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e", // Aave V3 PoolAddressesProvider-Mainnet
    "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", // Uniswap V2 Router
    "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F", // Sushiswap Router
    deployer.address // Initial owner
  );

  await flashloanArbitrage.deployed();

  console.log("FlashloanArbitrage deployed to:", flashloanArbitrage.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });