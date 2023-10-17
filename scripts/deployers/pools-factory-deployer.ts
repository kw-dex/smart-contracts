import { ethers } from "hardhat"

export default async function poolsFactoryDeployer(wrapperAddress: string) {
    const [owner] = await ethers.getSigners()

    const PoolFactory = await ethers.getContractFactory("KPoolFactory")

    const poolFactory = await PoolFactory.connect(owner).deploy(wrapperAddress)

    await poolFactory.waitForDeployment()

    const poolFactoryAddress = await poolFactory.getAddress()
    const poolFactoryContract = poolFactory

    return {
        poolFactoryContract,
        poolFactoryAddress
    }
}