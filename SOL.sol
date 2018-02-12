pragma solidity ^0.4.18;
import "./Token.sol";
import "./Access.sol";

contract SOL is MintableToken, Access {

    string public constant name = "Simple Coin Token";
    string public constant symbol = "SOL";
    uint public constant decimals = 18;
    uint public initialSupply = 96543000 * (10 ** decimals);
}
