// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library TournamentCalculations {
    function calculateExitCost(
        uint256 initialCoins,
        uint256 actualStartTime,
        uint16 exitCostBasePercentBPS,
        uint16 exitCostCompoundRateBPS,
        uint256 exitCostInterval
    ) internal view returns (uint256) {
        uint256 intervalsPassed = (block.timestamp - actualStartTime) /
            exitCostInterval;
        uint256 baseCost = (initialCoins * exitCostBasePercentBPS) / 10000;
        uint256 multiplier = 10000 +
            (exitCostCompoundRateBPS * intervalsPassed);
        return (baseCost * multiplier) / 10000;
    }

    function calculateCurrentCoins(
        uint256 storedCoins,
        uint256 lastDecayTimestamp,
        uint256 decayAmount,
        uint256 decayInterval
    ) internal view returns (uint256) {
        if (block.timestamp <= lastDecayTimestamp) {
            return storedCoins;
        }
        uint256 intervalsPassed = (block.timestamp - lastDecayTimestamp) /
            decayInterval;
        uint256 totalDecay = decayAmount * intervalsPassed;
        return storedCoins > totalDecay ? storedCoins - totalDecay : 0;
    }

    function calculateForfeitPenalty(
        uint256 stakeAmount,
        uint256 endTime,
        uint256 duration,
        uint8 forfeitPenaltyType, // 0 = Fixed, 1 = TimeBased
        uint8 forfeitMaxPenalty,
        uint8 forfeitMinPenalty
    ) internal view returns (uint256) {
        uint256 penaltyPercent;

        if (forfeitPenaltyType == 0) {
            penaltyPercent = forfeitMinPenalty;
        } else {
            uint256 timeRemaining = endTime > block.timestamp
                ? endTime - block.timestamp
                : 0;
            penaltyPercent = (forfeitMaxPenalty * timeRemaining) / duration;

            if (penaltyPercent < forfeitMinPenalty) {
                penaltyPercent = forfeitMinPenalty;
            }
            if (penaltyPercent > forfeitMaxPenalty) {
                penaltyPercent = forfeitMaxPenalty;
            }
        }
        if (stakeAmount > type(uint256).max / 100) {
            return (stakeAmount / 100) * penaltyPercent;
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
