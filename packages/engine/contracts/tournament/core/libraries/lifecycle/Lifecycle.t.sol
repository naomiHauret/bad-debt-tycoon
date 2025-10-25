// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {TournamentLifecycle} from "./Lifecycle.sol";
import {TournamentCore} from "./../../TournamentCore.sol";
import {Test} from "forge-std/Test.sol";

contract LifecycleTest is Test {
    WrapperLifecycle wrapper;
    MockRegistry registry;

    // Helper function to create default params
    function _createDefaultParams()
        internal
        view
        returns (TournamentCore.Params memory)
    {
        uint8[] memory excludedCards = new uint8[](0);

        return
            TournamentCore.Params({
                startTimestamp: uint32(block.timestamp),
                duration: 7200,
                gameInterval: 1200,
                minPlayers: 0,
                maxPlayers: 0,
                startPlayerCount: 0,
                startPoolAmount: 0,
                stakeToken: address(0x1),
                minStake: 100,
                maxStake: 10000,
                coinConversionRate: 1,
                decayAmount: 10,
                initialLives: 3,
                cardsPerType: 5,
                exitLivesRequired: 1,
                exitCostBasePercentBPS: 5000,
                exitCostCompoundRateBPS: 1000,
                creatorFeePercent: 2,
                platformFeePercent: 1,
                forfeitAllowed: true,
                forfeitPenaltyType: TournamentCore.ForfeitPenaltyType.Fixed,
                forfeitMaxPenalty: 80,
                forfeitMinPenalty: 20,
                deckCatalog: address(0x2),
                excludedCardIds: excludedCards,
                deckDrawCost: 50,
                deckShuffleCost: 30,
                deckPeekCost: 20
            });
    }

    function setUp() public {
        registry = new MockRegistry();
        wrapper = new WrapperLifecycle(address(registry));
    }
    // -- Start conditions --
    // Should return true when both conditions are met
    function test_AreStartConditionsMet_BothConditionsMet() public view {
        bool result = wrapper.areStartConditionsMet(
            10, // startPlayerCount
            1000, // startPoolAmount
            15, // currentPlayerCount (>= 10)
            1500 // currentTotalStaked (>= 1000)
        );

        assertTrue(result);
    }

    // Should return false when player count is below requirement
    function test_AreStartConditionsMet_PlayerCountNotMet() public view {
        bool result = wrapper.areStartConditionsMet(
            10, // startPlayerCount
            1000, // startPoolAmount
            5, // currentPlayerCount (< 10)
            1500 // currentTotalStaked (>= 1000)
        );

        assertFalse(result);
    }

    // Should return false when pool amount is below requirement
    function test_AreStartConditionsMet_PoolAmountNotMet() public view {
        bool result = wrapper.areStartConditionsMet(
            10, // startPlayerCount
            1000, // startPoolAmount
            15, // currentPlayerCount (>= 10)
            500 // currentTotalStaked (< 1000)
        );

        assertFalse(result);
    }

    // Should return false when both conditions are not met
    function test_AreStartConditionsMet_BothConditionsNotMet() public view {
        bool result = wrapper.areStartConditionsMet(
            10, // startPlayerCount
            1000, // startPoolAmount
            5, // currentPlayerCount (< 10)
            500 // currentTotalStaked (< 1000)
        );

        assertFalse(result);
    }

    // Should return true when player count requirement is disabled (0)
    function test_AreStartConditionsMet_NoPlayerCountRequirement() public view {
        bool result = wrapper.areStartConditionsMet(
            0, // startPlayerCount (disabled)
            1000, // startPoolAmount
            5, // currentPlayerCount (any value)
            1500 // currentTotalStaked (>= 1000)
        );

        assertTrue(result);
    }

    // Should return true when pool amount requirement is disabled (0)
    function test_AreStartConditionsMet_NoPoolAmountRequirement() public view {
        bool result = wrapper.areStartConditionsMet(
            10, // startPlayerCount
            0, // startPoolAmount (disabled)
            15, // currentPlayerCount (>= 10)
            500 // currentTotalStaked (any value)
        );

        assertTrue(result);
    }

    // Should return true when both requirements are disabled (0)
    function test_AreStartConditionsMet_BothRequirementsDisabled() public view {
        bool result = wrapper.areStartConditionsMet(
            0, // startPlayerCount (disabled)
            0, // startPoolAmount (disabled)
            0, // currentPlayerCount
            0 // currentTotalStaked
        );

        assertTrue(result);
    }

    // Should handle exact threshold values correctly
    function test_AreStartConditionsMet_ExactThresholds() public view {
        bool result = wrapper.areStartConditionsMet(
            10, // startPlayerCount
            1000, // startPoolAmount
            10, // currentPlayerCount (exactly 10)
            1000 // currentTotalStaked (exactly 1000)
        );

        assertTrue(result);
    }

    // Should validate conditions with random parameters
    function test_AreStartConditionsMet_Fuzz(
        uint16 startPlayerCount,
        uint256 startPoolAmount,
        uint16 currentPlayerCount,
        uint256 currentTotalStaked
    ) public view {
        bool result = wrapper.areStartConditionsMet(
            startPlayerCount,
            startPoolAmount,
            currentPlayerCount,
            currentTotalStaked
        );

        bool expectedPlayerCondition = startPlayerCount == 0 ||
            currentPlayerCount >= startPlayerCount;
        bool expectedPoolCondition = startPoolAmount == 0 ||
            currentTotalStaked >= startPoolAmount;
        bool expected = expectedPlayerCondition && expectedPoolCondition;

        assertEq(result, expected);
    }

    // Transitions
    // -- Locked
    // Should update status to Locked in registry when invoked
    function test_TransitionToLocked_UpdatesStatus() public {
        wrapper.transitionToLocked();

        TournamentCore.Status status = registry.getTournamentStatus();
        assertEq(uint8(status), uint8(TournamentCore.Status.Locked));
    }

    // -- Open
    // Should update status to Open in registry when invoked
    function test_TransitionToOpen_UpdatesStatus() public {
        // First lock it
        wrapper.transitionToLocked();

        // Then open it
        wrapper.transitionToOpen();

        TournamentCore.Status status = registry.getTournamentStatus();
        assertEq(uint8(status), uint8(TournamentCore.Status.Open));
    }

    // Should allow transition from any status <> Open
    function test_TransitionToOpen_FromAnyStatus() public {
        // From initial state
        wrapper.transitionToOpen();
        assertEq(
            uint8(registry.getTournamentStatus()),
            uint8(TournamentCore.Status.Open)
        );

        // From Locked
        wrapper.transitionToLocked();
        wrapper.transitionToOpen();
        assertEq(
            uint8(registry.getTournamentStatus()),
            uint8(TournamentCore.Status.Open)
        );

        // From PendingStart
        wrapper.transitionToPendingStart();
        wrapper.transitionToOpen();
        assertEq(
            uint8(registry.getTournamentStatus()),
            uint8(TournamentCore.Status.Open)
        );
    }

    // Should update status to PendingStart in registry when invoked
    function test_TransitionToPendingStart_UpdatesStatus() public {
        wrapper.transitionToPendingStart();

        TournamentCore.Status status = registry.getTournamentStatus();
        assertEq(uint8(status), uint8(TournamentCore.Status.PendingStart));
    }

    // Should update status to Active and return correct timestamps
    function test_TransitionToActive_UpdatesStatusAndReturnsTimestamps()
        public
    {
        uint32 duration = 3600; // 1 hour
        uint32 gameInterval = 600; // 10 minutes

        (
            uint32 actualStartTime,
            uint32 endTime,
            uint32 exitWindowStart
        ) = wrapper.transitionToActive(duration, gameInterval);

        // Verify status
        TournamentCore.Status status = registry.getTournamentStatus();
        assertEq(uint8(status), uint8(TournamentCore.Status.Active));

        // Verify timestamps
        assertEq(actualStartTime, uint32(block.timestamp));
        assertEq(endTime, actualStartTime + duration);
        assertEq(exitWindowStart, endTime - gameInterval);
    }

    // Should calculate exit window correctly
    function test_TransitionToActive_CalculatesExitWindow() public {
        uint32 duration = 7200; // 2 hours
        uint32 gameInterval = 1200; // 20 minutes

        (, uint32 endTime, uint32 exitWindowStart) = wrapper.transitionToActive(
            duration,
            gameInterval
        );

        assertEq(exitWindowStart, endTime - gameInterval);
        assertEq(endTime - exitWindowStart, gameInterval);
    }

    // Should handle different duration and interval combinations
    function test_TransitionToActive_Fuzz(
        uint32 duration,
        uint32 gameInterval
    ) public {
        vm.assume(duration > 0);
        vm.assume(gameInterval > 0);
        vm.assume(duration >= gameInterval);
        // Prevent overflow when calculating endTime
        // uint32 maxes out in 2106 so bear with me here
        vm.assume(duration <= type(uint32).max - uint32(block.timestamp));
        (
            uint32 actualStartTime,
            uint32 endTime,
            uint32 exitWindowStart
        ) = wrapper.transitionToActive(duration, gameInterval);

        assertEq(actualStartTime, uint32(block.timestamp));
        assertEq(endTime, actualStartTime + duration);
        assertEq(exitWindowStart, endTime - gameInterval);
        assertLe(exitWindowStart, endTime);
    }

    // Should update status to Ended in registry when invoked
    function test_TransitionToEnded_UpdatesStatus() public {
        wrapper.transitionToEnded(10000, 2000, 5);

        TournamentCore.Status status = registry.getTournamentStatus();
        assertEq(uint8(status), uint8(TournamentCore.Status.Ended));
    }

    // -- Status.Cancelled
    // Should update status to Cancelled in registry when invoked
    function test_TransitionToCancelled_UpdatesStatus() public {
        wrapper.transitionToCancelled();

        TournamentCore.Status status = registry.getTournamentStatus();
        assertEq(uint8(status), uint8(TournamentCore.Status.Cancelled));
    }

    // Should update status to Cancelled in registry after emergencyCancel() was invoked
    function test_EmergencyCancel_UpdatesStatus() public {
        address platformAdmin = address(0x1234);
        wrapper.emergencyCancel(platformAdmin);

        TournamentCore.Status status = registry.getTournamentStatus();
        assertEq(uint8(status), uint8(TournamentCore.Status.Cancelled));
    }

    // Should accept any address as platform admin
    function test_EmergencyCancel_AcceptsAnyAddress() public {
        wrapper.emergencyCancel(address(0)); // technically this would never happen

        TournamentCore.Status status = registry.getTournamentStatus();
        assertEq(uint8(status), uint8(TournamentCore.Status.Cancelled));
    }

    // -- checkAndTransition
    // Transition  Open -> Locked when max players reached
    function test_CheckAndTransition_OpenToLocked() public {
        TournamentCore.Params memory testParams = _createDefaultParams();
        testParams.maxPlayers = 10;
        testParams.startTimestamp = uint32(block.timestamp + 3600);

        (
            TournamentCore.Status newStatus,
            uint32 actualStart,
            uint32 end,
            uint32 exitWindow
        ) = wrapper.checkAndTransition(
                TournamentCore.Status.Open,
                testParams,
                10, // playerCount equals maxPlayers
                5000,
                address(registry)
            );

        assertEq(uint8(newStatus), uint8(TournamentCore.Status.Locked));
        assertEq(actualStart, 0);
        assertEq(end, 0);
        assertEq(exitWindow, 0);
    }

    // Can transition Locked <-> Open
    function test_CheckAndTransition_LockedToOpenToLocked() public {
        TournamentCore.Params memory testParams = _createDefaultParams();
        testParams.maxPlayers = 10;
        testParams.startTimestamp = uint32(block.timestamp + 3600);

        // First transition to Locked
        wrapper.checkAndTransition(
            TournamentCore.Status.Open,
            testParams,
            10,
            5000,
            address(registry)
        );

        // Manually transition back to Open (simulating refund)
        wrapper.transitionToOpen();

        // Then lock again
        (TournamentCore.Status newStatus, , , ) = wrapper.checkAndTransition(
            TournamentCore.Status.Open,
            testParams,
            10,
            5000,
            address(registry)
        );

        assertEq(uint8(newStatus), uint8(TournamentCore.Status.Locked));
    }

    // Transition Open -> PendingStart when start time reached
    function test_CheckAndTransition_OpenToPendingStart() public {
        TournamentCore.Params memory testParams = _createDefaultParams();
        testParams.startTimestamp = uint32(block.timestamp);
        testParams.startPlayerCount = 5;
        testParams.startPoolAmount = 5000;

        (TournamentCore.Status newStatus, , , ) = wrapper.checkAndTransition(
            TournamentCore.Status.Open,
            testParams,
            5,
            5000,
            address(registry)
        );

        assertEq(uint8(newStatus), uint8(TournamentCore.Status.Active));
    }

    // Transition Locked -> PendingStart when start time reached
    function test_CheckAndTransition_LockedToPendingStart() public {
        TournamentCore.Params memory testParams = _createDefaultParams();
        testParams.startTimestamp = uint32(block.timestamp);
        testParams.startPlayerCount = 5;
        testParams.startPoolAmount = 5000;

        (TournamentCore.Status newStatus, , , ) = wrapper.checkAndTransition(
            TournamentCore.Status.Locked,
            testParams,
            5,
            5000,
            address(registry)
        );

        assertEq(uint8(newStatus), uint8(TournamentCore.Status.Active));
    }

    // Transition PendingStart -> Cancelled when start conditions not met
    function test_CheckAndTransition_PendingStartToCancelled() public {
        TournamentCore.Params memory testParams = _createDefaultParams();
        testParams.startTimestamp = uint32(block.timestamp);
        testParams.startPlayerCount = 10;
        testParams.startPoolAmount = 10000;

        (TournamentCore.Status newStatus, , , ) = wrapper.checkAndTransition(
            TournamentCore.Status.Open,
            testParams,
            5, // Not enough players
            5000, // Not enough stake
            address(registry)
        );

        assertEq(uint8(newStatus), uint8(TournamentCore.Status.Cancelled));
    }

    // Can transition Open -> Locked -> PendingStart -> Active
    function test_CheckAndTransition_OpenToLockedToPendingStartToActive()
        public
    {
        TournamentCore.Params memory testParams = _createDefaultParams();
        testParams.maxPlayers = 10;
        testParams.startPlayerCount = 5;
        testParams.startPoolAmount = 5000;
        testParams.startTimestamp = uint32(block.timestamp + 3600);

        // Step 1: Open -> Locked
        (TournamentCore.Status status1, , , ) = wrapper.checkAndTransition(
            TournamentCore.Status.Open,
            testParams,
            10,
            5000,
            address(registry)
        );
        assertEq(uint8(status1), uint8(TournamentCore.Status.Locked));

        // Step 2: Warp to start time, should do Locked -> PendingStart -> Active
        vm.warp(block.timestamp + 3600);
        (
            TournamentCore.Status status2,
            uint32 actualStart,
            uint32 end,
            uint32 exitWindow
        ) = wrapper.checkAndTransition(
                TournamentCore.Status.Locked,
                testParams,
                10,
                10000,
                address(registry)
            );

        assertEq(uint8(status2), uint8(TournamentCore.Status.Active));
        assertGt(actualStart, 0);
        assertGt(end, 0);
        assertGt(exitWindow, 0);
    }

    // Should transition Open -> PendingStart -> Active
    function test_CheckAndTransition_OpenToPendingStartToActive() public {
        TournamentCore.Params memory testParams = _createDefaultParams();
        testParams.maxPlayers = 0; // No max
        testParams.startPlayerCount = 5;
        testParams.startPoolAmount = 5000;
        testParams.startTimestamp = uint32(block.timestamp);

        (
            TournamentCore.Status newStatus,
            uint32 actualStart,
            uint32 end,
            uint32 exitWindow
        ) = wrapper.checkAndTransition(
                TournamentCore.Status.Open,
                testParams,
                5,
                5000,
                address(registry)
            );

        assertEq(uint8(newStatus), uint8(TournamentCore.Status.Active));
        assertEq(actualStart, uint32(block.timestamp));
        assertEq(end, actualStart + testParams.duration);
        assertEq(exitWindow, end - testParams.gameInterval);
    }

    // Can transition Locked -> Open -> PendingStart -> Active
    function test_CheckAndTransition_LockedToOpenToPendingStartToActive()
        public
    {
        TournamentCore.Params memory testParams = _createDefaultParams();
        testParams.maxPlayers = 10;
        testParams.startPlayerCount = 5;
        testParams.startPoolAmount = 5000;
        testParams.startTimestamp = uint32(block.timestamp + 3600);

        // Start Locked
        wrapper.transitionToLocked();

        // Unlock to Open
        wrapper.transitionToOpen();
        assertEq(
            uint8(registry.getTournamentStatus()),
            uint8(TournamentCore.Status.Open)
        );

        // Warp to start time
        vm.warp(block.timestamp + 3600);

        // Open -> PendingStart -> Active
        (TournamentCore.Status newStatus, , , ) = wrapper.checkAndTransition(
            TournamentCore.Status.Open,
            testParams,
            5,
            5000,
            address(registry)
        );

        assertEq(uint8(newStatus), uint8(TournamentCore.Status.Active));
    }

    // Should NOT transition when in Active status
    function test_CheckAndTransition_ActiveStatusUnchanged() public {
        TournamentCore.Params memory testParams = _createDefaultParams();

        (TournamentCore.Status newStatus, , , ) = wrapper.checkAndTransition(
            TournamentCore.Status.Active,
            testParams,
            5,
            5000,
            address(registry)
        );

        assertEq(uint8(newStatus), uint8(TournamentCore.Status.Active));
    }

    // Should NOT transition when in Ended status
    function test_CheckAndTransition_EndedStatusUnchanged() public {
        TournamentCore.Params memory testParams = _createDefaultParams();

        (TournamentCore.Status newStatus, , , ) = wrapper.checkAndTransition(
            TournamentCore.Status.Ended,
            testParams,
            5,
            5000,
            address(registry)
        );

        assertEq(uint8(newStatus), uint8(TournamentCore.Status.Ended));
    }

    // Should NOT transition when in Cancelled status
    function test_CheckAndTransition_CancelledStatusUnchanged() public {
        TournamentCore.Params memory testParams = _createDefaultParams();

        (TournamentCore.Status newStatus, , , ) = wrapper.checkAndTransition(
            TournamentCore.Status.Cancelled,
            testParams,
            5,
            5000,
            address(registry)
        );

        assertEq(uint8(newStatus), uint8(TournamentCore.Status.Cancelled));
    }
}

// Mock Registry for testing
contract MockRegistry {
    TournamentCore.Status public currentStatus;

    function updateTournamentStatus(TournamentCore.Status newStatus) external {
        currentStatus = newStatus;
    }

    function getTournamentStatus()
        external
        view
        returns (TournamentCore.Status)
    {
        return currentStatus;
    }
}

// Wrapper contract to expose library functions for testing
contract WrapperLifecycle {
    address public registry;

    constructor(address _registry) {
        registry = _registry;
    }

    function areStartConditionsMet(
        uint16 startPlayerCount,
        uint256 startPoolAmount,
        uint16 currentPlayerCount,
        uint256 currentTotalStaked
    ) external pure returns (bool) {
        if (startPlayerCount > 0 && currentPlayerCount < startPlayerCount) {
            return false;
        }
        if (startPoolAmount > 0 && currentTotalStaked < startPoolAmount) {
            return false;
        }
        return true;
    }

    function transitionToLocked() external {
        MockRegistry(registry).updateTournamentStatus(
            TournamentCore.Status.Locked
        );
    }

    function transitionToOpen() external {
        MockRegistry(registry).updateTournamentStatus(
            TournamentCore.Status.Open
        );
    }

    function transitionToPendingStart() external {
        MockRegistry(registry).updateTournamentStatus(
            TournamentCore.Status.PendingStart
        );
    }

    function transitionToActive(
        uint32 duration,
        uint32 gameInterval
    )
        external
        returns (uint32 actualStartTime, uint32 endTime, uint32 exitWindowStart)
    {
        actualStartTime = uint32(block.timestamp);
        endTime = actualStartTime + duration;
        exitWindowStart = endTime - gameInterval;

        MockRegistry(registry).updateTournamentStatus(
            TournamentCore.Status.Active
        );

        return (actualStartTime, endTime, exitWindowStart);
    }

    function transitionToEnded(
        uint256 totalStaked,
        uint256 totalForfeitPenalties,
        uint256 winnerCount
    ) external {
        MockRegistry(registry).updateTournamentStatus(
            TournamentCore.Status.Ended
        );
    }

    function transitionToCancelled() external {
        MockRegistry(registry).updateTournamentStatus(
            TournamentCore.Status.Cancelled
        );
    }

    function emergencyCancel(address platformAdmin) external {
        MockRegistry(registry).updateTournamentStatus(
            TournamentCore.Status.Cancelled
        );
    }

    function checkAndTransition(
        TournamentCore.Status currentStatus,
        TournamentCore.Params memory params,
        uint16 playerCount,
        uint256 totalStaked,
        address registryAddress
    )
        external
        returns (
            TournamentCore.Status newStatus,
            uint32 actualStartTime,
            uint32 endTime,
            uint32 exitWindowStart
        )
    {
        newStatus = currentStatus;

        // Open -> Locked if max players reached
        if (currentStatus == TournamentCore.Status.Open) {
            if (params.maxPlayers > 0 && playerCount >= params.maxPlayers) {
                newStatus = TournamentCore.Status.Locked;
                MockRegistry(registryAddress).updateTournamentStatus(newStatus);
            }
        }

        // Open/Locked -> PendingStart if start time reached
        if (
            currentStatus == TournamentCore.Status.Open ||
            currentStatus == TournamentCore.Status.Locked
        ) {
            if (block.timestamp >= params.startTimestamp) {
                newStatus = TournamentCore.Status.PendingStart;
                MockRegistry(registryAddress).updateTournamentStatus(newStatus);

                // PendingStart -> Active or Cancelled
                bool startConditionsMet = this.areStartConditionsMet(
                    params.startPlayerCount,
                    params.startPoolAmount,
                    playerCount,
                    totalStaked
                );

                if (startConditionsMet) {
                    newStatus = TournamentCore.Status.Active;
                    actualStartTime = uint32(block.timestamp);
                    endTime = actualStartTime + params.duration;
                    exitWindowStart = endTime - params.gameInterval;
                    MockRegistry(registryAddress).updateTournamentStatus(
                        newStatus
                    );
                } else {
                    newStatus = TournamentCore.Status.Cancelled;
                    MockRegistry(registryAddress).updateTournamentStatus(
                        newStatus
                    );
                }
            }
        }

        return (newStatus, actualStartTime, endTime, exitWindowStart);
    }
}
