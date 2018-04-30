pragma solidity ^0.4.18;
import "./StandardToken.sol";
import "./Access.sol";

contract SOL is StandardToken, Access {

    string public constant name = "Solar Token";
    string public constant symbol = "SOL";
    uint public constant decimals = 18;
}
