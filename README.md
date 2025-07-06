# Custodia

Custodia is a decentralized escrow platform built on Ethereum that provides secure transactions between buyers and sellers. It leverages smart contracts to hold funds until all agreement terms are met, ensuring trust and transparency in digital transactions. By eliminating intermediaries, Custodia reduces costs while maintaining security through blockchain technology.

## Architecture


## Components
* **Frontend:** Responsive web interface using TailwindCSS and ethers.js.
* **Wallet Integration:** MetaMask/Brave Wallet for user authentication.
* **Smart Contracts:** Escrow logic deployed on Ethereum Sepolia testnet

## Features

* **Secure Transactions:** Funds held in escrow until conditions met.

* **Transparent Process:** All transactions recorded on blockchain.

* **Dispute Resolution:** Neutral arbiter mediation system.

* **User Dashboard:** Manage all escrow agreements in one place.

* **Decentralized:** No single point of failure or control.

## Smart Contract Documentation

**Create new escrow agreement**

`function createEscrow(address _seller, address _arbiter) external returns (uint256)`

**Deposit funds to escrow**

`function deposit(uint256 escrowId) external payable`

**Seller marks goods as delivered**

`function markDelivered(uint256 escrowId) external`

**Buyer confirms delivery**

`function confirmDelivery(uint256 escrowId) external`

**Raise dispute**

`function raiseDispute(uint256 escrowId) external`

**Arbiter resolves dispute**

`function resolveDispute(uint256 escrowId, bool toSeller) external`

## Contract Address

**Sepolia Testnet:** `0xcecb1DCfA527d07DFf4c93dD01224F1C504aDc22`

## Team Members 

* Kushal Sapra
* Renu sapra

## Acknowledgements

We would like to thank:

* Ethereum Foundation for the incredible blockchain infrastructure & Ethers.js for the powerful blockchain interaction library.

* Vercel for providing deployment instrastructure. 
