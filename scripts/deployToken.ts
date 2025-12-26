import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deployer:",await deployer.getAddress());
  
  const MockWETH = await ethers.getContractFactory("MockWETH");
  const mockWeth = await MockWETH.deploy();
  await mockWeth.waitForDeployment();
  console.log("MockWETH:",await mockWeth.getAddress());

  const OracleRouter = await ethers.getContractFactory("OracleRouter");
  const router = await OracleRouter.deploy();
  await router.waitForDeployment();
  console.log("OracleRouter:",await router.getAddress());

  const MockERC20 = await ethers.getContractFactory("MockERC20");
  const mockLST = await MockERC20.deploy("Mock rETH", "rETH", 18);
  await mockLST.waitForDeployment();
  console.log("MockERC20 (rETH):",await mockLST.getAddress());

  await mockLST.mint(await deployer.getAddress(), ethers.parseEther("1000"));
  console.log("Minted 1000 rETH to deployer");

  const MockAggregator = await ethers.getContractFactory("MockAggregator");
  const mockAgg = await MockAggregator.deploy("312800000000", 8); // 3128 * 1e8
  await mockAgg.waitForDeployment();
  console.log("MockAggregator:",await mockAgg.getAddress());

  // Set feed in router (asset=mockLST => aggregator=mockAgg)
  await router.setFeed(await mockLST.getAddress(),await mockAgg.getAddress(), 8, true);
  console.log("Set feed: rETH -> mockAgg");

  console.log("✅ Mocks waitForDeployment & router configured.");
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});