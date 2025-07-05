// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    
    event EscrowCreated(uint256 indexed escrowId, address indexed buyer, address indexed seller, address arbiter, uint256 amount);
    event FundsDeposited(uint256 indexed escrowId, address indexed buyer, uint256 amount);
    event DeliveryMarked(uint256 indexed escrowId, address indexed seller);
    event DeliveryConfirmed(uint256 indexed escrowId, address indexed buyer);
    event DisputeRaised(uint256 indexed escrowId, address indexed party);
    event Resolved(uint256 indexed escrowId, address indexed arbiter, bool sellerAwarded);

    modifier onlyBuyer(uint256 escrowId) {
        require(msg.sender == escrows[escrowId].buyer, "Not buyer");
        _;
    }
    
    modifier onlySeller(uint256 escrowId) {
        require(msg.sender == escrows[escrowId].seller, "Not seller");
        _;
    }
    
    modifier onlyArbiter(uint256 escrowId) {
        require(msg.sender == escrows[escrowId].arbiter, "Not arbiter");
        _;
    }
    
    modifier inState(uint256 escrowId, State _state) {
        require(escrows[escrowId].state == _state, "Invalid state");
        _;
    }

    function createEscrow(address _seller, address _arbiter) external payable returns (uint256) {
        uint256 escrowId = nextEscrowId++;
        Escrow storage e = escrows[escrowId];
        
        e.buyer = msg.sender;
        e.seller = _seller;
        e.arbiter = _arbiter;
        e.amount = msg.value;
        
        if(msg.value > 0) {
            e.state = State.Funded;
            emit FundsDeposited(escrowId, msg.sender, msg.value);
        } else {
            e.state = State.Created;
        }
        
        // Track escrow for all parties
        userEscrows[msg.sender].push(escrowId);
        userEscrows[_seller].push(escrowId);
        userEscrows[_arbiter].push(escrowId);
        
        emit EscrowCreated(escrowId, msg.sender, _seller, _arbiter, msg.value);
        return escrowId;
    }

    function deposit(uint256 escrowId) external payable onlyBuyer(escrowId) inState(escrowId, State.Created) {
        Escrow storage e = escrows[escrowId];
        e.amount = msg.value;
        e.state = State.Funded;
        emit FundsDeposited(escrowId, msg.sender, msg.value);
    }

    function markDelivered(uint256 escrowId) external onlySeller(escrowId) inState(escrowId, State.Funded) {
        escrows[escrowId].state = State.Delivered;
        emit DeliveryMarked(escrowId, msg.sender);
    }

    function confirmDelivery(uint256 escrowId) external onlyBuyer(escrowId) inState(escrowId, State.Delivered) {
        Escrow storage e = escrows[escrowId];
        e.state = State.Confirmed;
        payable(e.seller).transfer(e.amount);
        emit DeliveryConfirmed(escrowId, msg.sender);
    }

    function raiseDispute(uint256 escrowId) external inState(escrowId, State.Funded) {
        Escrow storage e = escrows[escrowId];
        require(
            msg.sender == e.buyer || msg.sender == e.seller,
            "Unauthorized"
        );
        e.state = State.Disputed;
        emit DisputeRaised(escrowId, msg.sender);
    }

    function resolveDispute(uint256 escrowId, bool toSeller) external onlyArbiter(escrowId) inState(escrowId, State.Disputed) {
        Escrow storage e = escrows[escrowId];
        e.state = State.Resolved;
        
        if(toSeller) {
            payable(e.seller).transfer(e.amount);
        } else {
            payable(e.buyer).transfer(e.amount);
        }
        
        emit Resolved(escrowId, msg.sender, toSeller);
    }

    function getEscrowsByUser(address user) external view returns (uint256[] memory) {
        return userEscrows[user];
    }
}
