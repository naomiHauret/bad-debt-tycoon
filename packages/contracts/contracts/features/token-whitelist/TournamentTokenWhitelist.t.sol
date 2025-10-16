// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {TournamentTokenWhitelist} from "./TournamentTokenWhitelist.sol";
import {MockERC20} from "../../mocks/MockERC20.sol";

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
        whitelist = new TournamentTokenWhitelist(owner);

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
        address[] memory tokens = whitelist.getWhitelistedTokens();
        assertEq(tokens.length, 0);
    }

    // Case: Adding token
    // Platform runner can add a token to the whitelist
    function test_OwnerCanAddToken() public {
        whitelist.addToken(address(pyusd));

        assertTrue(whitelist.isWhitelisted(address(pyusd)));
        assertEq(whitelist.getWhitelistedTokenCount(), 1);
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

        address[] memory tokens = whitelist.getWhitelistedTokens();
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

        vm.expectRevert(
            TournamentTokenWhitelist.TokenAlreadyWhitelisted.selector
        );
        whitelist.addToken(address(pyusd));
    }

    // Hell is not a valid token address :)
    function test_RevertWhen_AddingZeroAddress() public {
        vm.expectRevert(TournamentTokenWhitelist.InvalidTokenAddress.selector);
        whitelist.addToken(address(0));
    }

    // Case: removing tokens from the whitelis
    // The platform runner can remove a whitelisted token from the whitelist
    function test_OwnerCanRemoveToken() public {
        whitelist.addToken(address(pyusd));
        whitelist.removeToken(address(pyusd));

        assertFalse(whitelist.isWhitelisted(address(pyusd)));
        assertEq(whitelist.getWhitelistedTokenCount(), 0);
    }

    // When a token is removed from the whitelist, contract emits `TokenRemovedFromWhitelist`
    function test_RemoveTokenEmitsEvent() public {
        whitelist.addToken(address(pyusd));

        // Check that the token address in the emitted event MUST be the USDC address
        vm.expectEmit(true, false, false, false);
        emit TournamentTokenWhitelist.TokenRemovedFromWhitelist(address(pyusd));

        whitelist.removeToken(address(pyusd));
    }

    // When a token is removed from the whitelist, other tokens are still accessible
    function test_RemoveTokenMaintainsArrayIntegrity() public {
        whitelist.addToken(address(usdc));
        whitelist.addToken(address(pyusd));
        whitelist.addToken(address(gho));

        whitelist.removeToken(address(pyusd));

        assertEq(whitelist.getWhitelistedTokenCount(), 2);
        assertTrue(whitelist.isWhitelisted(address(usdc)));
        assertTrue(whitelist.isWhitelisted(address(gho)));
        assertFalse(whitelist.isWhitelisted(address(pyusd)));
    }

    // Only the platform runner can edit the whitelist
    function test_RevertWhen_NonOwnerTriesToRemoveToken() public {
        whitelist.addToken(address(pyusd));

        vm.prank(nonOwner);
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                nonOwner
            )
        );
        whitelist.removeToken(address(pyusd));
    }

    // Only existing whitelisted tokens can be removed from the whitelist
    function test_RevertWhen_RemovingNonWhitelistedToken() public {
        vm.expectRevert(TournamentTokenWhitelist.TokenNotWhitelisted.selector);
        whitelist.removeToken(address(pyusd));
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

    function test_GetWhitelistedTokensReturnsAllTokens() public {
        whitelist.addToken(address(pyusd));
        whitelist.addToken(address(usdc));

        address[] memory tokens = whitelist.getWhitelistedTokens();
        assertEq(tokens.length, 2);
        assertEq(tokens[0], address(pyusd));
        assertEq(tokens[1], address(usdc));
    }

    function test_GetWhitelistedTokenCountReturnsCorrectCount() public {
        assertEq(whitelist.getWhitelistedTokenCount(), 0);

        whitelist.addToken(address(pyusd));
        assertEq(whitelist.getWhitelistedTokenCount(), 1);

        whitelist.addToken(address(usdc));
        assertEq(whitelist.getWhitelistedTokenCount(), 2);

        whitelist.removeToken(address(usdc));
        assertEq(whitelist.getWhitelistedTokenCount(), 1);
    }

    // Verify token whitelist status is up-to-date after adding/removing it
    function test_AddAndRemoveToken(address token) public {
        // Skip zero address
        vm.assume(token != address(0));

        // Add token
        whitelist.addToken(token);
        assertTrue(whitelist.isWhitelisted(token));

        // Remove token
        whitelist.removeToken(token);
        assertFalse(whitelist.isWhitelisted(token));
    }

    function test_MultipleTokenOperations(
        address token1,
        address token2,
        address token3
    ) public {
        // Ensure unique non-zero addresses
        vm.assume(token1 != address(0));
        vm.assume(token2 != address(0));
        vm.assume(token3 != address(0));
        vm.assume(token1 != token2);
        vm.assume(token2 != token3);
        vm.assume(token1 != token3);

        // Add all tokens
        whitelist.addToken(token1);
        whitelist.addToken(token2);
        whitelist.addToken(token3);

        assertEq(whitelist.getWhitelistedTokenCount(), 3);

        // Remove one
        whitelist.removeToken(token2);
        assertEq(whitelist.getWhitelistedTokenCount(), 2);
        assertFalse(whitelist.isWhitelisted(token2));
        assertTrue(whitelist.isWhitelisted(token1));
        assertTrue(whitelist.isWhitelisted(token3));
    }
}
