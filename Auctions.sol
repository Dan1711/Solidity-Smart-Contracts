/*
    Auction handler in the Ethereum virtual Machine
    handles bids, withdraws for non winning wallets
    emit a winner when the timer comes to zero
    Let participants know who's the biggest bidder and the current bigger bid

    @Dan1711
*/
pragma solidity >=0.8.1;

contract Auction {
    address payable public beneficiary;
    uint public auctionEndTime;

    // Track auction status
    address public highestBidder;
    uint public highestBid;
    bool ended;

    mapping(address => uint) public pendingReturns;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    constructor(uint _biddingTime, address payable _beneficiary) {
        beneficiary = _beneficiary;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    function bid(uint amount) public payable{
        require(block.timestamp <= auctionEndTime, "The auction has ended");
        require(amount > 0, "Bid amount must be greater than 0");
        require(amount <= address(msg.sender).balance, "Insufficient balance");

        // Devuelve los fondos al ofertante anterior
        if (highestBid > 0) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = amount;
        emit HighestBidIncreased(msg.sender, amount);
    }

    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        require(amount > 0, "No funds to withdraw");

        pendingReturns[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");

        return true;
    }

    function auctionEnd() public payable{
        require(block.timestamp >= auctionEndTime, "The auction has not ended yet");
        require(!ended, "The auction is already over");

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        // Transfiere los fondos al beneficiario
        beneficiary.transfer(highestBid);
    }
}
