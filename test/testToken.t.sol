// SPDX-License_Identifier: MIT

pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";

contract TestToken is Test{
    Token token;

    address OWNER = address(0xABCD);
    address PERS1 = address(0x1);
    address PERS2   = address(0x2);
    address PERS3 = address(0x3);

    uint256 constant INITIAL_SUPPLY = 1000 ether;

    function setUp() external {
        vm.prank(OWNER);
        token = new Token("Truffle", "TFL", INITIAL_SUPPLY);
    }

    function testGetters() external view{
        assertEq(token.name(), "Truffle");
        assertEq(token.symbol(), "TFL");
        assertEq(token.DECIMALS(), 18);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.owner(), OWNER);
        assertEq(token.balanceOf(OWNER), INITIAL_SUPPLY);
        assertEq(token.allowance(OWNER, PERS3), 0);
    }
    
}