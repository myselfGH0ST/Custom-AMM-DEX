# 🚀 Custom-AMM-DEX
This project implements a fully functional Automated Market Maker (AMM) similar to Uniswap, built from scratch using Solidity.

The system includes:

✅ Custom ERC20 Token with transfer fees  
✅ Liquidity Pool (ETH ↔ Token)  
✅ Token Swapping (ETH ⇄ Token)  
✅ LP Token Logic (Liquidity Ownership)  
✅ Slippage Protection  
✅ Fee mechanism on swaps

## 🧠 Core Idea
```text
Liquidity Providers → Add funds  
        ↓
Pool stores reserves 
        ↓
Users swap assets   
        ↓
Fees distributed
```

## 🧩 Project Architecture
```text
contracts/
├── feeToken.sol    (ERC20 + fee system)
└── AMM.sol         (DEX logic)

scripts/
└── deploy.js       (deployment script)
```

## ⚙️ Components
### 🪙 1. Custom Token — feeToken
🔹 Features
- ERC20-like implementation  
- Transfer fee mechanism  
- Burn & mint logic  
- Pause functionality  
- Owner-controlled settings

🔹 Key Concepts
- Fee applied on every transfer:
```text
fee = (amount * feePercentage) / 100
```
- Net amount goes to receiver
- Fee goes to feeReceiver

🔹 Extra Features

- Pausable token  
- Allowance system  
- Burn support  
- Owner controls fee %

### 💧 2. AMM (Liquidity Pool Engine)
🔹 Features
- Add Liquidity  
- Remove Liquidity  
- Token → ETH swap  
- ETH → Token swap  
- LP Shares system  
- Reentrancy protection  
- Slippage control

## 🏦 Liquidity System
🔹 Add Liquidity
```text
addLiquidity(uint tokenAmount, uint ethAmount)
```
- Behavior

First provider → sets pool ratio ✅  
Next providers → must match ratio ✅  

- LP Shares Calculation
```text
Initial:
shares = sqrt(token * eth)

After:
shares = min(
  (token * totalShare) / tokenReserve,
  (eth * totalShare) / ethReserve
)
```

## 🔓 Remove Liquidity
```text
removeLiquidity(uint shares)
```

- Behavior
  
User gets proportional:

→ tokens  
→ ETH  

## 🔁 Swap Mechanism
### 🔹 1. Token → ETH
```text
swapTokenForEth(tokenIn, minEthOut)
```
- ✅ Formula
```text
ethOut = (ETH_reserve * tokenIn) / (Token_reserve + tokenIn)
```
✅ Features
-  Fee applied (0.3%)  
-  Slippage protection  
-  Uses actualReceived (important 🔥)

### 🔹 2. ETH → Token
```text
swapEthForToken(minTokenOut)
```
✅ Formula
```text
tokenOut = (Token_reserve * ethIn) / (ETH_reserve + ethIn)
```
✅ Features
- Fee deduction  
- Slippage validation  
- Uses msg.value (reliable)

## ⚠️ Slippage Protection
```text
require(output >= minExpected, "Slippage too high");
```
👉 Prevents:

❌ Bad trades  
❌ Price manipulation 

## 🔐 Security Features
✅ Reentrancy guard (noReentrant)  
✅ Safe ETH transfers (.call)  
✅ Input validation  
✅ Ratio enforcement  
✅ Fee handling 

## 📊 State Variables (AMM)
- tokenReserve 
- ethReserve 
- totalShare 
- lpBalances

## 🔄 Flow Diagram
```text

User adds liquidity
        ↓
Pool updates reserves
        ↓
LP shares minted ✅
        ↓
Users swap assets
        ↓
Fees collected
        ↓
LP owners earn indirectly ✅
```
## 🚀 Deployment
### 🔧 Run Local Node
```text
npx hardhat node
```
### 🔨 Deploy Contracts
```text
npx hardhat run scripts/deploy.js --network localhost
```

## 🧪 Example Workflow

1. Deploy token 
2. Deploy AMM 
3. Approve token 
4. Add liquidity 
5. Swap tokens 
6. Remove liquidity 

## 🚀 Future Improvements
✅ Frontend (React + ethers)  
✅ LP token ERC20  
✅ Multi-token support  
✅ Dynamic fee model  
✅ UI for swapping  
✅ Add price oracle
