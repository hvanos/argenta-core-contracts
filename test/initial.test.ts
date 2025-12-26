import { expect } from "chai";
import { ethers } from "hardhat";

describe("ArgentaVault basic CDP flow", function () {
  it("open vault, add ETH collateral, borrow, repay, close", async () => {
    const [deployer, user] = await ethers.getSigners();

    const MockWETH = await ethers.getContractFactory("MockWETH");
    const weth = await MockWETH.connect(deployer).deploy();
    await weth.waitForDeployment();

    const MockAggregator = await ethers.getContractFactory("MockAggregator");
    const ethAgg = await MockAggregator.connect(deployer).deploy("200000000000", 8);
    await ethAgg.waitForDeployment();

    const Stablecoin = await ethers.getContractFactory("Stablecoin");
    const stable = await Stablecoin.connect(deployer).deploy("Argenta USD", "USDa");
    await stable.waitForDeployment();

    const CollateralRegistry = await ethers.getContractFactory("CollateralRegistry");
    const registry = await CollateralRegistry.connect(deployer).deploy();
    await registry.waitForDeployment();

    const OracleRouter = await ethers.getContractFactory("OracleRouter");
    const oracle = await OracleRouter.connect(deployer).deploy();
    await oracle.waitForDeployment();

    const SafetyGuard = await ethers.getContractFactory("SafetyGuard");
    const guard = await SafetyGuard.connect(deployer).deploy(
      ethers.parseEther("10000000"),
      ethers.parseEther("1000000"),
      ethers.parseEther("100000")
    );
    await guard.waitForDeployment();

    const InterestRateModel = await ethers.getContractFactory("InterestRateModel");
    const irm = await InterestRateModel.connect(deployer).deploy(ethers.parseEther("0.05"));
    await irm.waitForDeployment();

    const DebtEngine = await ethers.getContractFactory("DebtEngine");
    const debtEngine = await DebtEngine.connect(deployer).deploy(await stable.getAddress());
    await debtEngine.waitForDeployment();

    // IMPORTANT: owner-only
    await (await stable.connect(deployer).setDebtEngine(await debtEngine.getAddress())).wait();

    const ArgentaVault = await ethers.getContractFactory("ArgentaVault");
    const vault = await ArgentaVault.connect(deployer).deploy(
      await registry.getAddress(),
      await debtEngine.getAddress(),
      await oracle.getAddress(),
      await guard.getAddress(),
      await irm.getAddress()
    );
    await vault.waitForDeployment();

    await (await debtEngine.connect(deployer).setVault(await vault.getAddress())).wait();

    await registry.connect(deployer).setCollateral(
      await weth.getAddress(),
      15000,
      13000,
      ethers.parseEther("100000"),
      true
    );
    await oracle.connect(deployer).setFeed(await weth.getAddress(), await ethAgg.getAddress(), 8, true);

    const tx = await vault.connect(user).openVault();
    const rc = await tx.wait();
    const vaultId = rc?.logs
      ?.map((l: any) => { try { return vault.interface.parseLog(l); } catch { return null; } })
      ?.find((x: any) => x && x.name === "VaultOpened")?.args?.vaultId;

    const collateralAmount = ethers.parseEther("1");
    await weth.connect(user).mint(await user.getAddress(), collateralAmount);
    await weth.connect(user).approve(await vault.getAddress(), collateralAmount);
    await (await vault.connect(user).addCollateral(
      vaultId,
      await weth.getAddress(),
      collateralAmount
    )).wait();

    const borrowAmount = ethers.parseEther("500");
    await (await vault.connect(user).borrow(vaultId, borrowAmount)).wait();

    expect(await stable.balanceOf(await user.getAddress())).to.equal(borrowAmount);

    const repayAmount = ethers.parseEther("200");
    await (await stable.connect(user).approve(await vault.getAddress(), repayAmount)).wait();
    await (await vault.connect(user).repay(vaultId, repayAmount)).wait();

    const remaining = borrowAmount - repayAmount;
    await (await stable.connect(user).approve(await vault.getAddress(), remaining)).wait();
    await (await vault.connect(user).repay(vaultId, remaining)).wait();

    await (await vault.connect(user).closeVault(vaultId)).wait();
  });
});
