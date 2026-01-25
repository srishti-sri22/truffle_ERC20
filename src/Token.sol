// SPDX-License-Identifer:MIT

pragma solidity ^0.8.20;

contract Token {
    //now lets do some gas optimisations
    //private make-> make getters
    //immutable i_
    //storage s_
    //constants

    uint8 public constant DECIMALS = 18;

    string private s_name;
    string private s_symbol;

    uint256 private s_totalSupply;

    mapping(address => uint256) private s_balances;
    mapping(address => mapping(address => uint256)) private s_allowances;

    address private immutable i_owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    modifier onlyOwner() {
        require(msg.sender == i_owner, "Only owner");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply_
    ) {
        s_name = name_;
        s_symbol = symbol_;
        i_owner = msg.sender;
        _mint(msg.sender, initialSupply_);
    }

    //lets make the getter functions

    function name() external view returns (string memory) {
        return s_name;
    }

    function symbol() external view returns (string memory) {
        return s_symbol;
    }

    function totalSupply() external view returns (uint256) {
        return s_totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return s_balances[account];
    }

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256) {
        return s_allowances[owner][spender];
    }

    function owner() external view returns (address) {
        return i_owner;
    }

    //lets make the functions that are given by the interface of OpenZepplin

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        s_allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        uint256 currentAllowance = s_allowances[from][msg.sender];
        require(currentAllowance >= amount, "Allowance exceeded");

        unchecked {
            s_allowances[from][msg.sender] = currentAllowance - amount;
        }

        _transfer(from, to, amount);
        return true;
    }

    //make the main comoutation functions
    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "Transfer to zero address");
        uint256 fromBalance = s_balances[from];
        require(fromBalance >= amount, "Balance too low");

        unchecked {
            s_balances[from] = fromBalance - amount;
            s_balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "Mint to zero address");

        s_totalSupply += amount;
        s_balances[to] += amount;

        emit Transfer(address(0), to, amount);
    }

    //now lets make the final and main minting function, for the faucet
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
