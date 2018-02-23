pragma solidity ^0.4.19;

import "./SOL.sol";
import "./PreICOParams.sol";
import "./ICOParams.sol";

contract CrowdsaleStage is Access{
    using SafeMath for uint;
    uint public startTime;
    //R зачем если есть getStartTime()??
    uint public endTime; // public for buyout function 
    uint8 internal currentStage;
    uint public decimals;
    Stage[4] internal stages;
    bool internal isEnd;

    uint8 public constant LAST_SUB_STAGE = 3;

    struct Stage {
        uint startTime;
        uint endTime;
        uint price;
        uint remainedTokens;
    }

    function getStartTime() public constant onlyOwner returns (uint) {
        return startTime;
    }

    function getEndTime() public constant onlyOwner returns (uint) {
        return endTime;
    }
    function getIsEnd() public constant onlyOwner returns (bool) {
        return isEnd;
    }

    //R нет проверки про деньги, что там вообще остались токены
    function isActive() public constant onlyOwner returns (bool) {
      return (!isEnd && now >= startTime && now < endTime);
    }

    function howMuchCanBuy(uint priceEthUSD) public onlyOwner returns (uint256 weiAmount) {
        weiAmount = 0;
        uint256 tokenPrice;
        updateCurrentStage();
        for (uint8 i = 0; i < stages.length; i++) {
          tokenPrice = calculateTokenPrice(stages[i].price, priceEthUSD);
          weiAmount = weiAmount.add(stages[i].remainedTokens.mul(tokenPrice).div(10 ** decimals));
        }

        return (weiAmount);
    }

    // Предлагаю перерабоать данную функцию вместе с updateBalance
    // предлагаю чтобы данная функция возвращала пару кол-во купленых токенов и их стоимость в эфире!
    // разница между paidWei и стоимостью возвращается пользователю 
    // таким образом можем полностью выпилить howMuchCanBuy и проверку этоого параметра во внешнем контракте
    // кроме того факт того что токены закончились разумно учитывать в isActive
    function buyTokens(uint paidWei, uint priceEthUSD) public onlyOwner returns (uint256 tokensBought) {
      require(howMuchCanBuy(priceEthUSD) >= paidWei);
      tokensBought = updateBalances(paidWei, 0, priceEthUSD);

      return tokensBought;
    }

    function updateBalances(uint paidWei, uint tokensBought, uint priceEthUSD) internal returns (uint allTokensBought) {
      uint currentPrice = stages[currentStage].price;
      uint tokenWeiPrice = calculateTokenPrice(currentPrice, priceEthUSD);
      uint currentStageRemain = stages[currentStage].remainedTokens;
      uint amount = paidWei.div(tokenWeiPrice);
      uint remainedTokensWeiPrice = (currentStageRemain.div(10 ** decimals)).mul(tokenWeiPrice);
      amount *= 10 ** decimals;
      //R надо обрабатывать ошибочные ситуации а не делать вид что их не будет amount > howMuchCanBuy
      if (currentStageRemain >= amount) {
          stages[currentStage].remainedTokens = currentStageRemain.sub(amount);
          if (currentStage == LAST_SUB_STAGE && currentStageRemain == amount) {
            isEnd = true;
          }
          return amount.add(tokensBought);
      } else {
          uint debt = paidWei.sub(remainedTokensWeiPrice); // wei
          stages[currentStage].remainedTokens = 0;
          updateCurrentStage();
          return updateBalances(debt, currentStageRemain.add(tokensBought), priceEthUSD);
      }
    }

    function updateCurrentStage() internal {
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
    }

    function calculateTokenPrice(uint centPrice, uint priceEthUSD) internal constant returns (uint weiPrice) {
        return (centPrice.mul(10 ** 18)).div(priceEthUSD);
    }

    function endStage() public returns (uint burntTokens) {
        isEnd = true;
        return burnAllRemainedTokens();
    }

    function burnAllRemainedTokens() private returns (uint burntTokens) {
        burntTokens = 0;
        for(uint8 i = 0; i < stages.length; i++) {
          burntTokens = burntTokens.add(stages[i].remainedTokens);
          stages[i].remainedTokens = 0;
        }
        return burntTokens;
    }

}



contract PreICO is CrowdsaleStage {
  PreICOParams preIcoParams = new PreICOParams();
  function PreICO() public {
    currentStage = 0;
    startTime = preIcoParams.START_TIME();
    endTime = preIcoParams.END_TIME();
    isEnd = false;
    stages[0] = Stage(
      preIcoParams.START_TIME(),
      preIcoParams.STAGE_1_END(),
      preIcoParams.STAGE_1_PRICE(),
      preIcoParams.STAGE_1_SUPPLY().mul(10 ** decimals)
    );
    stages[1] = Stage(
      preIcoParams.STAGE_1_END(),
      preIcoParams.STAGE_2_END(),
      preIcoParams.STAGE_2_PRICE(),
      preIcoParams.STAGE_2_SUPPLY().mul(10 ** decimals)
    );
    stages[2] = Stage(
      preIcoParams.STAGE_2_END(),
      preIcoParams.STAGE_3_END(),
      preIcoParams.STAGE_3_PRICE(),
      preIcoParams.STAGE_3_SUPPLY().mul(10 ** decimals)
    );
    stages[3] = Stage(
      preIcoParams.STAGE_3_END(),
      preIcoParams.END_TIME(),
      preIcoParams.STAGE_4_PRICE(),
      preIcoParams.STAGE_4_SUPPLY().mul(10 ** decimals)
    );
  }
}




contract ICO is CrowdsaleStage {
  ICOParams icoParams = new ICOParams();
  function ICO() public {
    currentStage = 0;
    startTime = icoParams.START_TIME();
    endTime = icoParams.END_TIME();
    isEnd = false;
    stages[0] = Stage(
      icoParams.START_TIME(),
      icoParams.STAGE_1_END(),
      icoParams.STAGE_1_PRICE(),
      icoParams.STAGE_1_SUPPLY().mul(10 ** decimals)
    );
    stages[1] = Stage(
      icoParams.STAGE_1_END(),
      icoParams.STAGE_2_END(),
      icoParams.STAGE_2_PRICE(),
      icoParams.STAGE_2_SUPPLY().mul(10 ** decimals)
    );
    stages[2] = Stage(
      icoParams.STAGE_2_END(),
      icoParams.STAGE_3_END(),
      icoParams.STAGE_3_PRICE(),
      icoParams.STAGE_3_SUPPLY().mul(10 ** decimals)
    );
    stages[3] = Stage(
      icoParams.STAGE_3_END(),
      icoParams.END_TIME(),
      icoParams.STAGE_4_PRICE(),
      icoParams.STAGE_4_SUPPLY().mul(10 ** decimals)
    );
  }
}

contract Crowdsale is SOL {

    mapping(address => bool) whiteList;
    mapping(address => uint) weiBalances;
    address[] investors;
    uint public remainedBountyTokens = 1893000;
    uint priceEthUSD = 120000;// cent
    uint startTime;
    uint icoTokensSold;
    ICO icoStage;
    PreICO preIcoStage;
    uint public softCap = 100;// general
    bool public outOfTokens = false;
    uint constant PANEL_PRICE = 600; // in tokens
    uint constant TOKEN_BUYOUT_PRICE = 110; // in cent

    event IcoEnded();
    event Buyout(address sender, uint amount);
    event BuyPanels(address buyer, uint countPanels);

    function () public payable {
        require(msg.value > 0);

        if (icoStage.getIsEnd()) return; // just save money on wallet for payout

        require(!outOfTokens);
        //require(isInWhiteList(msg.sender));

        uint paidWei;
        uint256 tokenBought;

        if (preIcoStage.isActive()) {

            //R логику проверки остатка средств предалагю так же засунуть внутрь функции buyTokens
            //
            require(preIcoStage.howMuchCanBuy(priceEthUSD) > 0);

            paidWei = preIcoStage.howMuchCanBuy(priceEthUSD) >= msg.value ? msg.value : preIcoStage.howMuchCanBuy(priceEthUSD);
            tokenBought = preIcoStage.buyTokens(paidWei, priceEthUSD);
            balances[msg.sender] = balances[msg.sender].add(tokenBought);
            totalSupply = totalSupply.add(tokenBought);

            if (msg.value > paidWei) msg.sender.transfer(msg.value - paidWei);

        } else if (icoStage.isActive()) {
            if (!preIcoStage.getIsEnd()) {
                preIcoStage.endStage();
                factory.transfer(this.balance);
            }

            if (icoStage.howMuchCanBuy(priceEthUSD) <= 0) {
              icoStage.endStage();
              msg.sender.transfer(msg.value);
              return;
            }

            paidWei = icoStage.howMuchCanBuy(priceEthUSD) >= msg.value ? msg.value : icoStage.howMuchCanBuy(priceEthUSD);
            tokenBought = icoStage.buyTokens(paidWei, priceEthUSD);
            icoTokensSold = icoTokensSold.add(tokenBought);
            balances[msg.sender] = balances[msg.sender].add(tokenBought);
            totalSupply = totalSupply.add(tokenBought);

            if (weiBalances[msg.sender] == 0) investors.push(msg.sender);
            weiBalances[msg.sender] = weiBalances[msg.sender].add(paidWei);

            if (msg.value > paidWei) msg.sender.transfer(msg.value - paidWei);
        } else if (now > icoStage.getEndTime()) {
            msg.sender.transfer(msg.value);
            if (!icoStage.getIsEnd()) {
                icoStage.endStage();
                uint usdCollected = this.balance.mul(priceEthUSD.div(100));
                if (usdCollected >= softCap) {
                  balances[factory] = icoTokensSold.div(10); // 10 percent of ico tokens sold
                  totalSupply = totalSupply.add(icoTokensSold.div(10));
                }
                remainedBountyTokens = 0;
                outOfTokens = true;
                IcoEnded();
            }
        }
    }

    function calculateTokenPrice(uint centPrice) internal constant returns (uint weiPrice) {
        return (centPrice.mul(10 ** 18)).div(priceEthUSD);
    }

    function Crowdsale() public {
        totalSupply = 0;
        preIcoStage = new PreICO();
        icoStage = new ICO();
        preSale();
    }

    function preSale() internal {
      /*
      balances[0x00000] = 100;
      investors.push(0x0000);
      whiteList[0x0000] = true;
      */
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

    function setPriceEthUSD(uint newPrice) public onlyPrice_updater { // cent
        priceEthUSD = newPrice;
    }

    function sendBountyTokens(address _to, uint _amount) public onlyBounty_manager {
        require(_amount <= remainedBountyTokens);
        require(isInWhiteList(msg.sender));
        investors.push(_to);
        balances[_to] = balances[_to].add(_amount);
        remainedBountyTokens = remainedBountyTokens.sub(_amount);
        totalSupply = totalSupply.add(_amount);
    }

    function isInWhiteList(address member) internal constant returns(bool){
        if(whiteList[member]) return true;
        return false;
    }

    function sendToFactory() public onlyFactory {
      if (!preIcoStage.getIsEnd()) {
        factory.transfer(this.balance);
        return;
      }
      uint usdCollected = this.balance.mul(priceEthUSD.div(100));
      if (usdCollected < softCap) revert();
      factory.transfer(this.balance);
    }

    function getBalance() public constant returns(uint) {
        return this.balance;
    }

    function returnFunds(address investor) public onlyOwner {
        require(balances[investor] != 0);
        investor.transfer(weiBalances[investor]);
        balances[investor] = 0;
        weiBalances[investor] = 0;
    }

    function returnAllFunds() public onlyOwner {
        for (uint i = 0; i < investors.length; i++) {
            returnFunds(investors[i]);
        }
        totalSupply = 0;
    }


    function buyout(uint _amount) public {
      require(balances[msg.sender] >= _amount);
      require(now > icoStage.endTime() + 2 years);
      uint weiNeedReturn = TOKEN_BUYOUT_PRICE.mul(_amount).mul(10 ** 18).div(priceEthUSD);
      uint realAmount = _amount;
      if (weiNeedReturn > this.balance) {
        realAmount = this.balance.mul(priceEthUSD).div(TOKEN_BUYOUT_PRICE).div(10 ** 18);
      }
      totalSupply = totalSupply.sub(realAmount);
      balances[msg.sender] = balances[msg.sender].sub(realAmount);
      Buyout(msg.sender, realAmount);
    }

    function buyPanel(uint paidTokens) public {
      require(balances[msg.sender] >= paidTokens);
      require(now > icoStage.endTime() + 1 years);
      uint countPanels = paidTokens.div(PANEL_PRICE);
      uint payTokens = countPanels.mul(PANEL_PRICE);
      totalSupply = totalSupply.sub(payTokens);
      balances[msg.sender] = balances[msg.sender].sub(payTokens);
      BuyPanels(msg.sender, countPanels);
    }

}
