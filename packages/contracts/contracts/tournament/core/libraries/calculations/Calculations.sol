// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {TournamentCore} from "./../../TournamentCore.sol";

library TournamentCalculations {
    function calculateExitCost(
        uint256 initialCoins,
        uint32 actualStartTime,
        uint16 exitCostBasePercentBPS,
        uint16 exitCostCompoundRateBPS,
        uint32 gameInterval
    ) internal view returns (uint256) {
        uint32 currentTime = uint32(block.timestamp);

        uint256 intervalsPassed = (currentTime - actualStartTime) /
            gameInterval;
        uint256 baseCost = (initialCoins * exitCostBasePercentBPS) / 10000;
        uint256 multiplier = 10000 +
            (exitCostCompoundRateBPS * intervalsPassed);
        return (baseCost * multiplier) / 10000;
    }

    function calculateCurrentCoins(
        uint256 storedCoins,
        uint32 lastDecayTimestamp,
        uint256 decayAmount,
        uint32 gameInterval
    ) internal view returns (uint256) {
        // Cast block.timestamp to uint32 for consistent arithmetic
        uint32 currentTime = uint32(block.timestamp);

        if (currentTime <= lastDecayTimestamp) {
            return storedCoins;
        }

        uint256 intervalsPassed = (currentTime - lastDecayTimestamp) /
            gameInterval;
        uint256 totalDecay = decayAmount * intervalsPassed;
        return storedCoins > totalDecay ? storedCoins - totalDecay : 0;
    }

    function calculateForfeitPenalty(
        uint256 stakeAmount,
        uint32 endTime,
        uint32 duration,
        uint8 forfeitPenaltyType, // 0 = Fixed, 1 = TimeBased
        uint8 forfeitMaxPenalty,
        uint8 forfeitMinPenalty
    ) internal view returns (uint256) {
        uint256 penaltyPercent;

        if (
            forfeitPenaltyType == uint8(TournamentCore.ForfeitPenaltyType.Fixed)
        ) {
            // For fixed penalty, apply the minimum penalty
            penaltyPercent = forfeitMinPenalty;
        } else {
            // For time-base penalty, calculate the percentage to apply
            uint32 currentTime = uint32(block.timestamp);

            uint32 timeRemaining = endTime > currentTime
                ? endTime - currentTime
                : 0;
            penaltyPercent =
                (uint256(forfeitMaxPenalty) * timeRemaining) /
                duration;

            if (penaltyPercent < forfeitMinPenalty) {
                // Clamp to min penalty value in case calculated % is too low
                penaltyPercent = forfeitMinPenalty;
            }
            if (penaltyPercent > forfeitMaxPenalty) {
                // Clamp to max penalty value in case calculated % is too high
                penaltyPercent = forfeitMaxPenalty;
            }
        }
        return (stakeAmount * penaltyPercent) / 100;
    }

    function calculatePrizePerWinner(
        uint256 totalStaked,
        uint256 totalForfeitPenalties,
        uint8 platformFeePercent,
        uint8 creatorFeePercent,
        uint256 winnerCount
    ) internal pure returns (uint256) {
        if (winnerCount == 0) return 0;

        uint256 totalPrizePool = totalStaked + totalForfeitPenalties;
        uint256 platformFee = (totalPrizePool * platformFeePercent) / 100;
        uint256 creatorFee = (totalPrizePool * creatorFeePercent) / 100;
        uint256 distributionPool = totalPrizePool - platformFee - creatorFee;

        return distributionPool / winnerCount;
    }
}
