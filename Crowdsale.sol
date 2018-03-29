pragma solidity ^0.4.19;

import "./SOL.sol";
import "./PreICOParams.sol";
import "./ICOParams.sol";
import "./CrowdsaleParams.sol";
import "./StubToken.sol";

/// @title Solar Token ICO.
/// @author Borovik Valdimir, Zenin Mikhail

contract CrowdsaleStage is Access{
    using SafeMath for uint;
    uint internal startTime;
    uint internal endTime;
    uint8 internal currentStage;
    uint public decimals = 18; // hardcode because it's overhead pass as a prop
    Stage[4] internal stages;
    bool internal isEnd;

    uint8 public constant LAST_SUB_STAGE = 3;

    struct Stage {
        uint startTime;
        uint endTime;
        uint price;
        uint remainedTokens;
    }

    /// @dev Getting start time of stage
    function getStartTime() public constant onlyOwner returns (uint) {
        return startTime;
    }

    /// @dev Getting end time of stage
    function getEndTime() public constant onlyOwner returns (uint) {
        return endTime;
    }

    /// @dev Checking end of stage
    function getIsEnd() public constant onlyOwner returns (bool) {
        return isEnd;
    }

    /// @dev Stage activity check
    function isActive() public constant onlyOwner returns (bool) {
      return (!isEnd && now >= startTime && now < endTime);
    }

    /// @dev Buying tokens
    /// @param paidWei payed wei
    /// @param priceEthUSD price ETH in cents
    /// @return Returns remained wei and how much tokens bought.
    function buyTokens(uint paidWei, uint priceEthUSD) public onlyOwner returns (uint remainedWei, uint tokensBought) {
      require(!getIsEnd());
      (remainedWei, tokensBought) = updateBalances(paidWei, 0, priceEthUSD);

      return (remainedWei, tokensBought);
    }

    /// @dev Updating balances for each stage
    /// @param paidWei payed wei
    /// @param priceEthUSD price ETH in cents
    /// @return Returns remained wei and how much user can buy tokens.
    function updateBalances(uint paidWei, uint tokensBought, uint priceEthUSD) internal returns (uint remainedWei, uint allTokensBought) {
      uint currentPrice = stages[currentStage].price;
      uint tokenWeiPrice = calculateTokenPrice(currentPrice, priceEthUSD);
      uint currentStageRemain = stages[currentStage].remainedTokens;
      uint amount = paidWei.div(tokenWeiPrice).mul(10 ** decimals);
      uint remainedTokensWeiPrice = (currentStageRemain.div(10 ** decimals)).mul(tokenWeiPrice);
      if (currentStageRemain >= amount) {
          stages[currentStage].remainedTokens = currentStageRemain.sub(amount);
          return (0, amount.add(tokensBought));
      } else if (currentStage == LAST_SUB_STAGE) {
          stages[currentStage].remainedTokens = 0;
          isEnd = true;
          return (paidWei.sub(remainedTokensWeiPrice), currentStageRemain.add(tokensBought));
      } else {
          uint debt = paidWei.sub(remainedTokensWeiPrice); // wei
          stages[currentStage].remainedTokens = 0;
          updateCurrentStage();
          return updateBalances(debt, currentStageRemain.add(tokensBought), priceEthUSD);
      }
    }


    /// @dev Updating current stage and remained tokens for each stage
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

    /// @dev Calculating token price in wei
    /// @param centPrice price token in cents
    /// @param priceEthUSD price ETH in cents
    /// @return Returns price token in wei
    function calculateTokenPrice(uint centPrice, uint priceEthUSD) internal pure returns (uint weiPrice) {
        return (centPrice.mul(10 ** 18)).div(priceEthUSD);
    }

    /// @dev Completion of the stage
    /// @return Returns how much tokens was burned
    function endStage() public returns (uint burntTokens) {
        isEnd = true;
        return burnAllRemainedTokens();
    }

    /// @dev Burning all remained tokens on all stages
    /// @return Returns how much tokens was burned
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

  /// @dev Setting all default params
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

  /// @dev Setting all default params
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

    CrowdsaleParams params = new CrowdsaleParams();
    uint internal remainedBountyTokens = params.REMAINED_BOUNTY_TOKENS();
    uint private priceEthUSD = params.PRICE_ETH_USD();// cent
    uint private startTime;
    uint private icoTokensSold;
    ICO private icoStage;
    PreICO private preIcoStage;
    uint internal softCap = params.SOFTCAP();// general
    bool internal outOfTokens = false;
    uint constant PANEL_PRICE = params.PANEL_PRICE(); // in tokens
    address newTokenAddress;

    event IcoEnded();
    event BuyPanels(address buyer, uint countPanels);

    /// @dev Get remained bounty tokens
    /// @return Returns amount of remained bounty tokens
    function getRemainedBountyTokens() public constant returns (uint){
      return remainedBountyTokens;
    }

    /// @dev Get soft cap of ICO
    /// @return Returns ICO's soft cap
    function getSoftCap() public constant returns (uint) {
      return softCap;
    }
    /// @dev checking remaining tokens
    /// @return Returns true/false, false - tokens did not end, true - no tokens
    function getOutOfTokens() public constant returns (bool) {
      return outOfTokens;
    }

    /// @dev overloaded transfer function form erc20, serves for the purchase of panels
    /// @param _to address of the recipient
    /// @param _value amount of tokens
    /// @return Returns true, if user want purchase panel, call transfer from erc20 if not
    function transfer(address _to, uint256 _value) public returns (bool){
      if (_to == buy_pannel) {
        buyPanel(msg.sender, _value);
        return true;
      }
      return super.transfer(_to, _value);
    }

    /// @dev overloaded transferFrom function form erc20, serves for the purchase of panels
    /// @param _from sender's address
    /// @param _to address of the recipient
    /// @param _value amount of tokens
    /// @return Returns true, if user want purchase panel, call transferFrom from erc20 if not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
      require(_value <= balances[_from]);
      require(_value <= allowed[_from][msg.sender]);
      if (_to == buy_pannel) {
        buyPanel(_from, _value);
        return true;
      }
      return super.transferFrom(_from, _to, _value);
    }

    /// @dev fallback function, processes purchase of tokens
    function () public payable {
        require(msg.value > 0);

        if (icoStage.getIsEnd() && msg.sender == factory) return; // just save money on wallet for payout

        require(!outOfTokens);
        require(isInWhiteList(msg.sender));

        uint paidWei;
        uint256 tokenBought;
        uint returnWei;
        if (preIcoStage.isActive()) {
            (returnWei, tokenBought) = preIcoStage.buyTokens(msg.value, priceEthUSD);
            balances[msg.sender] = balances[msg.sender].add(tokenBought);
            totalSupply = totalSupply.add(tokenBought);

            if (returnWei > 0) msg.sender.transfer(returnWei);

        } else if (now > preIcoStage.getEndTime() && now < icoStage.getStartTime()) { // time between preICO and ICO
            if (!preIcoStage.getIsEnd()) {
                preIcoStage.endStage();
                factory.transfer(this.balance);
            }
            msg.sender.transfer(msg.value);
        } else if (icoStage.isActive()) {
            if (!preIcoStage.getIsEnd()) {
                preIcoStage.endStage();
                factory.transfer(this.balance);
            }
            /*if (icoStage.isEnd()) {
              icoStage.endStage();
              msg.sender.transfer(msg.value);
              return;
            }*/

            (returnWei, tokenBought) = icoStage.buyTokens(msg.value, priceEthUSD);
            icoTokensSold = icoTokensSold.add(tokenBought);
            balances[msg.sender] = balances[msg.sender].add(tokenBought);
            totalSupply = totalSupply.add(tokenBought);

            if (weiBalances[msg.sender] == 0) investors.push(msg.sender);
            weiBalances[msg.sender] = weiBalances[msg.sender].add(paidWei);

            if (returnWei > 0) msg.sender.transfer(returnWei);

        } else if (now > icoStage.getEndTime() || icoStage.getIsEnd()) {
            msg.sender.transfer(msg.value);
            if (!icoStage.getIsEnd()) {
                icoStage.endStage();
            }
            uint usdCollected = this.balance.mul(priceEthUSD.div(100));
            if (usdCollected >= softCap) {
              balances[factory] = icoTokensSold.div(10); // 10 percent of ico tokens sold
              totalSupply = totalSupply.add(icoTokensSold.div(10));
            } else {
              returnAllFunds();
            }
            remainedBountyTokens = 0;
            outOfTokens = true;
            IcoEnded();
        } else {
            msg.sender.transfer(msg.value);
        }
    }

    /// @dev contract constructor, initializes total supply and stages of ICO, launches presale
    function Crowdsale() public {
        totalSupply = 0;
        preIcoStage = new PreICO();
        icoStage = new ICO();
        preSale();
    }

    /// @dev initializes presale accounts
    function preSale() internal {
      /*
      balances[0x00000] = 100;
      investors.push(0x0000);
      whiteList[0x0000] = true;
      totalSupply = totalSupply.add(100);
      */
    }

    /// @dev Adding members to white list
    /// @param members - array of proven members
    function addMembersToWhiteList(address[] members) public onlyKyc_manager {
        for(uint i = 0; i < members.length; i++) {
            whiteList[members[i]] = true;
        }
    }

    /// @dev Deleting members from white list
    /// @param members - array of members for delete
    function deleteMembersToWhiteList(address[] members) public onlyKyc_manager {
        for(uint i = 0; i < members.length; i++) {
            whiteList[members[i]] = false;
        }
    }

    /// @dev Setting ETH price in cents
    /// @param newPrice New ETH price in cents
    function setPriceEthUSD(uint newPrice) public onlyPrice_updater { // cent
        priceEthUSD = newPrice;
    }

    /// @dev Setting new token address for exchange in futher
    /// @param _newTokenAddress new token address
    function setNewTokenAddress(address _newTokenAddress) public onlyOwner {
        newTokenAddress = _newTokenAddress;
    }

    /// @dev Sending bounty tokens
    /// @param _to address of the recipient
    /// @param _amount amount of bounty tokens
    function sendBountyTokens(address _to, uint _amount) public onlyBounty_manager {
        require(_amount <= remainedBountyTokens);
        require(isInWhiteList(_to));
        investors.push(_to);
        balances[_to] = balances[_to].add(_amount);
        remainedBountyTokens = remainedBountyTokens.sub(_amount);
        totalSupply = totalSupply.add(_amount);
    }

    /// @dev Finding member in whitelist
    /// @param member member's address
    /// @return Returns true - if member in white list, false - if not
    function isInWhiteList(address member) internal constant returns(bool){
        if(whiteList[member]) return true;
        return false;
    }

    /// @dev Sending all funds to factory if preICO is end and assembled soft cap
    function sendToFactory() public onlyFactory {
      if (!preIcoStage.getIsEnd()) {
        factory.transfer(this.balance);
        return;
      }
      uint usdCollected = this.balance.mul(priceEthUSD.div(100));
      if (usdCollected < softCap) revert();
      factory.transfer(this.balance);
    }

    /// @dev Getting balance of Crowdsale contract
    /// @return Returns Crowdsale's balance
    function getBalance() public constant returns(uint) {
        return this.balance;
    }

    /// @dev Returning funds to investor
    /// @param investor investor's address
    function returnFunds(address investor) public onlyOwner {
        require(balances[investor] != 0);
        investor.transfer(weiBalances[investor]);
        balances[investor] = 0;
        weiBalances[investor] = 0;
    }

    /// @dev Returning funds to all investors and burning all SOL tokens
    function returnAllFunds() public onlyOwner {
        for (uint i = 0; i < investors.length; i++) {
            returnFunds(investors[i]);
            balances[investors[i]] = 0;
            weiBalances[investors[i]] = 0;
        }
        totalSupply = 0;
    }

    /// @dev Purchasing panel for tokens
    /// @param _from buyer's address
    /// @param paidTokens amount of tokens
    function buyPanel(address _from, uint paidTokens) public {
      require(balances[_from] >= paidTokens);
      require(now > icoStage.getEndTime() + 1 years);
      require(isInWhiteList(_from));
      uint countPanels = paidTokens.div(PANEL_PRICE);
      uint payTokens = countPanels.mul(PANEL_PRICE);
      totalSupply = totalSupply.sub(payTokens);
      balances[_from] = balances[_from].sub(payTokens);
      BuyPanels(_from, countPanels);
    }

    /// @dev Exchanging old tokens to new
    /// @param _amount amount of old tokens
    function exchangeToNewToken(uint _amount) public {
      require(newTokenAddress != 0);
      require(balances[msg.sender] >= _amount);
      StubToken token = StubToken(newTokenAddress);
      bool success = token.exchangeOldToken(msg.sender, _amount);
      if (success) {
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        totalSupply = totalSupply.sub(_amount);
      }
    }

}
