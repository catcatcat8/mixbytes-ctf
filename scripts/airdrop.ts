import { ethers } from 'hardhat'
import { BigNumber } from 'ethers'
import { Airdrop__factory, ERC20__factory } from '../typechain'
import { BSC_RPC, ETH_RPC } from '../secrets.config'
import { BNToNumstr } from '../gotbit-tools/hardhat/extensions/bignumber'

import * as dotenv from 'dotenv'
dotenv.config()

const airdropAddr = '0xe3d370ab3f6d4357aee66c2d6cb2482c4aeb52d6'

const providerBSC = new ethers.providers.JsonRpcProvider(BSC_RPC)
const providerETH = new ethers.providers.JsonRpcProvider(ETH_RPC)
const walletPrivateKey = process.env.PRIVATE_TEST

const token = BigNumber.from(10).pow(18)

async function bsc() {}
async function eth() {
  const signer = new ethers.Wallet('1e0d463e0755a9d55c9956d26f991f067bebb7aa92c11c784bb9c3ccb1ad91bc', providerETH)
  const airdropContract = Airdrop__factory.connect(airdropAddr, signer)
  const tokenAddr = await airdropContract.token()
  const tokenContract = ERC20__factory.connect(tokenAddr, providerETH)

  console.log(tokenAddr)
  console.log(BNToNumstr(await tokenContract.balanceOf(airdropAddr), 18, 18))

  // console.log("token:", await providerETH.getStorageAt(airdropAddr, 0));
  // console.log("merkle root:", await providerETH.getStorageAt(airdropAddr, 2));
  // console.log("proof length", await providerETH.getStorageAt(airdropAddr, 3));
  // console.log("drop per address", await providerETH.getStorageAt(airdropAddr, 4));
  // console.log(await airdropContract.latestAcceptedProof());
  // console.log(BNToNumstr(await airdropContract.nextDrop(), 18, 3));
  const me = '0x0000000000000000000000006EF1032E74B0371BAa3cA64878d8984eFd1B7453'
  const proof1 = [
    me,
    '0x000000000000000000000000e1847514b5feb72377d013dbe6b84afb697fe047',
    '0xc2575a0e9e593c00f959f8c92f12db2869c3395a3b0502d05e2516446f71f85b',
    '0xacc32c7db2a7199078e7b849d965ef7ba2f28c979f3b40c61be7cf7864da3ac9',
  ]
  await (await airdropContract.withdraw(proof1)).wait()
  
  
  console.log(BNToNumstr(await tokenContract.balanceOf(airdropAddr), 18, 18))
}

eth()
  // bsc()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
