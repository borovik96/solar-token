pragma solidity ^0.4.19;

import "./SOL.sol";

contract CrowdsaleStage {
    using SafeMath for uint256;
    uint public startTime;
    uint public endTime;
    uint8 public currentStage;
    uint decimals;
    Stage[4] internal stages;
    bool internal isEnd;
    uint8 public constant lastSubStage = 3;
    struct Stage {
        uint startTime;
        uint endTime;
        uint price;
        uint remainedTokens;
    }

    function getStartTime() public constant returns (uint) {
        return startTime;
    }

    function getEndTime() public constant returns (uint) {
        return endTime;
    }

    function CrowdsaleStage(uint8 _decimals) public{
        decimals = _decimals;
    }

    function IsEnd() public constant returns (bool) {
        return isEnd;
    }

    //возвращает сколько всего токенов осталось для продажи в рамках данного этапа
    //в Wei или эфире
        // мб сделать через переменную которая инициализируется на уровне конструктора и потом просто вычетается? ну чтоб экономить вычеслительные ресурсы! хотя это костыль
    function howMuchCanBuy(uint priceEthUSD) public constant returns (uint256 weiAmount) {
        weiAmount = 0;
        uint256 tokenPrice;
        for (uint8 i = 0; i < stages.length; i++) {
          tokenPrice = calculateTokenPrice(stages[i].price, priceEthUSD);
          weiAmount = weiAmount.add(stages[i].remainedTokens.mul(tokenPrice));
        }

        return (weiAmount);
    }

    // купить токенов. Возвращает кол-во токенов которые продали пользователю
    // если поданная на вход сумма больше суммарной стоимости всех токенов - надо ошибку бросить или че-то такое!
    function buyTokens(uint paidWei, uint priceEthUSD) public returns (uint256 tokensBought) {
      tokensBought = updateBalances(paidWei, 0, priceEthUSD);

      return tokensBought;
    }

    function updateBalances(uint paidWei, uint tokensBought, uint priceEthUSD) returns (uint allTokensBought) {
      uint currentPrice = stages[currentStage].price;
      uint tokenWeiPrice = calculateTokenPrice(currentPrice, priceEthUSD);
      uint currentStageRemain = stages[currentStage].remainedTokens;
      uint amount = paidWei.div(tokenWeiPrice);
      uint remainedTokensWeiPrice = (currentStageRemain.div(10 ** decimals)).mul(tokenWeiPrice);
      amount *= 10 ** decimals;
      if (currentStageRemain >= amount) {

          /*balances[msg.sender] = balances[msg.sender].add(amount);*/
          stages[currentStage].remainedTokens = currentStageRemain.sub(amount);
          /*if (isICO) weiBalances[msg.sender] = weiBalances[msg.sender].add(paidWei);*/
          /*totalSupply = totalSupply.sub(amount);*/
          return amount.add(tokensBought);
      } else if (currentStage == lastSubStage) {
          /*balances[msg.sender] = balances[msg.sender].add(currentStageRemain);*/
          stages[currentStage].remainedTokens = 0;
          /*if (isICO) weiBalances[msg.sender] = weiBalances[msg.sender].add(remainedTokensWeiPrice);*/
          /*totalSupply = totalSupply.sub(currentStageRemain);*/
          /*if (isICO) outOfTokens = true;*/
          /*msg.sender.transfer(msg.value - weiBalances[msg.sender]);*/
          isEnd = true;
          return currentStageRemain.add(tokensBought);
      } else {
          uint debt = paidWei.sub(remainedTokensWeiPrice); // wei
          /*balances[msg.sender] = balances[msg.sender].add(currentStageRemain);*/
          /*if (isICO) weiBalances[msg.sender] = weiBalances[msg.sender].add(remainedTokensWeiPrice);*/
          /*totalSupply = totalSupply.sub(currentStageRemain);*/
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

    function endStage() public returns (uint burntTokens){
        isEnd = true;
        return burnAllRemainedTokens();
    }

    function burnAllRemainedTokens() private returns (uint burntTokens){
        burntTokens = 0;
        for(uint8 i = 0; i < stages.length; i++) {
          burntTokens = burntTokens.add(stages[i].remainedTokens);
          stages[i].remainedTokens = 0;
        }
        return burntTokens;
    }

}

contract PreICO is CrowdsaleStage {
  uint private constant stage1end = 1523318400;
  uint private constant stage2end = 1523923200;
  uint private constant stage3end = 1524528000;
  uint private constant stage1price = 44;
  uint private constant stage2price = 47;
  uint private constant stage3price = 50;
  uint private constant stage4price = 52;
  uint private stageSupply = 1000000 * (10 ** decimals);
  function PreICO() {
    currentStage = 0;
    startTime = 1522713600;
    endTime = 1525046400;
    isEnd = false;
    stages[0] = Stage(startTime, stage1end, stage1price, stageSupply);
    stages[1] = Stage(stage1end, stage2end, stage2price, stageSupply);
    stages[2] = Stage(stage2end, stage3end, stage3price, stageSupply);
    stages[3] = Stage(stage3end, endTime, stage4price, stageSupply);
  }
}

contract ICO is CrowdsaleStage {
  uint private constant stage1end = 1525651200;
  uint private constant stage2end = 1526256000;
  uint private constant stage3end = 1526860800;
  uint private constant stage1price = 55;
  uint private constant stage2price = 60;
  uint private constant stage3price = 65;
  uint private constant stage4price = 70;
  uint private stageSupply = 10000000 * (10 ** decimals);
  function ICO() {
    currentStage = 0;
    startTime = 1525132800;
    endTime = 1527379200;
    isEnd = false;
    stages[0] = Stage(startTime, stage1end, stage1price, stageSupply);
    stages[1] = Stage(stage1end, stage2end, stage2price, stageSupply.mul(2));
    stages[2] = Stage(stage2end, stage3end, stage3price, stageSupply.mul(3));
    stages[3] = Stage(stage3end, endTime, stage4price, stageSupply.mul(3));
  }
}

contract Crowdsale is SOL{

    mapping(address => bool) whiteList;
    mapping(address => uint) weiBalances;
    address[] investors;
    uint public remainedBountyTokens = 1893000;
    uint priceEthUSD = 120000;// cent
    uint startTime;

    ICO private icoStage;
    PreICO private preIcoStage;
    uint public softCap = 100;// general
    bool public outOfTokens = false;

    event IcoIsEnded();

    function () public payable {
        require(msg.value > 0);
        require(!outOfTokens);
        //require(isInWhiteList(msg.sender));

        uint paidWei;
        uint256 tokenBought;
        if (now >= preIcoStage.getStartTime() && now < preIcoStage.getEndTime()) {
            require(preIcoStage.howMuchCanBuy(priceEthUSD) > 0);

            paidWei = preIcoStage.howMuchCanBuy(priceEthUSD) >= msg.value ? msg.value : preIcoStage.howMuchCanBuy(priceEthUSD);
            tokenBought = preIcoStage.buyTokens(paidWei, priceEthUSD);

            balances[msg.sender] = balances[msg.sender].add(tokenBought);
            totalSupply = totalSupply.sub(tokenBought);

            if (msg.value > paidWei) msg.sender.transfer(msg.value - paidWei);
        } else if (now >= icoStage.getStartTime() && now < icoStage.getEndTime()) {
            if (!preIcoStage.IsEnd()) {
                preIcoStage.endStage();
            }
            require(icoStage.howMuchCanBuy(priceEthUSD) > 0);

            paidWei = icoStage.howMuchCanBuy(priceEthUSD) >= msg.value ? msg.value : icoStage.howMuchCanBuy(priceEthUSD);
            tokenBought = icoStage.buyTokens(paidWei, priceEthUSD);

            balances[msg.sender] = balances[msg.sender].add(tokenBought);
            totalSupply = totalSupply.sub(tokenBought);

            if (weiBalances[msg.sender] == 0) investors.push(msg.sender);
            weiBalances[msg.sender] = weiBalances[msg.sender].add(paidWei);

            if (msg.value > paidWei) msg.sender.transfer(msg.value - paidWei);
        } else if (now > icoStage.getEndTime()) {
            if (!icoStage.IsEnd()) {
                icoStage.endStage();
                remainedBountyTokens = 0;
                outOfTokens = true;
                IcoIsEnded();
            }
        }
    }

    function calculateTokenPrice(uint centPrice) internal constant returns (uint weiPrice) {
        return (centPrice.mul(10 ** 18)).div(priceEthUSD);
    }

    function Crowdsale() public {
        totalSupply = initialSupply;
        preSale();
    }

    function preSale() internal {
      /*balances[0x00000] = 100;
      investors.push(0x0000);*/
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

    function setPriceEthUSD(uint newPrice) public onlyPrice_updater { // РІ С†РµРЅС‚Р°С…
        priceEthUSD = newPrice;
    }

    function sendBountyTokens(address _to, uint _amount) public onlyBounty_manager {
        require(_amount <= remainedBountyTokens);
        require(isInWhiteList(msg.sender));
        investors.push(_to);
        balances[_to] = balances[_to].add(_amount);
        remainedBountyTokens = remainedBountyTokens.sub(_amount);
        totalSupply = totalSupply.sub(_amount);
    }

    function isInWhiteList(address member) internal constant returns(bool){
        if(whiteList[member]) return true;
        return false;
    }

    function sendToFactory() public onlyFactory {
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
}
