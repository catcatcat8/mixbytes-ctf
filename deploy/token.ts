import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()

  await deploy('contracts/Token.sol:Token', {
    from: deployer,
    args: ["DefaultToken", "Token", 100],
    log: true,
  })
}
export default func

func.tags = ['contracts/Token.sol:Token']