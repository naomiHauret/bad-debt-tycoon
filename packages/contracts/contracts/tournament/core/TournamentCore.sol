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

    enum PlayerStatus {
        Active,
        Exited,
        Forfeited,
        PrizeClaimed,
        Refunded
    }

    enum ForfeitPenaltyType {
        Fixed,
        TimeBased
    }

    struct Params {
        uint32 startTimestamp;
        uint32 duration;
        uint32 gameInterval;
        // Player parameters
        uint16 minPlayers;
        uint16 maxPlayers;
        uint16 startPlayerCount;
        uint256 startPoolAmount;
        // Economic parameters
        address stakeToken;
        uint256 minStake;
        uint256 maxStake;
        uint40 coinConversionRate;
        uint256 decayAmount;
        // Combat parameters
        uint8 initialLives;
        uint8 cardsPerType;
        uint8 exitLivesRequired;
        // Exit parameters
        uint16 exitCostBasePercentBPS;
        uint16 exitCostCompoundRateBPS;
        uint8 creatorFeePercent;
        uint8 platformFeePercent;
        bool forfeitAllowed;
        ForfeitPenaltyType forfeitPenaltyType;
        uint8 forfeitMaxPenalty;
        uint8 forfeitMinPenalty;
        address deckCatalog;
        uint8[] excludedCardIds;
        uint256 deckDrawCost;
        uint256 deckShuffleCost;
        uint256 deckPeekCost;
        address deckOracle;
    }

    struct PlayerResources {
        uint256 initialCoins;
        uint256 coins;
        uint256 stakeAmount;
        uint32 lastDecayTimestamp;
        uint8 lives;
        uint8 totalCards;
        uint8 rockCards;
        uint8 paperCards;
        uint8 scissorsCards;
        PlayerStatus status;
        bool exists;
    }

    uint32 public constant RECOMMENDED_SECONDS_PER_CARD = 360;
    uint32 public constant MIN_DURATION = 1200; // 20 minutes
    uint8 public constant MIN_CARDS_PER_TYPE = 1;
    uint16 public constant MIN_PLAYERS_REQUIRED = 2;
    uint32 public constant MIN_GAME_INTERVAL = 60; // 1 minute
    uint8 public constant MAX_CREATOR_FEE_PERCENT = 5;
    uint8 public constant MAX_COMBINED_FEE_PERCENT = 10;
    uint8 public constant MIN_INTERVALS_REQUIRED = 3;
}
