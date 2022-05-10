const { ethers } = require("hardhat")
const main = async () => {
  const contractFactory = await ethers.getContractFactory("Moonbabies")
  const contract = await contractFactory.deploy(
    "Moonbabies",
    "BABY",
    "ipfs://Qme1eMNLQv2ByLi99g3wSx6aXWnsScGAcQTu87tWUKTsyF/",
    "NA"
  )
  contract.deployed()
  console.log(`deployed address: ${contract.address}`)
}
main()
