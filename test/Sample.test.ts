import { BigNumber, BigNumberish } from 'ethers'

import { ProfitableBusiness } from '../typechain'
import { HARDHAT_ACCS_PUB_KEYS } from '../hardhat.config'

import { expect } from 'chai'

import { setupUser, setupUsers } from './utils/index'
import { ethers, deployments, getNamedAccounts, getUnnamedAccounts, time, network } from 'hardhat'
import { BNToNumstr } from '../gotbit-tools/hardhat/extensions/bignumber'
import { ProfitableBusinessAttack } from '../typechain/contracts/ProfitableBusinessAttack'

const nonExistentFuncSignature = 'nonExistentFunction(uint256,uint256)'

async function setup() {
  await deployments.fixture(['ProfitableBusiness', 'ProfitableBusinessAttack'])

  const contracts = {
    mmm: (await ethers.getContract('ProfitableBusiness')) as ProfitableBusiness,
    mmmAttack: (await ethers.getContract('ProfitableBusinessAttack')) as ProfitableBusinessAttack
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
      const { mmm, mmmAttack, deployer, backend, feeAddress, users } = await setup()
      await deployer.mmm.enhanceDepositProfitability(1, 1)
      await deployer.mmm.mint({ value: BigNumber.from(10).pow(8) })
      await deployer.mmm.enhanceDepositProfitability(100, 1000000)
      console.log('contract balance:', await (await ethers.provider.getBalance(mmm.address)).toString());
      console.log('profitability:', await (await mmm.profitability()).toString())
      console.log('base:', await (await mmm.base()).toString())
      console.log('owner balance:', await (await mmm.balanceOf(deployer.address)).toString())
      console.log('owner shares:', await (await mmm.shares(deployer.address)).toString())
      console.log("--------");
      
      await users[0].mmmAttack.fallback({value: BigNumber.from(10).pow(15)})
      await users[0].mmmAttack.hack(mmm.address)
      console.log('owner shares:', await (await mmm.shares(deployer.address)).toString())
    })
  })
})
