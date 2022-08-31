import { BigNumber, BigNumberish } from 'ethers'

import { Challenge, Attack } from '../typechain'
import { HARDHAT_ACCS_PUB_KEYS } from '../hardhat.config'

import { expect } from 'chai'

import { setupUser, setupUsers } from './utils/index'
import {
  ethers,
  deployments,
  getNamedAccounts,
  getUnnamedAccounts,
  time,
  network,
} from 'hardhat'

async function setup() {
  await deployments.fixture(['Challenge', 'Attack'])

  const contracts = {
    challenge: (await ethers.getContract('Challenge')) as Challenge,
    attack: (await ethers.getContract('Attack')) as Attack,
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
    it('Should successfully define passed parameters to fields', async () => {
      const { challenge, attack, deployer, backend, feeAddress, users } = await setup()
      console.log(await attack.flag());
      await users[0].attack.hack(challenge.address);
      console.log(await attack.flag());
      // console.log(await challenge.flag());
    })
  })
})
