// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TournamentTokenWhitelist is Ownable {
    struct TokenInfo {
        bool exists;
        bool isPaused;
        uint8 index;
    }

    uint8 public constant MAX_TOKENS = 255;

    address[] private _tokens;
    mapping(address => TokenInfo) private _tokenInfo;

    event TokenWhitelisted(address indexed token);
    event TokenPaused(address indexed token, string reason);
    event TokenUnpaused(address indexed token);

    error InvalidTokenAddress();
    error AlreadyExists();
    error NotFound();
    error MaxTokensReached();

    constructor() Ownable(msg.sender) {}

    function addToken(address token) external onlyOwner {
        if (token == address(0)) revert InvalidTokenAddress();

        TokenInfo storage info = _tokenInfo[token];
        if (info.exists) revert AlreadyExists();

        uint256 currentLength = _tokens.length;
        if (currentLength >= MAX_TOKENS) revert MaxTokensReached();

        info.exists = true;
        info.isPaused = false;
        info.index = uint8(currentLength);

        _tokens.push(token);

        emit TokenWhitelisted(token);
    }

    function pauseToken(
        address token,
        string calldata reason
    ) external onlyOwner {
        TokenInfo storage info = _tokenInfo[token];
        if (!info.exists) revert NotFound();

        info.isPaused = true;
        emit TokenPaused(token, reason);
    }

    function unpauseToken(address token) external onlyOwner {
        TokenInfo storage info = _tokenInfo[token];
        if (!info.exists) revert NotFound();

        info.isPaused = false;
        emit TokenUnpaused(token);
    }

    function isWhitelisted(address token) external view returns (bool) {
        TokenInfo storage info = _tokenInfo[token];
        return info.exists && !info.isPaused;
    }

    function isPaused(address token) external view returns (bool) {
        return _tokenInfo[token].isPaused;
    }

    function isTokenRegistered(address token) external view returns (bool) {
        return _tokenInfo[token].exists;
    }

    function getTokens() external view returns (address[] memory) {
        return _tokens;
    }

    function getTokenCount() external view returns (uint256) {
        return _tokens.length;
    }

    function getRemainingCapacity() external view returns (uint256) {
        unchecked {
            return MAX_TOKENS - _tokens.length;
        }
    }

    function getToken(
        address token
    ) external view returns (bool whitelisted, bool paused, uint8 index) {
        TokenInfo storage info = _tokenInfo[token];
        return (info.exists, info.isPaused, info.index);
    }
}
