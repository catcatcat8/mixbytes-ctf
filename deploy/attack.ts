import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

import { ethers } from 'hardhat'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()

  await deploy('Attack', {
    from: deployer,
    args: ["0xcD7AB80Da7C893f86fA8deDDf862b74D94f4478E"],
    log: true,
  })
}
export default func

func.tags = ['Attack']
