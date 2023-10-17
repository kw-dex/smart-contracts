import { TToken } from "../misc/tokens"
import { KTokenFactory } from "../../typechain-types"

export default async function tokenDeployer(token: TToken, tokenFactory: KTokenFactory) {
    await (await tokenFactory.deployToken(...token)).wait()

    const deployedTokens = await tokenFactory.deployedTokens()

    return deployedTokens.slice(-1)[0]
}