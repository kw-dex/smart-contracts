import { KPoolFactory } from "../../typechain-types"

export default async function poolDeployer(token0: string, token1: string, fee: number, poolFactory: KPoolFactory) {
    const _fee = fee * 1e5

    await (await poolFactory.deployPool(token0, token1, _fee)).wait()

    return (await poolFactory.getPool(token0, token1, _fee)).poolAddress
}