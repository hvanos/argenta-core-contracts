import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deployer:",await deployer.getAddress());

  const AgentRegistry = await ethers.getContractFactory("AgentRegistry");
  const agentRegistry = await AgentRegistry.deploy();
  await agentRegistry.waitForDeployment();
  console.log("AgentRegistry:",await agentRegistry.getAddress());

  const ReputationRegistry = await ethers.getContractFactory("ReputationRegistry");
  const rep = await ReputationRegistry.deploy();
  await rep.waitForDeployment();
  console.log("ReputationRegistry:",await rep.getAddress());

  const ValidationRegistry = await ethers.getContractFactory("ValidationRegistry");
  const val = await ValidationRegistry.deploy();
  await val.waitForDeployment();
  console.log("ValidationRegistry:",await val.getAddress());

  console.log("✅ Agent registries waitForDeployment");
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
