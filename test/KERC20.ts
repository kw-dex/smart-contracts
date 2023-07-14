import {
  loadFixture
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("KERC20", () => {
  async function deploy() {
    const [owner, other] = await ethers.getSigners();

    const ownerAddress = await owner.getAddress();

    const otherAddress = await other.getAddress();

    const KRC20 = await ethers.getContractFactory("KRC20");

    const token = await KRC20.deploy(
      "TEST",
      "TEST TOKEN",
      18,
      ownerAddress
    );

    return { token, ownerAddress, otherAddress };
  }

  it("Should have right owner", async () => {
    const { token, ownerAddress } = await loadFixture(deploy);

    const tokenOwner = await token.owner();
    expect(tokenOwner).to.eq(ownerAddress);
  });

  it("Should mint and burn", async () => {
    const { token, ownerAddress } = await loadFixture(deploy);

    await token.mint(ethers.parseEther("1"), { from: ownerAddress });
    expect(await token.balanceOf(ownerAddress)).to.eq(ethers.parseEther("1"));

    await token.burn(ethers.parseEther("1"), { from: ownerAddress });

    expect(await token.balanceOf(ownerAddress)).to.eq(0);
  })
});