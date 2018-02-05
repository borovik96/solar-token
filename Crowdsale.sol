pragma solidity ^0.4.18;

import "./SOL.sol";


contract Crowdsale is SOL{
    mapping(address => bool) whiteList;
    uint public remainedBountyTokens;
    uint priceEthUSD = 85000;// в центах 
    uint startTime;
    uint currentStage = 0;
    struct Stage {
        uint endTime;
        uint price;
        uint remainedTokens;
    }
    Stage[8] private stages;
    uint public softCap;// general
    uint public hardCap;// general
    bool public outOfTokens = false;
    
    function () public payable{
        require(msg.value > 0);
        require(!outOfTokens);
        require(isInWhiteList(msg.sender));
        require(stages[7].endTime > now);
        updateCurrentStage();
        updateBalances(msg.value);
    }
    
    function calculateTokenPrice(uint centPrice) internal returns (uint weiPrice) {
        return (centPrice.mul(10 ** 18)).div(priceEthUSD);
    }
    
    function updateBalances(uint paidWei) internal {
        uint currentPrice = stages[currentStage].price;
        uint tokenWeiPrice = calculateTokenPrice(currentPrice);
        uint currentStageRemain = stages[currentStage].remainedTokens;
        uint amount = paidWei.div(tokenWeiPrice);
        amount *= 10 ** decimals;
        
        if(currentStageRemain >= amount) {
            balances[msg.sender] = balances[msg.sender].add(amount);
            stages[currentStage].remainedTokens = currentStageRemain.sub(amount);
            totalSupply = totalSupply.sub(amount);
        } else if (currentStage == 7) {
            uint paid = (currentStageRemain.div(10 ** decimals)).mul(tokenWeiPrice);
            balances[msg.sender] = balances[msg.sender].add(currentStageRemain);
            totalSupply = totalSupply.sub(currentStageRemain);
            stages[currentStage].remainedTokens = 0;
            msg.sender.send(msg.value - paid);
            outOfTokens = true;
        } else {
            uint debt = paidWei.sub((currentStageRemain.div(10 ** decimals)).mul(tokenWeiPrice)); // wei
            balances[msg.sender] = balances[msg.sender].add(currentStageRemain);
            totalSupply = totalSupply.sub(currentStageRemain);
            stages[currentStage].remainedTokens = 0;
            updateCurrentStage();
            updateBalances(debt);
        }
    }
    
    function updateCurrentStage() internal {
        if (stages[currentStage].remainedTokens <= 0) {
            currentStage++;
            stages[currentStage].endTime = now + 1 weeks;
        } else if (stages[currentStage].endTime <= now) {
            uint remainedTokensPrev = stages[currentStage].remainedTokens;
            currentStage++;
            stages[currentStage].endTime = now + 1 weeks;
            stages[currentStage].remainedTokens += remainedTokensPrev;
        }
    }
    
    function Crowdsale() public {
        startTime = now;
        totalSupply = initialSupply;
        stages[0] = Stage(startTime + 1 seconds, 1, 1000 * (10 ** decimals));
        stages[1] = Stage(startTime + 2 minutes, 10, 1000 * (10 ** decimals));
        stages[2] = Stage(startTime + 3 weeks, 1000, 1000 * (10 ** decimals));
        stages[3] = Stage(startTime + 4 weeks, 10000, 1000 * (10 ** decimals));
        stages[4] = Stage(startTime + 5 weeks, 100000, 3000 * (10 ** decimals));
        stages[5] = Stage(startTime + 6 weeks, 1000000, 1000 * (10 ** decimals));
        stages[6] = Stage(startTime + 7 weeks, 10000000, 1000 * (10 ** decimals));
        stages[7] = Stage(startTime + 8 weeks, 100000000, 1000 * (10 ** decimals));
    }
    
    function addMembersToWhiteList(address[] members) public onlyKyc_manager {
        for(uint i = 0; i < members.length; i++) {
            whiteList[members[i]] = true; // add member to whitelist
        }
    }
    
    function deleteMembersToWhiteList(address[] members) public onlyKyc_manager {
        for(uint i = 0; i < members.length; i++) {
            whiteList[members[i]] = false; // delete member to whitelist
        }
    }
    
    function setBountyTokens(uint amount) public onlyBounty_manager {
        remainedBountyTokens = amount;
    }

    function setPriceEthUSD(uint newPrice) public onlyPrice_updater { // в центах
        priceEthUSD = newPrice;
    }

    function sendBountyTokens(address _to, uint _amount) public onlyBounty_manager {
        require(_amount <= remainedBountyTokens);
        require(isInWhiteList(msg.sender));
        balances[_to] = balances[_to].add(_amount);
        remainedBountyTokens = remainedBountyTokens.sub(_amount);
        totalSupply = totalSupply.sub(_amount);
    }
    
    function isInWhiteList(address member) internal returns(bool){
        if(whiteList[member]) return true;
        return false;
    }
    
    function sendToFactory() public onlyOwner {
        factory.send(this.balance - 21 szabo);
    }
    
}