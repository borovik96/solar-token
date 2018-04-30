pragma solidity ^0.4.19;

import "./SOL.sol";

import "./StubToken.sol";

/// @title Solar Token ICO.
/// @author Borovik Valdimir, Zenin Mikhail

contract Crowdsale is SOL {
    using SafeMath for uint;
    uint public _totalSupply;
    mapping(address => bool) whiteList;
    mapping(address => uint) weiBalances;
    address[] investors;
    uint constant PANEL_PRICE = 600; // in tokens SET BEFORE DEPLOY
    uint constant BUY_PANEL_START_TIME = 1000; // timestamp SET BEFORE DEPLOY
    uint constant SEND_TOKENS_TO_TEAM_TIME_1 = 1000; // timestamp SET BEFORE DEPLOY
    uint constant SEND_TOKENS_TO_TEAM_TIME_2 = SEND_TOKENS_TO_TEAM_TIME_1 + 1 years;
    uint constant TEAM_BONUS = 1000; // in tokens SET BEFORE DEPLOY
    address newTokenAddress;

    event BuyPanels(address buyer, uint countPanels);

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

    function totalSupply() public constant returns (uint) {
       return _totalSupply  - balances[address(0)];
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

    /// @dev contract constructor, initializes total supply and stages of ICO, launches presale
    function Crowdsale() public {
        preSale();
    }

    /// @dev initializes presale accounts
    function preSale() internal {
      /*
      balances[0x00000] = 100;
      investors.push(0x0000);
      whiteList[0x0000] = true;
      _totalSupply = _totalSupply.add(100);
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

    /// @dev Setting new token address for exchange in futher
    /// @param _newTokenAddress new token address
    function setNewTokenAddress(address _newTokenAddress) public onlyOwner {
        newTokenAddress = _newTokenAddress;
    }

    /// @dev Finding member in whitelist
    /// @param member member's address
    /// @return Returns true - if member in white list, false - if not
    function isInWhiteList(address member) internal constant returns(bool){
        if(whiteList[member]) return true;
        return false;
    }

    /// @dev Purchasing panel for tokens
    /// @param _from buyer's address
    /// @param paidTokens amount of tokens
    function buyPanel(address _from, uint paidTokens) public {
      require(balances[_from] >= paidTokens);
      require(now >= BUY_PANEL_START_TIME);
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


    bool isFirstPartTeamsTokensSended = false;
    bool isSecondPartTeamsTokensSended = false;
    /// @dev Sending tokens to team
    function sendTokenToTeam() public onlyOwner {
      require(now >= SEND_TOKENS_TO_TEAM_TIME_1);
      if (!isFirstPartTeamsTokensSended) {
        balances[factory] = balances[factory].add(TEAM_BONUS);
        isFirstPartTeamsTokensSended = true;
      }
      if (now >= SEND_TOKENS_TO_TEAM_TIME_2 && !isSecondPartTeamsTokensSended) {
        balances[factory] = balances[factory].add(TEAM_BONUS);
        isSecondPartTeamsTokensSended = true;
      }
    }

    /// @dev check that tokens for team ready
    /// @return Returns true - if tokens ready, false - if not
    function isTokensForTeamReady() public constant returns (bool) {
      return (now >= SEND_TOKENS_TO_TEAM_TIME_1 && !isFirstPartTeamsTokensSended) ||
             (now >= SEND_TOKENS_TO_TEAM_TIME_2 && !isSecondPartTeamsTokensSended);
    }

}
