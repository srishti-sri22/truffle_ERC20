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

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setUp() external {
        vm.startPrank(owner);
        token = new Token("Truffle", "TFL", INITIAL_SUPPLY);
        vm.stopPrank();
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
        vm.startPrank(owner);

        vm.expectEmit(true, true, false, true, address(token));
        emit Transfer(owner, pers1, 100e18);
        bool success = token.transfer(pers1, 100e18);
        require(success);

        assertEq(token.balanceOf(pers1), 100e18);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - 100e18);

        vm.stopPrank();
    }

    function testTransferRevert() external {
        vm.prank(pers1);
        vm.expectRevert(bytes("Balance too low"));
        token.transfer(pers2, 1e18);
        vm.prank(owner);
        vm.expectRevert(bytes("Transfer to zero address"));
        token.transfer(address(0), 1e18);
    }

    function testApproveAndTransferFrom() external {
        vm.startPrank(owner);

        vm.expectEmit(true, true, false, true, address(token));
        emit Approval(owner, pers1, 300e18);
        bool approved = token.approve(pers1, 300e18);
        require(approved);

        vm.stopPrank();

        vm.startPrank(pers1);
        vm.expectEmit(true, true, false, true, address(token));
        emit Transfer(owner, pers2, 150e18);
        bool transferred = token.transferFrom(owner, pers2, 150e18);
        require(transferred);

        assertEq(token.balanceOf(pers2), 150e18);
        assertEq(token.allowance(owner, pers1), 150e18);

        vm.stopPrank();
    }

    function testTransferFromReverts() external {
        vm.prank(pers1);
        vm.expectRevert(bytes("Allowance exceeded"));
        token.transferFrom(owner, pers2, 1e18);

        vm.startPrank(owner);
        token.approve(pers1, INITIAL_SUPPLY + 1);
        vm.stopPrank();

        vm.prank(pers1);
        vm.expectRevert(bytes("Balance too low"));
        token.transferFrom(owner, pers2, INITIAL_SUPPLY + 1);
    }

    function testMint() external {
        vm.startPrank(owner);

        vm.expectEmit(true, true, false, true, address(token));
        emit Transfer(address(0), pers1, 500e18);
        token.mint(pers1, 500e18);

        assertEq(token.balanceOf(pers1), 500e18);
        assertEq(token.totalSupply(), INITIAL_SUPPLY + 500e18);

        vm.stopPrank();
    }

    function testMintReverts() external {
        vm.prank(pers1);
        vm.expectRevert(bytes("Only owner allowed"));
        token.mint(pers1, 1e18);

        vm.prank(owner);
        vm.expectRevert(bytes("Mint to zero address"));
        token.mint(address(0), 1e18);
    }

    function testBurn() external {
        vm.startPrank(owner);

        bool success = token.transfer(pers1, 200e18);
        require(success);

        vm.expectEmit(true, true, false, true, address(token));
        emit Transfer(pers1, address(0), 100e18);
        token.burn(pers1, 100e18);

        assertEq(token.balanceOf(pers1), 100e18);
        assertEq(token.totalSupply(), INITIAL_SUPPLY - 100e18);

        vm.stopPrank();
    }

    function testBurnFrom() external {
        vm.startPrank(owner);
        bool success = token.transfer(pers1, 200e18);
        vm.stopPrank();
        require(success);
        vm.startPrank(pers1);

        vm.expectEmit(true, true, false, true, address(token));
        emit Approval(pers1, pers2, 150e18);

        token.approve(pers2, 150e18);
        vm.stopPrank();

        vm.startPrank(pers2);

        vm.expectEmit(true, true, false, true, address(token));
        emit Transfer(pers1, address(0), 50e18);

        token.burnFrom(pers1, 50e18);

        assertEq(token.balanceOf(pers1), 150e18);
        assertEq(token.allowance(pers1, pers2), 100e18);

        vm.stopPrank();
    }

    function testIncreaseDecreaseAllowance() external {
        vm.startPrank(owner);
        token.approve(pers1, 100e18);

        vm.expectEmit(true, true, false, true, address(token));
        emit Approval(owner, pers1, 150e18);
        bool inc = token.increaseAllowance(pers1, 50e18);
        require(inc);
        assertEq(token.allowance(owner, pers1), 150e18);

        vm.expectEmit(true, true, false, true, address(token));
        emit Approval(owner, pers1, 100e18);
        bool dec = token.decreaseAllowance(pers1, 50e18);
        require(dec);
        assertEq(token.allowance(owner, pers1), 100e18);

        vm.expectRevert(bytes("ALLOWANCE_UNDERFLOW"));
        token.decreaseAllowance(pers1, 200e18);

        vm.stopPrank();
    }

    function testOwnershipTransfer() external {
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true, address(token));
        emit OwnershipTransferred(owner, pers1);
        token.transferOwnership(pers1);

        assertEq(token.owner(), pers1);
        vm.stopPrank();
    }

    function testFuzzTransfer(uint256 amount) external {
        amount = bound(amount, 1, INITIAL_SUPPLY);

        vm.startPrank(owner);

        vm.expectEmit(true, true, false, true, address(token));
        emit Transfer(owner, pers1, amount);

        bool success = token.transfer(pers1, amount);
        require(success);

        assertEq(token.balanceOf(pers1), amount);
        vm.stopPrank();
    }

    function testFuzzApproveAndTransferFrom(uint256 amount) external {
        amount = bound(amount, 1, INITIAL_SUPPLY);

        vm.startPrank(owner);

        vm.expectEmit(true, true, false, true, address(token));
        emit Approval(owner, pers1, amount);

        bool approved = token.approve(pers1, amount);
        require(approved);
        vm.stopPrank();

        vm.startPrank(pers1);

        vm.expectEmit(true, true, false, true, address(token));
        emit Transfer(owner, pers2, amount);

        bool transferred = token.transferFrom(owner, pers2, amount);
        require(transferred);

        assertEq(token.balanceOf(pers2), amount);
        assertEq(token.allowance(owner, pers1), 0);
        vm.stopPrank();
    }
}
