import { ethers } from "hardhat"

export default async function tokensFactoryDeployer() {
    const [owner] = await ethers.getSigners()

    const TokenFactory = await ethers.getContractFactory("KTokenFactory")

    const tokenFactory = await TokenFactory.connect(owner).deploy()

    await tokenFactory.waitForDeployment()

    const tokenFactoryAddress = await tokenFactory.getAddress()
    const tokenFactoryContract = tokenFactory

    return {
        tokenFactoryContract,
        tokenFactoryAddress
    }
}