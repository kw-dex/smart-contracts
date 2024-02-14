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

- TokenFactory `0x2d0C32F9A83C23d361Bb7c6D855FdBbcDE892A0d`
- Wrapper `0x734F48A9C357FfD35824ECb84D8E7Ae35892d68A`
- PoolFactory `0xDF324168602B040165484e975d47A2FADF89D472`
- MultiSwap `0xA5F7FdDd79ce0189C482d72F5757f898B32a9e85`

### Base token for prices calculation:
- USDT `0x7e617F53D1AAc3f13b11Fd586594056B9EB1C42C`

### Deployed liquidity pools:
- USDT-USDC 10% (OUTDATED) `0xBb92C0A1FFFdB4E2736B7FDc400d6e3c26eB667C`
