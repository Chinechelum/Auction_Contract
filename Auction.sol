// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint tokenId
    ) external;
}

contract Auction {
   
    event aBid(address sender, uint amount);
    event Withdraw(address bidder, uint amount);
    event End(address winner, uint amount);

    IERC20 public token;
    uint public tokenId;

    address payable public seller;
    uint public endAt;
    bool public started;
    bool public ended;

    address public highestBidder;
    uint public highestBid;
    mapping(address => uint) public bids;

    function createBid(
        address _token,
        uint _tokenId,
        uint _startingBid
    ) public returns (string memory sentence){
        token = IERC20(_token);
        tokenId = _tokenId;

        seller = payable(msg.sender);
        highestBid = _startingBid;
        return "Bid Created.";
    }

    function start(uint endTime) external returns (string memory sentence){
        require(!started, "started");
        require(msg.sender == seller, "not seller");
        require(endTime >= block.timestamp, "future date needed");

        token.transferFrom(msg.sender, address(this), tokenId);
        started = true;
        endAt = endTime;

        return "Now Started.";

    }

    function bid() external payable {
        require(started, "not started");
        require(block.timestamp < endAt, "ended");
        require(msg.value > highestBid, "value < highest");

        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit aBid(msg.sender, msg.value);
    }

    function withdraw() external {
        uint bal = bids[msg.sender];
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(bal);

        emit Withdraw(msg.sender, bal);
    }

    function end() external {
        require(started, "not started");
        require(block.timestamp >= endAt, "not ended");
        require(!ended, "ended");

        ended = true;
        if (highestBidder != address(0)) {
            token.transferFrom(address(this), highestBidder, tokenId);
            seller.transfer(highestBid);
        } else {
            token.transferFrom(address(this), seller, tokenId);
        }

        emit End(highestBidder, highestBid);
    }
}
