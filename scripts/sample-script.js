const hre = require("hardhat");

async function main() {
  const [owner, acc2] = await ethers.getSigners();


  const Askme = await ethers.getContractFactory("Askme");
  const ask_me = await Askme.deploy("VelasPunks", "VLXPUNK", "https://ipfs.io/ipfs/QmXH4ReL49syZ1TqX9HAQ2ZHxFWXk9PCykm1ycReSHyVPq/");
  await ask_me.deployed();
  console.log("NFT collection deployed to:", ask_me.address);