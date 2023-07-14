import { ethers } from "hardhat";
import { KRC20 } from "../typechain-types";

const deployAll = false

async function main() {
  const [owner] = await ethers.getSigners();
  const ownerAddress = await owner.getAddress();

  // Factories
  const TokenFactory = await ethers.getContractFactory("KTokenFactory");
  const PoolFactory = await ethers.getContractFactory("KPoolFactory");
  const Wrapper = await ethers.getContractFactory("KWrapper");
  const Faucet = await ethers.getContractFactory("KFaucet");
  const MultiSwap = await ethers.getContractFactory("KMultiSwap");
  const Token = await ethers.getContractFactory("KRC20");

  // Deploy infrastructure + wrapped
  const tokenFactory = await TokenFactory.connect(owner).deploy();
  const tokenFactoryAddress = await tokenFactory.getAddress()

  await tokenFactory.deployToken("twBNB", "Wrapped BNB", 18, { from: ownerAddress });
  const wrappedAddress = (await tokenFactory.deployedTokens())[0];

  const wrapper = await Wrapper.connect(owner).deploy(wrappedAddress);
  const wrapperAddress = await wrapper.getAddress();

  const wrapped = await Token.connect(owner).attach(wrappedAddress) as KRC20;
  await wrapped.transferOwnership(wrapperAddress);

  const poolFactory = await PoolFactory.connect(owner).deploy(wrapperAddress);
  const poolFactoryAddress = await poolFactory.getAddress();

  const faucet = await Faucet.connect(owner).deploy();
  const faucetAddress = await faucet.getAddress();

  const multiSwap = await MultiSwap.connect(owner).deploy();
  const multiSwapAddress = await multiSwap.getAddress();

  console.log("\nDeployed infrastructure contracts:");
  console.log("\tTokenFactory", tokenFactoryAddress);
  console.log("\tWrapper", wrapperAddress);
  console.log("\tPoolFactory", poolFactoryAddress);
  console.log("\tFaucet", faucetAddress);
  console.log("\tMultiSwap", multiSwapAddress);

  console.log("\nDeployed tokens:");
  console.log("\twtBNB", wrappedAddress);

  // Deploy tokens
  if (deployAll) {
    await tokenFactory.deployToken("tUSDT", "Tether USD", 6);
    await tokenFactory.deployToken("tUSDC", "USD Coin", 6);
    await tokenFactory.deployToken("tDAI", "Dai StableCoin", 18);
    await tokenFactory.deployToken("twETH", "Wrapped Ether", 18);

    const [
      USDT,
      USDC,
      DAI,
      wETH
    ] = (await tokenFactory.deployedTokens()).slice(1)

    // Deploy pools
    await poolFactory.deployPool(USDT, USDC, 0.1 * 1e5)

    await poolFactory.deployPool(wETH, USDT, 0.1 * 1e5);
    await poolFactory.deployPool(wETH, DAI, 0.1 * 1e5);
    await poolFactory.deployPool(wETH, USDC, 0.1 * 1e5);

    const USDT_USDC = await poolFactory.getPool(USDT, USDC, 0.1 * 1e5);
    const wETH_USDT = await poolFactory.getPool(wETH, USDT, 0.1 * 1e5);
    const wETH_USDC = await poolFactory.getPool(wETH, DAI, 0.1 * 1e5);
    const wETH_DAI = await poolFactory.getPool(wETH, USDC, 0.1 * 1e5);

    console.log("\tUSDT", USDT);
    console.log("\tUSDC", USDC);
    console.log("\twETH", wETH);
    console.log("\tDAI", DAI);
    console.log("\nDeployed liquidity pools:");
    console.log("\tUSDT-USDC 0.1%", USDT_USDC.poolAddress);
    console.log("\twETH-USDT 0.1%", wETH_USDT.poolAddress);
    console.log("\twETH-USDC 0.1%", wETH_USDC.poolAddress);
    console.log("\twETH-DAI 0.1%", wETH_DAI.poolAddress);
  }

  console.log("\n\n");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
