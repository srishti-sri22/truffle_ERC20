// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Token} from "../src/Token.sol";
import {TokenFaucet} from "../src/TokenFaucet.sol";

contract DeployAll is Script {
    function run() external returns (Token, TokenFaucet) {
        string memory name = "Truffle";
        string memory symbol = "TFL";
        uint256 initialSupply = 1000000e18;
        uint256 claimAmount = 100e18;
        uint256 cooldown = 1 days;

        vm.startBroadcast();

        Token token = new Token(name, symbol, initialSupply);
        TokenFaucet faucet = new TokenFaucet(address(token), claimAmount, cooldown);
        token.transfer(address(faucet), initialSupply);
        vm.stopBroadcast();

        return (token, faucet);
    }
}
