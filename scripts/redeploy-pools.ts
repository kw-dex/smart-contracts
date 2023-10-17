import poolsFactoryDeployer from "./deployers/pools-factory-deployer"
import poolDeployer from "./deployers/pool-deployer"

export default async function redeployPools() {
    const USDT = process.argv[2]
    const USDC = process.argv[3]
    const wrapped = process.argv[4]

    if (!USDT || !USDC || !wrapped) throw new Error("Invalid call")

    const poolFactory = await poolsFactoryDeployer(wrapped)

    const USDTUSDC10 = poolDeployer(USDT, USDC, 10, poolFactory.poolFactoryContract)

    console.log("Pool factory", poolFactory.poolFactoryAddress)
    console.log("USDTUSDC10", USDTUSDC10)
}