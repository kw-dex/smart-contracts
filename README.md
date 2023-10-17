# KW dex smart contracts

```shell
# NVM
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Deploy to local node
npx hardhat node
npx hardhat run --network localhost scripts/deploy.ts
```

### Deployed infrastructure contracts:

- TokenFactory `0x8d671DA62F82cDA6781a0e12E1852bFdAd72a964`
- Wrapper `0xD28ff1D935e13B9472846E274Eb77e4332257031`
- PoolFactory `0x3382a28f44409387550c8CC7cB66870441D0ab3A`
- Faucet `0x68BFd38fFF62C6A80556986D8725F2f55dAf53eB`
- MultiSwap `0x7d4E75e0B6a745c4fe8Fa072BddBDcbF4377fC2E`

### Deployed tokens:
- wBNB `0x4d63CfAcd60eA397B7a17BD2A3a26F4EE6Fc3De3`
- USDT `0xBa3ce4244a8e42a915d50d52603C7A6C1f9bFa29`
- USDC `0x3BEE470a8A2e3D41440dd25F984D1884f163Fc41`
- wETH `0x98938313E3a5CE46fD9EF31d240eE3e8C29e45ac`
- DAI `0x0F213F6E7B46Eaf0cedf34Fde2C0185ed976B60a`

### Deployed liquidity pools:
- USDT-USDC 10% `0x06D0bBa19c64431c67b084DD5279AC3cBB9C83AA`