// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Custodia {
    enum State { Created, Funded, Delivered, Confirmed, Disputed, Resolved }

    address public immutable buyer;
    address public immutable seller;
    address public immutable arbiter;
    State public state;
    uint256 public amount;

    event FundsDeposited(address indexed buyer, uint256 amount);
    event DeliveryMarked(address indexed seller);
    event DeliveryConfirmed(address indexed buyer);
    event DisputeRaised(address indexed party);
    event Resolved(address indexed arbiter, bool sellerAwarded);

    modifier onlyBuyer() { require(msg.sender == buyer, "Not buyer"); _; }
    modifier onlySeller() { require(msg.sender == seller, "Not seller"); _; }
    modifier onlyArbiter() { require(msg.sender == arbiter, "Not arbiter"); _; }
    modifier inState(State _state) { require(state == _state, "Invalid state"); _; }

    constructor(address _seller, address _arbiter) payable {
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        amount = msg.value;
        if(msg.value > 0) {
            state = State.Funded;
            emit FundsDeposited(msg.sender, msg.value);
        }
    }

    function deposit() external payable onlyBuyer inState(State.Created) {
        amount = msg.value;
        state = State.Funded;
        emit FundsDeposited(msg.sender, msg.value);
    }

    function markDelivered() external onlySeller inState(State.Funded) {
        state = State.Delivered;
        emit DeliveryMarked(msg.sender);
    }

    function confirmDelivery() external onlyBuyer inState(State.Delivered) {
        state = State.Confirmed;
        payable(seller).transfer(amount);
        emit DeliveryConfirmed(msg.sender);
    }

    function raiseDispute() external inState(State.Funded) {
        require(msg.sender == buyer || msg.sender == seller, "Unauthorized");
        state = State.Disputed;
        emit DisputeRaised(msg.sender);
    }

    function resolveDispute(bool toSeller) external onlyArbiter inState(State.Disputed) {
        state = State.Resolved;
        if(toSeller) payable(seller).transfer(amount);
        else payable(buyer).transfer(amount);
        emit Resolved(msg.sender, toSeller);
    }
}