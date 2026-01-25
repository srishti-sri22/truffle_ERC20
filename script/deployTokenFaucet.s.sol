// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {TokenFaucet} from "../src/TokenFaucet.sol";

contract DeployFaucet is Script {
    function run(address tokenAddress) external returns (TokenFaucet) {
        uint256 mintAmount = 100e18;
        uint256 cooldown = 1 days;

        vm.startBroadcast();
        TokenFaucet faucet = new TokenFaucet(tokenAddress, mintAmount, cooldown);
        vm.stopBroadcast();

        return faucet;
    }
}
