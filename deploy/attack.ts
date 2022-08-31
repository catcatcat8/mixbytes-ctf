import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

import { ethers } from 'hardhat'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()

  const challenge = await hre.ethers.getContract('Challenge')

  await deploy('Attack', {
    from: deployer,
    args: [],
    log: true,
  })
}
export default func

func.tags = ['Attack']
func.dependencies = ['Challenge']
