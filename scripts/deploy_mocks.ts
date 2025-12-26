import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deployer:",await deployer.getAddress());

  const existingRouter = process.env.ORACLE_ROUTER;
  let router: any;

  if (existingRouter && existingRouter !== "") {
    const OracleRouter = await ethers.getContractFactory("OracleRouter");
    router = OracleRouter.attach(existingRouter);
    console.log("Using existing OracleRouter:",await router.getAddress());
  } else {
    const OracleRouter = await ethers.getContractFactory("OracleRouter");
    router = await OracleRouter.deploy();
    await router.waitForDeployment();
    console.log("OracleRouter:",await router.getAddress());
  }

  // MockERC20
  const MockERC20 = await ethers.getContractFactory("MockERC20");
  const mockLST = await MockERC20.deploy("stETH", "stETH", 18);
  await mockLST.waitForDeployment();
  console.log("Address:",await mockLST.getAddress());

  // Mint some to deployer for demo
  const mintAmount = ethers.parseEther("1000");
  await (await mockLST.mint(await deployer.getAddress(), mintAmount)).wait();
  console.log("Minted:", ethers.formatEther(mintAmount));

  const MockAggregator = await ethers.getContractFactory("MockAggregator");
  const mockAgg = await MockAggregator.deploy("312800000000", 8);
  await mockAgg.waitForDeployment();
  console.log("MockAggregator:",await mockAgg.getAddress());

  // Configure router feed
  await (await router.setFeed(await mockLST.getAddress(),await mockAgg.getAddress(), 8, true)).wait();
  console.log("Configured feed: stETH -> MockAggregator");

  console.log("✅ deploy_mocks done");
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
