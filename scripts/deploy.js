// scripts/deploy.js
async function main() {
    const CC = await ethers.getContractFactory("CuriousCardsV3");
    console.log("Deploying CC...");
    const cc = await upgrades.deployProxy(CC, [], { initializer: 'initialize' });
    console.log("CC deployed to:", cc.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });