## requirements
- NodeJS v24.12.0
- Yarn v1.22.22
## installation
```bash
yarn install 
```
or
```bash
yarn install --frozen-lockfile
```
## compile
to compiling the smart contracts run
```bash
yarn compile
```
or
```bash
yarn hardhat compile
```
## test
to testing the smart contracts run
```bash
yarn test
```
or
```bash
yarn hardhat test
```
or
```bash
yarn hardhat test --network hardhat
```
## Error log
```
 Agent registries (ERC-8004 style) - basics
    ✔ register agent, update reputation, submit validation (493ms)

  ArgentaVault basic CDP flow
    1) open vault, add ETH collateral, borrow, repay, close

  Argenta ArgentaVault
    2) should allow opening a vault, depositing collateral, borrowing and repaying

  SessionPermissionVerifier + SessionExecutor
    3) should allow executing whitelisted call via SessionExecutor
    ✔ should reject non-whitelisted call (191ms)
    4) should enforce expiry
    5) should revoke permission


  2 passing (2s)
  5 failing

  1) ArgentaVault basic CDP flow
       open vault, add ETH collateral, borrow, repay, close:
     ReferenceError: Cannot access 'ethAgg' before initialization
      at Context.<anonymous> (test/initial.test.ts:54:37)

  2) Argenta ArgentaVault
       should allow opening a vault, depositing collateral, borrowing and repaying:
     Error: VM Exception while processing transaction: reverted with reason string 'CollateralRegistry: zero address'
    at CollateralRegistry.setCollateral (contracts/CollateralRegistry.sol:27)
    at EdrProviderWrapper.request (node_modules/hardhat/src/internal/hardhat-network/provider/provider.ts:455:41)
    at async HardhatEthersSigner.sendTransaction (node_modules/@nomicfoundation/hardhat-ethers/src/signers.ts:185:18)
    at async send (node_modules/ethers/src.ts/contract/contract.ts:313:20)
    at async Proxy.setCollateral (node_modules/ethers/src.ts/contract/contract.ts:352:16)
    at async Context.<anonymous> (test/protocol.test.ts:16:12)


  3) SessionPermissionVerifier + SessionExecutor
       should allow executing whitelisted call via SessionExecutor:
     Error: VM Exception while processing transaction: reverted with reason string 'SessionExecutor: permission denied'
    at SessionExecutor.transferOwnership (@openzeppelin/contracts/access/Ownable.sol:86)
    at SessionExecutor.execute (contracts/legacy/sessions/SessionExecutor.sol:31)
    at EdrProviderWrapper.request (node_modules/hardhat/src/internal/hardhat-network/provider/provider.ts:455:41)
    at async HardhatEthersSigner.sendTransaction (node_modules/@nomicfoundation/hardhat-ethers/src/signers.ts:185:18)
    at async send (node_modules/ethers/src.ts/contract/contract.ts:313:20)
    at async Proxy.execute (node_modules/ethers/src.ts/contract/contract.ts:352:16)
    at async waitForPendingTransaction (node_modules/@nomicfoundation/hardhat-chai-matchers/src/internal/emit.ts:28:17)
    at async Context.<anonymous> (test/session.test.ts:33:5)


  4) SessionPermissionVerifier + SessionExecutor
       should enforce expiry:
     Error: VM Exception while processing transaction: reverted with reason string 'SessionExecutor: permission denied'
    at SessionExecutor.transferOwnership (@openzeppelin/contracts/access/Ownable.sol:86)
    at SessionExecutor.execute (contracts/legacy/sessions/SessionExecutor.sol:31)
    at EdrProviderWrapper.request (node_modules/hardhat/src/internal/hardhat-network/provider/provider.ts:455:41)
    at async HardhatEthersSigner.sendTransaction (node_modules/@nomicfoundation/hardhat-ethers/src/signers.ts:185:18)
    at async send (node_modules/ethers/src.ts/contract/contract.ts:313:20)
    at async Proxy.execute (node_modules/ethers/src.ts/contract/contract.ts:352:16)
    at async Context.<anonymous> (test/session.test.ts:91:5)


  5) SessionPermissionVerifier + SessionExecutor
       should revoke permission:
     Error: VM Exception while processing transaction: reverted with reason string 'SessionExecutor: permission denied'
    at SessionExecutor.transferOwnership (@openzeppelin/contracts/access/Ownable.sol:86)
    at SessionExecutor.execute (contracts/legacy/sessions/SessionExecutor.sol:31)
    at EdrProviderWrapper.request (node_modules/hardhat/src/internal/hardhat-network/provider/provider.ts:455:41)
    at async HardhatEthersSigner.sendTransaction (node_modules/@nomicfoundation/hardhat-ethers/src/signers.ts:185:18)
    at async send (node_modules/ethers/src.ts/contract/contract.ts:313:20)
    at async Proxy.execute (node_modules/ethers/src.ts/contract/contract.ts:352:16)
    at async Context.<anonymous> (test/session.test.ts:125:5)
```
## notes
Please change or modify my entire test code to run this solidity smart contracts unit test.
I suggest you to do a personal test before you give the correct result. please do it carefully
