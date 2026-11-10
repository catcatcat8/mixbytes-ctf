// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title MockToken
/// @notice Minimal ERC20 used only as the "stuck" reward token for the
///         Unverified challenge test. Mints the full initial supply to the
///         deployer, who then seeds the Unverified contract's balance.
contract MockToken is ERC20 {
    constructor(string memory name_, string memory symbol_, uint256 initialSupply_) ERC20(name_, symbol_) {
        _mint(msg.sender, initialSupply_);
    }
}
