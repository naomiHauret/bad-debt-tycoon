// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract TournamentMysteryDeck is Initializable {
    address public hub;
    address public deckCatalog;
    address public randomizer;
    address public oracle;

    uint8 public cardsRemaining;
    uint256 public drawCount;

    uint256 public drawCost;
    uint256 public shuffleCost;
    uint256 public peekCost;

    uint8[] public excludedCardIds;

    error InvalidAddress();
    error Unauthorized();
    error InvalidCost();
    error TooManyExcludedCards();

    uint8 public constant MAX_EXCLUDED_CARDS = 50;

    modifier onlyHub() {
        if (msg.sender != hub) revert Unauthorized();
        _;
    }

    modifier onlyOracle() {
        if (msg.sender != oracle) revert Unauthorized();
        _;
    }

    function initialize(
        address _hub,
        address _catalog,
        address rand,
        uint8[] calldata _excludedCards,
        uint256 _drawCost,
        uint256 _shuffleCost,
        uint256 _peekCost,
        address _oracle
    ) external initializer {
        if (
            _hub == address(0) ||
            _catalog == address(0) ||
            rand == address(0) ||
            _oracle == address(0)
        ) {
            revert InvalidAddress();
        }

        if (_drawCost == 0 || _shuffleCost == 0 || _peekCost == 0) {
            revert InvalidCost();
        }

        if (_excludedCards.length > MAX_EXCLUDED_CARDS) {
            revert TooManyExcludedCards();
        }

        hub = _hub;
        deckCatalog = _catalog;
        randomizer = rand;
        oracle = _oracle;
        drawCost = _drawCost;
        shuffleCost = _shuffleCost;
        peekCost = _peekCost;
        excludedCardIds = _excludedCards;
    }

    // Future implementation:
    // - initializeDeck() - called when tournament goes Active
    // - drawCard() - player pays cost, backend determines card
    // - applyInstantCard() - oracle posts instant effect
    // - applyModifierCard() - oracle posts modifier effect
    // - applyResourceCard() - oracle adds card to hand
    // - resolveModifier() - auto-resolve when trigger occurs
    // - shuffleDeck() - player pays, request new seed from Randomizer
    // - peekDeck() - player pays, backend reveals privately
    // - addCardsToDeck() - manipulation action
    // - removeCardsFromDeck() - manipulation action
}
