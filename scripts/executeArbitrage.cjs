import { ethers } from "hardhat";

async function main() {
  const FlashloanArbitrage = await ethers.getContractFactory("FlashloanArbitrage");
  const flashloanArbitrage = await FlashloanArbitrage.attach("DEPLOYED_CONTRACT_ADDRESS");

  const DAI_ADDRESS = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
  const LOAN_AMOUNT = ethers.utils.parseEther("1000"); // 1000 DAI

  const tx = await flashloanArbitrage.executeArbitrage(DAI_ADDRESS, LOAN_AMOUNT);
  await tx.wait();

  console.log("Arbitrage executed successfully");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });