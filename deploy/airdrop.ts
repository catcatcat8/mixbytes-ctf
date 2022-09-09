import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

import { ethers } from 'hardhat'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()

//   const bank = await hre.ethers.getContract("Bank2")

  await deploy('Airdrop', {
    from: deployer,
    args: ["0x6EF1032E74B0371BAa3cA64878d8984eFd1B7453", 22, "0x0000000000000000000000000000000000000000000000000000000000000023", 4],
    log: true,
  })
}
export default func

func.tags = ['Airdrop']
// func.dependencies = ['Bank2']
