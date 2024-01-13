import poolsFactoryDeployer from "./deployers/pools-factory-deployer"
import poolDeployer from "./deployers/pool-deployer"

export default async function redeployPools() {
    const Token0 = "0x3BEE470a8A2e3D41440dd25F984D1884f163Fc41"
    const Token1 = "0xBa3ce4244a8e42a915d50d52603C7A6C1f9bFa29"
    const wrapped = "0x4d63CfAcd60eA397B7a17BD2A3a26F4EE6Fc3De3"
    const fee = 1


    // if (!Token0 || !Token1 || !wrapped) throw new Error("Invalid call")

    console.log("Deploying started");

    const poolFactory = await poolsFactoryDeployer(wrapped)

    console.log("Pool factory", poolFactory.poolFactoryAddress)

    const USDTUSDC10 = await poolDeployer(Token0, Token1, fee, poolFactory.poolFactoryContract)

    console.log("Pool address", USDTUSDC10)
}

redeployPools()
