// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {TournamentCore} from "./../../../../core/TournamentCore.sol";
import {TournamentTokenWhitelist} from "./../../../token-whitelist/TournamentTokenWhitelist.sol";

library TournamentFactoryValidation {
    error InvalidAddress();
    error InvalidStartTimestamp();
    error InvalidCardsPerType();
    error MinPlayersInvalid();
    error MaxPlayersInvalid();
    error InvalidStartPlayerCount();
    error DurationTooShort();
    error IntervalTooShort();
    error DurationTooShortForInterval();
    error CreatorFeeTooHigh();
    error CombinedFeesTooHigh();
    error InvalidStakeToken();
    error MinStakeExceedsMaxStake();
    error InvalidDecayAmount();
    error InvalidExitCostBase();
    error InvalidCoinConversionRate();
    error InvalidInitialLives();
    error InvalidExitLivesRequired();
    error InvalidForfeitPenaltyBounds();
    error ForfeitMinPenaltyExceedsMax();
    error InvalidDeckCost();

    function validateParams(
        TournamentCore.Params calldata params,
        TournamentTokenWhitelist whitelist
    ) external view {
        if (params.coinConversionRate == 0) revert InvalidCoinConversionRate();
        if (params.decayAmount == 0) revert InvalidDecayAmount();
        if (params.initialLives == 0) revert InvalidInitialLives();
        if (params.exitLivesRequired == 0) revert InvalidExitLivesRequired();
        if (params.exitCostBasePercentBPS == 0) revert InvalidExitCostBase();
        if (params.deckDrawCost == 0) revert InvalidDeckCost();
        if (params.deckShuffleCost == 0) revert InvalidDeckCost();
        if (params.deckPeekCost == 0) revert InvalidDeckCost();
        if (params.deckCatalog == address(0)) revert InvalidAddress();

        validateTimingParams(params);
        validatePlayerParams(params);
        validateEconomicParams(params, whitelist);
    }

    function validateTimingParams(
        TournamentCore.Params calldata params
    ) public view {
        if (params.startTimestamp <= block.timestamp)
            revert InvalidStartTimestamp();
        if (params.duration < TournamentCore.MIN_DURATION)
            revert DurationTooShort();
        if (params.gameInterval < TournamentCore.MIN_GAME_INTERVAL)
            revert IntervalTooShort();

        uint256 maxIntervals = params.duration / params.gameInterval;
        if (maxIntervals < TournamentCore.MIN_INTERVALS_REQUIRED)
            revert DurationTooShortForInterval();

        if (params.decayAmount > type(uint128).max / maxIntervals) {
            revert InvalidDecayAmount();
        }
    }

    function validatePlayerParams(
        TournamentCore.Params calldata params
    ) public pure {
        if (params.minPlayers < TournamentCore.MIN_PLAYERS_REQUIRED)
            revert MinPlayersInvalid();

        if (
            params.minPlayers >= TournamentCore.MIN_PLAYERS_REQUIRED &&
            params.startPlayerCount < params.minPlayers
        ) {
            revert InvalidStartPlayerCount();
        }

        if (params.maxPlayers > 0) {
            if (params.maxPlayers < params.minPlayers)
                revert MaxPlayersInvalid();
            if (params.startPlayerCount > params.maxPlayers)
                revert InvalidStartPlayerCount();
        }

        if (params.cardsPerType < TournamentCore.MIN_CARDS_PER_TYPE)
            revert InvalidCardsPerType();

        unchecked {
            if (params.cardsPerType * 3 > 255) revert InvalidCardsPerType();
        }
    }

    function validateEconomicParams(
        TournamentCore.Params calldata params,
        TournamentTokenWhitelist whitelist
    ) public view {
        if (
            params.minStake > 0 &&
            params.maxStake > 0 &&
            params.minStake > params.maxStake
        ) revert MinStakeExceedsMaxStake();

        if (params.creatorFeePercent > TournamentCore.MAX_CREATOR_FEE_PERCENT)
            revert CreatorFeeTooHigh();
        if (
            params.creatorFeePercent + params.platformFeePercent >
            TournamentCore.MAX_COMBINED_FEE_PERCENT
        ) revert CombinedFeesTooHigh();

        if (params.forfeitAllowed) {
            if (
                params.forfeitMinPenalty > 100 || params.forfeitMaxPenalty > 100
            ) revert InvalidForfeitPenaltyBounds();
            if (params.forfeitMinPenalty > params.forfeitMaxPenalty)
                revert ForfeitMinPenaltyExceedsMax();
        } else {
            if (params.forfeitMinPenalty > 0 || params.forfeitMaxPenalty > 0)
                revert InvalidForfeitPenaltyBounds();
        }

        if (!whitelist.isWhitelisted(params.stakeToken))
            revert InvalidStakeToken();
    }
}
