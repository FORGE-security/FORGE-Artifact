// SPDX-License-Identifier: MIT

pragma solidity ^0.4.8;

contract CryptoPunksMarket {
    // You can use this hash to verify the image file containing all the punks
    string public imageHash = "ac39af4793119ee46bbff351d8cb6b5f23da60222126add4268e261199a2921b";

    address owner;

    string public standard = "CryptoPunks";
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    uint256 public nextPunkIndexToAssign = 0;

    bool public allPunksAssigned = false;
    uint256 public punksRemainingToAssign = 0;

    //mapping (address => uint) public addressToPunkIndex;
    mapping(uint256 => address) public punkIndexToAddress;

    /* This creates an array with all balances */
    mapping(address => uint256) public balanceOf;

    struct Offer {
        bool isForSale;
        uint256 punkIndex;
        address seller;
        uint256 minValue; // in ether
        address onlySellTo; // specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid;
        uint256 punkIndex;
        address bidder;
        uint256 value;
    }

    // A record of punks that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping(uint256 => Offer) public punksOfferedForSale;

    // A record of the highest punk bid
    mapping(uint256 => Bid) public punkBids;

    mapping(address => uint256) public pendingWithdrawals;

    event Assign(address indexed to, uint256 punkIndex);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event PunkTransfer(address indexed from, address indexed to, uint256 punkIndex);
    event PunkOffered(uint256 indexed punkIndex, uint256 minValue, address indexed toAddress);
    event PunkBidEntered(uint256 indexed punkIndex, uint256 value, address indexed fromAddress);
    event PunkBidWithdrawn(uint256 indexed punkIndex, uint256 value, address indexed fromAddress);
    event PunkBought(uint256 indexed punkIndex, uint256 value, address indexed fromAddress, address indexed toAddress);
    event PunkNoLongerForSale(uint256 indexed punkIndex);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function CryptoPunksMarket() payable {
        //        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        owner = msg.sender;
        totalSupply = 10000; // Update total supply
        punksRemainingToAssign = totalSupply;
        name = "CRYPTOPUNKS"; // Set the name for display purposes
        symbol = "Ï¾"; // Set the symbol for display purposes
        decimals = 0; // Amount of decimals for display purposes
    }

    function setInitialOwner(address to, uint256 punkIndex) {
        if (msg.sender != owner) revert();
        if (allPunksAssigned) revert();
        if (punkIndex >= 10000) revert();
        if (punkIndexToAddress[punkIndex] != to) {
            if (punkIndexToAddress[punkIndex] != 0x0) {
                balanceOf[punkIndexToAddress[punkIndex]]--;
            } else {
                punksRemainingToAssign--;
            }
            punkIndexToAddress[punkIndex] = to;
            balanceOf[to]++;
            Assign(to, punkIndex);
        }
    }

    function setInitialOwners(address[] addresses, uint256[] indices) {
        if (msg.sender != owner) revert();
        uint256 n = addresses.length;
        for (uint256 i = 0; i < n; i++) {
            setInitialOwner(addresses[i], indices[i]);
        }
    }

    function allInitialOwnersAssigned() {
        if (msg.sender != owner) revert();
        allPunksAssigned = true;
    }

    function getPunk(uint256 punkIndex) {
        if (!allPunksAssigned) revert();
        if (punksRemainingToAssign == 0) revert();
        if (punkIndexToAddress[punkIndex] != 0x0) revert();
        if (punkIndex >= 10000) revert();
        punkIndexToAddress[punkIndex] = msg.sender;
        balanceOf[msg.sender]++;
        punksRemainingToAssign--;
        Assign(msg.sender, punkIndex);
    }

    // Transfer ownership of a punk to another user without requiring payment
    function transferPunk(address to, uint256 punkIndex) {
        if (!allPunksAssigned) revert();
        if (punkIndexToAddress[punkIndex] != msg.sender) revert();
        if (punkIndex >= 10000) revert();
        if (punksOfferedForSale[punkIndex].isForSale) {
            punkNoLongerForSale(punkIndex);
        }
        punkIndexToAddress[punkIndex] = to;
        balanceOf[msg.sender]--;
        balanceOf[to]++;
        Transfer(msg.sender, to, 1);
        PunkTransfer(msg.sender, to, punkIndex);
        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid bid = punkBids[punkIndex];
        if (bid.bidder == to) {
            // Kill bid and refund value
            pendingWithdrawals[to] += bid.value;
            punkBids[punkIndex] = Bid(false, punkIndex, 0x0, 0);
        }
    }

    function punkNoLongerForSale(uint256 punkIndex) {
        if (!allPunksAssigned) revert();
        if (punkIndexToAddress[punkIndex] != msg.sender) revert();
        if (punkIndex >= 10000) revert();
        punksOfferedForSale[punkIndex] = Offer(false, punkIndex, msg.sender, 0, 0x0);
        PunkNoLongerForSale(punkIndex);
    }

    function offerPunkForSale(uint256 punkIndex, uint256 minSalePriceInWei) {
        if (!allPunksAssigned) revert();
        if (punkIndexToAddress[punkIndex] != msg.sender) revert();
        if (punkIndex >= 10000) revert();
        punksOfferedForSale[punkIndex] = Offer(true, punkIndex, msg.sender, minSalePriceInWei, 0x0);
        PunkOffered(punkIndex, minSalePriceInWei, 0x0);
    }

    function offerPunkForSaleToAddress(
        uint256 punkIndex,
        uint256 minSalePriceInWei,
        address toAddress
    ) {
        if (!allPunksAssigned) revert();
        if (punkIndexToAddress[punkIndex] != msg.sender) revert();
        if (punkIndex >= 10000) revert();
        punksOfferedForSale[punkIndex] = Offer(true, punkIndex, msg.sender, minSalePriceInWei, toAddress);
        PunkOffered(punkIndex, minSalePriceInWei, toAddress);
    }

    function buyPunk(uint256 punkIndex) payable {
        if (!allPunksAssigned) revert();
        Offer offer = punksOfferedForSale[punkIndex];
        if (punkIndex >= 10000) revert();
        if (!offer.isForSale) revert(); // punk not actually for sale
        if (offer.onlySellTo != 0x0 && offer.onlySellTo != msg.sender) revert(); // punk not supposed to be sold to this user
        if (msg.value < offer.minValue) revert(); // Didn't send enough ETH
        if (offer.seller != punkIndexToAddress[punkIndex]) revert(); // Seller no longer owner of punk

        address seller = offer.seller;

        punkIndexToAddress[punkIndex] = msg.sender;
        balanceOf[seller]--;
        balanceOf[msg.sender]++;
        Transfer(seller, msg.sender, 1);

        punkNoLongerForSale(punkIndex);
        pendingWithdrawals[seller] += msg.value;
        PunkBought(punkIndex, msg.value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid bid = punkBids[punkIndex];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
            punkBids[punkIndex] = Bid(false, punkIndex, 0x0, 0);
        }
    }

    function withdraw() {
        if (!allPunksAssigned) revert();
        uint256 amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function enterBidForPunk(uint256 punkIndex) payable {
        if (punkIndex >= 10000) revert();
        if (!allPunksAssigned) revert();
        if (punkIndexToAddress[punkIndex] == 0x0) revert();
        if (punkIndexToAddress[punkIndex] == msg.sender) revert();
        if (msg.value == 0) revert();
        Bid existing = punkBids[punkIndex];
        if (msg.value <= existing.value) revert();
        if (existing.value > 0) {
            // Refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        punkBids[punkIndex] = Bid(true, punkIndex, msg.sender, msg.value);
        PunkBidEntered(punkIndex, msg.value, msg.sender);
    }

    function acceptBidForPunk(uint256 punkIndex, uint256 minPrice) {
        if (punkIndex >= 10000) revert();
        if (!allPunksAssigned) revert();
        if (punkIndexToAddress[punkIndex] != msg.sender) revert();
        address seller = msg.sender;
        Bid bid = punkBids[punkIndex];
        if (bid.value == 0) revert();
        if (bid.value < minPrice) revert();

        punkIndexToAddress[punkIndex] = bid.bidder;
        balanceOf[seller]--;
        balanceOf[bid.bidder]++;
        Transfer(seller, bid.bidder, 1);

        punksOfferedForSale[punkIndex] = Offer(false, punkIndex, bid.bidder, 0, 0x0);
        uint256 amount = bid.value;
        punkBids[punkIndex] = Bid(false, punkIndex, 0x0, 0);
        pendingWithdrawals[seller] += amount;
        PunkBought(punkIndex, bid.value, seller, bid.bidder);
    }

    function withdrawBidForPunk(uint256 punkIndex) {
        if (punkIndex >= 10000) revert();
        if (!allPunksAssigned) revert();
        if (punkIndexToAddress[punkIndex] == 0x0) revert();
        if (punkIndexToAddress[punkIndex] == msg.sender) revert();
        Bid bid = punkBids[punkIndex];
        if (bid.bidder != msg.sender) revert();
        PunkBidWithdrawn(punkIndex, bid.value, msg.sender);
        uint256 amount = bid.value;
        punkBids[punkIndex] = Bid(false, punkIndex, 0x0, 0);
        // Refund the bid money
        msg.sender.transfer(amount);
    }
}
