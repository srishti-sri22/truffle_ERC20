// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20Mintable {
    function mint(address to, uint256 amount) external;
}

contract TokenFaucet {
    error CooldownActive(uint256 nextClaimTimestamp);
    error ZeroAddress();

    IERC20Mintable private immutable I_TOKEN;
    uint256 private immutable I_MINT_AMOUNT;
    uint256 private immutable I_COOLDOWN;

    mapping(address => uint256) private sLastClaim;

    event Claimed(address indexed user, uint256 amount);

    constructor(
        address token_,
        uint256 mintAmount_,
        uint256 cooldown_
    ) {
        if (token_ == address(0)) revert ZeroAddress();
        I_TOKEN = IERC20Mintable(token_);
        I_MINT_AMOUNT = mintAmount_;
        I_COOLDOWN = cooldown_;
    }

    function claim() external {
        uint256 last = sLastClaim[msg.sender];
        uint256 nextAllowed = last + I_COOLDOWN;

        if (block.timestamp < nextAllowed) {
            revert CooldownActive(nextAllowed);
        }

        sLastClaim[msg.sender] = block.timestamp;
        I_TOKEN.mint(msg.sender, I_MINT_AMOUNT);

        emit Claimed(msg.sender, I_MINT_AMOUNT);
    }

    function lastClaim(address user) external view returns (uint256) {
        return sLastClaim[user];
    }

    function mintAmount() external view returns (uint256) {
        return I_MINT_AMOUNT;
    }

    function cooldown() external view returns (uint256) {
        return I_COOLDOWN;
    }
}
