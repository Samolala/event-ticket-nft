// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {EventTicketNFT} from "../src/EventTicketNFT.sol";

contract DeployEventTicketNFT is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying with account:", deployer);
        console.log("Account balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        EventTicketNFT ticketNFT = new EventTicketNFT(
            "EventTicketNFT",
            "TICKET",
            "https://api.example.com/metadata/",
            deployer
        );
        
        vm.stopBroadcast();
        
        console.log("EventTicketNFT deployed to:", address(ticketNFT));
    }
}
