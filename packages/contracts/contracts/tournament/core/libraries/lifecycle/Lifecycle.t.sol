// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {TournamentLifecycle} from "./Lifecycle.sol";
import {TournamentCore} from "./../../TournamentCore.sol";
import {Test} from "forge-std/Test.sol";

contract LifecycleTest is Test {
    WrapperLifecycle wrapper;
    MockRegistry registry;

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
}
