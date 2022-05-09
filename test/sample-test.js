const { expect } = require("chai")
const { ethers } = require("hardhat")

let alice, bob, NftTemplate, nftTemplate

beforeEach(async function () {
  ;[alice, bob] = await ethers.getSigners()
  NftTemplate = await ethers.getContractFactory("CategorizableNft")
  nftTemplate = await NftTemplate.deploy("fox", "FOX")
  await nftTemplate.deployed()
  nftTemplate.connect(alice)
  await nftTemplate.addNftClass(
    true,
    false,
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
  it("owner could change the owner of class", async function () {
    await nftTemplate.setOwnerOfClass(0, bob.address)
    expect((await nftTemplate.getClassData(0))[4]).to.equal(bob.address)
  })
  it("only owner can call setOwnerOfClass()", async function () {
    await expect(
      nftTemplate.connect(bob).setOwnerOfClass(0, bob.address)
    ).to.be.revertedWith("Ownable: caller is not the owner")
  })
})
describe("test ownership of the class", function () {
  it("owner could change metadata of class", async function () {
    await nftTemplate.flipTransferable(0)
    await nftTemplate.flipBurnable(0)
    await nftTemplate.flipMintable(0)
    await nftTemplate.setMaxSupplyOfClass(0, 9999)
    await nftTemplate.setPriceOfClass(0, ethers.utils.parseEther("0.01"))
    await nftTemplate.setMaxPerTxOfClass(0, 5)
    await nftTemplate.freezeClass(0)
  })
 it("only owner can change metadata of class", async function () {
    await expect(nftTemplate.connect(bob).flipTransferable(0)).to.be.revertedWith("Not the owner of the class!")
    await expect(nftTemplate.connect(bob).flipBurnable(0)).to.be.revertedWith("Not the owner of the class!")
    await expect(nftTemplate.connect(bob).freezeClass(0)).to.be.revertedWith("Not the owner of the class!")
    await expect(nftTemplate.connect(bob).flipMintable(0)).to.be.revertedWith("Not the owner of the class!")
    await expect(nftTemplate.connect(bob).setMaxSupplyOfClass(0, 9999)).to.be.revertedWith("Not the owner of the class!")
    await expect(nftTemplate.connect(bob).setPriceOfClass(0, ethers.utils.parseEther("0.01"))).to.be.revertedWith("Not the owner of the class!")
    await expect(nftTemplate.connect(bob).setMaxPerTxOfClass(0, 5)).to.be.revertedWith("Not the owner of the class!")
  })
  it("once class was frozen, no one can change it", async function() {
    await nftTemplate.freezeClass(0)
    await nftTemplate.freezeClass(0)
    await expect(nftTemplate.flipTransferable(0)).to.be.revertedWith("Class has been frozen!")
    await expect(nftTemplate.flipBurnable(0)).to.be.revertedWith("Class has been frozen!")
    await expect(nftTemplate.flipMintable(0)).to.be.revertedWith("Class has been frozen!")
    await expect(nftTemplate.setMaxSupplyOfClass(0, 9999)).to.be.revertedWith("Class has been frozen!")
    await expect(nftTemplate.setPriceOfClass(0, ethers.utils.parseEther("0.01"))).to.be.revertedWith("Class has been frozen!")
    await expect(nftTemplate.setMaxPerTxOfClass(0, 5)).to.be.revertedWith("Class has been frozen!")
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
    await nftTemplate.connect(bob).mint(1, 0, {
      value: ethers.utils.parseEther("0.1"),
    })
    expect(await nftTemplate.totalSupply()).to.equal(3)
  })
  it("current nft class index should be updated", async function () {
    await nftTemplate.mint(2, 0, {
      value: ethers.utils.parseEther("0.2"),
    })
    await nftTemplate.connect(bob).mint(1, 0, {
      value: ethers.utils.parseEther("0.1"),
    })
    expect(await nftTemplate.getCurrentSupplyOfClass(0)).to.equal(3)
  })
  it("nftClass balances should be updated", async function () {
    await nftTemplate.mint(2, 0, {
      value: ethers.utils.parseEther("0.2"),
    })
    expect(await nftTemplate.getBalancesOfClass(bob.address, 0)).to.equal(0)
    await nftTemplate.connect(bob).mint(1, 0, {
      value: ethers.utils.parseEther("0.1"),
    })
    expect(await nftTemplate.getBalancesOfClass(alice.address, 0)).to.equal(2)
    expect(await nftTemplate.getBalancesOfClass(bob.address, 0)).to.equal(1)
  })
  it("tokenClass should be updated", async function () {
    await nftTemplate.mint(2, 0, {
      value: ethers.utils.parseEther("0.2"),
    })
    await nftTemplate.connect(bob).mint(1, 0, {
      value: ethers.utils.parseEther("0.1"),
    })
    expect(await nftTemplate.getClassOfToken(0)).to.equal(0)
    expect(await nftTemplate.getClassOfToken(1)).to.equal(0)
    expect(await nftTemplate.getClassOfToken(2)).to.equal(0)
    await expect(nftTemplate.getClassOfToken(3)).to.be.revertedWith(
      "Invalid token id!"
    )
  })
  it("if class is not mintable, then people can't mint again", async function () {
    await nftTemplate.mint(2, 0, {
      value: ethers.utils.parseEther("0.2"),
    })
    await expect(
      nftTemplate.mint(2, 0, {
        value: ethers.utils.parseEther("0.2"),
      })
    ).to.be.revertedWith("it's not mintable for you!")
  })
})
