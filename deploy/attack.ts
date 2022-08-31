import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

import { ethers } from 'hardhat'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()

//   const bank = await hre.ethers.getContract("Bank2")

  await deploy('FaucetAttack', {
    from: deployer,
    args: ["0x9db6A88A8333530453d0b30B60DAd09DcC50a807"],
    log: true,
  })
}
export default func

func.tags = ['FaucetAttack']
// func.dependencies = ['Bank2']
