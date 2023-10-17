import { ethers } from "hardhat"

export default async function infrastructureDeployer(wrappedAddress: string) {
    const [owner] = await ethers.getSigners();

    const Wrapper = await ethers.getContractFactory("KWrapper");
    const Faucet = await ethers.getContractFactory("KFaucet");
    const MultiSwap = await ethers.getContractFactory("KMultiSwap");

    const wrapperContract = await Wrapper.connect(owner).deploy(wrappedAddress)
    await wrapperContract.waitForDeployment()

    const wrapperAddress = await wrapperContract.getAddress()

    const faucetContract = await Faucet.connect(owner).deploy()
    await faucetContract.waitForDeployment()

    const faucetAddress = await faucetContract.getAddress()

    const multiSwapContract = await MultiSwap.connect(owner).deploy(wrapperAddress)
    await multiSwapContract.waitForDeployment()

    const multiSwapAddress = await multiSwapContract.getAddress()

    return {
        wrapperAddress,
        faucetAddress,
        multiSwapAddress
    }
}