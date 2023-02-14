// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title Claim ownership of the contract below to complete this level
 * @dev Implement one time hackable smart contract (Switch)
 */
contract Wallet {
    address public owner;
    address public previousOwner;    
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }
    modifier onlyPreviousOwner() {
        require(msg.sender == previousOwner, "only for the previous owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function executeTransaction(address destination, uint _value, bytes memory data) public onlyOwner {
        destination.call{value: _value}(data);
    }

    // New owner have to accept ownership by providing a signature from the owner
    function acceptOwnership(uint8 v, bytes32 r,bytes32 s) public {
        require(ecrecover(generateHash(owner), v, r, s) != address(0), "you have not provided a signature from the owner");
        previousOwner = owner;
        owner = msg.sender;
    }    
    // Generates a hash compatible with EIP-191 signatures
    function generateHash(address _addr) public pure returns (bytes32) {
        bytes32 addressHash = keccak256(abi.encodePacked(_addr));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", addressHash));
    }
    receive() external payable {}
}