//SPDX-License-Identifer: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Token} from "../src/Token.sol";

contract DeployToken is Script {
    function run() external returns (Token) {
        string memory name = "Truffle";
        string memory symbol = "TFL";
        uint256 initialSupply = 1_000_000e18;

        vm.startBroadcast();
        Token token = new Token(name, symbol, initialSupply);
        vm.stopBroadcast();

        return token;
    }
}
