// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

contract BucketsAttack {
    function totalSupply() external pure {
        revert();
    }
}