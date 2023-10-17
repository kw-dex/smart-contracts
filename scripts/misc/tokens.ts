export type TToken = [string, string, number]

const Tokens = {
    USDT: ["tUSDT", "Tether USD", 6] as TToken,
    USDC: ["tUSDC", "USD Coin", 6] as TToken,
    WETH: ["tWETH", "Wrapped Ether", 18] as TToken,
    DAI: ["tDAI", "DAI Stablecoin", 18] as TToken,
    WBTC: ["tWBTC", "Wrapped Bitcoin", 18] as TToken,
    WBNB: ["tWBNB", "Wrapped BNB", 18] as TToken
}

export default Tokens
