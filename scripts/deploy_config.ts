import { ethers } from "hardhat";

/**
 * Post-deploy configuration helper (Sepolia)
 *
 * This script configures:
 * - ETH collateral params in CollateralRegistry
 * - ETH/USD feed in OracleRouter
 *
 * Required env vars:
 *   COLLATERAL_REGISTRY=0x...
 *   ORACLE_ROUTER=0x...
 *
 * Optional:
 *   ETH_AGGREGATOR=0x...  (use an existing Chainlink feed address)
 * If ETH_AGGREGATOR is not provided, this script deploys a MockAggregator and wires it.
 *
 * Run:
 *   COLLATERAL_REGISTRY=0x... ORACLE_ROUTER=0x... npx hardhat run scripts/deploy_config.ts --network sepolia
 */
async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", await deployer.getAddress());

  const collateralRegistryAddr = process.env.COLLATERAL_REGISTRY;
  const oracleRouterAddr = process.env.ORACLE_ROUTER;

  if (!collateralRegistryAddr || !oracleRouterAddr) {
    throw new Error("Missing env: COLLATERAL_REGISTRY and/or ORACLE_ROUTER");
  }

  const CollateralRegistry = await ethers.getContractFactory("CollateralRegistry");
  const registry = CollateralRegistry.attach(collateralRegistryAddr);

  const OracleRouter = await ethers.getContractFactory("OracleRouter");
  const oracle = OracleRouter.attach(oracleRouterAddr);

  // Configure ETH as collateral
  // mcr=15000 (150%), liqThreshold=13000 (130%), cap=100000 ETH, active=true
  console.log("Setting ETH collateral params...");
  await (await registry.setCollateral(
    ethers.ZeroAddress,
    15000,
    13000,
    ethers.parseEther("100000"),
    true
  )).wait();
  console.log("ETH collateral configured");

  // Configure ETH/USD feed
  let aggregator = process.env.ETH_AGGREGATOR;
  let decimals = 8;

  if (!aggregator) {
    console.log("ETH_AGGREGATOR not provided, deploying MockAggregator...");
    const MockAggregator = await ethers.getContractFactory("MockAggregator");
    // 2000 * 1e8
    const mock = await MockAggregator.deploy("298100000000", decimals);
    await mock.waitForDeployment();
    aggregator = await mock.getAddress();
    console.log("MockAggregator:", aggregator);
  } else {
    console.log("Using ETH_AGGREGATOR:", aggregator);
  }

  console.log("Setting OracleRouter feed for ETH...");
  await (await oracle.setFeed(ethers.ZeroAddress, aggregator, decimals, true)).wait();
  console.log("ETH feed configured");

  console.log("✅ deploy_config done");
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
