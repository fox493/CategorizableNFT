async function main() {
    // We get the contract to deploy
    const Greeter = await hre.ethers.getContractFactory("WTPhunks");
    const greeter = await Greeter.deploy('WTPhunks', 'WTP', 'ipfs://QmancN35ZeT5Q6LzmW8T9tcdoNabthcXKNYtFe6c3o9xUN/');
  
    await greeter.deployed();
  
    console.log("Greeter deployed to:", greeter.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
    