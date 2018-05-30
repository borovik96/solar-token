pragma solidity ^0.4.18;
import "./MintableToken.sol";
import "./Access.sol";

contract SOL is MintableToken, Access {

    string public constant name = "Solar Token";
    string public constant symbol = "SOL";
    uint public constant decimals = 18;
}
