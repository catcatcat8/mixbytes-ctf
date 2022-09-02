import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

import { ethers, getUnnamedAccounts } from 'hardhat'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  const users = await getUnnamedAccounts()

  await deploy('ProfitableBusinessAttack', {
    from: deployer,
    args: [],
    log: true,
  })
}
export default func

func.tags = ['ProfitableBusinessAttack']
