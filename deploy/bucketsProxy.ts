import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

import { ethers } from 'hardhat'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()

  const buckets = await hre.ethers.getContract("Buckets")

  await deploy('BucketsProxy', {
    from: deployer,
    args: [buckets.address, ethers.utils.parseEther("1000000")],
    log: true,
  })
}
export default func

func.tags = ['BucketsProxy']
func.dependencies = ['Buckets']
