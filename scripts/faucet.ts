import { ethers } from 'hardhat'
import { BigNumber } from 'ethers'
import { Bank2__factory, Attack__factory, Faucet__factory } from '../typechain'
import { BSC_RPC, ETH_RPC } from '../secrets.config'
import { BNToNumstr } from '../gotbit-tools/hardhat/extensions/bignumber'

import * as dotenv from 'dotenv'
dotenv.config()

const faucetInstanceAddr = "0x9db6A88A8333530453d0b30B60DAd09DcC50a807"
// const attackAddr = "0x85656ddf9a78d5492e707446C7F1ED07F4bF9c81"

const providerBSC = new ethers.providers.JsonRpcProvider(BSC_RPC)
const providerETH = new ethers.providers.JsonRpcProvider(ETH_RPC)
const walletPrivateKey = process.env.PRIVATE_TEST

const token = BigNumber.from(10).pow(18)

async function bsc() {}
async function eth() {
  const signer = new ethers.Wallet("1e0d463e0755a9d55c9956d26f991f067bebb7aa92c11c784bb9c3ccb1ad91bc", providerETH);
  const faucetContract = Faucet__factory.connect(faucetInstanceAddr, providerETH)
  console.log(BNToNumstr(await providerETH.getBalance(faucetInstanceAddr), 18, 3));
  
}

eth()
// bsc()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
