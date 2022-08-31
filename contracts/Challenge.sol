pragma solidity 0.8.10;

import 'hardhat/console.sol';

// The goal of this challenge is to be able to sign offchain a message
// with an address stored in winners.
contract Challenge{
    bool public flag;

    function setFlag() public {
        console.log(msg.sender);
        console.log(tx.origin);
        require(msg.sender == tx.origin, "call from contract");
        flag = true;
    }
}