# MixBytes CTF

# Description
Report on the passage of MixBytes CTF tasks while the studying the educational course "MixBytes Farm".

# Tasks
## 1. Withdraw all ether from the contract or call `setCompleted()`:
* Initial contract: https://github.com/catcatcat8/mixbytes-ctf/blob/main/contracts/1_Bank/Bank2.sol
* Attack contract: https://github.com/catcatcat8/mixbytes-ctf/blob/main/contracts/1_Bank/BankAttack.sol
* Attack scenario: https://github.com/catcatcat8/mixbytes-ctf/blob/main/scripts/1_attackBank.ts
* Found vulnerability: **reentrancy**

***

## 2. Make Buckets(Proxy.address).totalSupply() break:
* Initial contract: https://github.com/catcatcat8/mixbytes-ctf/blob/main/contracts/2_Proxy/BucketsProxy.sol
* Attack scenario: https://github.com/catcatcat8/mixbytes-ctf/blob/main/scripts/2_attackProxy.ts
* Found vulnerability: **storage slots collision**

***

## 3. Withdraw all ether from the contract:
* Initial contract: https://github.com/catcatcat8/mixbytes-ctf/blob/main/contracts/3_Faucet/Faucet.sol
* Attack contract: https://github.com/catcatcat8/mixbytes-ctf/blob/main/contracts/3_Faucet/FaucetAttack.sol
* Attack scenario: https://github.com/catcatcat8/mixbytes-ctf/blob/main/scripts/3_attackFaucet.ts
* Found vulnerability: **`isContract()`extcodesize check doesn't work while deploying + reentrancy**

***

## 5. Withdraw all ether from the contract:
`profitablity = 100`, `base = 1000000`
* Initial contract: https://github.com/catcatcat8/mixbytes-ctf/blob/main/contracts/5_MMM/ProfitableBusiness.sol
* Attack contract: https://github.com/catcatcat8/mixbytes-ctf/blob/main/contracts/5_MMM/ProfitableBusinessAttack.sol
* Attack scenario: https://github.com/catcatcat8/mixbytes-ctf/blob/main/scripts/5_attackMMM.ts
* Found vulnerability: **unexpected ether while `selfdestruct`**

# Result
Completed four out of five CTF tasks.
