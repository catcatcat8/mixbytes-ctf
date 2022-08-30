// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChallenge {
    function exploit_me(address winner) external;
    function lock_me() external;
}