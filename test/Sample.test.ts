import { BigNumber, BigNumberish } from 'ethers'

import { BankAttack, Bank2 } from '../typechain'
import { HARDHAT_ACCS_PUB_KEYS } from '../hardhat.config'

import { expect } from 'chai'

import { setupUser, setupUsers } from './utils/index'
import { ethers, deployments, getNamedAccounts, getUnnamedAccounts, time, network } from 'hardhat'
import { BNToNumstr } from '../gotbit-tools/hardhat/extensions/bignumber'

const nonExistentFuncSignature = 'nonExistentFunction(uint256,uint256)'

async function setup() {
  await deployments.fixture(['Bank2', 'Attack'])

  const contracts = {
    bank: (await ethers.getContract('Bank2')) as Bank2,
    attack: (await ethers.getContract('Attack')) as BankAttack,
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
      const { bank, attack, deployer, backend, feeAddress, users } = await setup()
      const userSigner = ethers.getSigner(deployer.address)

      console.log(BNToNumstr(await ethers.provider.getBalance(bank.address), 18, 4))
      await deployer.attack.hack1({ value: ethers.utils.parseEther('0.005') })
      console.log(BNToNumstr(await ethers.provider.getBalance(bank.address), 18, 4))
      await deployer.attack.hack2({ value: ethers.utils.parseEther('0.005') })
      console.log(BNToNumstr(await ethers.provider.getBalance(bank.address), 18, 4))

      console.log(BNToNumstr(await ethers.provider.getBalance(deployer.address), 18, 4))
      await deployer.attack.withdraw()
      console.log(BNToNumstr(await ethers.provider.getBalance(deployer.address), 18, 4))
    })
  })
})
