pragma solidity ^0.4.18;
import "./Token.sol";
import "./Access.sol";

contract SOL is MintableToken, Access {
    
    string public constant name = "Simple Coin Token";
    string public constant symbol = "SOL";
    uint public constant decimals = 18;
    uint public initialSupply = 10000 * (10 ** decimals);
    
    event BurnedTokens(address indexed from, uint256 amount);
    
    function burnTokens(uint256 _amount, address _addr) public onlyOwner{
        require(balances[_addr] >= _amount);
        totalSupply = totalSupply.sub(_amount);
        balances[_addr] = balances[_addr].sub(_amount);
        BurnedTokens(_addr, _amount);
    }
}