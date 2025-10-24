// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {TournamentTokenWhitelist} from "./TournamentTokenWhitelist.sol";
import {MockERC20} from "./../../../mocks/MockERC20.sol";

contract TournamentTokenWhitelistTest is Test {
    TournamentTokenWhitelist public whitelist;
    MockERC20 public usdc;
    MockERC20 public pyusd;
    MockERC20 public gho;

    address public owner;
    address public nonOwner;

    function setUp() public {
        owner = address(this);
        nonOwner = address(0x1);

        // Deploy whitelist
        whitelist = new TournamentTokenWhitelist();

        // Deploy mock tokens
        usdc = new MockERC20("USD Coin", "USDC", 6);
        pyusd = new MockERC20("PayPal USD", "PYUSD", 6);
        gho = new MockERC20("GHO", "GHO", 18);
    }

    // Case: Initialization
    // Ensure the platform runner (deployer address) is the owner
    function test_DeploymentSetsCorrectOwner() public view {
        assertEq(whitelist.owner(), owner);
    }

    // Ensure the whitelist is empty when created
    function test_DeploymentInitializesEmptyWhitelist() public view {
        address[] memory tokens = whitelist.getTokens();
        assertEq(tokens.length, 0);
    }

    // Case: Adding token
    // Platform runner can add a token to the whitelist
    function test_OwnerCanAddToken() public {
        whitelist.addToken(address(pyusd));

        assertTrue(whitelist.isWhitelisted(address(pyusd)));
        assertEq(whitelist.getTokenCount(), 1);
    }

    // When a token is added to the whitelist, an `TokenWhitelisted` event is emited
    function test_AddTokenEmitsEvent() public {
        // Check that the token address in the emitted event MUST be PYUSD contract address
        vm.expectEmit(true, false, false, false);
        emit TournamentTokenWhitelist.TokenWhitelisted(address(pyusd));

        whitelist.addToken(address(pyusd));
    }

    // Platform runner can add multiple tokens to the whitelist
    function test_OwnerCanAddMultipleTokens() public {
        whitelist.addToken(address(usdc));
        whitelist.addToken(address(pyusd));
        whitelist.addToken(address(gho));

        address[] memory tokens = whitelist.getTokens();
        assertEq(tokens.length, 3);
        assertTrue(whitelist.isWhitelisted(address(usdc)));
        assertTrue(whitelist.isWhitelisted(address(pyusd)));
        assertTrue(whitelist.isWhitelisted(address(gho)));
    }

    // Ensure that only the platform runner can add tokens to the whitelist
    function test_RevertWhen_NonOwnerTriesToAddToken() public {
        vm.prank(nonOwner);
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                nonOwner
            )
        );
        whitelist.addToken(address(pyusd));
    }

    // Ensure that a token that's already in the whitelist can't be added again
    function test_RevertWhen_AddingAlreadyWhitelistedToken() public {
        whitelist.addToken(address(pyusd));

        vm.expectRevert(TournamentTokenWhitelist.AlreadyExists.selector);
        whitelist.addToken(address(pyusd));
    }

    // Hell is not a valid token address :)
    function test_RevertWhen_AddingZeroAddress() public {
        vm.expectRevert(TournamentTokenWhitelist.InvalidTokenAddress.selector);
        whitelist.addToken(address(0));
    }

    // Case: pausing
    // Platform runner can pause a whitelisted token
    function test_OwnerCanPauseToken() public {
        whitelist.addToken(address(pyusd));

        whitelist.pauseToken(address(pyusd), "Security incident detected");

        assertTrue(whitelist.isPaused(address(pyusd)));
        assertTrue(whitelist.isTokenRegistered(address(pyusd)));
        assertFalse(whitelist.isWhitelisted(address(pyusd))); // isWhitelisted returns false for paused
    }

    // When a token is paused, contract emits `TokenPaused` with reason
    function test_PauseTokenEmitsEvent() public {
        whitelist.addToken(address(pyusd));

        vm.expectEmit(true, false, false, true);
        emit TournamentTokenWhitelist.TokenPaused(
            address(pyusd),
            "PYUSD minting exploit"
        );

        whitelist.pauseToken(address(pyusd), "PYUSD minting exploit");
    }

    // Platform runner can unpause a paused token
    function test_OwnerCanUnpauseToken() public {
        whitelist.addToken(address(pyusd));
        whitelist.pauseToken(address(pyusd), "Test");

        whitelist.unpauseToken(address(pyusd));

        assertFalse(whitelist.isPaused(address(pyusd)));
        assertTrue(whitelist.isWhitelisted(address(pyusd)));
        assertTrue(whitelist.isTokenRegistered(address(pyusd)));
    }

    // When a token is unpaused, contract emits `TokenUnpaused`
    function test_UnpauseTokenEmitsEvent() public {
        whitelist.addToken(address(pyusd));
        whitelist.pauseToken(address(pyusd), "Test");

        vm.expectEmit(true, false, false, false);
        emit TournamentTokenWhitelist.TokenUnpaused(address(pyusd));

        whitelist.unpauseToken(address(pyusd));
    }

    // Cannot pause a token that isn't whitelisted
    function test_RevertWhen_PausingNonWhitelistedToken() public {
        vm.expectRevert(TournamentTokenWhitelist.NotFound.selector);
        whitelist.pauseToken(address(pyusd), "Invalid operation");
    }

    // Cannot unpause a token that isn't whitelisted
    function test_RevertWhen_UnpausingNonWhitelistedToken() public {
        vm.expectRevert(TournamentTokenWhitelist.NotFound.selector);
        whitelist.unpauseToken(address(pyusd));
    }

    // Only owner can pause tokens
    function test_RevertWhen_NonOwnerTriesToPauseToken() public {
        whitelist.addToken(address(pyusd));

        vm.prank(nonOwner);
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                nonOwner
            )
        );
        whitelist.pauseToken(address(pyusd), "Unauthorized pause attempt");
    }

    // Only owner can unpause tokens
    function test_RevertWhen_NonOwnerTriesToUnpauseToken() public {
        whitelist.addToken(address(pyusd));
        whitelist.pauseToken(address(pyusd), "Test");

        vm.prank(nonOwner);
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                nonOwner
            )
        );
        whitelist.unpauseToken(address(pyusd));
    }

    // Pausing doesn't affect other tokens
    function test_PauseTokenDoesNotAffectOtherTokens() public {
        whitelist.addToken(address(usdc));
        whitelist.addToken(address(pyusd));
        whitelist.addToken(address(gho));

        whitelist.pauseToken(address(pyusd), "PYUSD issue");

        assertTrue(whitelist.isWhitelisted(address(usdc)));
        assertFalse(whitelist.isWhitelisted(address(pyusd)));
        assertTrue(whitelist.isWhitelisted(address(gho)));

        assertTrue(whitelist.isPaused(address(pyusd)));
        assertFalse(whitelist.isPaused(address(usdc)));
        assertFalse(whitelist.isPaused(address(gho)));
    }

    // Can pause and unpause the same token multiple times
    function test_CanPauseAndUnpauseMultipleTimes() public {
        whitelist.addToken(address(pyusd));

        // First pause cycle
        whitelist.pauseToken(address(pyusd), "Issue 1");
        assertTrue(whitelist.isPaused(address(pyusd)));

        whitelist.unpauseToken(address(pyusd));
        assertFalse(whitelist.isPaused(address(pyusd)));

        // Second pause cycle
        whitelist.pauseToken(address(pyusd), "Issue 2");
        assertTrue(whitelist.isPaused(address(pyusd)));

        whitelist.unpauseToken(address(pyusd));
        assertFalse(whitelist.isPaused(address(pyusd)));
    }

    // Case: data querying
    function test_IsWhitelistedReturnsFalseForNonWhitelistedToken()
        public
        view
    {
        assertFalse(whitelist.isWhitelisted(address(pyusd)));
    }

    function test_IsWhitelistedReturnsTrueForWhitelistedToken() public {
        whitelist.addToken(address(pyusd));
        assertTrue(whitelist.isWhitelisted(address(pyusd)));
    }

    function test_IsWhitelistedReturnsFalseForPausedToken() public {
        whitelist.addToken(address(pyusd));
        whitelist.pauseToken(address(pyusd), "Paused for testing");

        assertFalse(whitelist.isWhitelisted(address(pyusd)));
    }

    function test_IsTokenRegisteredReturnsTrueForPausedToken() public {
        whitelist.addToken(address(pyusd));
        whitelist.pauseToken(address(pyusd), "Test");

        assertTrue(whitelist.isTokenRegistered(address(pyusd)));
    }

    function test_IsPausedReturnsFalseForActiveToken() public {
        whitelist.addToken(address(pyusd));
        assertFalse(whitelist.isPaused(address(pyusd)));
    }

    function test_GetWhitelistedTokensReturnsAllTokens() public {
        whitelist.addToken(address(pyusd));
        whitelist.addToken(address(usdc));

        address[] memory tokens = whitelist.getTokens();
        assertEq(tokens.length, 2);
        assertEq(tokens[0], address(pyusd));
        assertEq(tokens[1], address(usdc));
    }

    function test_GetWhitelistedTokenCountReturnsCorrectCount() public {
        assertEq(whitelist.getTokenCount(), 0);

        whitelist.addToken(address(pyusd));
        assertEq(whitelist.getTokenCount(), 1);

        whitelist.addToken(address(usdc));
        assertEq(whitelist.getTokenCount(), 2);
    }

    function test_GetWhitelistedTokensIncludesPausedTokens() public {
        whitelist.addToken(address(usdc));
        whitelist.addToken(address(pyusd));
        whitelist.pauseToken(address(pyusd), "Test");

        address[] memory tokens = whitelist.getTokens();
        assertEq(tokens.length, 2);
    }

    function test_GetWhitelistedTokenCountUnaffectedByPause() public {
        whitelist.addToken(address(usdc));
        whitelist.addToken(address(pyusd));

        assertEq(whitelist.getTokenCount(), 2);

        whitelist.pauseToken(address(pyusd), "Test");
        assertEq(whitelist.getTokenCount(), 2);
    }

    function testFuzz_PauseAndUnpauseToken(address token) public {
        vm.assume(token != address(0));

        whitelist.addToken(token);
        assertTrue(whitelist.isWhitelisted(token));

        whitelist.pauseToken(token, "Fuzz test pause");
        assertFalse(whitelist.isWhitelisted(token));
        assertTrue(whitelist.isTokenRegistered(token));
        assertTrue(whitelist.isPaused(token));

        whitelist.unpauseToken(token);
        assertTrue(whitelist.isWhitelisted(token));
        assertFalse(whitelist.isPaused(token));
    }
}
