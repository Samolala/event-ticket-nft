// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {EventTicketNFT} from "../src/EventTicketNFT.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract EventTicketNFTTest is Test {
    EventTicketNFT public ticketNFT;
    MockERC20 public testToken;
    
    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    
    uint256 constant INITIAL_BALANCE = 1000 ether;
    
    function setUp() public {
        vm.startPrank(owner);
        
        testToken = new MockERC20("Test Token", "TEST", 18);
        testToken.mint(owner, INITIAL_BALANCE);
        testToken.mint(user1, INITIAL_BALANCE);
        testToken.mint(user2, INITIAL_BALANCE);
        
        ticketNFT = new EventTicketNFT(
            "Event Ticket NFT",
            "TICKET",
            "https://api.example.com/metadata/",
            owner
        );
        
        ticketNFT.setPaymentToken(address(testToken));
        vm.stopPrank();
    }
    
    function testInitialState() public view {
        assertEq(ticketNFT.totalSupply(), 0);
        assertEq(ticketNFT.getRemainingSupply(), 100);
        assertEq(ticketNFT.ethPrice(), 0.01 ether);
        assertEq(ticketNFT.MAX_SUPPLY(), 100);
        assertEq(ticketNFT.MAX_PER_WALLET(), 5);
    }
    
    function testMintWithETH() public {
        vm.deal(user1, 1 ether);
        
        vm.prank(user1);
        ticketNFT.mint{value: 0.05 ether}(5);
        
        assertEq(ticketNFT.balanceOf(user1), 5);
        assertEq(ticketNFT.totalSupply(), 5);
    }
    
    function testMintWithERC20() public {
        vm.prank(owner);
        ticketNFT.setPaymentMethod(true);
        
        vm.startPrank(user1);
        testToken.approve(address(ticketNFT), 100 ether);
        ticketNFT.mint(3);
        vm.stopPrank();
        
        assertEq(ticketNFT.balanceOf(user1), 3);
        assertEq(testToken.balanceOf(address(ticketNFT)), 30 ether);
    }
    
    function testCannotExceedMaxPerWallet() public {
        vm.deal(user1, 1 ether);
        
        vm.prank(user1);
        ticketNFT.mint{value: 0.05 ether}(5);
        
        vm.prank(user1);
        vm.expectRevert("Exceeds wallet limit");
        ticketNFT.mint{value: 0.01 ether}(1);
    }
    
    function testCannotExceedMaxSupply() public {
        vm.deal(user1, 10 ether);
        
        for (uint256 i = 0; i < 20; i++) {
            vm.prank(user1);
            ticketNFT.mint{value: 0.05 ether}(5);
        }
        
        vm.deal(user2, 1 ether);
        vm.prank(user2);
        vm.expectRevert("Exceeds max supply");
        ticketNFT.mint{value: 0.01 ether}(1);
    }
    
    function testWithdrawETH() public {
        vm.deal(user1, 0.05 ether);
        vm.prank(user1);
        ticketNFT.mint{value: 0.05 ether}(5);
        
        uint256 ownerBalanceBefore = owner.balance;
        vm.prank(owner);
        ticketNFT.withdrawETH();
        
        assertEq(address(ticketNFT).balance, 0);
        assertEq(owner.balance, ownerBalanceBefore + 0.05 ether);
    }
}
