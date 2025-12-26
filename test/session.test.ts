import { expect } from "chai";
import { ethers, network } from "hardhat";

describe("SessionPermissionVerifier + SessionExecutor", function () {
  it("should allow executing whitelisted call via SessionExecutor", async () => {
    const [owner, user, agent] = await ethers.getSigners();

    // Deploy verifier
    const Verifier = await ethers.getContractFactory("SessionPermissionVerifier");
    const verifier = await Verifier.connect(owner).deploy();
    await verifier.waitForDeployment();

    // Deploy executor
    const Executor = await ethers.getContractFactory("SessionExecutor");
    const executor = await Executor.connect(owner).deploy(await verifier.getAddress());
    await executor.waitForDeployment();

    // Deploy target contract
    const MockTarget = await ethers.getContractFactory("MockTarget");
    const target = await MockTarget.connect(owner).deploy();
    await target.waitForDeployment();

    // Compute selector for ping(uint256)
    const selector = ethers.dataSlice(target.interface.encodeFunctionData("ping", [0]), 0, 4);

    // user grants permission: target + selector
    await verifier.connect(user).grantPermission(await target.getAddress(), selector, 0);

    // prepare calldata for ping(123)
    const data = target.interface.encodeFunctionData("ping", [123]);

    // agent executes on behalf of user
    await expect(executor.connect(agent).execute(await user.getAddress(), await target.getAddress(), data))
      .to.emit(executor, "CallExecuted");

    // verify state updated
    expect(await target.number()).to.equal(123);

    // IMPORTANT: lastCaller should be SessionExecutor address (because it does the call)
    expect(await target.lastCaller()).to.equal(await executor.getAddress());
  });

  it("should reject non-whitelisted call", async () => {
    const [owner, user, agent] = await ethers.getSigners();

    const Verifier = await ethers.getContractFactory("SessionPermissionVerifier");
    const verifier = await Verifier.connect(owner).deploy();
    await verifier.waitForDeployment();

    const Executor = await ethers.getContractFactory("SessionExecutor");
    const executor = await Executor.connect(owner).deploy(await verifier.getAddress());
    await executor.waitForDeployment();

    const MockTarget = await ethers.getContractFactory("MockTarget");
    const target = await MockTarget.connect(owner).deploy();
    await target.waitForDeployment();

    const selector = ethers.dataSlice(target.interface.encodeFunctionData("ping", [0]), 0, 4);

    // user does NOT grant permission for this selector+target pairing

    const data = target.interface.encodeFunctionData("ping", [999]);

    await expect(
      executor.connect(agent).execute(await user.getAddress(),await target.getAddress(), data)
    ).to.be.revertedWith("SessionExecutor: permission denied");
  });

  it("should enforce expiry", async () => {
    const [owner, user, agent] = await ethers.getSigners();

    const Verifier = await ethers.getContractFactory("SessionPermissionVerifier");
    const verifier = await Verifier.connect(owner).deploy();
    await verifier.waitForDeployment();

    const Executor = await ethers.getContractFactory("SessionExecutor");
    const executor = await Executor.connect(owner).deploy(await verifier.getAddress());
    await executor.waitForDeployment();

    const MockTarget = await ethers.getContractFactory("MockTarget");
    const target = await MockTarget.connect(owner).deploy();
    await target.waitForDeployment();

    const selector = ethers.dataSlice(target.interface.encodeFunctionData("ping", [0]), 0, 4);

    const now = (await ethers.provider.getBlock("latest")).timestamp;
    const expiry = now + 5; // 5 seconds
    await verifier.connect(user).grantPermission(await target.getAddress(), selector, expiry);

    const data = target.interface.encodeFunctionData("ping", [1]);

    // should work before expiry
    await executor.connect(agent).execute(await user.getAddress(),await target.getAddress(), data);

    // move time forward past expiry
    await network.provider.send("evm_increaseTime", [10]);
    await network.provider.send("evm_mine");

    await expect(
      executor.connect(agent).execute(await user.getAddress(),await target.getAddress(), data)
    ).to.be.revertedWith("SessionExecutor: permission denied");
  });

  it("should revoke permission", async () => {
    const [owner, user, agent] = await ethers.getSigners();

    const Verifier = await ethers.getContractFactory("SessionPermissionVerifier");
    const verifier = await Verifier.connect(owner).deploy();
    await verifier.waitForDeployment();

    const Executor = await ethers.getContractFactory("SessionExecutor");
    const executor = await Executor.connect(owner).deploy(await verifier.getAddress());
    await executor.waitForDeployment();

    const MockTarget = await ethers.getContractFactory("MockTarget");
    const target = await MockTarget.connect(owner).deploy();
    await target.waitForDeployment();

    const selector = ethers.dataSlice(target.interface.encodeFunctionData("ping", [0]), 0, 4);

    // grant permission id=0 (first permission)
    await verifier.connect(user).grantPermission(await target.getAddress(), selector, 0);

    const data = target.interface.encodeFunctionData("ping", [777]);

    // works
    await executor.connect(agent).execute(await user.getAddress(),await target.getAddress(), data);

    // revoke permission id=0
    await verifier.connect(user).revokePermission(0);

    await expect(
      executor.connect(agent).execute(await user.getAddress(),await target.getAddress(), data)
    ).to.be.revertedWith("SessionExecutor: permission denied");
  });
});
