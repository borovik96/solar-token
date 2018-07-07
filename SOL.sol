pragma solidity ^0.4.18;
import "./MintableToken.sol";
import "./Access.sol";

contract SOL is MintableToken, Access {

    string public constant name = "SOL Token";
    string public constant symbol = "SOLP";
    uint public constant decimals = 18;
}
