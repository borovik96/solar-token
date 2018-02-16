pragma solidity ^0.4.18;

import "./SOL.sol";

contract CrowdsaleStage {
    using SafeMath for uint;
    //R to private for more security FIXED
    uint internal startTime;
    uint internal endTime;
    uint8 internal currentStage;
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

    //R all public methods to onlyOwner
    function getStartTime() public constant onlyOwner returns (uint) {
        return startTime;
    }

    function getEndTime() public constant onlyOwner returns (uint) {
        return endTime;
    }

    // function CrowdsaleStage(uint8 _decimals) public{
    //     decimals = _decimals;
    // }

    function IsEnd() public constant onlyOwner returns (bool) {
        return isEnd;
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


    function buyTokens(uint paidWei, uint priceEthUSD) public onlyOwner returns (uint256 tokensBought) {
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
      if (currentStageRemain >= amount) {
          stages[currentStage].remainedTokens = currentStageRemain.sub(amount);
          return amount.add(tokensBought);
      } else if (currentStage == lastSubStage) {
          //R я еще не посмотрел что там в точке вызова но чтоб не забыть
          //R не понятно что будет с деньгами пользователя за которые он не получит токенов
          //R мне кажется переход в данную ветку ошибочным! соответственно надо кидать исключение или возвращать ошибку - например 0 токенов куплено если сумаа поданная пользователем превышает максимлаьно допустимую
          //
          // Всё верно, можем объяснить
          //
          stages[currentStage].remainedTokens = 0;
          isEnd = true;
          return currentStageRemain.add(tokensBought);
      } else {
          //R тут мне кажется ошибка в том что пользователь не получит нисколько токенов по цене текущей стадии
          //так как данная инфа нигде не сохраняется, а после вызова updateCurrentStage все токены из текущей стадии переедут в следующую
          //кроме того вычитается цена токенов. мб я не прав но вроде зесь ошибка
          //
          // Всё верно, можем объяснить
          //
          uint debt = paidWei.sub(remainedTokensWeiPrice); // wei
          stages[currentStage].remainedTokens = 0;
          updateCurrentStage();
          return updateBalances(debt, currentStageRemain.add(tokensBought), priceEthUSD);
      }
    }

    function updateCurrentStage() internal {
        uint8 i = 0;

        //R теоретически данное условие может стать бесконечным! Например когда у нас now будет за пределами последнего этапа!
        //R мы вроде не должны такое допускать но проверка тут  будет не лишней
        //R или лишней? какое ваше мнение?
        //
        // Если now большое, то не попадём сюда, думаю лишнее будет, если мыз наем что этого не произойдёт
        //
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
  uint private constant stage1end = startTime + 2 seconds;
  uint private constant stage2end = startTime + 4 seconds;
  uint private constant stage3end = startTime + 6 seconds;
  uint private constant stage1price = 10;
  uint private constant stage2price = 20;
  uint private constant stage3price = 30;
  uint private constant stage4price = 40;

  //R why it is not constant??
  // FIXED
  uint private constant stageSupply = 1000 * (10 ** decimals);

  //R мне кажется что всю инициализацию необходимо вынести в одну точку! и параетры стадий передавать в конструкторе!
  //
  // Обсудили, не будем менять
  //
  function PreICO() public {
    currentStage = 0;
    startTime = now;
    endTime = startTime + 180 seconds;
    isEnd = false;
    stages[0] = Stage(startTime, stage1end, stage1price, stageSupply);
    stages[1] = Stage(stage1end, stage2end, stage2price, stageSupply);
    stages[2] = Stage(stage2end, stage3end, stage3price, stageSupply);
    stages[3] = Stage(stage3end, endTime, stage4price, stageSupply);
  }
}

contract ICO is CrowdsaleStage {
  //R аналогично с предидущем
  //
  // Обсудили, не будем менять
  //
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

contract Crowdsale is SOL {

    mapping(address => bool) whiteList;
    mapping(address => uint) weiBalances;
    address[] investors;
    uint public remainedBountyTokens = 1893000;
    uint priceEthUSD = 120000;// cent
    uint startTime;

    ICO icoStage;
    PreICO preIcoStage;
    uint public softCap = 100;// general
    bool public outOfTokens = false;

    event IcoIsEnded();

    function () public payable {
        require(msg.value > 0);
        require(!outOfTokens);
        //require(isInWhiteList(msg.sender));

        uint paidWei;
        uint256 tokenBought;

        //R можно в начало засунуть !preIcoStage.IsEnd() && - это теоретически ускорит процесс
        //
        // FIXED
        if (!preIcoStage.IsEnd() && now >= preIcoStage.getStartTime() && now < preIcoStage.getEndTime()) {

            //R вообще здесь можно добавить вместо require if и в случай 0 - завершать этап
            //
            // Этапы завершаются автоматически в одном месте (updateBalances) если у нас 0, то этап уже завершён
            //
            require(preIcoStage.howMuchCanBuy(priceEthUSD) > 0);

            paidWei = preIcoStage.howMuchCanBuy(priceEthUSD) >= msg.value ? msg.value : preIcoStage.howMuchCanBuy(priceEthUSD);
            tokenBought = preIcoStage.buyTokens(paidWei, priceEthUSD);
            balances[msg.sender] = balances[msg.sender].add(tokenBought);
            totalSupply = totalSupply.sub(tokenBought);

            if (msg.value > paidWei) msg.sender.transfer(msg.value - paidWei);

        //R аналогично !icoStage.IsEnd() &&
        //
        // FIXED
        } else if (!icoStage.IsEnd() && now >= icoStage.getStartTime() && now < icoStage.getEndTime()) {
            if (!preIcoStage.IsEnd()) {
                preIcoStage.endStage();
                factory.transfer(this.balance);
            }

            //R аналогично require заменить на if
            //
            // Ответ выше (223 строка)
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
                balances[factory] = initialSupply.sub(totalSupply).div(10); // 10 percent of all tokens
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
        preIcoStage = new PreICO();
        icoStage = new ICO();
        preSale();
    }

    //R всех из preSale надо сразу в whiteList
    //
    // Fixed
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
        totalSupply = totalSupply.sub(_amount);
    }

    function isInWhiteList(address member) internal constant returns(bool){
        if(whiteList[member]) return true;
        return false;
    }

    //R я мб пропустил но как будут выводиться средства с preICO для которого нет softCAP
    //R в рамках ICO деньги должны выводиться только по оконанию ICO
    function sendToFactory() public onlyFactory {
      if (!preICO.isEnd()) {
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
}
