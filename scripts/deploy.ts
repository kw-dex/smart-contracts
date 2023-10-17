import { KRC20 } from "../typechain-types";
const { ethers } = require("hardhat")

const deployAll = true;

async function main() {
  const [owner] = await ethers.getSigners();
  const ownerAddress = await owner.getAddress();

  console.log("Creating factories...")
  // Factories
  const TokenFactory = await ethers.getContractFactory("KTokenFactory");
  const PoolFactory = await ethers.getContractFactory("KPoolFactory");
  const Wrapper = await ethers.getContractFactory("KWrapper");
  const Faucet = await ethers.getContractFactory("KFaucet");
  const MultiSwap = await ethers.getContractFactory("KMultiSwap");
  const Token = await ethers.getContractFactory("KRC20");

  console.log("Deploying token factory...")

  // Deploy infrastructure + wrapped
  const tokenFactory = (await TokenFactory.connect(owner).deploy())
  await tokenFactory.waitForDeployment()

  const tokenFactoryAddress = "0x8d671DA62F82cDA6781a0e12E1852bFdAd72a964"

  console.log("Deploying twBNB token...")
  await (await tokenFactory.deployToken("twBNB", "Wrapped BNB", 18, { from: ownerAddress })).wait();
  const wrappedAddress = (await tokenFactory.deployedTokens())[0];

  console.log("Deploying wrapper...")
  const wrapper = (await Wrapper.connect(owner).deploy(wrappedAddress))

  await wrapper.waitForDeployment()
  const wrapperAddress = await wrapper.getAddress()

  console.log("Transferring twBNB ownership...")
  const wrapped = await Token.connect(owner).attach(wrappedAddress) as KRC20;
  await (await wrapped.transferOwnership(wrapperAddress)).wait();

  console.log("Deploying pool factory...")
  const poolFactory = (await PoolFactory.connect(owner).deploy(wrapperAddress))

  await poolFactory.waitForDeployment()
  const poolFactoryAddress = await poolFactory.getAddress();

  console.log("Deploying faucet...")
  const faucet = (await Faucet.connect(owner).deploy())

  await faucet.waitForDeployment()
  const faucetAddress = "0x68BFd38fFF62C6A80556986D8725F2f55dAf53eB"

  console.log("Deploying multi swap...")
  const multiSwap = (await MultiSwap.connect(owner).deploy(wrapperAddress))

  await multiSwap.waitForDeployment()
  const multiSwapAddress = await multiSwap.getAddress();

  console.log("\nDeployed infrastructure contracts:");
  console.log("\tTokenFactory", tokenFactoryAddress);
  console.log("\tWrapper", wrapperAddress);
  console.log("\tPoolFactory", poolFactoryAddress);
  console.log("\tFaucet", faucetAddress);
  console.log("\tMultiSwap", multiSwapAddress);

  console.log("\nDeployed tokens:");
  console.log("\ttwBNB", wrappedAddress);

  // Deploy tokens
  if (deployAll) {
    console.log("Deploying tokens...")

    await (await tokenFactory.deployToken("tUSDT", "Tether USD", 6)).wait();
    await (await tokenFactory.deployToken("tUSDC", "USD Coin", 6)).wait();
    await (await tokenFactory.deployToken("tDAI", "Dai StableCoin", 18)).wait();
    await (await tokenFactory.deployToken("twETH", "Wrapped Ether", 18)).wait();

    const [
      USDT,
      USDC,
      DAI,
      wETH
    ] = (await tokenFactory.deployedTokens()).slice(1);

    console.log("Deploying pools...")
    // Deploy pools
    await (await poolFactory.deployPool(USDT, USDC, 10 * 1e5)).wait()

    // await (await poolFactory.deployPool(wETH, USDT, 10 * 1e5)).wait()
    // await (await poolFactory.deployPool(wETH, DAI, 10 * 1e5)).wait()
    // await (await poolFactory.deployPool(wETH, USDC, 10 * 1e5)).wait();

    const USDT_USDC = await poolFactory.getPool(USDT, USDC, 10 * 1e5);
    // const wETH_USDT = await poolFactory.getPool(wETH, USDT, 10 * 1e5);
    // const wETH_USDC = await poolFactory.getPool(wETH, DAI, 10 * 1e5);
    // const wETH_DAI = await poolFactory.getPool(wETH, USDC, 10 * 1e5);

    console.log("\tUSDT", USDT);
    console.log("\tUSDC", USDC);
    console.log("\twETH", wETH);
    console.log("\tDAI", DAI);
    console.log("\nDeployed liquidity pools:");
    console.log("\tUSDT-USDC 10%", USDT_USDC.poolAddress);
    // console.log("\twETH-USDT 10%", wETH_USDT.poolAddress);
    // console.log("\twETH-USDC 10%", wETH_USDC.poolAddress);
    // console.log("\twETH-DAI 10%", wETH_DAI.poolAddress);
  }

  console.log("\n\n");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
