import {
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("KWrapper", () => {
  async function deploy() {
    const [owner] = await ethers.getSigners();

    const ownerAddress = await owner.getAddress()

    const KRC20 = await ethers.getContractFactory("KRC20");

    const wrappedBNB = await KRC20.deploy(
      "wBNB",
      "Wrapped BNB",
      18,
      ownerAddress
    )

    const wrappedAddress = await wrappedBNB.getAddress()

    const Wrapper = await ethers.getContractFactory("KWrapper")
    const wrapper = await Wrapper.deploy(wrappedAddress)

    const wrapperAddress = await wrapper.getAddress()

    await wrappedBNB.transferOwnership(wrapperAddress)

    return { wrappedBNB, wrapper, wrappedAddress, ownerAddress, wrapperAddress }
  }

  it("Should wrap and unwrap", async () => {
    const { wrapper, wrappedBNB, ownerAddress, wrapperAddress } = await loadFixture(deploy)

    await wrapper.wrap({ value: ethers.parseEther("0.01"), from: ownerAddress })

    const wrappedBalance = await wrappedBNB.balanceOf(ownerAddress)

    expect(wrappedBalance).to.equal(ethers.parseEther("0.01"))

    await wrappedBNB.approve(wrapperAddress, ethers.parseEther("0.01"), { from: ownerAddress })
    const initialEthers = await ethers.provider.getBalance(ownerAddress)

    await wrapper.unwrap(ethers.parseEther("0.01"), { from: ownerAddress })

    const wrappedBalanceN = await wrappedBNB.balanceOf(ownerAddress)
    const finalEthers = await ethers.provider.getBalance(ownerAddress)

    expect(wrappedBalanceN).to.eq(0)
    expect(finalEthers - initialEthers).to.lessThanOrEqual(ethers.parseEther("0.01"))
    expect(finalEthers - initialEthers).to.greaterThan(0)
  })
})