# MixBytes CTF

[![test](https://github.com/catcatcat8/mixbytes-ctf/actions/workflows/test.yml/badge.svg)](https://github.com/catcatcat8/mixbytes-ctf/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

My solutions to the smart contract CTF from the MixBytes Farm course (2022). Each solved challenge is reproduced by a Foundry test that deploys the vulnerable contract, runs the attack, and asserts the win condition.

## Overview

This repository contains my solutions to four challenges from the course. Each challenge was a vulnerable contract deployed on the Goerli testnet, and the goal was to find the bug and exploit it. Goerli has since been shut down, so the exploits are now replayed locally and all run with a single `forge test`.

## Challenges

| # | Challenge | Goal | Vulnerability | Exploit | Test |
|---|-----------|------|---------------|---------|------|
| 1 | Bank | Drain the contract or call `setCompleted()` | Reentrancy | [BankAttack.sol](contracts/Bank/BankAttack.sol) | [01_Bank.t.sol](test/01_Bank.t.sol) |
| 2 | Proxy | Break `Buckets(proxy).totalSupply()` | Storage slot collision | in the test | [02_Proxy.t.sol](test/02_Proxy.t.sol) |
| 3 | Faucet | Drain the contract | `extcodesize` check bypass + reentrancy | [FaucetAttack.sol](contracts/Faucet/FaucetAttack.sol) | [03_Faucet.t.sol](test/03_Faucet.t.sol) |
| 4 | MMM | Drain the contract | Balance manipulation via `selfdestruct` | [ProfitableBusinessAttack.sol](contracts/MMM/ProfitableBusinessAttack.sol) | [04_MMM.t.sol](test/04_MMM.t.sol) |

## 1. Bank

Contract: [Bank2.sol](contracts/Bank/Bank2.sol) — Exploit: [BankAttack.sol](contracts/Bank/BankAttack.sol)

The bank is considered robbed once its ETH balance drops below the hardcoded "director" deposit, which is the condition `setCompleted(true)` checks.

**Vulnerability**

`withdraw_with_bonus()` pays the user's bonus with a low-level `call` and only *after* that sets `_bonuses_for_users[msg.sender] = 0`. The receiver can reenter `withdraw_with_bonus()` from its `receive()` function before the bonus is cleared, and is paid the same bonus again. This is a classic violation of the checks-effects-interactions pattern.

There is a second, separate bug in the same function: it sets `_balances[msg.sender] = 0` and then sends `_balances[msg.sender]` (now zero) in the following `call`, so honest users never get their deposit back.

**Exploit steps**

1. `hack1()` forwards ETH to the bank so the attacker contract has a non-zero recorded balance (required to pass the checks in `giveBonusToUser` and `withdraw_with_bonus`).
2. `hack2()` calls `giveBonusToUser(self)` and then `withdraw_with_bonus()`.
3. Each bonus payout reenters `withdraw_with_bonus()` from `BankAttack.receive()`, which keeps calling back as long as the bank still holds ETH, draining it round after round.
4. Call `setCompleted(true)` to claim the win once the balance is below the director's deposit.

**Fix**

Follow checks-effects-interactions: zero out the bonus and balance *before* sending ETH. Check the return value of the low-level `call`, and add a reentrancy guard.

## 2. Proxy

Contract: [BucketsProxy.sol](contracts/Proxy/BucketsProxy.sol) — the exploit is written directly in the test.

The goal is to make `Buckets(proxy).totalSupply()` stop working.

**Vulnerability**

The proxy and its implementation share storage. The proxy declares `uint256 salt` in slot 0, while the implementation keeps the length of `uint256[] buckets` in that same slot 0. Anyone can write to `salt` through `setFailsafeAdmin()`, which therefore overwrites the array length seen by the implementation.

**Exploit steps**

1. Call `setFailsafeAdmin(type(uint256).max)`. Through the implementation this sets `buckets.length` to `2^256 - 1`, so the array bounds check always passes.
2. Elements of an array based at slot 0 live at `keccak256(0) + i`. Pick `i = IMPLEMENTATION_SLOT - keccak256(0)`, where `IMPLEMENTATION_SLOT` is the EIP-1967 implementation-address slot (`0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`).
3. Call `deposit(i)` with 1 wei. This runs `buckets[i] += msg.value`, which physically writes into the implementation-address slot and corrupts it.
4. After that, any call through the proxy (such as `totalSupply()`) delegatecalls into a non-existent address and returns empty data; decoding that as a `uint256` reverts.

**Fix**

Keep the proxy's own variables in pseudo-random EIP-1967 slots (as `ERC1967Proxy` itself does) instead of slot 0, so they cannot collide with the implementation's storage layout. Also restrict access to the administrative functions.

## 3. Faucet

Contract: [Faucet.sol](contracts/Faucet/Faucet.sol) — Exploit: [FaucetAttack.sol](contracts/Faucet/FaucetAttack.sol)

The goal is to drain the faucet.

**Vulnerability**

`register()` rejects contracts using `extcodesize(addr) > 0`, but a contract has `extcodesize == 0` while its constructor is still running. `FaucetAttack` registers itself as an "EOA" from within its constructor. On top of that, `withdraw()` pays 0.001 ETH with a low-level `call` *before* resetting `users[msg.sender]`, which allows reentrancy.

**Exploit steps**

1. Deploy `FaucetAttack`, which registers itself in its constructor.
2. Roll one block forward so the attacker passes the `users[msg.sender] < block.number` check.
3. Call `hack()`, which calls `withdraw()`. The payout lands in `FaucetAttack.receive()`, which reenters `withdraw()` again (looping until its counter `i` reaches 10), withdrawing up to 10 × 0.001 ETH in a single call before the bookkeeping is updated.

**Fix**

Do not rely on `extcodesize` to detect an EOA (it is trivially bypassed from a constructor; `tx.origin == msg.sender` is also not a universal test). Reset `users[msg.sender]` before the external call and add a reentrancy guard.

## 4. MMM

Contract: [ProfitableBusiness.sol](contracts/MMM/ProfitableBusiness.sol) — Exploit: [ProfitableBusinessAttack.sol](contracts/MMM/ProfitableBusinessAttack.sol)

The goal is to drain the contract.

**Vulnerability**

`ethTotalSupply()` returns `address(this).balance`, and `shares(user) = balanceOf(user) * base / ethTotalSupply()` divides by it. Forcing ETH into the contract via `selfdestruct` inflates the balance without minting any tokens, which collapses every holder's `shares()` (including the owner's) to zero through integer division.

**Exploit steps**

1. Deploy `ProfitableBusinessAttack`, give it some ETH, and call `hack(mmm)`. Its `selfdestruct` sends the ETH into the contract, dropping `shares(owner)` to 0.
2. `changeMajorityOwner()` requires `shares(msg.sender) >= shares(owner())`. The attacker holds 0 tokens (shares 0), so `0 >= 0` passes and the attacker becomes the owner.
3. As the owner, call `enhanceDepositProfitability(10**18, 1)` to set a huge deposit rate.
4. Call `mint{value: 1}()` to receive about `10**18` tokens for 1 wei.
5. Call `burn(amount)` with `amount <= ethTotalSupply()`. It burns the tokens and pays out `amount` wei 1:1, draining all ETH from the contract.

**Fix**

Do not use `address(this).balance` as the source of truth for share/reserve accounting. Track an internal accounting variable that is increased only in `mint()`, which makes a forced ETH transfer via `selfdestruct` harmless.

## Getting started

Requirements: [Foundry](https://book.getfoundry.sh/getting-started/installation).

Clone with submodules:

```bash
git clone --recurse-submodules <repo>
# or, if already cloned:
git submodule update --init --recursive
```

Build:

```bash
forge build
```

Run all exploits:

```bash
forge test -vv
```

The tests print the relevant balances before and after each step of the attack, so run them with `-vv` to follow along.

## Notes

The initial deposit amounts for the Bank, Faucet, and MMM contracts were not kept together with the Goerli deployment, so the tests use reasonable values instead. This does not change how the exploits work, and it is noted in the NatSpec of each test.

## Project structure

```
.
├── contracts/
│   ├── Bank/            # Bank2.sol + BankAttack.sol
│   ├── Proxy/           # BucketsProxy.sol
│   ├── Faucet/          # Faucet.sol + FaucetAttack.sol
│   └── MMM/             # ProfitableBusiness.sol + ProfitableBusinessAttack.sol
├── test/
│   ├── 01_Bank.t.sol
│   ├── 02_Proxy.t.sol
│   ├── 03_Faucet.t.sol
│   └── 04_MMM.t.sol
├── lib/                 # forge-std, openzeppelin-contracts, openzeppelin-contracts-upgradeable (git submodules)
└── foundry.toml
```

## Context

The challenges come from the MixBytes Farm course (2022). The attacks were originally run as scripts against the Goerli testnet; they have since been rewritten for Foundry and are now reproduced locally. Author: Evgeniy Lebedev.

## License

MIT — see [LICENSE](LICENSE).
