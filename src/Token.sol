// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract Token {
    //now lets do some gas optimisations
    //private make-> make getters
    //immutable i_
    //storage s_
    //constants

    uint8 public constant DECIMALS = 18;

    string private sName;
    string private sSymbol;

    uint256 private sTotalSupply;

    mapping(address => uint256) private sBalances;
    mapping(address => mapping(address => uint256)) private sAllowances;

    address private immutable I_OWNER;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        require(msg.sender == I_OWNER, "Only owner");
    }

    constructor(string memory name_, string memory symbol_, uint256 initialSupply_) {
        sName = name_;
        sSymbol = symbol_;
        I_OWNER = msg.sender;
        _mint(msg.sender, initialSupply_);
    }

    //lets make the getter functions

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
        return I_OWNER;
    }

    //lets make the functions that are given by the interface of OpenZepplin

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

    //make the main comoutation functions
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

    //now lets make the final and main minting function, for the faucet
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
