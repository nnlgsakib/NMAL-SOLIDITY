// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NLGmal.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract AutomatedPrivateNLGWallet is ReentrancyGuard {
    using ECDSA for bytes32;

    NLGmal private immutable nlgmal;
    mapping(bytes32 => address) private nlgmalToAddress;
    mapping(address => uint256) private balances;
    mapping(address => uint256) private nonces;

    event AnonymousTransfer(bytes32 indexed commitmentHash);

    constructor(address nlgmalAddress) {
        nlgmal = NLGmal(nlgmalAddress);
    }

    function registerNlgmalAddress() external {
        string memory nlgmalAddress = nlgmal.addressToNlgmal(msg.sender);
        bytes32 hashedNlgmal = keccak256(abi.encodePacked(nlgmalAddress));
        nlgmalToAddress[hashedNlgmal] = msg.sender;
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    function anonymousTransfer(
        string memory recipientNlgmal,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        require(block.timestamp <= deadline, "Transaction expired");

        bytes32 hashedRecipientNlgmal = keccak256(abi.encodePacked(recipientNlgmal));
        address recipient = nlgmalToAddress[hashedRecipientNlgmal];
        require(recipient != address(0), "Invalid recipient");

        bytes32 messageHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(recipientNlgmal, amount, nonces[msg.sender], deadline))
        ));

        address signer = ecrecover(messageHash, v, r, s);
        require(signer == msg.sender, "Invalid signature");

        require(balances[signer] >= amount, "Insufficient balance");

        balances[signer] -= amount;
        balances[recipient] += amount;
        nonces[signer]++;

        bytes32 commitmentHash = keccak256(abi.encodePacked(signer, recipient, amount, block.timestamp));
        emit AnonymousTransfer(commitmentHash);
    }

    function getNonce(address user) external view returns (uint256) {
        return nonces[user];
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
    }
}
