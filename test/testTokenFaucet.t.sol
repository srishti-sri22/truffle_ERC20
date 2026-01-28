// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";
import {TokenFaucet} from "../src/TokenFaucet.sol";

contract TestTokenFaucet is Test {
    Token token;
    TokenFaucet faucet;

    address owner = address(0xABCD);
    address user1 = address(0x1);
    address user2 = address(0x2);

    uint256 constant INITIAL_SUPPLY = 10_000e18;
    uint256 constant CLAIM_AMOUNT = 100e18;
    uint256 constant COOLDOWN = 1 hours;

    function setUp() external {
        vm.startPrank(owner);

        token = new Token("Truffle", "TFL", INITIAL_SUPPLY);
        faucet = new TokenFaucet(address(token), CLAIM_AMOUNT, COOLDOWN);

        bool success = token.transfer(address(faucet), INITIAL_SUPPLY);
        require(success);

        vm.stopPrank();
    }

    function testInitialSetup() external view {
        assertEq(token.balanceOf(address(faucet)), INITIAL_SUPPLY);
        assertEq(faucet.claimAmount(), CLAIM_AMOUNT);
        assertEq(faucet.cooldown(), COOLDOWN);
        assertEq(faucet.owner(), owner);
        assertEq(faucet.token(), address(token));
    }

    function testSingleUserClaim() external {
        vm.prank(user1);
        faucet.claim();

        assertEq(token.balanceOf(user1), CLAIM_AMOUNT);
        assertEq(token.balanceOf(address(faucet)), INITIAL_SUPPLY - CLAIM_AMOUNT);
    }

    function testUserCannotClaimTwiceWithinCooldown() external {
        vm.prank(user1);
        faucet.claim();

        uint256 nextAllowed = block.timestamp + COOLDOWN;

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(TokenFaucet.CooldownActive.selector, nextAllowed));
        faucet.claim();
    }

    function testUserCanClaimAfterCooldown() external {
        vm.prank(user1);
        faucet.claim();

        vm.warp(block.timestamp + COOLDOWN);

        vm.prank(user1);
        faucet.claim();

        assertEq(token.balanceOf(user1), CLAIM_AMOUNT * 2);
    }

    function testMultipleUsersCanClaim() external {
        vm.prank(user1);
        faucet.claim();

        vm.prank(user2);
        faucet.claim();

        assertEq(token.balanceOf(user1), CLAIM_AMOUNT);
        assertEq(token.balanceOf(user2), CLAIM_AMOUNT);
    }


    function testWithdrawTokens() external {
        uint256 withdrawAmount = 500e18;

        uint256 ownerBalanceBefore = token.balanceOf(owner);
        uint256 faucetBalanceBefore = token.balanceOf(address(faucet));

        vm.prank(owner);
        faucet.withdrawTokens(withdrawAmount);

        assertEq(token.balanceOf(owner), ownerBalanceBefore + withdrawAmount);
        assertEq(token.balanceOf(address(faucet)), faucetBalanceBefore - withdrawAmount);
    }

    function testWithdrawTokensInsufficientBalance() external {
        vm.prank(owner);
        vm.expectRevert(TokenFaucet.InsufficientFaucetBalance.selector);
        faucet.withdrawTokens(INITIAL_SUPPLY + 1);
    }

    function testTransferOwnership() external {
        vm.prank(owner);
        faucet.transferOwnership(user1);

        assertEq(faucet.owner(), user1);
    }

    function testTransferOwnershipNotOwner() external {
        vm.prank(user1);
        vm.expectRevert(bytes("Only owner allowed"));
        faucet.transferOwnership(user2);
    }
}
