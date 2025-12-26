import { expect } from "chai";
import { ethers } from "hardhat";

describe("Agent registries (ERC-8004 style) - basics", function () {
  it("register agent, update reputation, submit validation", async () => {
    const [owner, agent, user] = await ethers.getSigners();

    const AgentRegistry = await ethers.getContractFactory("AgentRegistry");
    const agentRegistry = await AgentRegistry.connect(owner).deploy();
    await agentRegistry.waitForDeployment();

    const ReputationRegistry = await ethers.getContractFactory("ReputationRegistry");
    const rep = await ReputationRegistry.connect(owner).deploy();
    await rep.waitForDeployment();

    const ValidationRegistry = await ethers.getContractFactory("ValidationRegistry");
    const val = await ValidationRegistry.connect(owner).deploy();
    await val.waitForDeployment();

    // Agent self-registers
    await expect(agentRegistry.connect(agent).register("ipfs://agent-metadata"))
      .to.emit(agentRegistry, "AgentRegistered");

    const info = await agentRegistry.getAgent(await agent.getAddress());
    expect(info.active).to.equal(true);

    // Owner updates reputation score
    await expect(rep.connect(owner).setScore(await agent.getAddress(), 100))
      .to.emit(rep, "ScoreUpdated");

    expect(await rep.scoreOf(await agent.getAddress())).to.equal(100);

    // Submit validation (signature: submitValidation(address agent, bytes32 jobHash, bool valid))
    const jobHash = ethers.keccak256(ethers.toUtf8Bytes("job#1"));

    await expect(val.connect(user).submitValidation(await agent.getAddress(), jobHash, true))
      .to.emit(val, "ValidationSubmitted");

    // getValidation(uint256 id) - first record is id=0
    const rec = await val.getValidation(0);
    // rec is tuple: (agent, jobHash, valid, submitter, timestamp)
    expect(rec[0]).to.equal(await agent.getAddress());
    expect(rec[1]).to.equal(jobHash);
    expect(rec[2]).to.equal(true);
  });
});