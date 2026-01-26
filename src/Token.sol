// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract Token {
    uint8 private constant DECIMALS = 18;

    string private sName;
    string private sSymbol;

    uint256 private sTotalSupply;

    mapping(address => uint256) private sBalances;
    mapping(address => mapping(address => uint256)) private sAllowances;

    address private sOwner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view{
        require(msg.sender == sOwner, "Only owner allowed");
    }

    constructor(string memory name_, string memory symbol_, uint256 initialSupply_) {
        sName = name_;
        sSymbol = symbol_;
        sOwner = msg.sender;
        _mint(msg.sender, initialSupply_);
    }

    function name() external view returns (string memory) {
        return sName;
    }

    function symbol() external view returns (string memory) {
        return sSymbol;
    }

    function totalSupply() external view returns (uint256) {
        return sTotalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return sBalances[account];
    }

    function allowance(address tokenOwner, address spender) external view returns (uint256) {
        return sAllowances[tokenOwner][spender];
    }

    function owner() external view returns (address) {
        return sOwner;
    }

    function decimals() external pure returns (uint8) {
        return DECIMALS;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        sAllowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 currentAllowance = sAllowances[from][msg.sender];
        require(currentAllowance >= amount, "Allowance exceeded");

        unchecked {
            sAllowances[from][msg.sender] = currentAllowance - amount;
        }

        _transfer(from, to, amount);
        return true;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        emit OwnershipTransferred(sOwner, newOwner);
        sOwner = newOwner;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        sAllowances[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, sAllowances[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = sAllowances[msg.sender][spender];
        require(subtractedValue <= currentAllowance, "ALLOWANCE_UNDERFLOW");

        unchecked {
            sAllowances[msg.sender][spender] = currentAllowance - subtractedValue;
        }

        emit Approval(msg.sender, spender, sAllowances[msg.sender][spender]);
        return true;
    }



    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "Transfer to zero address");
        uint256 fromBalance = sBalances[from];
        require(fromBalance >= amount, "Balance too low");

        unchecked {
            sBalances[from] = fromBalance - amount;
            sBalances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "Mint to zero address");

        sTotalSupply += amount;
        sBalances[to] += amount;

        emit Transfer(address(0), to, amount);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        uint256 currentAllowance = sAllowances[account][msg.sender];
        require(amount <= currentAllowance, "ALLOWANCE_EXCEEDED");

        unchecked {
            sAllowances[account][msg.sender] = currentAllowance - amount;
        }

        _burn(account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ZERO_ADDRESS");
        uint256 accountBalance = sBalances[account];
        require(amount <= accountBalance, "INSUFFICIENT_BALANCE");

        unchecked {
            sBalances[account] = accountBalance - amount;
            sTotalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }
}
