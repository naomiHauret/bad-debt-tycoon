// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Manages the list of approved stablecoins that can be used for tournament stakes
 */
contract TournamentTokenWhitelist is Ownable {
    address[] private _whitelistedTokens;
    mapping(address => bool) private _isWhitelisted;
    mapping(address => uint256) private _tokenIndex;

    event TokenWhitelisted(address indexed token);
    event TokenRemovedFromWhitelist(address indexed token);

    error InvalidTokenAddress();
    error TokenAlreadyWhitelisted();
    error TokenNotWhitelisted();

    constructor(address initialOwner) Ownable(initialOwner) {}

    function addToken(address token) external onlyOwner {
        if (token == address(0)) {
            revert InvalidTokenAddress();
        }
        if (_isWhitelisted[token]) {
            revert TokenAlreadyWhitelisted();
        }

        _isWhitelisted[token] = true;
        _tokenIndex[token] = _whitelistedTokens.length;
        _whitelistedTokens.push(token);

        emit TokenWhitelisted(token);
    }

    function removeToken(address token) external onlyOwner {
        if (!_isWhitelisted[token]) {
            revert TokenNotWhitelisted();
        }

        _isWhitelisted[token] = false;

        uint256 indexToRemove = _tokenIndex[token];
        uint256 lastIndex = _whitelistedTokens.length - 1;

        if (indexToRemove != lastIndex) {
            address lastToken = _whitelistedTokens[lastIndex];
            _whitelistedTokens[indexToRemove] = lastToken;
            _tokenIndex[lastToken] = indexToRemove;
        }

        _whitelistedTokens.pop();
        delete _tokenIndex[token];

        emit TokenRemovedFromWhitelist(token);
    }

    function isWhitelisted(address token) external view returns (bool) {
        return _isWhitelisted[token];
    }

    function getWhitelistedTokens() external view returns (address[] memory) {
        return _whitelistedTokens;
    }

    function getWhitelistedTokenCount() external view returns (uint256) {
        return _whitelistedTokens.length;
    }
}
