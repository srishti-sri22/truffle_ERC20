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

    uint256 constant FAUCET_BALANCE = 1000e18;

    function setUp() external {
        vm.prank(OWNER);
        token = new Token("Truffle", "TFL", 0);

        faucet = new TokenFaucet(address(token));

        vm.prank(OWNER);
        token.mint(address(faucet), FAUCET_BALANCE);
    }

    function testInitialFaucetBalance() external view {
        assertEq(token.balanceOf(address(faucet)), FAUCET_BALANCE);
    }

    function testUserCanClaim() external {
        vm.prank(USER1);
        faucet.claim();

        assertGt(token.balanceOf(USER1), 0);
    }

    function testFaucetBalanceReducesAfterClaim() external {
        uint256 beforeBalance = token.balanceOf(address(faucet));

        vm.prank(USER1);
        faucet.claim();

        uint256 afterBalance = token.balanceOf(address(faucet));
        assertLt(afterBalance, beforeBalance);
    }

    function testUserCannotClaimTwice() external {
        vm.prank(USER1);
        faucet.claim();

        vm.prank(USER1);
        vm.expectRevert();
        faucet.claim();
    }

    function testDifferentUsersCanClaim() external {
        vm.prank(USER1);
        faucet.claim();

        vm.prank(USER2);
        faucet.claim();

        assertGt(token.balanceOf(USER1), 0);
        assertGt(token.balanceOf(USER2), 0);
    }

    function testClaimRevertsWhenFaucetEmpty() external {
        vm.prank(OWNER);
        token.mint(address(faucet), 1e18);

        vm.prank(USER1);
        faucet.claim();

        vm.prank(USER2);
        vm.expectRevert();
        faucet.claim();
    }

    function testClaim() external {
        vm.prank(USER1);
        faucet.claim();

        assertEq(token.balanceOf(USER1), MINT_AMOUNT);
        assertEq(
            token.balanceOf(address(faucet)),
            FAUCET_BALANCE - MINT_AMOUNT
        );
    }

    function testMultipleUsersClaim() external {
        vm.prank(USER1);
        faucet.claim();

        vm.prank(USER2);
        faucet.claim();

        assertEq(token.balanceOf(USER1), MINT_AMOUNT);
        assertEq(token.balanceOf(USER2), MINT_AMOUNT);
    }

    function testClaimRevertCooldown() external {
        vm.prank(USER1);
        faucet.claim();

        vm.prank(USER1);
        vm.expectRevert();
        faucet.claim();
    }

    function testClaimAfterCooldown() external {
        vm.prank(USER1);
        faucet.claim();

        vm.warp(block.timestamp + COOLDOWN);

        vm.prank(USER1);
        faucet.claim();

        assertEq(token.balanceOf(USER1), MINT_AMOUNT * 2);
    }

    function testClaimRevertInsufficientBalance() external {
        vm.prank(OWNER);
        token.transfer(address(0xdead), FAUCET_BALANCE);

        vm.prank(USER1);
        vm.expectRevert();
        faucet.claim();
    }
}
