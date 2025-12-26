import { ethers } from "hardhat";

/**
 * Deploy Argenta core contracts:
 * - Stablecoin (USDa, with Permit)
 * - CollateralRegistry
 * - OracleRouter
 * - SafetyGuard
 * - InterestRateModel
 * - DebtEngine
 * - ArgentaVault
 * - LiquidationModule (optional) and wire it to vault
 */
async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deployer:",await deployer.getAddress());

  const Stablecoin = await ethers.getContractFactory("Stablecoin");
  const stable = await Stablecoin.deploy("Argenta USD", "USDa");
  await stable.waitForDeployment();
  console.log("Stablecoin:",await stable.getAddress());

  const CollateralRegistry = await ethers.getContractFactory("CollateralRegistry");
  const collateralRegistry = await CollateralRegistry.deploy();
  await collateralRegistry.waitForDeployment();
  console.log("CollateralRegistry:",await collateralRegistry.getAddress());

  const OracleRouter = await ethers.getContractFactory("OracleRouter");
  const oracle = await OracleRouter.deploy();
  await oracle.waitForDeployment();
  console.log("OracleRouter:",await oracle.getAddress());

  const SafetyGuard = await ethers.getContractFactory("SafetyGuard");
  const guard = await SafetyGuard.deploy();
  await guard.waitForDeployment();
  console.log("SafetyGuard:",await guard.getAddress());

  const InterestRateModel = await ethers.getContractFactory("InterestRateModel");
  const irm = await InterestRateModel.deploy(ethers.parseEther("0.05"));
  await irm.waitForDeployment();
  console.log("InterestRateModel:",await irm.getAddress());

  const DebtEngine = await ethers.getContractFactory("DebtEngine");
  const debtEngine = await DebtEngine.deploy(stable.getAddress());
  await debtEngine.waitForDeployment();
  console.log("DebtEngine:",await debtEngine.getAddress());
  // set Stablecoin
  await (
    await stable.setDebtEngine(await debtEngine.getAddress())).wait();
  console.log("Stablecoin setted")

  const ArgentaVault = await ethers.getContractFactory("ArgentaVault");
  const vault = await ArgentaVault.deploy(
    await collateralRegistry.getAddress(),
    await debtEngine.getAddress(),
    await oracle.getAddress(),
    await guard.getAddress(),
    await irm.getAddress()
  );
  await vault.waitForDeployment();
  console.log("ArgentaVault:",await vault.getAddress());

  // Wire vault into DebtEngine (also sets DebtEngine in Stablecoin)
  await (await debtEngine.setVault(await vault.getAddress())).wait();
  console.log("Vault setted");

  // Optional liquidation module
  const LiquidationModule = await ethers.getContractFactory("LiquidationModule");
  const liquidation = await LiquidationModule.deploy();
  await liquidation.waitForDeployment();
  console.log("LiquidationModule:",await  liquidation.getAddress());

  await (await liquidation.setVault(await vault.getAddress())).wait();
  console.log("LiquidationModule.setVault done");

  console.log("Deployment success");
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
