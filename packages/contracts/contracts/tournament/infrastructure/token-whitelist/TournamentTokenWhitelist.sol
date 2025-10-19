// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TournamentTokenWhitelist is Ownable {
    address[] private _whitelistedTokens;
    mapping(address => bool) private _isWhitelisted;
    mapping(address => bool) private _isPaused;
    mapping(address => uint256) private _tokenIndex;

    event TokenWhitelisted(address indexed token);
    event TokenPaused(address indexed token, string reason);
    event TokenUnpaused(address indexed token);

    error InvalidTokenAddress();
    error TokenAlreadyWhitelisted();
    error TokenNotWhitelisted();

    modifier onlyValidAddress(address token) {
        if (token == address(0)) {
            revert InvalidTokenAddress();
        }
        _;
    }

    modifier onlyWhitelisted(address token) {
        if (!_isWhitelisted[token]) {
            revert TokenNotWhitelisted();
        }
        _;
    }

    modifier onlyNotWhitelisted(address token) {
        if (_isWhitelisted[token]) {
            revert TokenAlreadyWhitelisted();
        }
        _;
    }

    constructor(address initialOwner) Ownable(initialOwner) {}

    function addToken(
        address token
    ) external onlyOwner onlyValidAddress(token) onlyNotWhitelisted(token) {
        _isWhitelisted[token] = true;
        _tokenIndex[token] = _whitelistedTokens.length;
        _whitelistedTokens.push(token);

        emit TokenWhitelisted(token);
    }

    function pauseToken(
        address token,
        string calldata reason
    ) external onlyOwner onlyWhitelisted(token) {
        _isPaused[token] = true;
        emit TokenPaused(token, reason);
    }

    function unpauseToken(
        address token
    ) external onlyOwner onlyWhitelisted(token) {
        _isPaused[token] = false;
        emit TokenUnpaused(token);
    }

    function isWhitelisted(address token) external view returns (bool) {
        return _isWhitelisted[token] && !_isPaused[token];
    }

    function isPaused(address token) external view returns (bool) {
        return _isPaused[token];
    }

    function isTokenRegistered(address token) external view returns (bool) {
        return _isWhitelisted[token];
    }

    function getWhitelistedTokens() external view returns (address[] memory) {
        return _whitelistedTokens;
    }

    function getActiveTokens() external view returns (address[] memory) {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < _whitelistedTokens.length; i++) {
            if (!_isPaused[_whitelistedTokens[i]]) {
                activeCount++;
            }
        }

        address[] memory activeTokens = new address[](activeCount);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < _whitelistedTokens.length; i++) {
            if (!_isPaused[_whitelistedTokens[i]]) {
                activeTokens[currentIndex] = _whitelistedTokens[i];
                currentIndex++;
            }
        }

        return activeTokens;
    }

    function getWhitelistedTokenCount() external view returns (uint256) {
        return _whitelistedTokens.length;
    }
}
