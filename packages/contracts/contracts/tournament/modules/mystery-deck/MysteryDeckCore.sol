// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import {TournamentDeckCatalog} from "./../../infrastructure/deck-catalog/TournamentDeckCatalog.sol";

library MysteryDeckCore {
    struct ActiveModifier {
        uint8 cardId;
        TournamentDeckCatalog.ModifierTrigger trigger;
        bytes effectData; // Encoded effect parameters (interpreted by backend)
        uint32 appliedAt;
        bool exists;
    }

    struct DeckConfig {
        address catalog;
        uint8[] excludedCardIds;
        uint256 drawCost; // Cost to draw a card (in coins)
        uint256 shuffleCost; // Cost to shuffle deck (in coins)
        uint256 peekCost; // Cost per card to peek (in coins)
        address oracle; // Backend address authorized to post card effects
        bool initialized;
    }

    struct DeckState {
        uint8 initialSize; // Starting deck size (for verification)
        uint8 cardsRemaining;
        uint256 currentShuffleSeed; // Partial seed (Pyth VRF output only, not backend secret)
        bytes32 backendSecretHash; // Hash of backend secret (revealed at tournament end)
        uint256 drawCount;
        uint256 shuffleCount; // Total shuffles performed
        uint32 lastShuffleTime; // When last shuffle occurred
        bool initialized; // Deck initialized flag
    }

    struct PlayerDeckState {
        // Active modifiers (one per trigger type max)
        mapping(TournamentDeckCatalog.ModifierTrigger => ActiveModifier) activeModifiers;
        uint8 activeModifierCount; // How many modifiers currently active (0-5)
        uint256 totalDraws;
        uint32 lastDrawTime;
        bool exists;
    }

    uint8 public constant MAX_ACTIVE_MODIFIERS = 5; // One per trigger type
    uint8 public constant MAX_DECK_SIZE = 100; // Sanity limit
    uint8 public constant MIN_DECK_SIZE = 10; // Minimum viable deck
    uint8 public constant MAX_EXCLUDED_CARDS = 50; // Limit exclusion list size
    uint8 public constant MAX_PEEK_CARDS = 5; // Max cards to peek at once
}
