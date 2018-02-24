pragma solidity ^0.4.18;
import "./Token.sol";

contract Access is Ownable {
    address price_updater;
    address bounty_manager = 0xca35b7d915458ef540ade6068dfe2f44e8fa733c; // change before deploy
    address kyc_manager = 0xca35b7d915458ef540ade6068dfe2f44e8fa733c; // change before deploy
    address factory;
    modifier onlyPrice_updater() {
        require(msg.sender == price_updater);
        _;
    }
    modifier onlyBounty_manager() {
        require(msg.sender == bounty_manager);
        _;
    }
    modifier onlyKyc_manager() {
        require(msg.sender == kyc_manager);
        _;
    }
    modifier onlyFactory() {
        require(msg.sender == factory);
        _;
    }
}
