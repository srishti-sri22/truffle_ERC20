// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Token} from "../src/Token.sol";
import {TokenFaucet} from "../src/TokenFaucet.sol";

contract InvariantTokenFaucet is StdInvariant, Test {
    Token token;
    TokenFaucet faucet;

    address OWNER = address(0xABCD);

    function setUp() external {
        vm.prank(OWNER);
        token = new Token("Truffle", "TFL", 0);

        faucet = new TokenFaucet(address(token));

        vm.prank(OWNER);
        token.mint(address(faucet), 1000e18);

        targetContract(address(faucet));
    }

    function invariant_TotalSupplyConstant() external view {
        assertEq(token.totalSupply(), token.balanceOf(address(faucet)) + _usersBalance());
    }

    function _usersBalance() internal view returns (uint256 sum) {
        address;
        users[0] = address(0x1);
        users[1] = address(0x2);
        users[2] = address(0x3);

        for (uint256 i = 0; i < users.length; i++) {
            sum += token.balanceOf(users[i]);
        }
    }
}
