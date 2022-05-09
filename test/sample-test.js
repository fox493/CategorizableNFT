const { expect } = require("chai")
const { ethers } = require("hardhat")

let alice, bob, NftTemplate, nftTemplate

beforeEach(async function () {
  ;[alice, bob] = await ethers.getSigners()
  NftTemplate = await ethers.getContractFactory("NftTemplate")
  nftTemplate = await NftTemplate.deploy("fox", "FOX")
  await nftTemplate.deployed()
  nftTemplate.connect(alice)
  await nftTemplate.addNftClass(
    true,
    true,
    false,
    false,
    alice.address,
    2,
    999,
    ethers.utils.parseEther("0.1")
  )
})
describe("test ownership of the contract", function () {
  it("owner should be deployer", async function () {
    expect(await nftTemplate.owner()).to.equal(alice.address)
  })
})
describe("testing mint function", function () {
  it("should reverted with invalid class id", async function () {
    await expect(nftTemplate.mint(2, 1)).to.be.revertedWith("Invalid class id!")
  })
  it("can not exceed max per tx", async function () {
    await expect(nftTemplate.mint(3, 0)).to.be.revertedWith(
      "Can not mint this many!"
    )
  })
  it("can not mint with wrong value", async function () {
    await expect(nftTemplate.mint(2, 0)).to.be.revertedWith(
      "Wrong amount of ether!"
    )
  })
  it("could mint", async function () {
    await nftTemplate.mint(2, 0, {
      value: ethers.utils.parseEther("0.2"),
    })
  })
})
describe("after 2 people minted 3 tokens", function () {
  it("totalSupply should be 3", async function () {
    await nftTemplate.mint(2, 0, {
      value: ethers.utils.parseEther("0.2"),
    })
    nftTemplate.connect(bob)
    await nftTemplate.mint(1, 0, {
      value: ethers.utils.parseEther("0.1"),
    })
    expect(await nftTemplate.totalSupply()).to.equal(3)
  })
  it("current nft class index should be updated", async function () {
    await nftTemplate.mint(2, 0, {
      value: ethers.utils.parseEther("0.2"),
    })
    nftTemplate.connect(bob)
    await nftTemplate.mint(1, 0, {
      value: ethers.utils.parseEther("0.1"),
    })
    expect(await nftTemplate.getCurrentSupplyOfClass(0)).to.equal(3)
  })
  it("nftClass balances should be updated", async function() {
    await nftTemplate.mint(2, 0, {
      value: ethers.utils.parseEther("0.2"),
    })
    nftTemplate.connect(bob)
    await nftTemplate.mint(1, 0, {
      value: ethers.utils.parseEther("0.1"),
    })
    expect(await nftTemplate.balances[alice.address]).to.equal(2)
    expect(await nftTemplate.balances[bob.address]).to.equal(1)
  })
})
