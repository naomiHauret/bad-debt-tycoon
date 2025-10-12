// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {TournamentRegistry} from "./TournamentRegistry.sol";

contract TournamentRegistryTest is Test {
    TournamentRegistry public registry;

    address public owner;
    address public factory;
    address public nonFactory;
    address public tournament1;
    address public tournament2;
    address public tournament3;

    function setUp() public {
        owner = address(this);
        factory = address(0x1);
        nonFactory = address(0x2);
        tournament1 = address(0x3);
        tournament2 = address(0x4);
        tournament3 = address(0x5);

        // Deploy registry
        registry = new TournamentRegistry();
    }

    // Ensure platform runner is deployer address (contract owner)
    function test_DeploymentSetsCorrectOwner() public view {
        assertEq(registry.owner(), owner);
    }

    function test_DeploymentInitializesEmptyRegistry() public view {
        address[] memory tournaments = registry.getAllTournaments();
        assertEq(tournaments.length, 0);
    }

    // - Role management -
    // The registry needs to control who can add tournaments to avoid malicious entries.
    // So we "issue"/"grant" the role of "factory" to a trusted factory contract (ours).

    // Ensure only the platform runner can grant the factory role
    function test_OwnerCanGrantFactoryRole() public {
        registry.grantFactoryRole(factory);
        assertTrue(registry.hasFactoryRole(factory));
    }

    // Verify events are emitted properly (factory role granted)
    function test_GrantFactoryRoleEmitsEvent() public {
        vm.expectEmit(true, false, false, false);
        emit TournamentRegistry.FactoryRoleGranted(factory);

        registry.grantFactoryRole(factory);
    }

    // Verify events are emitted properly (factory role revoked)
    function test_RevokeFactoryRoleEmitsEvent() public {
        registry.grantFactoryRole(factory);

        // the contract address (previously with a factory role)
        // in the emitted event MUST match factory
        vm.expectEmit(true, false, false, false);
        emit TournamentRegistry.FactoryRoleRevoked(factory);

        registry.revokeFactoryRole(factory);
    }

    // Only the platform runner should be able to grant/revoke the factory role
    function test_OwnerCanRevokeFactoryRole() public {
        registry.grantFactoryRole(factory);
        registry.revokeFactoryRole(factory);

        assertFalse(registry.hasFactoryRole(factory));
    }

    function test_RevertWhen_NonOwnerTriesToGrantFactoryRole() public {
        vm.prank(nonFactory);
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                nonFactory
            )
        );
        registry.grantFactoryRole(factory);
    }

    function test_RevertWhen_NonOwnerTriesToRevokeFactoryRole() public {
        registry.grantFactoryRole(factory);

        vm.prank(nonFactory);
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                nonFactory
            )
        );
        registry.revokeFactoryRole(factory);
    }

    // No, the contract address of hell can't be a tournament factory
    function test_RevertWhen_GrantingFactoryRoleToZeroAddress() public {
        vm.expectRevert(TournamentRegistry.InvalidAddress.selector);
        registry.grantFactoryRole(address(0));
    }

    // Tournament registration

    // Ensure factory can create and track tournaments
    function test_FactoryCanRegisterTournament() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournament(tournament1);

        address[] memory tournaments = registry.getAllTournaments();
        assertEq(tournaments.length, 1);
        assertEq(tournaments[0], tournament1);
    }

    // Ensure creating a tournament emits the proper event `TournamentRegistered`
    function test_RegisterTournamentEmitsEvent() public {
        registry.grantFactoryRole(factory);

        // The tournament must have tournament1 address as its value
        // it must also have Open as its status
        vm.expectEmit(true, true, false, false);
        emit TournamentRegistry.TournamentRegistered(
            tournament1,
            TournamentRegistry.TournamentStatus.Open
        );

        vm.prank(factory);
        registry.registerTournament(tournament1);
    }

    // Ensure that when the factory creates a tournament, the tournament status is "Open"
    function test_RegisterTournamentInitializesWithOpenStatus() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournament(tournament1);
        assertEq(
            registry.getTournamentStatus(tournament1),
            uint8(TournamentRegistry.TournamentStatus.Open)
        );
    }

    // Ensure the factory can run create and track multiple tournaments
    function test_FactoryCanRegisterMultipleTournaments() public {
        registry.grantFactoryRole(factory);

        vm.startPrank(factory);
        registry.registerTournament(tournament1);
        registry.registerTournament(tournament2);
        registry.registerTournament(tournament3);
        vm.stopPrank();

        address[] memory tournaments = registry.getAllTournaments();
        assertEq(tournaments.length, 3);
    }

    // Ensure only OUR factories can create Bad Debt Tycoon tournaments
    function test_RevertWhen_NonFactoryTriesToRegisterTournament() public {
        vm.prank(nonFactory);
        vm.expectRevert(TournamentRegistry.OnlyFactory.selector);
        registry.registerTournament(tournament1);
    }

    // Ensure the address of hell cannot be used when registering a tournament address
    function test_RevertWhen_RegisteringZeroAddress() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        vm.expectRevert(TournamentRegistry.InvalidAddress.selector);
        registry.registerTournament(address(0));
    }

    // Ensure the factory can't track the same tournament multiple times
    function test_RevertWhen_RegisteringAlreadyRegisteredTournament() public {
        registry.grantFactoryRole(factory);

        vm.startPrank(factory);
        registry.registerTournament(tournament1);

        vm.expectRevert(
            TournamentRegistry.TournamentAlreadyRegistered.selector
        );
        registry.registerTournament(tournament1);
        vm.stopPrank();
    }

    // Tournament status updates
    // Ensure a tournament contract can upate its status by itself
    // and that status change is tracked by the factory
    function test_TournamentCanUpdateItsOwnStatus() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournament(tournament1);

        // Tournament updates its own status
        vm.prank(tournament1);
        registry.updateTournamentStatus(
            TournamentRegistry.TournamentStatus.Active
        );

        assertEq(
            registry.getTournamentStatus(tournament1),
            uint8(TournamentRegistry.TournamentStatus.Active)
        );
    }

    // Check that a tournament status change emits the appropriate TournamentStatusUpdated event
    function test_UpdateStatusEmitsEvent() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournament(tournament1);
        // It must be the tournament with contract address = tournament1
        // the previous status must be open
        // the new status must be active
        vm.expectEmit(true, true, true, false);
        emit TournamentRegistry.TournamentStatusUpdated(
            tournament1,
            TournamentRegistry.TournamentStatus.Open,
            TournamentRegistry.TournamentStatus.Active
        );

        vm.prank(tournament1);
        registry.updateTournamentStatus(
            TournamentRegistry.TournamentStatus.Active
        );
    }

    function test_CanUpdateThroughAllStatuses() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournament(tournament1);

        // Open -> Active
        vm.prank(tournament1);
        registry.updateTournamentStatus(
            TournamentRegistry.TournamentStatus.Active
        );
        assertEq(
            registry.getTournamentStatus(tournament1),
            uint8(TournamentRegistry.TournamentStatus.Active)
        );

        // Active -> Ended
        vm.prank(tournament1);
        registry.updateTournamentStatus(
            TournamentRegistry.TournamentStatus.Ended
        );
        assertEq(
            registry.getTournamentStatus(tournament1),
            uint8(TournamentRegistry.TournamentStatus.Ended)
        );
    }

    // Ensure only tournament contracts can update their own status
    function test_RevertWhen_NonTournamentTriesToUpdateStatus() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournament(tournament1);

        vm.prank(nonFactory);
        vm.expectRevert(TournamentRegistry.TournamentNotRegistered.selector);
        registry.updateTournamentStatus(
            TournamentRegistry.TournamentStatus.Active
        );
    }

    // Checks that the registry can't update the status of an untracked tournament
    function test_RevertWhen_UnregisteredTournamentTriesToUpdateStatus()
        public
    {
        vm.prank(tournament1);
        vm.expectRevert(TournamentRegistry.TournamentNotRegistered.selector);
        registry.updateTournamentStatus(
            TournamentRegistry.TournamentStatus.Active
        );
    }

    // - Query
    // Get all registered tournaments
    function test_GetAllTournamentsReturnsAllRegistered() public {
        registry.grantFactoryRole(factory);

        vm.startPrank(factory);
        registry.registerTournament(tournament1);
        registry.registerTournament(tournament2);
        vm.stopPrank();

        address[] memory tournaments = registry.getAllTournaments();
        assertEq(tournaments.length, 2);
        assertEq(tournaments[0], tournament1);
        assertEq(tournaments[1], tournament2);
    }

    function test_GetTournamentsByStatusFiltersCorrectly() public {
        registry.grantFactoryRole(factory);

        // Register multiple tournaments
        vm.startPrank(factory);
        registry.registerTournament(tournament1);
        registry.registerTournament(tournament2);
        registry.registerTournament(tournament3);
        vm.stopPrank();

        // Update some to Active status
        vm.prank(tournament1);
        registry.updateTournamentStatus(
            TournamentRegistry.TournamentStatus.Active
        );

        vm.prank(tournament2);
        registry.updateTournamentStatus(
            TournamentRegistry.TournamentStatus.Active
        );

        // Query by status
        address[] memory openTournaments = registry.getTournamentsByStatus(
            TournamentRegistry.TournamentStatus.Open
        );
        address[] memory activeTournaments = registry.getTournamentsByStatus(
            TournamentRegistry.TournamentStatus.Active
        );

        assertEq(openTournaments.length, 1);
        assertEq(openTournaments[0], tournament3);

        assertEq(activeTournaments.length, 2);
        assertEq(activeTournaments[0], tournament1);
        assertEq(activeTournaments[1], tournament2);
    }

    // Verifies that tournaments can be tracked by their status
    function test_GetTournamentStatusReturnsCorrectStatus() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournament(tournament1);

        assertEq(
            registry.getTournamentStatus(tournament1),
            uint8(TournamentRegistry.TournamentStatus.Open)
        );

        vm.prank(tournament1);
        registry.updateTournamentStatus(
            TournamentRegistry.TournamentStatus.Active
        );

        assertEq(
            registry.getTournamentStatus(tournament1),
            uint8(TournamentRegistry.TournamentStatus.Active)
        );
    }

    // Verifies that tournaments are tracked properly (tournament exists once created)
    function test_IsTournamentRegisteredReturnsCorrectValue() public {
        assertFalse(registry.isTournamentRegistered(tournament1));

        registry.grantFactoryRole(factory);
        vm.prank(factory);
        registry.registerTournament(tournament1);

        assertTrue(registry.isTournamentRegistered(tournament1));
    }

    // Verifies that tournaments are tracked properly (list size updates when tournament is created)
    function test_GetTournamentCountReturnsCorrectCount() public {
        assertEq(registry.getTournamentCount(), 0);

        registry.grantFactoryRole(factory);

        vm.startPrank(factory);
        registry.registerTournament(tournament1);
        assertEq(registry.getTournamentCount(), 1);

        registry.registerTournament(tournament2);
        assertEq(registry.getTournamentCount(), 2);
        vm.stopPrank();
    }

    function test_RegisterAndQueryTournament(address tournament) public {
        vm.assume(tournament != address(0));

        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournament(tournament);

        assertTrue(registry.isTournamentRegistered(tournament));
        assertEq(
            registry.getTournamentStatus(tournament),
            uint8(TournamentRegistry.TournamentStatus.Open)
        );
    }

    // Tournament can update its status
    function test_TournamentCanUpdateStatus(
        address tournament,
        uint8 statusValue
    ) public {
        vm.assume(tournament != address(0));
        vm.assume(
            statusValue <= uint8(TournamentRegistry.TournamentStatus.Cancelled)
        );

        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournament(tournament);

        vm.prank(tournament);
        registry.updateTournamentStatus(
            TournamentRegistry.TournamentStatus(statusValue)
        );

        assertEq(registry.getTournamentStatus(tournament), statusValue);
    }
}
