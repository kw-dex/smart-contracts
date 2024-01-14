import { KRC20 } from "../typechain-types";
const { ethers, run } = require("hardhat")

const deployAll = true;

async function main() {
  const [owner] = await ethers.getSigners();
  const ownerAddress = await owner.getAddress();

  console.log("1 | Preparing environment...");
  console.log("\t- Creating factories...")
  // Factories
  const TokenFactory = await ethers.getContractFactory("KTokenFactory");
  const PoolFactory = await ethers.getContractFactory("KPoolFactory");
  const Wrapper = await ethers.getContractFactory("KWrapper");
  const Faucet = await ethers.getContractFactory("KFaucet");
  const MultiSwap = await ethers.getContractFactory("KMultiSwap");
  const Token = await ethers.getContractFactory("KRC20");

  // ========================================================================
  // Deploy infrastructure

  console.log("\n2 | Deploying & verifying contracts")
  console.log("\t- Deploying token factory...")

  const tokenFactory = (await TokenFactory.connect(owner).deploy())
  await tokenFactory.waitForDeployment()

  const tokenFactoryAddress = await tokenFactory.getAddress()

  console.log("\t\t[i] 1/2 Token factory deployed:", tokenFactoryAddress)

  await run("verify:verify", {
    address: tokenFactoryAddress,
    constructorArguments: [],
  });

  console.log("\t\t[i] 2/2 Token factory contract verified")

  // ========================================================================
  // Deploy wrapped + wrapper

  const verificationErrors: string[] = []

  console.log("\t- Deploying twBNB token...")

  await (await tokenFactory.deployToken("twBNB", "Wrapped BNB", 18, { from: ownerAddress })).wait();
  const wrappedAddress = (await tokenFactory.deployedTokens())[0];

  console.log("\t\t[i] 1/2 twBNB token deployed:", wrappedAddress)

  await run("verify:verify", {
    address: wrappedAddress,
    constructorArguments: ["twBNB", "Wrapped BNB", 18, ownerAddress],
  }).catch(() => {
    verificationErrors.push(wrappedAddress)
  });

  console.log("\t\t[i] 2/2 twBNB token contract verified")
  console.log("\t-Deploying token wrapper...")

  const wrapper = (await Wrapper.connect(owner).deploy(wrappedAddress))

  await wrapper.waitForDeployment()
  const wrapperAddress = await wrapper.getAddress()

  console.log("\t\t[i] 1/3 Token wrapper deployed at:", wrapperAddress)

  await run("verify:verify", {
    address: wrapperAddress,
    constructorArguments: [wrappedAddress],
  }).catch(() => {
    verificationErrors.push(wrapperAddress)
  });

  console.log("\t\t[i] 2/3 Token wrapper contract verified")

  const wrapped = await Token.connect(owner).attach(wrappedAddress) as KRC20;
  await (await wrapped.transferOwnership(wrapperAddress)).wait();

  console.log("\t\t[i] 3/3 twBNB ownership transferred form owner to wrapper")

  // ========================================================================
  // Deploy pool factory

  console.log("\t- Deploying pool factory...")
  const poolFactory = (await PoolFactory.connect(owner).deploy(wrapperAddress))

  await poolFactory.waitForDeployment()
  const poolFactoryAddress = await poolFactory.getAddress();

  console.log("\t\t[i] 1/2 Pool factory deployed at:", poolFactoryAddress)

  await run("verify:verify", {
    address: poolFactoryAddress,
    constructorArguments: [wrapperAddress],
  }).catch(() => {
    verificationErrors.push(poolFactoryAddress)
  });

  console.log("\t\t[i] 2/2 Pool factory contract verified")

  // ========================================================================
  // Deploy faucet (deprecated)

  // console.log("\t-Deploying faucet...")
  // const faucet = (await Faucet.connect(owner).deploy())
  //
  // await faucet.waitForDeployment()
  // const faucetAddress = "0x68BFd38fFF62C6A80556986D8725F2f55dAf53eB"

  // ========================================================================
  // Deploy faucet (deprecated)

  console.log("\t- Deploying multi swap...")
  const multiSwap = (await MultiSwap.connect(owner).deploy(wrapperAddress))

  await multiSwap.waitForDeployment()
  const multiSwapAddress = await multiSwap.getAddress();

  console.log("\t\t[i] 1/2 Multi swap deployed at:", multiSwapAddress)

  await run("verify:verify", {
    address: multiSwapAddress,
    constructorArguments: [wrapperAddress],
  }).catch(() => {
    verificationErrors.push(multiSwapAddress)
  });

  console.log("\t\t[i] 1/2 Multi swap contract verified")

  // ========================================================================
  //
  //                          S U M M A R Y
  //                     for minimized iteration
  //
  // ========================================================================

  console.log("\n3 | Deployed infrastructure contracts:");
  console.log("\t- TokenFactory", tokenFactoryAddress);
  console.log("\t- Wrapper", wrapperAddress);
  console.log("\t- PoolFactory", poolFactoryAddress);
  console.log("\t- Faucet", "SKIPPED");
  console.log("\t- MultiSwap", multiSwapAddress);

  console.log("\nDeployed tokens:");
  console.log("\t- twBNB", wrappedAddress);

  console.log("\nNot verified contract (error):");
  verificationErrors.map(addr => console.log(`\t- ${addr}`))
  console.log("\n")



  // ========================================================================
  //
  //                       F U L L    D E P L O Y
  //
  // ========================================================================

  // Deploy tokens
  if (deployAll) {
    console.log("\n4 | Executing full deploy sequence...");

    console.log("\t- Deploying tokens & pools...")

    await (await tokenFactory.deployToken("tUSDT", "Tether USD", 6)).wait();
    await (await tokenFactory.deployToken("tUSDC", "USD Coin", 6)).wait();
    await (await tokenFactory.deployToken("tDAI", "Dai StableCoin", 18)).wait();
    await (await tokenFactory.deployToken("twETH", "Wrapped Ether", 18)).wait();
    await (await tokenFactory.deployToken("ALICE", "My Neighbor Alice", 6)).wait();
    await (await tokenFactory.deployToken("ANIMA", "Anima Token", 18)).wait();
    await (await tokenFactory.deployToken("KWNET", "KW Network Token", 18)).wait();

    console.log("\t\t[i] Tokens deployed (7)");

    const [
      USDT,
      USDC,
      DAI,
      wETH,
      ALICE,
      ANIMA,
      KWNET
    ] = (await tokenFactory.deployedTokens()).slice(1);

    // Deploy pools
    await (await poolFactory.deployPool(USDT, USDC, 0.1 * 1e5)).wait()

    // await (await poolFactory.deployPool(wETH, USDT, 10 * 1e5)).wait()
    // await (await poolFactory.deployPool(wETH, DAI, 10 * 1e5)).wait()
    // await (await poolFactory.deployPool(wETH, USDC, 10 * 1e5)).wait();

    const USDT_USDC = await poolFactory.getPool(USDT, USDC, 0.1 * 1e5);

    console.log("\t\t[i] Pools deployed (1)");
    // const wETH_USDT = await poolFactory.getPool(wETH, USDT, 10 * 1e5);
    // const wETH_USDC = await poolFactory.getPool(wETH, DAI, 10 * 1e5);
    // const wETH_DAI = await poolFactory.getPool(wETH, USDC, 10 * 1e5);

    console.log("\tUSDT", USDT);
    console.log("\tUSDC", USDC);
    console.log("\twETH", wETH);
    console.log("\tDAI", DAI);
    console.log("\tALICE", ALICE);
    console.log("\tANIMA", ANIMA);
    console.log("\tKWNET", KWNET);
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
