pragma solidity ^0.4.19;

contract StubToken {

  function exchangeOldToken(address user, uint amount) public returns (bool) {
    require(msg.sender == 0); // check address Crowdsale after deploy
    return true; // exchange was successfull or not
  }

}
