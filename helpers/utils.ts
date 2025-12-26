import { BigNumber, ethers } from "ethers";


export function toWei(amount: string | number): BigNumber {
  return ethers.parseUnits(String(amount), 18);
}

export function computeHealthFactor(collateralValue: BigNumber, debt: BigNumber): BigNumber {
  if (debt.isZero()) return BigNumber.from(2).pow(255);
  return collateralValue.mul(ethers.constants.WeiPerEther).div(debt);
}