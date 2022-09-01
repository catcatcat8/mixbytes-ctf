// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ProfitableBusiness is ERC20, Ownable {
    // Welcome to The Profitable Business of Sergey Mavrody!
    // Just deposit some money and take extra profit!

    // WOW! Profitability of your deposits is X100.00! MASSIVE!
    uint256 public profitability = 10000;
    uint256 public base = 100;

    constructor() ERC20("Mavrodi Shares", "MMM") {}

    // You're on your way to get rich!
    function mint() external payable {
        uint256 deposit = msg.value * profitability / base;
        uint256 fee = deposit < msg.value ? msg.value - deposit : 0;

        _mint(msg.sender, deposit);
        _mint(owner(), fee);
    }

    function burn(uint256 amount) external {
        require(amount <= ethTotalSupply(), "Vsem vsyo platitsya!");
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }

    function changeMajorityOwner() external {
        require(shares(msg.sender) >= shares(owner()), "Too poor");
        _transferOwnership(msg.sender);
    }

    function enhanceDepositProfitability(uint256 _profitability, uint256 _base) external onlyOwner {
        profitability = _profitability;
        base = _base;
    }

    function shares(address user) public view returns (uint256) {
        return balanceOf(user) * base / ethTotalSupply();
    }

    function ethTotalSupply() public view returns (uint256) {
        return address(this).balance;
    }
}