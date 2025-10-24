// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {TournamentCore} from "./../../TournamentCore.sol";
import {TournamentCalculations} from "./../calculations/Calculations.sol";

library TournamentViews {
    error NotFound();

    function getCurrentCoins(
        TournamentCore.PlayerResources calldata player,
        uint256 decayAmount,
        uint32 gameInterval
    ) external view returns (uint256) {
        if (!player.exists) return 0;

        return
            TournamentCalculations.calculateCurrentCoins(
                player.coins,
                player.lastDecayTimestamp,
                decayAmount,
                gameInterval
            );
    }

    function calculateExitCost(
        TournamentCore.Status status,
        TournamentCore.PlayerResources calldata player,
        uint32 actualStartTime,
        uint16 exitCostBasePercentBPS,
        uint16 exitCostCompoundRateBPS,
        uint32 gameInterval
    ) external view returns (uint256) {
        if (status != TournamentCore.Status.Active || !player.exists) return 0;

        return
            TournamentCalculations.calculateExitCost(
                player.initialCoins,
                actualStartTime,
                exitCostBasePercentBPS,
                exitCostCompoundRateBPS,
                gameInterval
            );
    }

    function canExit(
        TournamentCore.Status status,
        TournamentCore.PlayerResources calldata player,
        uint256 currentCoins,
        uint256 exitCost,
        uint8 exitLivesRequired
    ) external pure returns (bool) {
        if (status != TournamentCore.Status.Active) return false;
        if (player.status != TournamentCore.PlayerStatus.Active) return false;
        if (!player.exists) return false;
        if (player.lives < exitLivesRequired) return false;
        if (player.totalCards != 0) return false;
        if (currentCoins < exitCost) return false;

        return true;
    }

    function calculateForfeitPenalty(
        TournamentCore.PlayerResources calldata player,
        uint32 endTime,
        uint32 duration,
        uint8 forfeitPenaltyType,
        uint8 forfeitMaxPenalty,
        uint8 forfeitMinPenalty
    ) external view returns (uint256) {
        if (!player.exists) return 0;

        return
            TournamentCalculations.calculateForfeitPenalty(
                player.stakeAmount,
                endTime,
                duration,
                forfeitPenaltyType,
                forfeitMaxPenalty,
                forfeitMinPenalty
            );
    }

    function getCurrentPlayerResources(
        TournamentCore.PlayerResources memory player,
        uint256 currentCoins
    ) external pure returns (TournamentCore.PlayerResources memory) {
        player.coins = currentCoins;
        return player;
    }

    function calculatePrizePerWinner(
        uint256 totalStaked,
        uint256 totalForfeitPenalties,
        uint8 platformFeePercent,
        uint8 creatorFeePercent,
        uint256 winnersLength
    ) external pure returns (uint256) {
        return
            TournamentCalculations.calculatePrizePerWinner(
                totalStaked,
                totalForfeitPenalties,
                platformFeePercent,
                creatorFeePercent,
                winnersLength
            );
    }

    function getExitWindow(
        uint32 exitWindowStart,
        uint32 endTime
    )
        external
        view
        returns (uint32 windowStart, uint32 windowEnd, bool isOpen)
    {
        windowStart = exitWindowStart;
        windowEnd = endTime;

        if (block.timestamp < exitWindowStart) {
            isOpen = false;
            return (windowStart, windowEnd, isOpen);
        }

        isOpen = block.timestamp < endTime;
    }

    function getCurrentCoinsFromStorage(
        mapping(address => TournamentCore.PlayerResources) storage players,
        TournamentCore.Params storage params,
        address player
    ) external view returns (uint256) {
        return
            TournamentCalculations.calculateCurrentCoins(
                players[player].coins,
                players[player].lastDecayTimestamp,
                params.decayAmount,
                params.gameInterval
            );
    }

    function calculateExitCostFromStorage(
        mapping(address => TournamentCore.PlayerResources) storage players,
        TournamentCore.Params storage params,
        TournamentCore.Status status,
        uint32 actualStartTime,
        address player
    ) external view returns (uint256) {
        if (status != TournamentCore.Status.Active) return 0;
        if (!players[player].exists) return 0;

        return
            TournamentCalculations.calculateExitCost(
                players[player].initialCoins,
                actualStartTime,
                params.exitCostBasePercentBPS,
                params.exitCostCompoundRateBPS,
                params.gameInterval
            );
    }

    function canExitFromStorage(
        mapping(address => TournamentCore.PlayerResources) storage players,
        TournamentCore.Params storage params,
        TournamentCore.Status status,
        uint32 actualStartTime,
        address player
    ) external view returns (bool) {
        if (status != TournamentCore.Status.Active) return false;

        TournamentCore.PlayerResources storage playerData = players[player];
        if (!playerData.exists) return false;
        if (playerData.status != TournamentCore.PlayerStatus.Active)
            return false;
        if (playerData.lives < params.exitLivesRequired) return false;
        if (playerData.totalCards != 0) return false;

        uint256 currentCoins = TournamentCalculations.calculateCurrentCoins(
            playerData.coins,
            playerData.lastDecayTimestamp,
            params.decayAmount,
            params.gameInterval
        );

        uint256 exitCost = TournamentCalculations.calculateExitCost(
            playerData.initialCoins,
            actualStartTime,
            params.exitCostBasePercentBPS,
            params.exitCostCompoundRateBPS,
            params.gameInterval
        );

        return currentCoins >= exitCost;
    }

    function calculateForfeitPenaltyFromStorage(
        mapping(address => TournamentCore.PlayerResources) storage players,
        TournamentCore.Params storage params,
        uint32 endTime,
        address player
    ) external view returns (uint256) {
        if (!players[player].exists) return 0;

        return
            TournamentCalculations.calculateForfeitPenalty(
                players[player].stakeAmount,
                endTime,
                params.duration,
                uint8(params.forfeitPenaltyType),
                params.forfeitMaxPenalty,
                params.forfeitMinPenalty
            );
    }

    function getCurrentPlayerResourcesFromStorage(
        mapping(address => TournamentCore.PlayerResources) storage players,
        TournamentCore.Params storage params,
        address player
    ) external view returns (TournamentCore.PlayerResources memory) {
        if (!players[player].exists) revert NotFound();

        TournamentCore.PlayerResources memory playerData = players[player];

        playerData.coins = TournamentCalculations.calculateCurrentCoins(
            playerData.coins,
            playerData.lastDecayTimestamp,
            params.decayAmount,
            params.gameInterval
        );

        return playerData;
    }

    function getPlayerFromStorage(
        mapping(address => TournamentCore.PlayerResources) storage players,
        address player
    ) external view returns (TournamentCore.PlayerResources memory) {
        if (!players[player].exists) revert NotFound();
        return players[player];
    }
}
