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

    uint256 constant INITIAL_SUPPLY = 10000e18;
    uint256 constant CLAIM_AMOUNT = 100e18;
    uint256 constant COOLDOWN = 1 hours;
    uint256 constant FAUCET_FUND_AMOUNT = 1000e18;

    event Claimed(address indexed user, uint256 amount);
    event FaucetFunded(uint256 amount, bool wasMinted);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TokensWithdrawn(address indexed to, uint256 amount);

    function setUp() external {
        vm.startPrank(owner);
        token = new Token("Truffle", "TFL", INITIAL_SUPPLY);
        faucet = new TokenFaucet(address(token), CLAIM_AMOUNT, COOLDOWN);
        token.transferOwnership(address(faucet));
        faucet.updateMintStatus();
        vm.stopPrank();

        vm.prank(owner);
        faucet.fundFaucet(FAUCET_FUND_AMOUNT);
    }

    function testInitialSetup() external view {
        assertEq(token.balanceOf(address(faucet)), FAUCET_FUND_AMOUNT);
        assertEq(faucet.faucetBalance(), FAUCET_FUND_AMOUNT);
        assertEq(faucet.claimAmount(), CLAIM_AMOUNT);
        assertEq(faucet.cooldown(), COOLDOWN);
        assertEq(faucet.owner(), owner);
        assertEq(faucet.canMint(), true);
        assertEq(faucet.token(), address(token));
    }

    function testSingleUserClaim() external {
        uint256 initialFaucetBalance = token.balanceOf(address(faucet));

        vm.prank(user1);
        faucet.claim();

        assertEq(token.balanceOf(user1), CLAIM_AMOUNT);
        assertEq(token.balanceOf(address(faucet)), initialFaucetBalance - CLAIM_AMOUNT);
    }

    function testUserCannotClaimTwiceWithinCooldown() external {
        vm.prank(user1);
        faucet.claim();

        uint256 nextAllowed = block.timestamp + COOLDOWN;

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(TokenFaucet.CooldownActive.selector, nextAllowed));
        faucet.claim();
    }

    function testMultipleUsersCanClaim() external {
        vm.prank(user1);
        faucet.claim();

        vm.prank(user2);
        faucet.claim();

        assertEq(token.balanceOf(user1), CLAIM_AMOUNT);
        assertEq(token.balanceOf(user2), CLAIM_AMOUNT);
    }

    function testUserCanClaimAfterCooldown() external {
        vm.prank(user1);
        faucet.claim();

        vm.warp(block.timestamp + COOLDOWN);

        vm.prank(user1);
        faucet.claim();

        assertEq(token.balanceOf(user1), CLAIM_AMOUNT * 2);
    }

    function testFundFaucet() external {
        uint256 additionalAmount = 500e18;
        uint256 initialFaucetBalance = token.balanceOf(address(faucet));

        vm.prank(owner);
        faucet.fundFaucet(additionalAmount);

        assertEq(token.balanceOf(address(faucet)), initialFaucetBalance + additionalAmount);
    }

    function testMintToFaucet() external {
        uint256 mintAmount = 500e18;
        uint256 initialFaucetBalance = token.balanceOf(address(faucet));

        vm.prank(owner);
        faucet.mintToFaucet(mintAmount);

        assertEq(token.balanceOf(address(faucet)), initialFaucetBalance + mintAmount);
    }

    function testWithdrawTokens() external {
        uint256 withdrawAmount = 500e18;
        uint256 initialOwnerBalance = token.balanceOf(owner);
        uint256 initialFaucetBalance = token.balanceOf(address(faucet));

        vm.prank(owner);
        faucet.withdrawTokens(withdrawAmount);

        assertEq(token.balanceOf(owner), initialOwnerBalance + withdrawAmount);
        assertEq(token.balanceOf(address(faucet)), initialFaucetBalance - withdrawAmount);
    }

    function testTransferOwnership() external {
        vm.prank(owner);
        faucet.transferOwnership(user1);

        assertEq(faucet.owner(), user1);
    }

    function testClaimWhenFaucetEmpty() external {
        uint256 claimsUntilEmpty = FAUCET_FUND_AMOUNT / CLAIM_AMOUNT;
        for (uint256 i = 0; i < claimsUntilEmpty; i++) {
            address user = address(uint160(i + 100));
            vm.prank(user);
            faucet.claim();
        }
        assertEq(token.balanceOf(address(faucet)), 0);

        vm.prank(user1);
        faucet.claim();

        assertEq(token.balanceOf(user1), CLAIM_AMOUNT);
    }

    function testEventsAreEmitted() external {
        vm.expectEmit(true, false, false, true, address(faucet));
        emit Claimed(user1, CLAIM_AMOUNT);
        vm.prank(user1);
        faucet.claim();
        vm.expectEmit(false, false, false, true, address(faucet));
        emit FaucetFunded(500e18, false);
        vm.prank(owner);
        faucet.fundFaucet(500e18);
    }

    function testWithdrawTokensInsufficientBalance() external {
        uint256 excessAmount = FAUCET_FUND_AMOUNT + 1;

        vm.prank(owner);
        vm.expectRevert(TokenFaucet.InsufficientFaucetBalance.selector);
        faucet.withdrawTokens(excessAmount);
    }

    function testTransferOwnershipNotOwner() external {
        vm.prank(user1);
        vm.expectRevert(TokenFaucet.NotOwner.selector);
        faucet.transferOwnership(user2);
    }

    function testMintToFaucetNotOwner() external {
        vm.prank(user1);
        vm.expectRevert(TokenFaucet.NotOwner.selector);
        faucet.mintToFaucet(100e18);
    }
}
