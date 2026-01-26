// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";

contract TestToken is Test {
    Token token;

    address owner = address(0xABCD);
    address pers1 = address(0x1);
    address pers2 = address(0x2);
    address pers3 = address(0x3);

    uint256 constant INITIAL_SUPPLY = 1000e18;

    function setUp() external {
        vm.prank(owner);
        token = new Token("Truffle", "TFL", INITIAL_SUPPLY);
    }

    function testGetters() external view {
        assertEq(token.name(), "Truffle");
        assertEq(token.symbol(), "TFL");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.owner(), owner);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
        assertEq(token.allowance(owner, pers3), 0);
    }

    function testTransfer() external {
        vm.prank(owner);
        bool success = token.transfer(pers1, 100e18);
        uint256 supplyBefore = token.totalSupply();
        require(success);
        assertEq(token.balanceOf(pers1), 100e18);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - 100e18);
        assertEq(token.totalSupply(), supplyBefore);
    }

    function testTransferEvent() external {
        vm.expectEmit(true, true, false, true, address(token));
        vm.prank(owner);
        bool success = token.transfer(pers1, 50e18);
        require(success);
    }

    function testApprove() external {
        vm.prank(owner);
        token.approve(pers1, 200e18);
        uint256 supplyBefore = token.totalSupply();
        assertEq(token.allowance(owner, pers1), 200e18);
        assertEq(token.totalSupply(), supplyBefore);
    }

    function testApproveEvent() external {
        vm.expectEmit(true, true, false, true);
        vm.prank(owner);
        token.approve(pers1, 100e18);
    }

    function testTransferFrom() external {
        vm.startPrank(owner);
        token.approve(pers1, 300e18);
        vm.stopPrank();

        vm.prank(pers1);
        bool success = token.transferFrom(owner, pers2, 150e18);
        require(success);
        uint256 supplyBefore = token.totalSupply();
        assertEq(token.balanceOf(pers2), 150e18);
        assertEq(token.allowance(owner, pers1), 150e18);
        assertEq(token.totalSupply(), supplyBefore);
    }

    function testTransferFromExactAllowance() external {
        vm.prank(owner);
        token.approve(pers1, 1e18);

        vm.prank(pers1);
        bool success = token.transferFrom(owner, pers2, 1e18);
        require(success);
        uint256 supplyBefore = token.totalSupply();
        assertEq(token.allowance(owner, pers1), 0);
        assertEq(token.totalSupply(), supplyBefore);
    }

    function testTransferRevertLowBalance() external {
        vm.prank(pers1);
        vm.expectRevert("Balance too low");
        bool success = token.transfer(pers2, 1e18);
        require(success);
    }

    function testTransferRevertZeroAddress() external {
        vm.prank(owner);
        vm.expectRevert("Transfer to zero address");
        bool success = token.transfer(address(0), 1e18);
        require(success);
    }

    function testTransferFromRevertAllowance() external {
        vm.prank(pers1);
        vm.expectRevert("Allowance exceeded");
        bool success = token.transferFrom(owner, pers2, 1e18);
        require(success);
    }

    function testTransferFromRevertBalance() external {
        vm.prank(owner);
        token.approve(pers1, INITIAL_SUPPLY + 1);

        vm.prank(pers1);
        vm.expectRevert("Balance too low");
        bool success = token.transferFrom(owner, pers2, INITIAL_SUPPLY + 1);
        require(success);
    }

    function testMint() external {
        vm.prank(owner);
        token.mint(pers1, 500e18);

        assertEq(token.balanceOf(pers1), 500e18);
        assertEq(token.totalSupply(), INITIAL_SUPPLY + 500e18);
    }

    function testMintEvent() external {
        vm.expectEmit(true, true, false, true, address(token));
        vm.prank(owner);
        token.mint(pers1, 100e18);
    }

    function testMintRevertNotOwner() external {
        vm.prank(pers1);
        vm.expectRevert("Only owner");
        token.mint(pers1, 1e18);
    }

    function testMintRevertZeroAddress() external {
        vm.prank(owner);
        vm.expectRevert("Mint to zero address");
        token.mint(address(0), 1e18);
    }

    function testFuzzTransfer(uint256 amount) external {
        amount = bound(amount, 1, INITIAL_SUPPLY);

        vm.prank(owner);
        bool success = token.transfer(pers1, amount);
        require(success);

        assertEq(token.balanceOf(pers1), amount);
    }

    function testFuzzApproveAndTransferFrom(uint256 amount) external {
        amount = bound(amount, 1, INITIAL_SUPPLY);

        vm.prank(owner);
        token.approve(pers1, amount);

        vm.prank(pers1);
        bool success = token.transferFrom(owner, pers2, amount);
        require(success);

        assertEq(token.balanceOf(pers2), amount);
        assertEq(token.allowance(owner, pers1), 0);
    }
}
