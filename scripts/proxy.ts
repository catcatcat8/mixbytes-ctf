import { ethers } from 'hardhat'
import { BigNumber } from 'ethers'
import { Bank2__factory, Attack__factory, Faucet__factory, BucketsProxy__factory, Buckets__factory } from '../typechain'
import { BSC_RPC, ETH_RPC } from '../secrets.config'
import { BNToNumstr } from '../gotbit-tools/hardhat/extensions/bignumber'

import * as dotenv from 'dotenv'
dotenv.config()

const proxyInstanceAddr = "0x9A848B15f31A36F1B2683E3f20A00ef70C3c2d21"
// const attackAddr = "0x85656ddf9a78d5492e707446C7F1ED07F4bF9c81"

const providerBSC = new ethers.providers.JsonRpcProvider(BSC_RPC)
const providerETH = new ethers.providers.JsonRpcProvider(ETH_RPC)
const walletPrivateKey = process.env.PRIVATE_TEST

const token = BigNumber.from(10).pow(18)

async function bsc() {}
async function eth() {
  const signer = new ethers.Wallet("1e0d463e0755a9d55c9956d26f991f067bebb7aa92c11c784bb9c3ccb1ad91bc", providerETH);
  const proxyContract = BucketsProxy__factory.connect(proxyInstanceAddr, providerETH)
  console.log(BNToNumstr(await providerETH.getBalance(proxyInstanceAddr), 18, 3));
  
  const bucketsContract = Buckets__factory.connect(proxyInstanceAddr, providerETH)
  console.log(BNToNumstr(await bucketsContract.totalSupply(), 18, 3));
  console.log(BNToNumstr(await bucketsContract.balanceOf(proxyInstanceAddr), 18, 3));
  console.log(await providerETH.getStorageAt(proxyInstanceAddr, "0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103"))
}

eth()
// bsc()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
