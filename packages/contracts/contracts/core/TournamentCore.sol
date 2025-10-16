// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library TournamentCore {
    enum Status {
        Open, // Accepting players
        Active, // Game in progress
        Ended, // Finished normally
        Cancelled, // Start conditions not met
        Locked, // Maximum players threshold reached
        PendingStart // Start timestamp reached, assessing other start conditions
    }

    enum ForfeitPenaltyType {
        Fixed,
        TimeBased
    }

    struct TournamentParams {
        uint32 startTimestamp;
        uint32 duration;
        uint16 minPlayers;
        uint16 maxPlayers;
        uint40 coinConversionRate;
        address stakeToken;
        uint256 minStake;
        uint256 maxStake;
        uint16 startPlayerCount;
        uint256 startPoolAmount;
        uint8 initialLives;
        uint8 cardsPerType;
        uint256 decayAmount;
        uint256 decayInterval;
        uint8 exitLivesRequired;
        uint16 exitCostBasePercentBPS;
        uint16 exitCostCompoundRateBPS;
        uint256 exitCostInterval;
        uint8 creatorFeePercent;
        uint8 platformFeePercent;
        bool forfeitAllowed;
        ForfeitPenaltyType forfeitPenaltyType;
        uint8 forfeitMaxPenalty;
        uint8 forfeitMinPenalty;
    }

    enum PlayerStatus {
        Active,
        Exited,
        Forfeited,
        PrizeClaimed,
        Refunded
    }

    struct PlayerResources {
        uint256 initialCoins;
        uint256 coins;
        uint256 stakeAmount;
        uint256 lastDecayTimestamp;
        uint8 lives;
        uint8 totalCards;
        PlayerStatus status;
        bool exists;
    }

    uint32 public constant RECOMMENDED_SECONDS_PER_CARD = 360;
    uint32 public constant MIN_DURATION = 1200; // in seconds
    uint8 public constant MIN_CARDS_PER_TYPE = 1;
    uint16 public constant MIN_PLAYERS_REQUIRED = 2;
    uint256 public constant MIN_DECAY_INTERVAL = 60; // in seconds
    uint256 public constant MIN_EXIT_COST_INTERVAL = 60; // in seconds
    uint8 public constant MAX_CREATOR_FEE_PERCENT = 5;
    uint8 public constant MAX_COMBINED_FEE_PERCENT = 10;
}
