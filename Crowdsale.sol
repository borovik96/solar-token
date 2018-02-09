pragma solidity ^0.4.19;

import "./SOL.sol";


contract Crowdsale is SOL{
    mapping(address => bool) whiteList;
    mapping(address => uint) weiBalances;
    address[] investors;
    uint public remainedBountyTokens;
    uint priceEthUSD = 85000;// cent
    uint startTime;
    uint public currentStage = 0;
    uint8 lastSubStage = 3;
    bool isPreICOBurnt = false;
    struct Stage {
        uint startTime;
        uint endTime;
        uint price;
        uint remainedTokens;
    }
    Stage[4] private icoStages;
    Stage[4] private preIcoStages;
    uint public softCap = 100;
    bool public outOfTokens = false;

    function () public payable{
        require(msg.value > 0);
        require(!outOfTokens);
        //require(isInWhiteList(msg.sender));
        require(icoStages[lastSubStage].endTime > now);
        if (now > icoStages[lastSubStage].endTime) {
          //BURN ALL remains tokens and return money
          burnAllRemainedTokens();
          msg.sender.transfer(msg.value);
          outOfTokens = true;
          return;
        }

        if (now > preIcoStages[lastSubStage].endTime && now < icoStages[0].startTime) { // time between PreICO and ICO
          // BURN preICO remains tokens and return money
          burnPreIcoTokens();
          msg.sender.transfer(msg.value);
          isPreICOBurnt = true;
          return;
        }
        bool isICO = now >= icoStages[0].startTime;
        if (!isPreICOBurnt && isICO) burnPreIcoTokens();// BURN preICO tokens;
        updateCurrentStage(isICO);
        if (isICO) updateBalances(icoStages, msg.value, true); // ICO go
        else updateBalances(preIcoStages, msg.value, false); // preICO is going on

    }

    function calculateTokenPrice(uint centPrice) internal constant returns (uint weiPrice) {
        return (centPrice.mul(10 ** 18)).div(priceEthUSD);
    }

    function updateBalances(Stage[4] stages, uint paidWei, bool isICO) internal {
        uint currentPrice = stages[currentStage].price;
        uint tokenWeiPrice = calculateTokenPrice(currentPrice);
        uint currentStageRemain = stages[currentStage].remainedTokens;
        uint amount = paidWei.div(tokenWeiPrice);
        uint remainedTokensWeiPrice = (currentStageRemain.div(10 ** decimals)).mul(tokenWeiPrice);
        amount *= 10 ** decimals;
        if(weiBalances[msg.sender] == 0 ) investors.push(msg.sender);

        if (currentStageRemain >= amount) {
            balances[msg.sender] = balances[msg.sender].add(amount);
            stages[currentStage].remainedTokens = currentStageRemain.sub(amount);
            weiBalances[msg.sender] = weiBalances[msg.sender].add(paidWei);
            updateStages(stages, isICO);
            totalSupply = totalSupply.sub(amount);
        } else if (currentStage == lastSubStage) {
            balances[msg.sender] = balances[msg.sender].add(currentStageRemain);
            stages[currentStage].remainedTokens = 0;
            weiBalances[msg.sender] = weiBalances[msg.sender].add(remainedTokensWeiPrice);
            updateStages(stages, isICO);
            totalSupply = totalSupply.sub(currentStageRemain);
            if (isICO) outOfTokens = true;
            msg.sender.transfer(msg.value - weiBalances[msg.sender]);
        } else {
            uint debt = paidWei.sub(remainedTokensWeiPrice); // wei
            balances[msg.sender] = balances[msg.sender].add(currentStageRemain);
            weiBalances[msg.sender] = weiBalances[msg.sender].add(remainedTokensWeiPrice);
            totalSupply = totalSupply.sub(currentStageRemain);
            stages[currentStage].remainedTokens = 0;
            updateStages(stages, isICO);
            stages = updateCurrentStage(isICO);
            updateBalances(stages, debt, isICO);
        }
    }
    // needs because in Solidity isn't able get point to array
    function updateStages(Stage[4] stages, bool isICO) internal {
        if (isICO) for (uint8 i = 0; i <= lastSubStage; i++) icoStages[i] = stages[i];
        else for (i = 0; i <= lastSubStage; i++) preIcoStages[i] = stages[i];
    }

    function updateCurrentStage(bool isICO) internal returns (Stage[4]){
        Stage[4] memory stages;
        if (isICO) stages = icoStages;
        else stages = preIcoStages;

        uint8 i = 0;
        while(!(stages[i].endTime > now && stages[i].startTime <= now)) i++;
        currentStage = i;
        for (uint8 k = 0; k < i; k++) { // collect all tokens to currentStage
          stages[currentStage].remainedTokens = stages[currentStage].remainedTokens.add(stages[k].remainedTokens);
          stages[k].remainedTokens = 0;
        }
        if (stages[currentStage].remainedTokens <= 0) {
          stages[currentStage].endTime = now;
          currentStage += 1;
          stages[currentStage].startTime = now;
        }
        return stages;
    }

    function Crowdsale() public {
        startTime = now;
        totalSupply = initialSupply;
        // PreICO 0-3
        preIcoStages[0] = Stage(startTime, startTime + 1 weeks, 10, 1000 * (10 ** decimals));
        preIcoStages[1] = Stage(startTime + 1 weeks, startTime + 2 weeks, 10, 1000 * (10 ** decimals));
        preIcoStages[2] = Stage(startTime + 2 weeks, startTime + 3 weeks, 10, 1000 * (10 ** decimals));
        preIcoStages[3] = Stage(startTime + 3 weeks, startTime + 4 weeks, 10, 1000 * (10 ** decimals));
        // ICO 4-7
        icoStages[0] = Stage(startTime + 4 weeks, startTime + 5 weeks, 100000, 3000 * (10 ** decimals));
        icoStages[1] = Stage(startTime + 5 weeks, startTime + 6 weeks, 1000000, 1000 * (10 ** decimals));
        icoStages[2] = Stage(startTime + 6 weeks, startTime + 7 weeks, 10000000, 1000 * (10 ** decimals));
        icoStages[3] = Stage(startTime + 7 weeks, startTime + 8 weeks, 100000000, 1000 * (10 ** decimals));
    }

    function addMembersToWhiteList(address[] members) public onlyKyc_manager {
        for(uint i = 0; i < members.length; i++) {
            whiteList[members[i]] = true;
        }
    }

    function deleteMembersToWhiteList(address[] members) public onlyKyc_manager {
        for(uint i = 0; i < members.length; i++) {
            whiteList[members[i]] = false;
        }
    }

    function setBountyTokens(uint amount) public onlyBounty_manager {
        remainedBountyTokens = amount;
    }

    function setPriceEthUSD(uint newPrice) public onlyPrice_updater { // РІ С†РµРЅС‚Р°С…
        priceEthUSD = newPrice;
    }

    function sendBountyTokens(address _to, uint _amount) public onlyBounty_manager {
        require(_amount <= remainedBountyTokens);
        require(isInWhiteList(msg.sender));
        balances[_to] = balances[_to].add(_amount);
        remainedBountyTokens = remainedBountyTokens.sub(_amount);
        totalSupply = totalSupply.sub(_amount);
    }

    function isInWhiteList(address member) internal constant returns(bool){
        if(whiteList[member]) return true;
        return false;
    }

    function burnPreIcoTokens() internal {
        for(uint8 i = 0; i <= lastSubStage; i++) {
            totalSupply = totalSupply.sub(preIcoStages[i].remainedTokens);
            preIcoStages[i].remainedTokens = 0;
        }
    }

    function burnAllRemainedTokens() internal {
        for(uint8 i = 0; i <= lastSubStage; i++) {
            totalSupply = totalSupply.sub(icoStages[i].remainedTokens);
            icoStages[i].remainedTokens = 0;
        }
        remainedBountyTokens = 0;
    }

    function sendToFactory() public onlyFactory {
      uint usdCollected = this.balance.mul(priceEthUSD.div(100));
      if (usdCollected < softCap) revert();
      factory.transfer(this.balance);
    }

    function getBalance() public constant returns(uint) {
        return this.balance;
    }

    function returnFunds(address investor) public onlyKyc_manager{
        require(balances[investor] != 0);
        investor.transfer(weiBalances[investor]);
        balances[investor] = 0;
        weiBalances[investor] = 0;
    }

    function returnAllFunds() public onlyKyc_manager {
        for (uint i = 0; i < investors.length; i++) {
            returnFunds(investors[i]);
        }
        totalSupply = 0;
    }
}
