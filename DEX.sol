//***** AMM (Automated Market Maker) *****
//***** LP TOKENS (Liquidity Ownership System) *****

// 1. Liquidity Pool
// 2. Swap token to get Eth
// 3. Swap Eth to get Token
// 4. Added fee in both the swap transfer
// 5.  slippage protection

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/Math.sol";

interface IERC20 {
    function balanceOf(address user) external view returns (uint);
    function transfer(address receiver, uint amount) external returns (bool);
    function transferFrom(
        address from,
        address receiver,
        uint amount
    ) external returns (bool);
}

contract feeToken is IERC20 {
    // State Variables
    string public name = "CottonCoin";
    string public symbol = "CC";
    uint public decimals = 18;
    uint public totalSupply;
    address public Owner;
    uint public feePercentage; // Fee token state variable
    address public feeReceiver = Owner; // Fee token state variable
    bool public paused = true;
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowances;

    //Constructor
    constructor(uint _totalSupply) {
        _mint(msg.sender, _totalSupply);
        Owner = msg.sender;
        feeReceiver = Owner;
    }

    modifier onlyOwner() {
        require(Owner == msg.sender, "You are not owner");
        _;
    }

    //Events
    event Transfer(
        address indexed sender,
        address indexed receiver,
        uint amount
    );
    event Approval(address indexed owner, address indexed spender, uint amount);

    function setFeePercentage(uint _feePercentage) public onlyOwner {
        require(_feePercentage <= 10, "Invalid Input");
        feePercentage = _feePercentage;
    }

    //External Approve function
    function approve(address spender, uint amount) public returns (bool) {
        require(spender != address(0), "Zero Address");
        _approve(msg.sender, spender, amount);
        return true;
    }

    //Internal approve function
    function _approve(address owner, address spender, uint amount) internal {
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    //External Transferfrom function
    function transferFrom(
        address from,
        address receiver,
        uint amount
    ) external returns (bool) {
        require(
            amount <= allowances[from][msg.sender],
            "Insufficient Allowance"
        );
        require(from != address(0), "Zero Address");
        require(receiver != address(0), "Zero Address");
        allowances[from][msg.sender] -= amount;
        _transfer(from, receiver, amount);
        return true;
    }

    //External Transfer function
    function transfer(address receiver, uint amount) external returns (bool) {
        require(receiver != address(0), "Zero Address");
        _transfer(msg.sender, receiver, amount);
        return true;
    }

    //Internal transfer function
    function _transfer(address sender, address receiver, uint amount) internal {
        _update(sender, receiver, amount);
    }

    //Minting New Tokens
    function _mint(address receiver, uint amount) internal {
        require(receiver != address(0), "Zero Address");
        _update(address(0), receiver, amount);
    }

    //External Burn
    function burn(uint amount) public returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }

    //Burn approval
    function burnFrom(address from, uint amount) public returns (bool) {
        require(from != address(0), "Zero Address");
        require(
            amount <= allowances[from][msg.sender],
            "Insufficient allowance"
        );
        allowances[from][msg.sender] -= amount;
        _burn(from, amount);
        return true;
    }

    //Burning existing Tokens
    function _burn(address sender, uint amount) internal {
        require(sender != address(0), "Zero address");
        _update(sender, address(0), amount);
    }

    //OpenZepplin Universal Update
    function _update(address from, address to, uint amount) internal {
        _beforeTokenTransfer(from, to);
        if (from != address(0) && to != address(0)) {
            require(amount <= balances[from], "Insufficient Balance");
            uint fee = (amount * feePercentage) / 100;
            uint netAmount = amount - fee;
            balances[from] -= amount;
            balances[to] += netAmount;
            balances[feeReceiver] += fee;
            emit Transfer(from, to, netAmount);
            emit Transfer(from, feeReceiver, fee);
        } else {
            if (from != address(0)) {
                require(amount <= balances[from], "Insufficient Balanbce");
                balances[from] -= amount;
            }
            if (to != address(0)) {
                balances[to] += amount;
            }
            if (from == address(0)) {
                totalSupply += amount;
            }
            if (to == address(0)) {
                totalSupply -= amount;
            }
            emit Transfer(from, to, amount);
        }
        _afterTokenTransfer(from, to, amount);
    }

    //Hook- Before State change
    function _beforeTokenTransfer(address from, address to) internal view {
        require(
            !(paused && from != address(0) && to != address(0)),
            "Transfers are paused"
        );
    }

    //Pausable Functions
    function pause() public onlyOwner {
        require(paused == false, "Already paused");
        paused = true;
    }
    function unpause() public onlyOwner {
        require(paused == true, "Already Unpaused");
        paused = false;
    }

    //Hook- After State change
    function _afterTokenTransfer(
        address from,
        address to,
        uint amount
    ) internal {}

    //Balance Getter function
    function balanceOf(address user) external view returns (uint) {
        return balances[user];
    }
}

contract AMM {
    address public tokenAddress;
    IERC20 public token;
    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
        token = IERC20(_tokenAddress);
    }
    uint public tokenReserve;
    uint public ethReserve;
    uint public totalShare;
    bool locked;
    mapping(address => uint) public lpBalances;

    event Swap(address user, uint tokenAmount, uint ethReceived);
    event LiquidityAdded(address user, uint tokenAmount, uint ethReceived);

    // Reentrancy Checker
    modifier noReentrant() {
        require(!locked, "Rentrant Call");
        locked = true;
        _;
        locked = false;
    }

    // Liquidity Function
    function addLiquidity(uint x, uint y) public payable {
        uint oldTokenReserve = token.balanceOf(address(this));
        uint oldEthReserve = address(this).balance;
        uint shares;
        require(msg.value == y, "Invalid eth entered");

        require(
            token.transferFrom(msg.sender, address(this), x),
            "Token Transfer failed"
        );
        tokenReserve = token.balanceOf(address(this));
        uint actualTokenReceived = tokenReserve - oldTokenReserve;
        uint actualEthReceived = msg.value;

        if (oldTokenReserve == 0 && oldEthReserve == 0) {
            tokenReserve = token.balanceOf(address(this));
            ethReserve = address(this).balance;
        } else {
            require(x * oldEthReserve == y * oldTokenReserve, "Invalid Ratio");
            tokenReserve = token.balanceOf(address(this));
            ethReserve = address(this).balance;
        }

        if (totalShare == 0) {
            shares = Math.sqrt(actualTokenReceived * actualEthReceived);
        } else {
            shares = Math.min(
                (actualTokenReceived * totalShare) / oldTokenReserve,
                (actualEthReceived * totalShare) / oldEthReserve
            );
        }
        lpBalances[msg.sender] += shares;
        totalShare += shares;
        tokenReserve = token.balanceOf(address(this));
        ethReserve = address(this).balance;
        emit LiquidityAdded(msg.sender, x, y);
    }

    // Remove Liquidity
    function removeLiquidity(uint shares) public noReentrant {
        require(shares <= lpBalances[msg.sender], "Invalid Input");
        require(totalShare > 0, "Not enough Share");
        uint tokenAmount = (shares * tokenReserve) / totalShare;
        uint ethAmount = (shares * ethReserve) / totalShare;

        lpBalances[msg.sender] -= shares;
        totalShare -= shares;

        require(token.transfer(msg.sender, tokenAmount), "transfer failed");
        (bool success, ) = payable(msg.sender).call{value: ethAmount}("");
        require(success, "Transfer Failed");
        tokenReserve = token.balanceOf(address(this));
        ethReserve = address(this).balance;
    }

    //Swap Function  TOKEN → ETH
    function swapTokenForEth(uint tokenIn, uint minEthOut) public {
        require(tokenIn > 0, "Invalid amount input");

        uint feePercentage = 3;
        uint beforeBalance = token.balanceOf(address(this));
        require(
            token.transferFrom(msg.sender, address(this), tokenIn),
            "Token Transfer Failed"
        );
        uint afterBalance = token.balanceOf(address(this));
        uint currentTokenReserve = tokenReserve;
        uint currentEthReserve = ethReserve;

        uint received = (afterBalance - beforeBalance);
        uint dexFee = (received * feePercentage) / 1000;
        uint actualReceived = received - dexFee;
        uint ethOut = (currentEthReserve * actualReceived) /
            (currentTokenReserve + actualReceived);

        require(ethOut >= minEthOut, "Slippage too high");
        require(ethOut <= currentEthReserve, "Not enough ETH");

        tokenReserve = token.balanceOf(address(this));
        ethReserve = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: ethOut}("");
        require(success, "Transfer Failed");

        emit Swap(msg.sender, tokenIn, ethOut);
    }

    //Swap Function  ETH → TOKEN
    function swapEthForToken(uint minTokenOut) public payable {
        require(msg.value > 0, "Invalid Input");
        uint ethIn = msg.value;

        uint feePercentage = 3;
        uint currentTokenReserve = tokenReserve;
        uint currentEthReserve = ethReserve;
        uint dexFee = (ethIn * feePercentage) / 1000;
        uint actualEth = ethIn - dexFee;
        uint tokenOut = (currentTokenReserve * actualEth) /
            (currentEthReserve + actualEth);

        require(tokenOut >= minTokenOut, "Slippage too high");
        require(tokenOut <= currentTokenReserve, "Not Enough Token");

        require(token.transfer(msg.sender, tokenOut), "Transfer Failed");
        tokenReserve = token.balanceOf(address(this));
        ethReserve = address(this).balance;

        emit Swap(msg.sender, tokenOut, ethIn);
    }

    receive() external payable {}
}

//**** Important Notes *****
// TOKEN → ETH
// We use actualReceived ✅
// because fee token affects transferFrom ✅

// ETH → TOKEN
// ETH is exact ✅
// msg.value is reliable ✅
