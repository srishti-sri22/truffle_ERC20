// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20Mintable {
    function mint(address to, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function owner() external view returns (address);
}

contract TokenFaucet {
    error CooldownActive(uint256 nextClaimTimestamp);
    error ZeroAddress();
    error InsufficientFaucetBalance();
    error NotOwner();
    error TransferFailed();

    IERC20Mintable private immutable I_TOKEN;
    uint256 private immutable I_CLAIM_AMOUNT;
    uint256 private immutable I_COOLDOWN;

    uint256 private constant MIN_BALANCE = 1000e18;
    uint256 private constant TOP_UP_AMOUNT = 10000e18;

    address private sOwner;
    mapping(address => uint256) private sLastClaim;

    event Claimed(address indexed user, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TokensWithdrawn(address indexed to, uint256 amount);

    constructor(address token_, uint256 claimAmount_, uint256 cooldown_) {
        if (token_ == address(0)) revert ZeroAddress();
        I_TOKEN = IERC20Mintable(token_);
        I_CLAIM_AMOUNT = claimAmount_;
        I_COOLDOWN = cooldown_;
        sOwner = msg.sender;
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal {
        require(sOwner == msg.sender, "Only owner allowed");
    }

    function claim() external {
        uint256 last = sLastClaim[msg.sender];
        if (last != 0 && block.timestamp < last + I_COOLDOWN) {
            revert CooldownActive(last + I_COOLDOWN);
        }

        sLastClaim[msg.sender] = block.timestamp;

        bool success = I_TOKEN.transfer(msg.sender, I_CLAIM_AMOUNT);
        if (!success) revert TransferFailed();

        emit Claimed(msg.sender, I_CLAIM_AMOUNT);
    }

    function withdrawTokens(uint256 amount) external onlyOwner {
        uint256 balance = I_TOKEN.balanceOf(address(this));
        if (balance < amount) revert InsufficientFaucetBalance();

        bool success = I_TOKEN.transfer(sOwner, amount);
        if (!success) revert TransferFailed();

        emit TokensWithdrawn(sOwner, amount);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        emit OwnershipTransferred(sOwner, newOwner);
        sOwner = newOwner;
    }

    function lastClaim(address user) external view returns (uint256) {
        return sLastClaim[user];
    }

    function claimAmount() external view returns (uint256) {
        return I_CLAIM_AMOUNT;
    }

    function cooldown() external view returns (uint256) {
        return I_COOLDOWN;
    }

    function faucetBalance() external view returns (uint256) {
        return I_TOKEN.balanceOf(address(this));
    }

    function owner() external view returns (address) {
        return sOwner;
    }

    function token() external view returns (address) {
        return address(I_TOKEN);
    }
}
