// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Token} from "../src/Token.sol";

contract TransferOwnershipToFaucet is Script {
    function run(address tokenAddress, address faucetAddress) external {
        vm.startBroadcast();
        Token(tokenAddress).transferOwnership(faucetAddress);
        vm.stopBroadcast();
    }
}
