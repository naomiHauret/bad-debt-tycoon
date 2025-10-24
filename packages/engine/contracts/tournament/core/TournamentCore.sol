// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library TournamentCore {
    enum Status {
        Open,
        Locked,
        PendingStart,
        Active,
        Ended,
        Cancelled
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
        uint16 minPlayers;
        uint16 maxPlayers;
        uint16 startPlayerCount;
        uint256 startPoolAmount;
        address stakeToken;
        uint256 minStake;
        uint256 maxStake;
        uint40 coinConversionRate;
        uint256 decayAmount;
        uint8 initialLives;
        uint8 cardsPerType;
        uint8 exitLivesRequired;
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
        uint16 combatCount;
        uint8 lives;
        uint8 totalCards;
        PlayerStatus status;
        bool exists;
        bool inCombat;
    }

    uint32 public constant RECOMMENDED_SECONDS_PER_CARD = 360;
    uint32 public constant MIN_DURATION = 1200;
    uint8 public constant MIN_CARDS_PER_TYPE = 1;
    uint8 public constant MAX_CARDS_PER_TYPE = 10;
    uint16 public constant MIN_PLAYERS_REQUIRED = 2;
    uint16 public constant MAX_PLAYERS_LIMIT = 10000;
    uint32 public constant MIN_GAME_INTERVAL = 60;
    uint32 public constant MAX_GAME_INTERVAL = 3600;
    uint8 public constant MAX_CREATOR_FEE_PERCENT = 5;
    uint8 public constant MAX_PLATFORM_FEE = 5;
    uint8 public constant MAX_COMBINED_FEE_PERCENT = 10;
    uint8 public constant MIN_INTERVALS_REQUIRED = 3;
}
