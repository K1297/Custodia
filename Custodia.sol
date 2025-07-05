// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract CustodiaFactory {
    enum State { Created, Funded, Delivered, Confirmed, Disputed, Resolved }

    struct Escrow {
        address buyer;
        address seller;
        address arbiter;
        State state;
        uint256 amount;
    }

    uint256 public nextEscrowId;
    mapping(uint256 => Escrow) public escrows;
    mapping(address => uint256[]) public userEscrows;

    event EscrowCreated(uint256 escrowId, address buyer, address seller, address arbiter, uint256 amount);
    event FundsDeposited(uint256 escrowId, address buyer, uint256 amount);
    event DeliveryMarked(uint256 escrowId, address seller);
    event DeliveryConfirmed(uint256 escrowId, address buyer);
    event DisputeRaised(uint256 escrowId, address party);
    event Resolved(uint256 escrowId, address arbiter, bool sellerAwarded);

    function createEscrow(address _seller, address _arbiter) external returns (uint256) {
        uint256 escrowId = nextEscrowId++;

        escrows[escrowId] = Escrow({
            buyer: msg.sender,
            seller: _seller,
            arbiter: _arbiter,
            state: State.Created,
            amount: 0
        });

        userEscrows[msg.sender].push(escrowId);
        userEscrows[_seller].push(escrowId);
        userEscrows[_arbiter].push(escrowId);

        emit EscrowCreated(escrowId, msg.sender, _seller, _arbiter, 0);

        return escrowId;
    }

    function deposit(uint256 escrowId) external payable {
        Escrow storage escrow = escrows[escrowId];
        require(msg.sender == escrow.buyer, "Only buyer can deposit");
        require(escrow.state == State.Created, "Invalid state");

        escrow.amount = msg.value;
        escrow.state = State.Funded;

        emit FundsDeposited(escrowId, msg.sender, msg.value);
    }

    function markDelivered(uint256 escrowId) external {
        Escrow storage escrow = escrows[escrowId];
        require(msg.sender == escrow.seller, "Only seller can mark delivered");
        require(escrow.state == State.Funded, "Invalid state");

        escrow.state = State.Delivered;
        emit DeliveryMarked(escrowId, msg.sender);
    }

    function confirmDelivery(uint256 escrowId) external {
        Escrow storage escrow = escrows[escrowId];
        require(msg.sender == escrow.buyer, "Only buyer can confirm");
        require(escrow.state == State.Delivered, "Invalid state");

        escrow.state = State.Confirmed;
        payable(escrow.seller).transfer(escrow.amount);

        emit DeliveryConfirmed(escrowId, msg.sender);
    }

    function raiseDispute(uint256 escrowId) external {
        Escrow storage escrow = escrows[escrowId];
        require(msg.sender == escrow.buyer || msg.sender == escrow.seller, "Not authorized");
        require(escrow.state == State.Delivered, "Can only dispute delivered escrow");

        escrow.state = State.Disputed;
        emit DisputeRaised(escrowId, msg.sender);
    }

    function resolveDispute(uint256 escrowId, bool toSeller) external {
        Escrow storage escrow = escrows[escrowId];
        require(msg.sender == escrow.arbiter, "Only arbiter can resolve");
        require(escrow.state == State.Disputed, "Invalid state");

        escrow.state = State.Resolved;

        if (toSeller) {
            payable(escrow.seller).transfer(escrow.amount);
        } else {
            payable(escrow.buyer).transfer(escrow.amount);
        }

        emit Resolved(escrowId, msg.sender, toSeller);
    }

    function getEscrowsByUser(address user) external view returns (uint256[] memory) {
        return userEscrows[user];
    }

    function userEscrowsView(address user, uint256 index) external view returns (uint256) {
        return userEscrows[user][index];
    }
}
