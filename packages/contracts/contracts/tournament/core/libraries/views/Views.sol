// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {TournamentCore} from "./../../TournamentCore.sol";
import {TournamentCalculations} from "./../calculations/Calculations.sol";

library TournamentViews {
    function getCurrentCoins(
        TournamentCore.PlayerResources memory player,
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
        TournamentCore.PlayerResources memory player,
        uint32 actualStartTime,
        uint16 exitCostBasePercentBPS,
        uint16 exitCostCompoundRateBPS,
        uint32 gameInterval
    ) external view returns (uint256) {
        if (status != TournamentCore.Status.Active) return 0;
        if (!player.exists) return 0;

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
        TournamentCore.PlayerResources memory player,
        uint256 currentCoins,
        uint256 exitCost,
        uint8 exitLivesRequired
    ) external pure returns (bool) {
        if (!player.exists) return false;
        if (status != TournamentCore.Status.Active) return false;
        if (player.status != TournamentCore.PlayerStatus.Active) return false;

        return (player.lives >= exitLivesRequired &&
            player.totalCards == 0 &&
            currentCoins >= exitCost);
    }

    function calculateForfeitPenalty(
        TournamentCore.PlayerResources memory player,
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

    function calculateRecommendedDuration(
        uint8 cardsPerType,
        uint32 recommendedSecondsPerCard,
        uint32 minDuration
    ) external pure returns (uint32) {
        uint32 totalCards = uint32(cardsPerType) * 3;
        uint32 cardBasedRecommended = totalCards * recommendedSecondsPerCard;
        return
            cardBasedRecommended > minDuration
                ? cardBasedRecommended
                : minDuration;
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
        isOpen =
            block.timestamp >= exitWindowStart &&
            block.timestamp < endTime;
    }
}
