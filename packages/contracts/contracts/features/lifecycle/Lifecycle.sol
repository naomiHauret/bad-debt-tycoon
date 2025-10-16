// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {TournamentCore} from "./../../core/TournamentCore.sol";
import {TournamentRegistry} from "./../tournament-registry/TournamentRegistry.sol";

library TournamentLifecycle {
    event TournamentLocked(uint32 timestamp);
    event TournamentUnlocked(uint32 timestamp);
    event TournamentPendingStart(uint32 timestamp);
    event TournamentRevertedToOpen(uint32 timestamp);
    event TournamentStarted(uint32 startTime, uint32 endTime);
    event TournamentEnded(
        uint256 winnerCount,
        uint256 prizePool,
        uint32 timestamp
    );
    event TournamentCancelled(uint32 timestamp);
    event EmergencyCancellation(
        address indexed platformAdmin,
        uint256 timestamp
    );

    function transitionToLocked(TournamentRegistry registry) internal {
        registry.updateTournamentStatus(TournamentCore.Status.Locked);
        emit TournamentLocked(uint32(block.timestamp));
    }

    function transitionToOpen(TournamentRegistry registry) internal {
        registry.updateTournamentStatus(TournamentCore.Status.Open);
        emit TournamentUnlocked(uint32(block.timestamp));
    }

    function transitionToPendingStart(TournamentRegistry registry) internal {
        registry.updateTournamentStatus(TournamentCore.Status.PendingStart);
        emit TournamentPendingStart(uint32(block.timestamp));
    }

    function transitionToActive(
        TournamentRegistry registry,
        uint32 duration
    ) internal returns (uint32 actualStartTime, uint32 endTime) {
        actualStartTime = uint32(block.timestamp);
        endTime = actualStartTime + duration;

        registry.updateTournamentStatus(TournamentCore.Status.Active);
        emit TournamentStarted(actualStartTime, endTime);

        return (actualStartTime, endTime);
    }

    function transitionToEnded(
        TournamentRegistry registry,
        uint256 totalStaked,
        uint256 totalForfeitPenalties,
        uint256 winnerCount
    ) internal {
        registry.updateTournamentStatus(TournamentCore.Status.Ended);

        uint256 prizePool = totalStaked + totalForfeitPenalties;
        emit TournamentEnded(winnerCount, prizePool, uint32(block.timestamp));
    }

    function transitionToCancelled(TournamentRegistry registry) internal {
        registry.updateTournamentStatus(TournamentCore.Status.Cancelled);
        emit TournamentCancelled(uint32(block.timestamp));
    }

    function emergencyCancel(
        TournamentRegistry registry,
        address platformAdmin
    ) internal {
        registry.updateTournamentStatus(TournamentCore.Status.Cancelled);
        emit EmergencyCancellation(platformAdmin, block.timestamp);
    }

    function emitRevertToOpen() internal {
        emit TournamentRevertedToOpen(uint32(block.timestamp));
    }

    function checkAndTransition(
        TournamentCore.Status currentStatus,
        TournamentCore.TournamentParams memory params,
        uint16 playerCount,
        uint256 totalStaked,
        TournamentRegistry registry
    )
        external
        returns (
            TournamentCore.Status newStatus,
            uint32 actualStartTime,
            uint32 endTime
        )
    {
        newStatus = currentStatus;

        if (currentStatus == TournamentCore.Status.Open) {
            if (params.maxPlayers > 0 && playerCount >= params.maxPlayers) {
                newStatus = TournamentCore.Status.Locked;
                transitionToLocked(registry);
            }
        }

        if (
            currentStatus == TournamentCore.Status.Open ||
            currentStatus == TournamentCore.Status.Locked
        ) {
            if (block.timestamp >= params.startTimestamp) {
                newStatus = TournamentCore.Status.PendingStart;
                transitionToPendingStart(registry);

                if (
                    areStartConditionsMet(
                        params.startPlayerCount,
                        params.startPoolAmount,
                        playerCount,
                        totalStaked
                    )
                ) {
                    newStatus = TournamentCore.Status.Active;
                    (actualStartTime, endTime) = transitionToActive(
                        registry,
                        params.duration
                    );
                } else {
                    newStatus = TournamentCore.Status.Cancelled;
                    transitionToCancelled(registry);
                }
            }
        }
    }

    function areStartConditionsMet(
        uint16 startPlayerCount,
        uint256 startPoolAmount,
        uint16 currentPlayerCount,
        uint256 currentTotalStaked
    ) public pure returns (bool) {
        if (startPlayerCount > 0 && currentPlayerCount < startPlayerCount) {
            return false;
        }
        if (startPoolAmount > 0 && currentTotalStaked < startPoolAmount) {
            return false;
        }
        return true;
    }
}
