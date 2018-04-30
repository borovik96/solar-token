pragma solidity ^0.4.18;
import "./Ownable.sol";

contract Access is Ownable {
    address kyc_manager = 0xca35b7d915458ef540ade6068dfe2f44e8fa733c; // change before deploy
    address factory;
    address buy_pannel;
    modifier onlyKyc_manager() {
        require(msg.sender == kyc_manager);
        _;
    }
    modifier onlyFactory() {
        require(msg.sender == factory);
        _;
    }
}
