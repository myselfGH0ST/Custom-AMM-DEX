import { ethers } from "ethers";
import hre from "hardhat";



async function main() {

  const provider = new ethers.JsonRpcProvider("http://127.0.0.1:8545");
  const signer = await provider.getSigner();

  // Load compiled artifacts of feeToken
  const tokenArtifact = await hre.artifacts.readArtifact("feeToken");

  const TokenFactory = new ethers.ContractFactory(
    tokenArtifact.abi,
    tokenArtifact.bytecode,
    signer
  );

  // Deploy feeToken contract
  const token = await TokenFactory.deploy(ethers.parseEther("1000000"));
  await token.waitForDeployment();

  console.log("Token deployed at:", token.target);

  // Load compiled artifacts of AMM
  const ammArtifact = await hre.artifacts.readArtifact("AMM");

  const AMMFactory = new ethers.ContractFactory(
    ammArtifact.abi,
    ammArtifact.bytecode,
    signer
  );

  //Deploy AMM contract
  const amm = await AMMFactory.deploy(token.target);
  await amm.waitForDeployment();

  console.log("AMM deployed at:", amm.target);
}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
