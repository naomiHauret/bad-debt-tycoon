// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TournamentTokenWhitelist is Ownable {
    struct TokenInfo {
        bool isWhitelisted;
        bool isPaused;
        uint8 index;
    }

    uint8 public constant MAX_TOKENS = 255;

    address[] private _whitelistedTokens;
    mapping(address => TokenInfo) private _tokenInfo;

    event TokenWhitelisted(address indexed token);
    event TokenPaused(address indexed token, string reason);
    event TokenUnpaused(address indexed token);

    error InvalidTokenAddress();
    error TokenAlreadyWhitelisted();
    error TokenNotWhitelisted();
    error MaxTokensReached();

    constructor(address initialOwner) Ownable(initialOwner) {}

    function addToken(address token) external onlyOwner {
        if (token == address(0)) revert InvalidTokenAddress();

        TokenInfo storage info = _tokenInfo[token];
        if (info.isWhitelisted) revert TokenAlreadyWhitelisted();

        uint256 currentLength = _whitelistedTokens.length;
        if (currentLength >= MAX_TOKENS) revert MaxTokensReached();

        info.isWhitelisted = true;
        info.isPaused = false;
        info.index = uint8(currentLength);

        _whitelistedTokens.push(token);

        emit TokenWhitelisted(token);
    }

    function pauseToken(
        address token,
        string calldata reason
    ) external onlyOwner {
        TokenInfo storage info = _tokenInfo[token];
        if (!info.isWhitelisted) revert TokenNotWhitelisted();

        info.isPaused = true;
        emit TokenPaused(token, reason);
    }

    function unpauseToken(address token) external onlyOwner {
        TokenInfo storage info = _tokenInfo[token];
        if (!info.isWhitelisted) revert TokenNotWhitelisted();

        info.isPaused = false;
        emit TokenUnpaused(token);
    }

    function isWhitelisted(address token) external view returns (bool) {
        TokenInfo storage info = _tokenInfo[token];
        return info.isWhitelisted && !info.isPaused;
    }

    function isPaused(address token) external view returns (bool) {
        return _tokenInfo[token].isPaused;
    }

    function isTokenRegistered(address token) external view returns (bool) {
        return _tokenInfo[token].isWhitelisted;
    }

    function getWhitelistedTokens() external view returns (address[] memory) {
        return _whitelistedTokens;
    }

    function getActiveTokens() external view returns (address[] memory) {
        uint256 length = _whitelistedTokens.length;
        uint256 activeCount = 0;

        for (uint256 i = 0; i < length; ) {
            if (!_tokenInfo[_whitelistedTokens[i]].isPaused) {
                unchecked {
                    ++activeCount;
                }
            }
            unchecked {
                ++i;
            }
        }

        address[] memory activeTokens = new address[](activeCount);
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < length; ) {
            address token = _whitelistedTokens[i];
            if (!_tokenInfo[token].isPaused) {
                activeTokens[currentIndex] = token;
                unchecked {
                    ++currentIndex;
                }
            }
            unchecked {
                ++i;
            }
        }

        return activeTokens;
    }

    function getWhitelistedTokenCount() external view returns (uint256) {
        return _whitelistedTokens.length;
    }

    function getRemainingCapacity() external view returns (uint256) {
        unchecked {
            return MAX_TOKENS - _whitelistedTokens.length;
        }
    }

    function addTokens(address[] calldata tokens) external onlyOwner {
        uint256 length = tokens.length;
        uint256 currentLength = _whitelistedTokens.length;

        unchecked {
            // Check batch won't exceed limit
            if (currentLength + length > MAX_TOKENS) revert MaxTokensReached();
        }

        for (uint256 i = 0; i < length; ) {
            address token = tokens[i];

            if (token == address(0)) revert InvalidTokenAddress();

            TokenInfo storage info = _tokenInfo[token];
            if (info.isWhitelisted) revert TokenAlreadyWhitelisted();

            info.isWhitelisted = true;
            info.isPaused = false;

            unchecked {
                info.index = uint8(currentLength + i);
            }

            _whitelistedTokens.push(token);

            emit TokenWhitelisted(token);

            unchecked {
                ++i;
            }
        }
    }

    function pauseTokens(
        address[] calldata tokens,
        string calldata reason
    ) external onlyOwner {
        uint256 length = tokens.length;

        for (uint256 i = 0; i < length; ) {
            address token = tokens[i];
            TokenInfo storage info = _tokenInfo[token];

            if (!info.isWhitelisted) revert TokenNotWhitelisted();

            info.isPaused = true;
            emit TokenPaused(token, reason);

            unchecked {
                ++i;
            }
        }
    }

    function unpauseTokens(address[] calldata tokens) external onlyOwner {
        uint256 length = tokens.length;

        for (uint256 i = 0; i < length; ) {
            address token = tokens[i];
            TokenInfo storage info = _tokenInfo[token];

            if (!info.isWhitelisted) revert TokenNotWhitelisted();

            info.isPaused = false;
            emit TokenUnpaused(token);

            unchecked {
                ++i;
            }
        }
    }

    function getTokenInfo(
        address token
    ) external view returns (bool whitelisted, bool paused, uint8 index) {
        TokenInfo storage info = _tokenInfo[token];
        return (info.isWhitelisted, info.isPaused, info.index);
    }
}
