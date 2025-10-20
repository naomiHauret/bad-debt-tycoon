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

    // Tournament 1 system
    address public hub1;
    address public combat1;
    address public deck1;
    address public trading1;
    address public randomizer1;

    // Tournament 2 system
    address public hub2;
    address public combat2;
    address public deck2;
    address public trading2;
    address public randomizer2;

    // Tournament 3 system
    address public hub3;
    address public combat3;
    address public deck3;
    address public trading3;
    address public randomizer3;

    function setUp() public {
        owner = address(this);
        factory = address(0x1);
        nonFactory = address(0x2);

        // Tournament 1 addresses
        hub1 = address(0x100);
        combat1 = address(0x101);
        deck1 = address(0x102);
        trading1 = address(0x103);
        randomizer1 = address(0x104);

        // Tournament 2 addresses
        hub2 = address(0x200);
        combat2 = address(0x201);
        deck2 = address(0x202);
        trading2 = address(0x203);
        randomizer2 = address(0x204);

        // Tournament 3 addresses
        hub3 = address(0x300);
        combat3 = address(0x301);
        deck3 = address(0x302);
        trading3 = address(0x303);
        randomizer3 = address(0x304);

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

    // -- Tournament system registration
    // Tournament system = hub, combat, mystery deck, trading, and randomizer contracts
    // A system is complete when all those contracts are deployed and registered

    // Vetted registry should be able to register tournament systems
    function test_FactoryCanRegisterTournamentSystem() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );

        address[] memory tournaments = registry.getAllTournaments();
        assertEq(tournaments.length, 1);
        assertEq(tournaments[0], hub1);
    }

    // registerTournamentSystem() should emit `TournamentSystemRegistered` event
    function test_RegisterTournamentSystemEmitsEvent() public {
        registry.grantFactoryRole(factory);

        vm.expectEmit(true, true, false, false);
        emit TournamentRegistry.TournamentSystemRegistered(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1,
            TournamentCore.Status.Open
        );

        vm.prank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );
    }

    // When tracked in the registry for the first time, tracked tournament status is "Open"
    function test_RegisterTournamentSystemInitializesWithOpenStatus() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );

        assertEq(
            registry.getTournamentStatus(hub1),
            uint8(TournamentCore.Status.Open)
        );
    }

    // Registry should be able to register multiple tournament systems
    function test_FactoryCanRegisterMultipleTournamentSystems() public {
        registry.grantFactoryRole(factory);

        vm.startPrank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );
        registry.registerTournamentSystem(
            hub2,
            combat2,
            deck2,
            trading2,
            randomizer2
        );
        registry.registerTournamentSystem(
            hub3,
            combat3,
            deck3,
            trading3,
            randomizer3
        );
        vm.stopPrank();

        address[] memory tournaments = registry.getAllTournaments();
        assertEq(tournaments.length, 3);
    }

    // Ensure only addresses with factory role can register tournament systems
    function test_RevertWhen_NonFactoryTriesToRegisterTournamentSystem()
        public
    {
        vm.prank(nonFactory);
        vm.expectRevert(TournamentRegistry.OnlyFactory.selector);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );
    }

    // Ensure zero addresses cannot be used when registering
    function test_RevertWhen_RegisteringZeroAddressHub() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        vm.expectRevert(TournamentRegistry.InvalidAddress.selector);
        registry.registerTournamentSystem(
            address(0),
            combat1,
            deck1,
            trading1,
            randomizer1
        );
    }

    function test_RevertWhen_RegisteringZeroAddressCombat() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        vm.expectRevert(TournamentRegistry.InvalidAddress.selector);
        registry.registerTournamentSystem(
            hub1,
            address(0),
            deck1,
            trading1,
            randomizer1
        );
    }

    function test_RevertWhen_RegisteringZeroAddressDeck() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        vm.expectRevert(TournamentRegistry.InvalidAddress.selector);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            address(0),
            trading1,
            randomizer1
        );
    }

    function test_RevertWhen_RegisteringZeroAddressTrading() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        vm.expectRevert(TournamentRegistry.InvalidAddress.selector);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            address(0),
            randomizer1
        );
    }

    function test_RevertWhen_RegisteringZeroAddressRandomizer() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        vm.expectRevert(TournamentRegistry.InvalidAddress.selector);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            address(0)
        );
    }

    // Ensure the registry can't track the same hub multiple times
    function test_RevertWhen_RegisteringAlreadyRegisteredHub() public {
        registry.grantFactoryRole(factory);

        vm.startPrank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );

        vm.expectRevert(TournamentRegistry.AlreadyRegistered.selector);
        registry.registerTournamentSystem(
            hub1,
            combat2,
            deck2,
            trading2,
            randomizer2
        );
        vm.stopPrank();
    }

    // Ensure modules cannot be reused across tournaments
    // - Deployed Combat module can't be reused in multiple tournaments
    function test_RevertWhen_ReusingCombatModule() public {
        registry.grantFactoryRole(factory);

        vm.startPrank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );

        vm.expectRevert(TournamentRegistry.ModuleAlreadyUsed.selector);
        registry.registerTournamentSystem(
            hub2,
            combat1,
            deck2,
            trading2,
            randomizer2
        );
        vm.stopPrank();
    }

    // - Deployed MysteryDeck module can't be reused in multiple tournaments
    function test_RevertWhen_ReusingDeckModule() public {
        registry.grantFactoryRole(factory);

        vm.startPrank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );

        vm.expectRevert(TournamentRegistry.ModuleAlreadyUsed.selector);
        registry.registerTournamentSystem(
            hub2,
            combat2,
            deck1,
            trading2,
            randomizer2
        );
        vm.stopPrank();
    }
    // - Deployed Trading module can't be reused in multiple tournaments
    function test_RevertWhen_ReusingTradingModule() public {
        registry.grantFactoryRole(factory);

        vm.startPrank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );

        vm.expectRevert(TournamentRegistry.ModuleAlreadyUsed.selector);
        registry.registerTournamentSystem(
            hub2,
            combat2,
            deck2,
            trading1,
            randomizer2
        );
        vm.stopPrank();
    }
    // - Deployed Randomizer module can't be reused in multiple tournaments
    function test_RevertWhen_ReusingRandomizerModule() public {
        registry.grantFactoryRole(factory);

        vm.startPrank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );

        vm.expectRevert(TournamentRegistry.ModuleAlreadyUsed.selector);
        registry.registerTournamentSystem(
            hub2,
            combat2,
            deck2,
            trading2,
            randomizer1
        );
        vm.stopPrank();
    }

    // Should be able to retrieve entire system from registered Hub address
    function test_GetTournamentSystemReturnsCorrectData() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );

        TournamentRegistry.TournamentSystem memory system = registry
            .getTournamentSystem(hub1);

        assertEq(system.hub, hub1);
        assertEq(system.combat, combat1);
        assertEq(system.mysteryDeck, deck1);
        assertEq(system.trading, trading1);
        assertEq(system.randomizer, randomizer1);
        assertTrue(system.exists);
    }

    // Should be revert when trying to get system with unregistered Hub address
    function test_RevertWhen_GettingUnregisteredTournamentSystem() public {
        vm.expectRevert(TournamentRegistry.NotRegistered.selector);
        registry.getTournamentSystem(hub1);
    }

    // Reverse Lookups
    // Getting hub address from Hub should return itself
    function test_GetHubAddressFromHubReturnsItself() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );

        assertEq(registry.getHubAddress(hub1), hub1);
    }
    // Should be able to return Hub address with Combat module address
    function test_GetHubAddressFromCombatModule() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );

        assertEq(registry.getHubAddress(combat1), hub1);
    }

    // Should be able to return Hub address with MysteryDeck module address
    function test_GetHubAddressFromDeckModule() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );

        assertEq(registry.getHubAddress(deck1), hub1);
    }

    // Should be able to return Hub address with Trading module address
    function test_GetHubAddressFromTradingModule() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );

        assertEq(registry.getHubAddress(trading1), hub1);
    }

    // Should be able to return Hub address with Randomizer module address
    function test_GetHubAddressFromRandomizerModule() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );

        assertEq(registry.getHubAddress(randomizer1), hub1);
    }

    // Should revert when trying to get Hub address with unknown/unregistered address (not a registered module)
    function test_RevertWhen_GettingHubAddressFromUnregisteredModule() public {
        vm.expectRevert(TournamentRegistry.NotRegistered.selector);
        registry.getHubAddress(address(0x999));
    }

    // Should return entire system addresses using a system module address
    function test_GetTournamentSystemByModule() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );

        TournamentRegistry.TournamentSystem memory system = registry
            .getTournamentSystemByModule(combat1);

        assertEq(system.hub, hub1);
        assertEq(system.combat, combat1);
        assertEq(system.mysteryDeck, deck1);
        assertEq(system.trading, trading1);
        assertEq(system.randomizer, randomizer1);
    }

    // Should revert when trying to get system addresses with unknown/unregistered address (not a registered module)
    function test_RevertWhen_GettingTournamentSystemByUnregisteredModule()
        public
    {
        vm.expectRevert(TournamentRegistry.NotRegistered.selector);
        registry.getTournamentSystemByModule(address(0x999));
    }

    // Should return false if address is not a registered module, true if it is
    function test_IsModuleRegistered() public {
        registry.grantFactoryRole(factory);

        assertFalse(registry.isModuleRegistered(combat1));

        vm.prank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );

        assertTrue(registry.isModuleRegistered(hub1));
        assertTrue(registry.isModuleRegistered(combat1));
        assertTrue(registry.isModuleRegistered(deck1));
        assertTrue(registry.isModuleRegistered(trading1));
        assertTrue(registry.isModuleRegistered(randomizer1));
    }

    // Tournament status updates
    // Trying to change tournament status to same status shouldn't error/change anything
    function test_UpdatingToSameStatusDoesNothing() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );

        vm.prank(hub1);
        registry.updateTournamentStatus(TournamentCore.Status.Open);

        assertEq(
            registry.getTournamentStatus(hub1),
            uint8(TournamentCore.Status.Open)
        );
    }

    // Ensure a tournament hub can update its status
    function test_TournamentHubCanUpdateItsOwnStatus() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );

        vm.prank(hub1);
        registry.updateTournamentStatus(TournamentCore.Status.Active);

        assertEq(
            registry.getTournamentStatus(hub1),
            uint8(TournamentCore.Status.Active)
        );
    }

    // Tournament status change should emit the TournamentStatusUpdated event
    function test_UpdateStatusEmitsEvent() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );

        vm.expectEmit(true, true, true, false);
        emit TournamentRegistry.TournamentStatusUpdated(
            hub1,
            TournamentCore.Status.Open,
            TournamentCore.Status.Active
        );

        vm.prank(hub1);
        registry.updateTournamentStatus(TournamentCore.Status.Active);
    }

    // Ensure only hub can update tournament status
    function test_RevertWhen_NonHubTriesToUpdateStatus() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );

        // Modules are not registered as hubs, so they get NotRegistered error
        vm.prank(combat1);
        vm.expectRevert(TournamentRegistry.NotRegistered.selector);
        registry.updateTournamentStatus(TournamentCore.Status.Active);

        vm.prank(deck1);
        vm.expectRevert(TournamentRegistry.NotRegistered.selector);
        registry.updateTournamentStatus(TournamentCore.Status.Active);

        vm.prank(trading1);
        vm.expectRevert(TournamentRegistry.NotRegistered.selector);
        registry.updateTournamentStatus(TournamentCore.Status.Active);

        vm.prank(randomizer1);
        vm.expectRevert(TournamentRegistry.NotRegistered.selector);
        registry.updateTournamentStatus(TournamentCore.Status.Active);
    }

    function test_RevertWhen_RandomAddressTriesToUpdateStatus() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );

        vm.prank(nonFactory);
        vm.expectRevert(TournamentRegistry.NotRegistered.selector);
        registry.updateTournamentStatus(TournamentCore.Status.Active);
    }

    function test_RevertWhen_UnregisteredHubTriesToUpdateStatus() public {
        vm.prank(hub1);
        vm.expectRevert(TournamentRegistry.NotRegistered.selector);
        registry.updateTournamentStatus(TournamentCore.Status.Active);
    }

    // Query functions
    // Should b able to return all registered tournaments
    function test_GetAllTournamentsReturnsAllRegistered() public {
        registry.grantFactoryRole(factory);

        vm.startPrank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );
        registry.registerTournamentSystem(
            hub2,
            combat2,
            deck2,
            trading2,
            randomizer2
        );
        vm.stopPrank();

        address[] memory tournaments = registry.getAllTournaments();
        assertEq(tournaments.length, 2);
        assertEq(tournaments[0], hub1);
        assertEq(tournaments[1], hub2);
    }

    // Should b able to filtered registered tournaments based on tournament status
    function test_GetTournamentsByStatusFiltersCorrectly() public {
        registry.grantFactoryRole(factory);

        vm.startPrank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );
        registry.registerTournamentSystem(
            hub2,
            combat2,
            deck2,
            trading2,
            randomizer2
        );
        registry.registerTournamentSystem(
            hub3,
            combat3,
            deck3,
            trading3,
            randomizer3
        );
        vm.stopPrank();

        vm.prank(hub1);
        registry.updateTournamentStatus(TournamentCore.Status.Active);

        vm.prank(hub2);
        registry.updateTournamentStatus(TournamentCore.Status.Active);

        address[] memory openTournaments = registry.getTournamentsByStatus(
            TournamentCore.Status.Open
        );
        address[] memory activeTournaments = registry.getTournamentsByStatus(
            TournamentCore.Status.Active
        );

        assertEq(openTournaments.length, 1);
        assertEq(openTournaments[0], hub3);

        assertEq(activeTournaments.length, 2);
        assertEq(activeTournaments[0], hub1);
        assertEq(activeTournaments[1], hub2);
    }

    // Before/after updating tracked tournament status in registry,
    // should be able to get accurate tracked tournament status
    function test_GetTournamentStatusReturnsCorrectStatus() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );

        assertEq(
            registry.getTournamentStatus(hub1),
            uint8(TournamentCore.Status.Open)
        );

        vm.prank(hub1);
        registry.updateTournamentStatus(TournamentCore.Status.Active);

        assertEq(
            registry.getTournamentStatus(hub1),
            uint8(TournamentCore.Status.Active)
        );
    }

    // Before registering, isTournamentRegistered() should return false
    // After, should return true
    function test_IsTournamentRegisteredReturnsCorrectValue() public {
        assertFalse(registry.isTournamentRegistered(hub1));

        registry.grantFactoryRole(factory);
        vm.prank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );

        assertTrue(registry.isTournamentRegistered(hub1));
    }

    // Registering tournament should increase tournaments count in registry
    function test_GetTournamentCountReturnsCorrectCount() public {
        assertEq(registry.getTournamentCount(), 0);

        registry.grantFactoryRole(factory);

        vm.startPrank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );
        assertEq(registry.getTournamentCount(), 1);

        registry.registerTournamentSystem(
            hub2,
            combat2,
            deck2,
            trading2,
            randomizer2
        );
        assertEq(registry.getTournamentCount(), 2);
        vm.stopPrank();
    }

    // Should return empty array when registry tracks no tournaments with given status
    function test_GetTournamentsByStatusReturnsEmptyArray() public {
        address[] memory activeTournaments = registry.getTournamentsByStatus(
            TournamentCore.Status.Active
        );

        assertEq(activeTournaments.length, 0);
    }

    // Status transitions
    // Should be able to track system status transitions in parallel
    function test_StatusTransitions() public {
        registry.grantFactoryRole(factory);

        vm.startPrank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );
        registry.registerTournamentSystem(
            hub2,
            combat2,
            deck2,
            trading2,
            randomizer2
        );
        registry.registerTournamentSystem(
            hub3,
            combat3,
            deck3,
            trading3,
            randomizer3
        );
        vm.stopPrank();

        // hub1: Open -> Active -> Ended
        vm.prank(hub1);
        registry.updateTournamentStatus(TournamentCore.Status.Active);
        vm.prank(hub1);
        registry.updateTournamentStatus(TournamentCore.Status.Ended);

        // hub2: Open -> Cancelled
        vm.prank(hub2);
        registry.updateTournamentStatus(TournamentCore.Status.Cancelled);

        // hub3: stays Open

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

    // Should be able to switch system status back and forth in registry
    function test_StatusChangesBackAndForth() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );

        vm.prank(hub1);
        registry.updateTournamentStatus(TournamentCore.Status.Active);
        assertEq(
            registry.getTournamentStatus(hub1),
            uint8(TournamentCore.Status.Active)
        );

        vm.prank(hub1);
        registry.updateTournamentStatus(TournamentCore.Status.Open);

        assertEq(
            registry.getTournamentStatus(hub1),
            uint8(TournamentCore.Status.Open)
        );

        address[] memory openTournaments = registry.getTournamentsByStatus(
            TournamentCore.Status.Open
        );
        assertEq(openTournaments.length, 1);
        assertEq(openTournaments[0], hub1);
    }

    // Should be able to change tracked status to PendingStart in registry
    function test_UpdateToPendingStartStatus() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );

        vm.prank(hub1);
        registry.updateTournamentStatus(TournamentCore.Status.PendingStart);

        assertEq(
            registry.getTournamentStatus(hub1),
            uint8(TournamentCore.Status.PendingStart)
        );
    }

    // Should be able to change tracked status to Active in registry
    function test_UpdateToActiveStatus() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );

        vm.prank(hub1);
        registry.updateTournamentStatus(TournamentCore.Status.Active);

        assertEq(
            registry.getTournamentStatus(hub1),
            uint8(TournamentCore.Status.Active)
        );
    }

    // Should be able to change tracked status to Active in registry
    function test_UpdateToEndedStatus() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );

        vm.prank(hub1);
        registry.updateTournamentStatus(TournamentCore.Status.Ended);

        assertEq(
            registry.getTournamentStatus(hub1),
            uint8(TournamentCore.Status.Ended)
        );
    }

    // Should be able to change tracked status to Locked in registry
    function test_UpdateToLockedStatus() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );

        vm.prank(hub1);
        registry.updateTournamentStatus(TournamentCore.Status.Locked);

        assertEq(
            registry.getTournamentStatus(hub1),
            uint8(TournamentCore.Status.Locked)
        );
    }

    // Should be able to change tracked status to Cancelled in registry
    function test_UpdateToCancelledStatus() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );

        vm.prank(hub1);
        registry.updateTournamentStatus(TournamentCore.Status.Cancelled);

        assertEq(
            registry.getTournamentStatus(hub1),
            uint8(TournamentCore.Status.Cancelled)
        );
    }

    // Should be able to change tracked status to Open in registry
    function test_UpdateToOpenStatus() public {
        registry.grantFactoryRole(factory);

        vm.prank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );

        vm.prank(hub1);
        registry.updateTournamentStatus(TournamentCore.Status.Locked);

        vm.prank(hub1);
        registry.updateTournamentStatus(TournamentCore.Status.Open);

        assertEq(
            registry.getTournamentStatus(hub1),
            uint8(TournamentCore.Status.Open)
        );
    }

    // Should be able to return all tracked tournament systems with PendingStart status
    function test_GetTournamentsByPendingStartStatus() public {
        registry.grantFactoryRole(factory);

        vm.startPrank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );
        registry.registerTournamentSystem(
            hub2,
            combat2,
            deck2,
            trading2,
            randomizer2
        );
        vm.stopPrank();

        vm.prank(hub1);
        registry.updateTournamentStatus(TournamentCore.Status.PendingStart);

        address[] memory pendingTournaments = registry.getTournamentsByStatus(
            TournamentCore.Status.PendingStart
        );

        assertEq(pendingTournaments.length, 1);
        assertEq(pendingTournaments[0], hub1);
    }

    // Should be able to return all tracked tournament systems with Active status
    function test_GetTournamentsByActiveStatus() public {
        registry.grantFactoryRole(factory);

        vm.startPrank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );
        registry.registerTournamentSystem(
            hub2,
            combat2,
            deck2,
            trading2,
            randomizer2
        );
        vm.stopPrank();

        vm.prank(hub1);
        registry.updateTournamentStatus(TournamentCore.Status.Active);

        address[] memory activeTournaments = registry.getTournamentsByStatus(
            TournamentCore.Status.Active
        );

        assertEq(activeTournaments.length, 1);
        assertEq(activeTournaments[0], hub1);
    }

    // Should be able to return all tracked tournament systems with Ended status
    function test_GetTournamentsByEndedStatus() public {
        registry.grantFactoryRole(factory);

        vm.startPrank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );
        registry.registerTournamentSystem(
            hub2,
            combat2,
            deck2,
            trading2,
            randomizer2
        );
        vm.stopPrank();

        vm.prank(hub1);
        registry.updateTournamentStatus(TournamentCore.Status.Ended);

        address[] memory endedTournaments = registry.getTournamentsByStatus(
            TournamentCore.Status.Ended
        );

        assertEq(endedTournaments.length, 1);
        assertEq(endedTournaments[0], hub1);
    }

    // Should be able to return all tracked tournament systems with Cancelled status
    function test_GetTournamentsByCancelledStatus() public {
        registry.grantFactoryRole(factory);

        vm.startPrank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );
        registry.registerTournamentSystem(
            hub2,
            combat2,
            deck2,
            trading2,
            randomizer2
        );
        vm.stopPrank();

        vm.prank(hub1);
        registry.updateTournamentStatus(TournamentCore.Status.Cancelled);

        address[] memory cancelledTournaments = registry.getTournamentsByStatus(
            TournamentCore.Status.Cancelled
        );

        assertEq(cancelledTournaments.length, 1);
        assertEq(cancelledTournaments[0], hub1);
    }

    // Should be able to return all tracked tournament systems with Locked status
    function test_GetTournamentsByLockedStatus() public {
        registry.grantFactoryRole(factory);

        vm.startPrank(factory);
        registry.registerTournamentSystem(
            hub1,
            combat1,
            deck1,
            trading1,
            randomizer1
        );
        registry.registerTournamentSystem(
            hub2,
            combat2,
            deck2,
            trading2,
            randomizer2
        );
        vm.stopPrank();

        vm.prank(hub1);
        registry.updateTournamentStatus(TournamentCore.Status.Locked);

        address[] memory lockedTournaments = registry.getTournamentsByStatus(
            TournamentCore.Status.Locked
        );

        assertEq(lockedTournaments.length, 1);
        assertEq(lockedTournaments[0], hub1);
    }

    // Should revert if trying to get status of unregistered tournament system
    function test_RevertWhen_GettingStatusOfUnregisteredTournament() public {
        vm.expectRevert(TournamentRegistry.NotRegistered.selector);
        registry.getTournamentStatus(hub1);
    }

    function test_RevertWhen_GettingStatusOfAnyUnregisteredTournament(
        address randomTournament
    ) public {
        vm.assume(randomTournament != address(0));
        vm.assume(!registry.isTournamentRegistered(randomTournament));

        vm.expectRevert(TournamentRegistry.NotRegistered.selector);
        registry.getTournamentStatus(randomTournament);
    }
}
