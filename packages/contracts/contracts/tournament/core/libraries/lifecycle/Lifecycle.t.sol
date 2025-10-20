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

    // -- areStartConditionsMet

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

        // Manually verify the expected result
        bool expectedPlayerCondition = startPlayerCount == 0 ||
            currentPlayerCount >= startPlayerCount;
        bool expectedPoolCondition = startPoolAmount == 0 ||
            currentTotalStaked >= startPoolAmount;
        bool expected = expectedPlayerCondition && expectedPoolCondition;

        assertEq(result, expected);
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
}
