//SPDX-License-Identifer:MIT

pragma solidity ^0.8.2;

contract Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    address public owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        owner = msg.sender;
    }

    //lets make the functions that are given by the interface of OpenZepplin

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        uint256 currentAllowance = allowances[from][msg.sender];
        require(currentAllowance >= amount, "Allowance exceeded");

        allowances[from][msg.sender] = currentAllowance - amount;
        _transfer(from, to, amount);

        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(
        address tokenOwner,
        address spender
    ) external view returns (uint256) {
        return allowances[tokenOwner][spender];
    }


    //make the main comoutation functions
    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "Transfer to zero address");
        require(balances[from] >= amount, "Balance too low");

        balances[from] -= amount;
        balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "Mint to zero address");

        totalSupply += amount;
        balances[to] += amount;

        emit Transfer(address(0), to, amount);
    }


    //now lets make the final and main minting function, for the faucet
     function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
