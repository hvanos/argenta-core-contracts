import { expect } from "chai";
import { ethers } from "hardhat";

describe("Argenta ArgentaVault", function () {
  it("should allow opening a vault, depositing collateral, borrowing and repaying", async () => {
    const [owner, other] = await ethers.getSigners();

    const MockWETH = await ethers.getContractFactory("MockWETH");
    const weth = await MockWETH.connect(owner).deploy();
    await weth.waitForDeployment();

    const Stablecoin = await ethers.getContractFactory("Stablecoin");
    const stable = await Stablecoin.connect(owner).deploy("Argenta USD", "USDa");
    await stable.waitForDeployment();

    const CollateralRegistry = await ethers.getContractFactory("CollateralRegistry");
    const collRegistry = await CollateralRegistry.connect(owner).deploy();
    await collRegistry.waitForDeployment();

    await (await collRegistry.connect(owner).setCollateral(
      await weth.getAddress(),
      15000,
      13000,
      ethers.parseEther("100000"),
      true
    )).wait();

    const InterestRateModel = await ethers.getContractFactory("InterestRateModel");
    const interestModel = await InterestRateModel.connect(owner).deploy(ethers.parseUnits("0.05", 18));
    await interestModel.waitForDeployment();

    const SafetyGuard = await ethers.getContractFactory("SafetyGuard");
    const safetyGuard = await SafetyGuard.connect(owner).deploy(
      ethers.parseUnits("10000000", 18),
      ethers.parseUnits("1000000", 18),
      ethers.parseUnits("100000", 18)
    );
    await safetyGuard.waitForDeployment();

    const OracleRouter = await ethers.getContractFactory("OracleRouter");
    const oracle = await OracleRouter.connect(owner).deploy();
    await oracle.waitForDeployment();

    const MockAggregator = await ethers.getContractFactory("MockAggregator");
    const mockAggregator = await MockAggregator.connect(owner).deploy("200000000000", 8);
    await mockAggregator.waitForDeployment();

    await (await oracle.connect(owner).setFeed(await weth.getAddress(), await mockAggregator.getAddress(), 8, true)).wait();

    const DebtEngine = await ethers.getContractFactory("DebtEngine");
    const debtEngine = await DebtEngine.connect(owner).deploy(await stable.getAddress());
    await debtEngine.waitForDeployment();

    await (await stable.connect(owner).setDebtEngine(await debtEngine.getAddress())).wait();

    const ArgentaVault = await ethers.getContractFactory("ArgentaVault");
    const cdpVault = await ArgentaVault.connect(owner).deploy(
      await collRegistry.getAddress(),
      await debtEngine.getAddress(),
      await oracle.getAddress(),
      await safetyGuard.getAddress(),
      await interestModel.getAddress()
    );
    await cdpVault.waitForDeployment();

    await (await debtEngine.connect(owner).setVault(await cdpVault.getAddress())).wait();

    const tx = await cdpVault.connect(other).openVault();
    const receipt = await tx.wait();
    const parsed = receipt!.logs
      .map((l: any) => { try { return cdpVault.interface.parseLog(l); } catch { return null; } })
      .find((x: any) => x && x.name === "VaultOpened");
    const vaultId = parsed!.args.vaultId;

    const depositAmount = ethers.parseEther("1");
    await weth.connect(other).mint(await other.getAddress(), depositAmount);
    await weth.connect(other).approve(await cdpVault.getAddress(), depositAmount);
    await (await cdpVault.connect(other).addCollateral(
      vaultId,
      await weth.getAddress(),
      depositAmount
    )).wait();

    const borrowAmount = ethers.parseEther("500");
    await (await cdpVault.connect(other).borrow(vaultId, borrowAmount)).wait();

    // repay all
    await (await stable.connect(other).approve(await cdpVault.getAddress(), borrowAmount)).wait();
    await (await cdpVault.connect(other).repay(vaultId, borrowAmount)).wait();

    expect(await stable.balanceOf(await other.getAddress())).to.equal(0n);
  });
});
