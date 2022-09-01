import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

import { ethers } from 'hardhat'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()

//   const bank = await hre.ethers.getContract("Bank2")

  await deploy('Buckets', {
    from: deployer,
    args: [],
    log: true,
  })
}
export default func

func.tags = ['Buckets']
// func.dependencies = ['Bank2']
