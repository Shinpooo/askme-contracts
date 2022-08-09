// scripts/deploy.js
const { ethers, upgrades } = require("hardhat");

async function main() {
    const CCV3 = await ethers.getContractFactory("CuriousCardsV3");
    let cc = await upgrades.upgradeProxy("0x663F0D9C19D912d201DC9aD97F9264e42c35c181", CCV3);
    console.log("Upgraded Proxy done to:", cc.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });