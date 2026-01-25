// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";
import {TokenFaucet} from "../src/TokenFaucet.sol";

contract TestTokenFaucet is Test {
    Token token;
    TokenFaucet faucet;

    address OWNER = address(0xABCD);
    address USER1 = address(0x1);
    address USER2 = address(0x2);
    address USER3 = address(0x3);

    uint256 constant FAUCET_BALANCE = 1000e18;
    uint256 constant MINT_AMOUNT = 100e18;
    uint256 constant COOLDOWN = 1 hours;

    function setUp() external {
        vm.startPrank(OWNER);
        token = new Token("Truffle", "TFL", 0);
        faucet = new TokenFaucet(Token(address(token)), MINT_AMOUNT, COOLDOWN);
        token.mint(address(faucet), FAUCET_BALANCE);
        token.transferOwnership(address(faucet));
        vm.stopPrank();
    }

    function testInitialFaucetBalance() external view {
        assertEq(token.balanceOf(address(faucet)), FAUCET_BALANCE);
    }

    function testSingleUserClaim() external {
        vm.prank(USER1);
        faucet.claim();

        assertEq(token.balanceOf(USER1), MINT_AMOUNT);
        assertEq(token.balanceOf(address(faucet)), FAUCET_BALANCE - MINT_AMOUNT);
    }

    function testMultipleUsersClaim() external {
        vm.prank(USER1);
        faucet.claim();

        vm.prank(USER2);
        faucet.claim();

        assertEq(token.balanceOf(USER1), MINT_AMOUNT);
        assertEq(token.balanceOf(USER2), MINT_AMOUNT);
        assertEq(token.balanceOf(address(faucet)), FAUCET_BALANCE - 2 * MINT_AMOUNT);
    }

    function testUserCannotClaimTwiceWithinCooldown() external {
        vm.prank(USER1);
        faucet.claim();

        vm.prank(USER1);
        vm.expectRevert(TokenFaucet.CooldownNotPassed.selector);
        faucet.claim();
    }

    function testUserCanClaimAfterCooldown() external {
        vm.prank(USER1);
        faucet.claim();

        vm.warp(block.timestamp + COOLDOWN);

        vm.prank(USER1);
        faucet.claim();

        assertEq(token.balanceOf(USER1), MINT_AMOUNT * 2);
        assertEq(token.balanceOf(address(faucet)), FAUCET_BALANCE - MINT_AMOUNT * 2);
    }

    function testClaimRevertsWhenFaucetEmpty() external {
        vm.prank(USER1);
        faucet.claim();

        vm.prank(USER2);
        vm.expectRevert(TokenFaucet.InsufficientBalance.selector);
        faucet.claim();
    }

    function testFuzzClaimsSingleUser(uint256 fuzzAmount) external {
        fuzzAmount = bound(fuzzAmount, 1, FAUCET_BALANCE);

        vm.prank(OWNER);
        token.mint(address(faucet), fuzzAmount);

        vm.prank(USER1);
        faucet.claim();

        uint256 userBalance = token.balanceOf(USER1);
        assertEq(userBalance, MINT_AMOUNT);
    }

    function testFuzzMultipleUsers(uint256 fuzzAmount1, uint256 fuzzAmount2) external {
        fuzzAmount1 = bound(fuzzAmount1, 1, FAUCET_BALANCE / 2);
        fuzzAmount2 = bound(fuzzAmount2, 1, FAUCET_BALANCE / 2);

        vm.prank(OWNER);
        token.mint(address(faucet), fuzzAmount1 + fuzzAmount2);

        vm.prank(USER1);
        faucet.claim();

        vm.prank(USER2);
        faucet.claim();

        assertEq(token.balanceOf(USER1), MINT_AMOUNT);
        assertEq(token.balanceOf(USER2), MINT_AMOUNT);
        assertEq(token.balanceOf(address(faucet)), FAUCET_BALANCE + fuzzAmount1 + fuzzAmount2 - 2 * MINT_AMOUNT);
    }

    function testClaimRevertIfInsufficientFaucetBalance() external {
        vm.prank(OWNER);
        token.transfer(address(0xdead), FAUCET_BALANCE - MINT_AMOUNT + 1);

        vm.prank(USER1);
        vm.expectRevert(TokenFaucet.InsufficientBalance.selector);
        faucet.claim();
    }
}
