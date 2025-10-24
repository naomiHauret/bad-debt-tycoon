// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {TournamentCore} from "./../../../../core/TournamentCore.sol";
import {TournamentLifecycle} from "./../../../../core/libraries/lifecycle/Lifecycle.sol";
import {TournamentPlayerActions} from "./../../../../core/libraries/player-actions/PlayerActions.sol";
import {TournamentRegistry} from "./../../../../infrastructure/registry/TournamentRegistry.sol";

library TournamentHubStatus {
    struct StatusUpdateResult {
        TournamentCore.Status newStatus;
        uint32 newActualStartTime;
        uint32 newEndTime;
        uint32 newExitWindowStart;
        bool shouldEmitExitWindow;
        bool shouldTransitionToEnded;
    }

    function applyDecayAndUpdateStatus(
        mapping(address => TournamentCore.PlayerResources) storage players,
        TournamentCore.Params storage params,
        TournamentCore.Status currentStatus,
        uint16 playerCount,
        uint256 totalStaked,
        uint256 totalForfeitPenalties,
        uint256 endTime,
        uint256 winnersLength,
        TournamentRegistry registry,
        address sender
    ) external returns (StatusUpdateResult memory result) {
        // Apply decay first
        TournamentPlayerActions.applyDecay(
            players[sender],
            sender,
            params.decayAmount,
            params.gameInterval
        );

        // Check and transition status
        (
            result.newStatus,
            result.newActualStartTime,
            result.newEndTime,
            result.newExitWindowStart
        ) = TournamentLifecycle.checkAndTransition(
            currentStatus,
            params,
            playerCount,
            totalStaked,
            registry
        );

        result.shouldEmitExitWindow = result.newExitWindowStart > 0;

        // Check if should transition to ended
        if (
            result.newStatus == TournamentCore.Status.Active &&
            block.timestamp >= endTime
        ) {
            TournamentLifecycle.transitionToEnded(
                registry,
                totalStaked,
                totalForfeitPenalties,
                winnersLength
            );
            result.newStatus = TournamentCore.Status.Ended;
            result.shouldTransitionToEnded = true;
        }
    }

    function updateStatusOnly(
        TournamentCore.Params storage params,
        TournamentCore.Status currentStatus,
        uint16 playerCount,
        uint256 totalStaked,
        uint256 totalForfeitPenalties,
        uint256 endTime,
        uint256 winnersLength,
        TournamentRegistry registry
    ) external returns (StatusUpdateResult memory result) {
        (
            result.newStatus,
            result.newActualStartTime,
            result.newEndTime,
            result.newExitWindowStart
        ) = TournamentLifecycle.checkAndTransition(
            currentStatus,
            params,
            playerCount,
            totalStaked,
            registry
        );

        result.shouldEmitExitWindow = result.newExitWindowStart > 0;

        if (
            result.newStatus == TournamentCore.Status.Active &&
            block.timestamp >= endTime
        ) {
            TournamentLifecycle.transitionToEnded(
                registry,
                totalStaked,
                totalForfeitPenalties,
                winnersLength
            );
            result.newStatus = TournamentCore.Status.Ended;
            result.shouldTransitionToEnded = true;
        }
    }

    function checkEarlyEnd(
        uint16 activePlayerCount,
        uint256 totalStaked,
        uint256 totalForfeitPenalties,
        uint256 winnersLength,
        TournamentRegistry registry
    ) external returns (bool shouldEnd) {
        if (activePlayerCount == 0) {
            TournamentLifecycle.transitionToEnded(
                registry,
                totalStaked,
                totalForfeitPenalties,
                winnersLength
            );
            return true;
        }
        return false;
    }
}
