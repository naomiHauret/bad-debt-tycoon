// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {TournamentCalculations} from "./Calculations.sol";
import {Test} from "forge-std/Test.sol";

contract CalculationsTest is Test {
    WrapperCalculations wrapper;
    uint256 initialCoins;
    uint128 stakeAmount;
    uint8 maxPenalty;
    uint8 minPenalty;
    uint16 exitCostBasePercentBPS;
    uint16 exitCostCompoundRateBPS;
    uint256 exitCostInterval;
    uint256 decayAmount;
    uint256 decayInterval;

    function setUp() public {
        wrapper = new WrapperCalculations();
        initialCoins = 400;
        stakeAmount = 1000;
        // exit costs
        exitCostBasePercentBPS = 5000; // 50% base
        exitCostCompoundRateBPS = 1000; // 10% compound rate
        exitCostInterval = 3600; // 1 hour interval (exit cost)
        // decay
        decayAmount = 10; // 10 coins per interval
        decayInterval = 1200; // 20 min interval (decay)
        // forfeit
        maxPenalty = 80;
        minPenalty = 20;
    }

    // -- calculateExitCost

    // Should not error with 0 as params
    function test_CalculateExitCost_ZeroInputs() public {
        // With zero initial coins
        uint256 cost = wrapper.calculateExitCost(
            0,
            block.timestamp,
            exitCostBasePercentBPS,
            exitCostCompoundRateBPS,
            exitCostInterval
        );
        assertEq(cost, 0);

        // With zero base percentage
        cost = wrapper.calculateExitCost(
            initialCoins,
            block.timestamp,
            0,
            exitCostCompoundRateBPS,
            exitCostInterval
        );
        assertEq(cost, 0);

        // With zero compound rate (should still have base cost)
        cost = wrapper.calculateExitCost(
            initialCoins,
            block.timestamp,
            exitCostBasePercentBPS,
            0,
            exitCostInterval
        );
        assertEq(cost, 200); // Just base cost
    }

    // Should only apply base percent exit cost to initial coin amount at H0 (no compounding)
    function test_CalculateExitCost_AtStart() public {
        //  400 initial coins, 50% base (5000 BPS), at hour 0
        uint256 startTime = block.timestamp;
        uint256 actualStartTime = startTime;

        uint256 exitCost = wrapper.calculateExitCost(
            initialCoins,
            startTime,
            exitCostBasePercentBPS,
            exitCostCompoundRateBPS,
            exitCostInterval
        );

        // At hour 0: baseCost = 200, multiplier = 10000, exitCost = 200
        assertEq(exitCost, 200);
    }

    // Should apply exitCostCompoundRateBPS compound after each interval
    function test_CalculateExitCost_ApplyAfterEachInterval() public {
        uint256 startTime = block.timestamp;
        uint256 actualStartTime = startTime;

        // Fast forward 1 interval
        vm.warp(block.timestamp + exitCostInterval);

        uint256 exitCost = wrapper.calculateExitCost(
            initialCoins,
            startTime,
            exitCostBasePercentBPS,
            exitCostCompoundRateBPS,
            exitCostInterval
        );

        // At hour 1: intervals = 1, multiplier = 11000, exitCost = 220
        assertEq(exitCost, 220);

        // Fast forward another interval
        vm.warp(block.timestamp + exitCostInterval);

        exitCost = wrapper.calculateExitCost(
            initialCoins,
            startTime,
            exitCostBasePercentBPS,
            exitCostCompoundRateBPS,
            exitCostInterval
        );

        // At hour 2: intervals = 2, multiplier = 12000, exitCost = 240
        assertEq(exitCost, 240);
    }

    // Should ignore partial intervals
    function test_CalculateExitCost_IgnorePartialInterval() public {
        uint256 startTime = block.timestamp;

        // Fast forward a partial interval
        vm.warp(block.timestamp + 3000);
        uint256 exitCost = wrapper.calculateExitCost(
            initialCoins,
            startTime,
            exitCostBasePercentBPS,
            exitCostCompoundRateBPS,
            exitCostInterval
        );

        // With 0 complete intervals, should be just the base cost
        uint256 expectedBaseCost = (initialCoins * exitCostBasePercentBPS) /
            10000;
        // expectedBaseCost = (400 * 5000) / 10000 = 200
        assertEq(exitCost, expectedBaseCost);
    }

    // Costs should grow over time
    function test_CalculateExitCost_CompoundGrowth() public {
        uint256 startTime = block.timestamp;
        vm.warp(startTime + 3600); // 1 hour
        uint256 cost1h = wrapper.calculateExitCost(
            initialCoins,
            startTime,
            exitCostBasePercentBPS,
            exitCostCompoundRateBPS,
            exitCostInterval
        );

        vm.warp(startTime + 7200); // 2 hours
        uint256 cost2h = wrapper.calculateExitCost(
            initialCoins,
            startTime,
            exitCostBasePercentBPS,
            exitCostCompoundRateBPS,
            exitCostInterval
        );

        vm.warp(startTime + 10800); // 3 hours
        uint256 cost3h = wrapper.calculateExitCost(
            initialCoins,
            startTime,
            exitCostBasePercentBPS,
            exitCostCompoundRateBPS,
            exitCostInterval
        );

        assertLt(cost1h, cost2h, "Cost should increase from hour 1 to 2");
        assertLt(cost2h, cost3h, "Cost should increase from hour 2 to 3");

        assertEq(cost1h, 220); // baseCost=200, +10%
        assertEq(cost2h, 240); // baseCost=200, +20%
        assertEq(cost3h, 260); // baseCost=200, +30%
    }

    // -- calculateCurrentCoins

    // Should not apply decay before interval elapsed
    function test_CalculateCurrentCoins_NoDecayBeforeElapsedInterval() public {
        uint256 currentCoins = wrapper.calculateCurrentCoins(
            initialCoins, // storedCoins
            block.timestamp, // lastDecayTimestamp (now)
            decayAmount,
            decayInterval
        );

        assertEq(currentCoins, initialCoins);
    }

    // Decay should apply (coin amount decreases) after 1 interval
    function test_CalculateCurrentCoins_ApplyDecayAfterElapsedInterval()
        public
    {
        uint256 lastDecay = block.timestamp;

        // Fast forward 20 minutes (1 interval)
        vm.warp(block.timestamp + decayInterval);

        uint256 currentCoins = wrapper.calculateCurrentCoins(
            initialCoins,
            lastDecay,
            decayAmount,
            decayInterval
        );

        assertEq(currentCoins, initialCoins - decayAmount);
    }

    // Should apply decay equivalent to decayAmount multiplied by elapsed interval amount
    function test_CalculateCurrentCoins_DecaysWithEachInterval() public {
        uint256 lastDecay = block.timestamp;

        // Fast forward 3 intervals
        vm.warp(block.timestamp + decayInterval * 3);

        uint256 currentCoins = wrapper.calculateCurrentCoins(
            initialCoins,
            lastDecay,
            decayAmount,
            decayInterval
        );

        // 3 intervals * 10 decay = 30 coins lost
        assertEq(currentCoins, initialCoins - decayAmount * 3);
    }

    // Partial interval should not apply decay
    function test_CalculateCurrentCoins_ShouldNotApplyDecayWithPartialInterval()
        public
    {
        uint256 lastDecay = block.timestamp;

        // Fast forward just before interval elapses
        vm.warp(block.timestamp + decayInterval - 1);

        uint256 currentCoins = wrapper.calculateCurrentCoins(
            initialCoins,
            lastDecay,
            decayAmount,
            decayInterval
        );

        assertEq(currentCoins, initialCoins);
    }

    // Should not decay player coins below 0
    function test_CalculateCurrentCoins_ClampToPlayerCoinsToZero() public {
        uint256 lastDecay = block.timestamp;

        // Fast forward enough to decay all coins
        vm.warp(block.timestamp + decayInterval * 10);

        uint256 currentCoins = wrapper.calculateCurrentCoins(
            1,
            lastDecay,
            decayAmount,
            decayInterval
        );

        assertEq(currentCoins, 0);
    }

    function test_CalculateCurrentCoins_WithZeroAsParams() public {
        // Decay should clamp to 0
        uint256 baseTime = 1000000;

        uint256 currentCoins = wrapper.calculateCurrentCoins(
            100,
            baseTime,
            50,
            1800
        );

        // Warp to 2 hours later
        vm.warp(baseTime + 7200);

        currentCoins = wrapper.calculateCurrentCoins(100, baseTime, 50, 1800);
        // 4 intervals * 50 = 200 decay, but only 100 coins available
        assertEq(currentCoins, 0);

        // With decayAmount = 0, no decay should apply
        currentCoins = wrapper.calculateCurrentCoins(
            400,
            block.timestamp,
            0,
            decayInterval
        );
        assertEq(currentCoins, 400);

        // With T=0 no decay should apply
        currentCoins = wrapper.calculateCurrentCoins(
            400,
            block.timestamp,
            10,
            decayInterval
        );
        assertEq(currentCoins, 400);
    }

    // -- calculateForfeitPenalty Tests

    // Should return minimum penalty value when calculating fixed penalty
    function test_CalculateForfeitPenalty_FixedType() public {
        uint256 penalty = wrapper.calculateForfeitPenalty(
            stakeAmount,
            block.timestamp + 3600, // end time
            3600, // duration (1 hour total)
            0, // Fixed penalty (fixed % of stake)
            30, // maxPenalty,
            20 // minPenalty
        );

        // Fixed penalty: 1000 * 20 / 100 = 200
        assertEq(penalty, 200);
    }

    // Should calculate penalty in real time when penalty is time based
    function test_CalculateForfeitPenalty_TimeBased_RealTime() public {
        uint256 endTime = block.timestamp + 3600;

        // Fast forward 30 minutes (halfway)
        vm.warp(block.timestamp + 1800);

        uint256 penalty = wrapper.calculateForfeitPenalty(
            1000,
            endTime,
            3600,
            1,
            80,
            10
        );

        // Halfway: timeRemaining = 1800, penaltyPercent = (80 * 1800) / 3600 = 40%
        // Penalty = 1000 * 40 / 100 = 400
        assertEq(penalty, 400);
    }

    // Should ensure penalty is within bound (clamp to min if it falls below)
    function test_CalculateForfeitPenalty_TimeBased_WithinRange_MinClamp()
        public
    {
        uint256 endTime = block.timestamp + 3600;

        // Fast forward to end
        vm.warp(endTime);

        uint256 penalty = wrapper.calculateForfeitPenalty(
            1000,
            endTime,
            3600,
            1,
            80,
            10 // min 10%
        );

        // At end: timeRemaining = 0, penaltyPercent = 0, but clamped to min 10%
        // Penalty = 1000 * 10 / 100 = 100
        assertEq(penalty, 100);
    }

    // Should ensure penalty is within bound (clamp to max if it is above)
    function test_CalculateForfeitPenalty_TimeBased_WithinRange_MaxClamp()
        public
    {
        uint256 endTime = block.timestamp + 3600;

        uint256 penalty = wrapper.calculateForfeitPenalty(
            1000,
            endTime,
            3600,
            1,
            50, // Max 50%
            10
        );

        // Calculated: (50 * 3600) / 3600 = 50%, which equals max
        assertEq(penalty, 500);
    }

    function test_CalculateForfeitPenalty_Range(
        uint128 _stakeAmount,
        uint8 _maxPenalty,
        uint8 _minPenalty
    ) public {
        vm.assume(_stakeAmount > 0);
        vm.assume(_stakeAmount <= 1e24);
        vm.assume(_maxPenalty <= 100);
        vm.assume(_minPenalty <= _maxPenalty);
        uint256 penalty = wrapper.calculateForfeitPenalty(
            _stakeAmount,
            block.timestamp + 3600,
            3600,
            1,
            _maxPenalty,
            _minPenalty
        );

        // Penalty should be within bounds
        uint256 maxPossible = (_stakeAmount * _maxPenalty) / 100;
        uint256 minPossible = (_stakeAmount * _minPenalty) / 100;

        assertLe(penalty, maxPossible);
        assertGe(penalty, minPossible);
    }

    //
    function test_CalculateForfeitPenalty_BoundaryPercentages() public {
        // With zero (min/max), penalty should be 0
        uint256 penalty = wrapper.calculateForfeitPenalty(
            1000,
            block.timestamp + 3600,
            3600,
            0,
            0,
            0
        );
        assertEq(penalty, 0);

        // With 100 (min/max), penalty should be entire stake
        penalty = wrapper.calculateForfeitPenalty(
            1000,
            block.timestamp + 3600,
            3600,
            0,
            100,
            100
        );
        assertEq(penalty, 1000);
    }

    // -- calculatePrizePerWinner

    // Should apply platform fee, winners should get equal share
    function test_CalculatePrizePerWinner_MultipleWinners_ApplyPlatformFee()
        public
    {
        uint256 prize = wrapper.calculatePrizePerWinner(
            10000, // total staked
            0,
            1,
            0,
            3 // 3 winners
        );

        // Pool: 10000, platform fee: 100, distribution: 9900, per winner: 3300
        assertEq(prize, 3300);
    }

    // If forfeits, should include them to prize pool
    function test_CalculatePrizePerWinner_IncludeForfeitPenalties() public {
        uint256 prize = wrapper.calculatePrizePerWinner(
            10000, // total staked
            2000, // forfeit penalties added to pool
            1,
            0,
            2
        );

        // Pool: 12000, platform fee: 120, distribution: 11880, per winner: 5940
        assertEq(prize, 5940);
    }

    // Should apply all fess
    function test_CalculatePrizePerWinner_WithCreatorFee() public {
        uint256 prize = wrapper.calculatePrizePerWinner(
            10000,
            0,
            1, // 1% platform
            2, // 2% creator
            1
        );

        // Pool: 10000, fees: 300 (100 + 200), distribution: 9700
        assertEq(prize, 9700);
    }

    // Should return 0 when no winners
    function test_CalculatePrizePerWinner_ZeroWinners() public {
        uint256 prize = wrapper.calculatePrizePerWinner(
            10000,
            0,
            1,
            0,
            0 // 0 winners
        );

        assertEq(prize, 0);
    }

    function test_CalculatePrizePerWinner_RoundDown() public {
        uint256 prize = wrapper.calculatePrizePerWinner(100, 0, 0, 0, 3);

        assertEq(prize, 33);
    }

    // -- Economy collapse
    // Game economy should collapse given certain params
    // See docs
    function test_EconomicCollapse() public {
        uint256 startTime = block.timestamp;

        vm.warp(startTime + 4 * 3600);

        uint256 coinsAfterDecay = wrapper.calculateCurrentCoins(
            400,
            startTime,
            10,
            1200
        );
        uint256 exitCost = wrapper.calculateExitCost(
            400,
            startTime,
            5000,
            1000,
            3600
        );

        // H4: coins=280, exitCost=280
        assertEq(coinsAfterDecay, 280, "Coins should be 280 after 4 hours");
        assertEq(exitCost, 280, "Exit cost should be 280 after 4 hours");

        vm.warp(startTime + 5 * 3600); // H5
        coinsAfterDecay = wrapper.calculateCurrentCoins(
            400,
            startTime,
            10,
            1200
        );
        exitCost = wrapper.calculateExitCost(400, startTime, 5000, 1000, 3600);

        assertLt(
            coinsAfterDecay,
            exitCost,
            "At hour 5, without any actions, should not be able to exit"
        );
    }
}

// Wrapper contract to expose library functions for testing
contract WrapperCalculations {
    function calculateExitCost(
        uint256 initialCoins,
        uint256 actualStartTime,
        uint16 exitCostBasePercentBPS,
        uint16 exitCostCompoundRateBPS,
        uint256 exitCostInterval
    ) external view returns (uint256) {
        return
            TournamentCalculations.calculateExitCost(
                initialCoins,
                actualStartTime,
                exitCostBasePercentBPS,
                exitCostCompoundRateBPS,
                exitCostInterval
            );
    }

    function calculateCurrentCoins(
        uint256 storedCoins,
        uint256 lastDecayTimestamp,
        uint256 decayAmount,
        uint256 decayInterval
    ) external view returns (uint256) {
        return
            TournamentCalculations.calculateCurrentCoins(
                storedCoins,
                lastDecayTimestamp,
                decayAmount,
                decayInterval
            );
    }

    function calculateForfeitPenalty(
        uint256 stakeAmount,
        uint256 endTime,
        uint256 duration,
        uint8 forfeitPenaltyType,
        uint8 forfeitMaxPenalty,
        uint8 forfeitMinPenalty
    ) external view returns (uint256) {
        return
            TournamentCalculations.calculateForfeitPenalty(
                stakeAmount,
                endTime,
                duration,
                forfeitPenaltyType,
                forfeitMaxPenalty,
                forfeitMinPenalty
            );
    }

    function calculatePrizePerWinner(
        uint256 totalStaked,
        uint256 totalForfeitPenalties,
        uint8 platformFeePercent,
        uint8 creatorFeePercent,
        uint256 winnerCount
    ) external pure returns (uint256) {
        return
            TournamentCalculations.calculatePrizePerWinner(
                totalStaked,
                totalForfeitPenalties,
                platformFeePercent,
                creatorFeePercent,
                winnerCount
            );
    }
}
