// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {TournamentCore} from "./../../../../core/TournamentCore.sol";
import {TournamentPlayerActions} from "./../../../../core/libraries/player-actions/PlayerActions.sol";
import {TournamentLifecycle} from "./../../../../core/libraries/lifecycle/Lifecycle.sol";
import {TournamentRegistry} from "./../../../../infrastructure/registry/TournamentRegistry.sol";

library TournamentHubPlayer {
    event ExitWindowOpened(uint32 windowStart, uint32 windowEnd);

    error InvalidStatus();
    error AlreadyJoined();
    error CannotExit();
    error ExitWindowNotOpen();
    error ForfeitNotAllowed();
    error AlreadyForfeited();
    error AlreadyExited();

    struct JoinResult {
        TournamentCore.Status newStatus;
        uint32 newActualStartTime;
        uint32 newEndTime;
        uint32 newExitWindowStart;
    }

    function processJoin(
        mapping(address => TournamentCore.PlayerResources) storage players,
        TournamentCore.Params storage params,
        TournamentCore.Status status,
        uint16 playerCount,
        uint256 totalStaked,
        TournamentRegistry registry,
        address sender,
        uint256 stakeAmount
    ) external returns (JoinResult memory result) {
        if (status != TournamentCore.Status.Open) revert InvalidStatus();
        if (players[sender].exists) revert AlreadyJoined();

        TournamentPlayerActions.validateEntry(
            params.minStake,
            params.maxStake,
            params.maxPlayers,
            stakeAmount,
            playerCount
        );

        TournamentPlayerActions.processJoin(
            players[sender],
            params.stakeToken,
            sender,
            stakeAmount,
            params.coinConversionRate,
            params.initialLives,
            params.cardsPerType
        );

        (
            result.newStatus,
            result.newActualStartTime,
            result.newEndTime,
            result.newExitWindowStart
        ) = TournamentLifecycle.checkAndTransition(
            status,
            params,
            playerCount + 1,
            totalStaked + stakeAmount,
            registry
        );
    }

    function processExit(
        mapping(address => TournamentCore.PlayerResources) storage players,
        address[] storage winners,
        TournamentCore.Status status,
        uint32 exitWindowStart,
        address sender,
        bool canExit
    ) external {
        if (status != TournamentCore.Status.Active) revert InvalidStatus();
        if (block.timestamp < exitWindowStart) revert ExitWindowNotOpen();
        if (!canExit) revert CannotExit();

        TournamentPlayerActions.processExit(players[sender], sender);
        winners.push(sender);
    }

    function processForfeit(
        mapping(address => TournamentCore.PlayerResources) storage players,
        TournamentCore.Params storage params,
        TournamentCore.Status status,
        address sender,
        uint256 penaltyAmount
    ) external {
        if (status != TournamentCore.Status.Active) revert InvalidStatus();
        if (!params.forfeitAllowed) revert ForfeitNotAllowed();

        TournamentCore.PlayerResources storage player = players[sender];
        if (player.status == TournamentCore.PlayerStatus.Forfeited)
            revert AlreadyForfeited();
        if (player.status == TournamentCore.PlayerStatus.Exited)
            revert AlreadyExited();

        TournamentPlayerActions.processForfeit(
            player,
            params.stakeToken,
            sender,
            penaltyAmount
        );
    }
}
