// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {TournamentCore} from "./../../core/TournamentCore.sol";
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

    // Platform runner should be deployer address (contract owner)
    function test_DeploymentSetsCorrectOwner() public view {
        assertEq(registry.owner(), owner);
    }

    // Registry should be empty post creation
    function test_DeploymentInitializesEmptyRegistry() public view {
        address[] memory tournaments = registry.getAllTournaments();
        assertEq(tournaments.length, 0);
    }

    // - Role management -
    // The registry needs to control who can add tournaments to avoid malicious entries.
    // So we "issue"/"grant" the role of "factory" to a trusted factory contract (ours).

    // Only platform runner can grant the factory role
    function test_OwnerCanGrantFactoryRole() public {
        registry.grantFactoryRole(factory);
        assertTrue(registry.hasFactoryRole(factory));
    }

    // grantFactoryRole() should emit `FactoryRoleGranted` event
    function test_GrantFactoryRoleEmitsEvent() public {
        vm.expectEmit(true, false, false, false);
        emit TournamentRegistry.FactoryRoleGranted(factory);

        registry.grantFactoryRole(factory);
    }

    // revokeFactoryRole() should emit `FactoryRoleRevoked` event
    function test_RevokeFactoryRoleEmitsEvent() public {
        registry.grantFactoryRole(factory);

        // the contract address (previously with a factory role)
        // in the emitted event MUST match factory
        vm.expectEmit(true, false, false, false);
        emit TournamentRegistry.FactoryRoleRevoked(factory);

        registry.revokeFactoryRole(factory);
    }

    // Registry should be able to revoke factory role
    function test_OwnerCanRevokeFactoryRole() public {
        registry.grantFactoryRole(factory);
        registry.revokeFactoryRole(factory);

        assertFalse(registry.hasFactoryRole(factory));
    }

    // Should revert when non owner tries to grant factory role
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

    // Should revert when non-owner tries to revoke factory role
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

    // hasFactoryRole() should return false after revokeFactoryRole()
    function test_RevokingNeverGrantedFactoryRole() public {
        registry.revokeFactoryRole(factory);
        assertFalse(registry.hasFactoryRole(factory));
    }

    // Granting factory role 2x in a row shouldn't error/change anything
    function test_GrantingFactoryRoleTwice() public {
        registry.grantFactoryRole(factory);
        registry.grantFactoryRole(factory);
        assertTrue(registry.hasFactoryRole(factory));
    }

    // Trying to change tournament status to same status
    // in registry shouldn't error/change anything
    function test_UpdatingToSameStatusDoesNothing() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournament(tournament1);

        vm.prank(tournament1);
        registry.updateTournamentStatus(TournamentCore.Status.Open);

        assertEq(
            registry.getTournamentStatus(tournament1),
            uint8(TournamentCore.Status.Open)
        );
    }

    // Vetted registry should be able to register and track tournaments
    function test_FactoryCanRegisterTournament() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournament(tournament1);

        address[] memory tournaments = registry.getAllTournaments();
        assertEq(tournaments.length, 1);
        assertEq(tournaments[0], tournament1);
    }

    // registerTournament() should emit `TournamentRegistered` event
    function test_RegisterTournamentEmitsEvent() public {
        registry.grantFactoryRole(factory);

        // The tournament must have tournament1 address as its value
        // it must also have Open as its status
        vm.expectEmit(true, true, false, false);
        emit TournamentRegistry.TournamentRegistered(
            tournament1,
            TournamentCore.Status.Open
        );

        vm.prank(factory);
        registry.registerTournament(tournament1);
    }

    // When tracked in the registry for the first time, tracked tournament status is "Open"
    function test_RegisterTournamentInitializesWithOpenStatus() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournament(tournament1);
        assertEq(
            registry.getTournamentStatus(tournament1),
            uint8(TournamentCore.Status.Open)
        );
    }

    // Registry should be able to register and track multiple tournaments
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

    // Ensure only addresses with factory role can register tournaments
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

        vm.expectRevert(TournamentRegistry.AlreadyRegistered.selector);
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
        registry.updateTournamentStatus(TournamentCore.Status.Active);

        assertEq(
            registry.getTournamentStatus(tournament1),
            uint8(TournamentCore.Status.Active)
        );
    }

    // Tournament status change should emit the TournamentStatusUpdated event with accurate former -> new
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
            TournamentCore.Status.Open,
            TournamentCore.Status.Active
        );

        vm.prank(tournament1);
        registry.updateTournamentStatus(TournamentCore.Status.Active);
    }

    // Ensure only tournament contracts can update their own status
    function test_RevertWhen_NonTournamentTriesToUpdateStatus() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournament(tournament1);

        vm.prank(nonFactory);
        vm.expectRevert(TournamentRegistry.NotRegistered.selector);
        registry.updateTournamentStatus(TournamentCore.Status.Active);
    }

    // Checks that the registry can't update the status of an untracked tournament
    function test_RevertWhen_UnregisteredTournamentTriesToUpdateStatus()
        public
    {
        vm.prank(tournament1);
        vm.expectRevert(TournamentRegistry.NotRegistered.selector);
        registry.updateTournamentStatus(TournamentCore.Status.Active);
    }

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
        registry.updateTournamentStatus(TournamentCore.Status.Active);

        vm.prank(tournament2);
        registry.updateTournamentStatus(TournamentCore.Status.Active);

        // Query by status
        address[] memory openTournaments = registry.getTournamentsByStatus(
            TournamentCore.Status.Open
        );
        address[] memory activeTournaments = registry.getTournamentsByStatus(
            TournamentCore.Status.Active
        );

        assertEq(openTournaments.length, 1);
        assertEq(openTournaments[0], tournament3);

        assertEq(activeTournaments.length, 2);
        assertEq(activeTournaments[0], tournament1);
        assertEq(activeTournaments[1], tournament2);
    }

    // Verifies that tracked tournaments status changes are reflected
    // in registry when queried
    function test_GetTournamentStatusReturnsCorrectStatus() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournament(tournament1);

        assertEq(
            registry.getTournamentStatus(tournament1),
            uint8(TournamentCore.Status.Open)
        );

        vm.prank(tournament1);
        registry.updateTournamentStatus(TournamentCore.Status.Active);

        assertEq(
            registry.getTournamentStatus(tournament1),
            uint8(TournamentCore.Status.Active)
        );
    }

    // Verifies that tournaments are tracked properly
    // (tournament exists once created)
    function test_IsTournamentRegisteredReturnsCorrectValue() public {
        assertFalse(registry.isTournamentRegistered(tournament1));

        registry.grantFactoryRole(factory);
        vm.prank(factory);
        registry.registerTournament(tournament1);

        assertTrue(registry.isTournamentRegistered(tournament1));
    }

    // Verifies that tournaments are tracked properly
    // (list size updates when tournament is created)
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

    // Should return 0 when querying for existing status with 0 tracked tournaments
    function test_GetTournamentsByStatusReturnsEmptyArray() public {
        address[] memory activeTournaments = registry.getTournamentsByStatus(
            TournamentCore.Status.Active
        );

        assertEq(activeTournaments.length, 0);
    }

    // Should be able to track different status transitions of different tracked tournaments
    function test_ComplexStatusTransitions() public {
        registry.grantFactoryRole(factory);

        vm.startPrank(factory);
        registry.registerTournament(tournament1);
        registry.registerTournament(tournament2);
        registry.registerTournament(tournament3);
        vm.stopPrank();

        // tournament1: Open -> Active -> Ended
        vm.prank(tournament1);
        registry.updateTournamentStatus(TournamentCore.Status.Active);
        vm.prank(tournament1);
        registry.updateTournamentStatus(TournamentCore.Status.Ended);

        // tournament2: Open -> Cancelled
        vm.prank(tournament2);
        registry.updateTournamentStatus(TournamentCore.Status.Cancelled);

        // tournament3: stays Open

        assertEq(
            registry.getTournamentsByStatus(TournamentCore.Status.Open).length,
            1
        );
        assertEq(
            registry
                .getTournamentsByStatus(TournamentCore.Status.Active)
                .length,
            0
        );
        assertEq(
            registry.getTournamentsByStatus(TournamentCore.Status.Ended).length,
            1
        );
        assertEq(
            registry
                .getTournamentsByStatus(TournamentCore.Status.Cancelled)
                .length,
            1
        );

        assertEq(registry.getTournamentCount(), 3);
    }

    // Should be able to update registered tournament status to "Open"
    function test_UpdateToOpenStatus() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournament(tournament1);

        vm.prank(tournament1);
        assertEq(
            registry.getTournamentStatus(tournament1),
            uint8(TournamentCore.Status.Open)
        );

        vm.prank(tournament1);
        registry.updateTournamentStatus(TournamentCore.Status.Locked);

        assertEq(
            registry.getTournamentStatus(tournament1),
            uint8(TournamentCore.Status.Locked)
        );

        vm.prank(tournament1);
        registry.updateTournamentStatus(TournamentCore.Status.Open);

        assertEq(
            registry.getTournamentStatus(tournament1),
            uint8(TournamentCore.Status.Open)
        );
    }

    // Should be able to update registered tournament status to "PendingStart"
    function test_UpdateToPendingStartStatus() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournament(tournament1);

        vm.prank(tournament1);
        assertEq(
            registry.getTournamentStatus(tournament1),
            uint8(TournamentCore.Status.Open)
        );

        vm.prank(tournament1);
        registry.updateTournamentStatus(TournamentCore.Status.PendingStart);

        assertEq(
            registry.getTournamentStatus(tournament1),
            uint8(TournamentCore.Status.PendingStart)
        );
    }

    // Should be able to update registered tournament status to "Active"
    function test_UpdateToActiveStatus() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournament(tournament1);

        vm.prank(tournament1);
        assertEq(
            registry.getTournamentStatus(tournament1),
            uint8(TournamentCore.Status.Open)
        );

        vm.prank(tournament1);
        registry.updateTournamentStatus(TournamentCore.Status.Active);

        assertEq(
            registry.getTournamentStatus(tournament1),
            uint8(TournamentCore.Status.Active)
        );
    }

    // Should be able to update registered tournament status to "Ended"
    function test_UpdateToEndedStatus() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournament(tournament1);

        vm.prank(tournament1);
        assertEq(
            registry.getTournamentStatus(tournament1),
            uint8(TournamentCore.Status.Open)
        );

        vm.prank(tournament1);
        registry.updateTournamentStatus(TournamentCore.Status.Ended);

        assertEq(
            registry.getTournamentStatus(tournament1),
            uint8(TournamentCore.Status.Ended)
        );
    }

    // Should be able to update registered tournament status to "Locked"
    function test_UpdateToLockedStatus() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournament(tournament1);

        vm.prank(tournament1);
        assertEq(
            registry.getTournamentStatus(tournament1),
            uint8(TournamentCore.Status.Open)
        );

        vm.prank(tournament1);
        registry.updateTournamentStatus(TournamentCore.Status.Locked);

        assertEq(
            registry.getTournamentStatus(tournament1),
            uint8(TournamentCore.Status.Locked)
        );
    }

    // Should be able to update registered tournament status to "Cancelled"
    function test_UpdateToCancelledStatus() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournament(tournament1);

        vm.prank(tournament1);
        assertEq(
            registry.getTournamentStatus(tournament1),
            uint8(TournamentCore.Status.Open)
        );

        vm.prank(tournament1);
        registry.updateTournamentStatus(TournamentCore.Status.Cancelled);

        assertEq(
            registry.getTournamentStatus(tournament1),
            uint8(TournamentCore.Status.Cancelled)
        );
    }

    // Changing status back and forth should work
    function test_StatusChangesBackAndForth() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournament(tournament1);
        assertEq(
            registry.getTournamentStatus(tournament1),
            uint8(TournamentCore.Status.Open)
        );
        // Open -> Active
        vm.prank(tournament1);
        registry.updateTournamentStatus(TournamentCore.Status.Active);
        assertEq(
            registry.getTournamentStatus(tournament1),
            uint8(TournamentCore.Status.Active)
        );

        // Active -> Open (going backwards)
        vm.prank(tournament1);
        registry.updateTournamentStatus(TournamentCore.Status.Open);

        assertEq(
            registry.getTournamentStatus(tournament1),
            uint8(TournamentCore.Status.Open)
        );

        // Verify it's in the correct status array
        address[] memory openTournaments = registry.getTournamentsByStatus(
            TournamentCore.Status.Open
        );
        assertEq(openTournaments.length, 1);
        assertEq(openTournaments[0], tournament1);
    }

    // Can query registry for (registered) "PendingStart" tournaments
    function test_GetTournamentsByPendingStartStatus() public {
        registry.grantFactoryRole(factory);

        vm.startPrank(factory);
        registry.registerTournament(tournament1);
        registry.registerTournament(tournament2);
        vm.stopPrank();

        vm.prank(tournament1);
        registry.updateTournamentStatus(TournamentCore.Status.PendingStart);

        address[] memory pendingTournaments = registry.getTournamentsByStatus(
            TournamentCore.Status.PendingStart
        );

        assertEq(pendingTournaments.length, 1);
        assertEq(pendingTournaments[0], tournament1);
    }

    // Can query registry for (registered) "Active" tournaments
    function test_GetTournamentsByActiveStatus() public {
        registry.grantFactoryRole(factory);

        vm.startPrank(factory);
        registry.registerTournament(tournament1);
        registry.registerTournament(tournament2);
        vm.stopPrank();

        vm.prank(tournament1);
        registry.updateTournamentStatus(TournamentCore.Status.Active);

        address[] memory activeTournaments = registry.getTournamentsByStatus(
            TournamentCore.Status.Active
        );

        assertEq(activeTournaments.length, 1);
        assertEq(activeTournaments[0], tournament1);
    }

    // Can query registry for (registered) "Ended" tournaments
    function test_GetTournamentsByEndedStatus() public {
        registry.grantFactoryRole(factory);

        vm.startPrank(factory);
        registry.registerTournament(tournament1);
        registry.registerTournament(tournament2);
        vm.stopPrank();

        vm.prank(tournament1);
        registry.updateTournamentStatus(TournamentCore.Status.Ended);

        address[] memory endedTournaments = registry.getTournamentsByStatus(
            TournamentCore.Status.Ended
        );

        assertEq(endedTournaments.length, 1);
        assertEq(endedTournaments[0], tournament1);
    }
    // Can query registry for (registered) "Cancelled" tournaments
    function test_GetTournamentsByCancelledStatus() public {
        registry.grantFactoryRole(factory);

        vm.startPrank(factory);
        registry.registerTournament(tournament1);
        registry.registerTournament(tournament2);
        vm.stopPrank();

        vm.prank(tournament1);
        registry.updateTournamentStatus(TournamentCore.Status.Cancelled);

        address[] memory cancelledTournaments = registry.getTournamentsByStatus(
            TournamentCore.Status.Cancelled
        );

        assertEq(cancelledTournaments.length, 1);
        assertEq(cancelledTournaments[0], tournament1);
    }

    // Can query registry for (registered) "Locked" tournaments
    function test_GetTournamentsByLockedStatus() public {
        registry.grantFactoryRole(factory);

        vm.startPrank(factory);
        registry.registerTournament(tournament1);
        registry.registerTournament(tournament2);
        vm.stopPrank();

        vm.prank(tournament1);
        registry.updateTournamentStatus(TournamentCore.Status.Locked);

        address[] memory cancelledTournaments = registry.getTournamentsByStatus(
            TournamentCore.Status.Locked
        );

        assertEq(cancelledTournaments.length, 1);
        assertEq(cancelledTournaments[0], tournament1);
    }

    // Should throw error when trying to get status of untracked tournament
    function test_RevertWhen_GettingStatusOfUnregisteredTournament() public {
        vm.expectRevert(TournamentRegistry.NotRegistered.selector);
        registry.getTournamentStatus(tournament1);
    }

    // Should throw error when trying to get status of random address
    function test_RevertWhen_GettingStatusOfAnyUnregisteredTournament(
        address randomTournament
    ) public {
        vm.assume(randomTournament != address(0));
        vm.assume(!registry.isTournamentRegistered(randomTournament));

        vm.expectRevert(TournamentRegistry.NotRegistered.selector);
        registry.getTournamentStatus(randomTournament);
    }
}
