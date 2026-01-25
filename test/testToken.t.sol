// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";

contract TestToken is Test {
    Token token;

    address OWNER = address(0xABCD);
    address PERS1 = address(0x1);
    address PERS2 = address(0x2);
    address PERS3 = address(0x3);

    uint256 constant INITIAL_SUPPLY = 1000e18;

    function setUp() external {
        vm.prank(OWNER);
        token = new Token("Truffle", "TFL", INITIAL_SUPPLY);
    }

    function testGetters() external view {
        assertEq(token.name(), "Truffle");
        assertEq(token.symbol(), "TFL");
        assertEq(token.DECIMALS(), 18);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.owner(), OWNER);
        assertEq(token.balanceOf(OWNER), INITIAL_SUPPLY);
        assertEq(token.allowance(OWNER, PERS3), 0);
    }

    function testTransfer() external {
        vm.prank(OWNER);
        token.transfer(PERS1, 100e18);
        uint256 supplyBefore = token.totalSupply();
        assertEq(token.balanceOf(PERS1), 100e18);
        assertEq(token.balanceOf(OWNER), INITIAL_SUPPLY - 100e18);
        assertEq(token.totalSupply(), supplyBefore);
    }

    function testTransferEvent() external {
        vm.expectEmit(true, true, false, true, address(token));
        emit Token.Transfer(OWNER, PERS1, 50e18);

        vm.prank(OWNER);
        token.transfer(PERS1, 50e18);
    }

    function testApprove() external {
        vm.prank(OWNER);
        token.approve(PERS1, 200e18);
        uint256 supplyBefore = token.totalSupply();
        assertEq(token.allowance(OWNER, PERS1), 200e18);
        assertEq(token.totalSupply(), supplyBefore);
    }

    function testApproveEvent() external {
        vm.expectEmit(true, true, false, true);
        emit Token.Approval(OWNER, PERS1, 100e18);

        vm.prank(OWNER);
        token.approve(PERS1, 100e18);
    }

    function testTransferFrom() external {
        vm.startPrank(OWNER);
        token.approve(PERS1, 300e18);
        vm.stopPrank();

        vm.prank(PERS1);
        token.transferFrom(OWNER, PERS2, 150e18);
        uint256 supplyBefore = token.totalSupply();
        assertEq(token.balanceOf(PERS2), 150e18);
        assertEq(token.allowance(OWNER, PERS1), 150e18);
        assertEq(token.totalSupply(), supplyBefore);
    }

    function testTransferFromExactAllowance() external {
        vm.prank(OWNER);
        token.approve(PERS1, 1e18);

        vm.prank(PERS1);
        token.transferFrom(OWNER, PERS2, 1e18);
        uint256 supplyBefore = token.totalSupply();
        assertEq(token.allowance(OWNER, PERS1), 0);
        assertEq(token.totalSupply(), supplyBefore);
    }

    function testTransferRevertLowBalance() external {
        vm.prank(PERS1);
        vm.expectRevert("Balance too low");
        token.transfer(PERS2, 1e18);
    }

    function testTransferRevertZeroAddress() external {
        vm.prank(OWNER);
        vm.expectRevert("Transfer to zero address");
        token.transfer(address(0), 1e18);
    }

    function testTransferFromRevertAllowance() external {
        vm.prank(PERS1);
        vm.expectRevert("Allowance exceeded");
        token.transferFrom(OWNER, PERS2, 1e18);
    }

    function testTransferFromRevertBalance() external {
        vm.prank(OWNER);
        token.approve(PERS1, INITIAL_SUPPLY + 1);

        vm.prank(PERS1);
        vm.expectRevert("Balance too low");
        token.transferFrom(OWNER, PERS2, INITIAL_SUPPLY + 1);
    }

    function testMint() external {
        vm.prank(OWNER);
        token.mint(PERS1, 500e18);

        assertEq(token.balanceOf(PERS1), 500e18);
        assertEq(token.totalSupply(), INITIAL_SUPPLY + 500e18);
    }

    function testMintEvent() external {
        vm.expectEmit(true, true, false, true, address(token));
        emit Token.Transfer(address(0), PERS1, 100e18);

        vm.prank(OWNER);
        token.mint(PERS1, 100e18);
    }

    function testMintRevertNotOwner() external {
        vm.prank(PERS1);
        vm.expectRevert("Only owner");
        token.mint(PERS1, 1e18);
    }

    function testMintRevertZeroAddress() external {
        vm.prank(OWNER);
        vm.expectRevert("Mint to zero address");
        token.mint(address(0), 1e18);
    }

    function testFuzzTransfer(uint256 amount) external {
        amount = bound(amount, 1, INITIAL_SUPPLY);

        vm.prank(OWNER);
        token.transfer(PERS1, amount);

        assertEq(token.balanceOf(PERS1), amount);
    }

    function testFuzzApproveAndTransferFrom(uint256 amount) external {
        amount = bound(amount, 1, INITIAL_SUPPLY);

        vm.prank(OWNER);
        token.approve(PERS1, amount);

        vm.prank(PERS1);
        token.transferFrom(OWNER, PERS2, amount);

        assertEq(token.balanceOf(PERS2), amount);
        assertEq(token.allowance(OWNER, PERS1), 0);
    }
}
