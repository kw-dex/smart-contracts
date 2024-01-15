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

- TokenFactory `0xd054E71f127420a4f1fF2c0BA0fa110C12a3f970`
- Wrapper `0x6d6532B865367b23b8D930A543228303E624C432`
- PoolFactory `0x01594c5ceA785f01Fa36aBa1953B6a9408e07493`
- Faucet (DEPRECATED) `0x68BFd38fFF62C6A80556986D8725F2f55dAf53eB`
- MultiSwap `0xac7300122053Deca4B8Ba4788407C38B26C9FBaF`

### Deployed tokens:
- wBNB `0xd75D3f3F9f46DF5c75254BDC2c50BF89a52ce603`
- USDT `0x5aea0302145C1080298a8D4469182c15b342E392`
- USDC `0x882246b457bAcDA8351f92176c351354e372f330`
- wETH `0x536eC5eC8909D01524785c80C1bab9C233dF6393`
- DAI `0x7eBeDdE88435c8DC550dCEC53E385c3c44D05c86`
- ALICE `0x32aD0E8cE45447163CB4920a34616372AdCe12B8`
- ANIMA `0x8e4c6fad4aDCf3D0174cd0E316574aCBA8Aebd22`
- KWNET `0xcea8cAF2363aaCD592Ef92990CA885d4200f138c`

### Deployed liquidity pools:
- USDT-USDC 10% `0xBb92C0A1FFFdB4E2736B7FDc400d6e3c26eB667C`
