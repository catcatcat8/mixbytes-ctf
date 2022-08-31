import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

import { ethers } from 'hardhat'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()

//   const bank = await hre.ethers.getContract("Bank2")

  await deploy('Attack', {
    from: deployer,
    args: ["0x866d0461173957Aeb968BF431eaa6A3c9157BE92"],
    log: true,
  })
}
export default func

func.tags = ['Attack']
// func.dependencies = ['Bank2']
