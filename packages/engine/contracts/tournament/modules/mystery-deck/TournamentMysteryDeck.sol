// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {TournamentCore} from "./../../core/TournamentCore.sol";
import {TournamentDeckCatalog} from "./../../infrastructure/deck-catalog/TournamentDeckCatalog.sol";

interface ITournamentHub {
    function getPlayer(
        address player
    ) external view returns (TournamentCore.PlayerResources memory);
    function getCurrentPlayerResources(
        address player
    ) external view returns (TournamentCore.PlayerResources memory);
    function updatePlayerResources(
        address player,
        TournamentCore.PlayerResources calldata resources
    ) external;
    function status() external view returns (TournamentCore.Status);
}

contract TournamentMysteryDeck is Initializable {
    address public hub;
    uint32 public drawCount;
    uint32 public shuffleCount;
    uint32 public lastShuffleTime;

    address public catalog;
    bool public initialized;
    address public gameOracle;

    uint256 public initialSize;
    uint256 public cardsRemaining;

    uint256 public drawCost;
    uint256 public shuffleCost;
    uint256 public peekCost;

    uint256 public currentShuffleSeed;
    bytes32 public backendSecretHash;

    uint8[] public excludedCardIds;

    uint8 public constant MAX_EXCLUDED_CARDS = 50;
    uint8 public constant MAX_PEEK_CARDS = 5;
    uint256 public constant ADD_REMOVE_COST_MULTIPLIER = 105;

    event DeckInitialized(
        uint256 indexed deckSize,
        uint64 indexed sequenceNumber,
        uint32 timestamp
    );
    event CardDrawn(
        address indexed player,
        uint256 costPaid,
        uint256 newDrawCount,
        uint256 cardsRemaining,
        uint32 timestamp
    );
    event DeckShuffled(
        address indexed player,
        uint256 costPaid,
        uint256 newShuffleCount,
        uint32 timestamp
    );
    event CardsPeeked(
        address indexed player,
        uint8 cardCount,
        uint256 costPaid,
        uint32 timestamp
    );
    event CardsAdded(
        address indexed player,
        uint8 cardCount,
        uint256 costPaid,
        uint256 newCardsRemaining,
        uint32 timestamp
    );
    event CardsRemoved(
        address indexed player,
        uint8 cardCount,
        uint256 costPaid,
        uint256 newCardsRemaining,
        uint32 timestamp
    );
    event ShuffleSeedUpdated(
        uint256 indexed newSeed,
        bytes32 backendSecretHash,
        uint32 timestamp
    );

    error InvalidAddress();
    error InvalidCost();
    error TooManyExcludedCards();
    error DeckAlreadyInitialized();
    error DeckNotInitialized();
    error InsufficientCoins();
    error NotEnoughCardsRemaining();
    error InvalidPeekCount();
    error OnlyHub();
    error OnlyGameOracle();
    error PlayerNotFound();
    error PlayerNotActive();
    error PlayerInCombat();
    error InvalidCount();
    error TournamentNotActive();
    error ResourceOverflow();

    modifier onlyHub() {
        if (msg.sender != hub) revert OnlyHub();
        _;
    }

    modifier onlyGameOracle() {
        if (msg.sender != gameOracle) revert OnlyGameOracle();
        _;
    }

    modifier deckInitialized() {
        if (!initialized) revert DeckNotInitialized();
        _;
    }

    modifier tournamentActive() {
        if (ITournamentHub(hub).status() != TournamentCore.Status.Active)
            revert TournamentNotActive();
        _;
    }

    modifier onlyActivePlayer() {
        TournamentCore.PlayerResources memory player = ITournamentHub(hub)
            .getPlayer(msg.sender);
        if (!player.exists) revert PlayerNotFound();
        if (player.status != TournamentCore.PlayerStatus.Active)
            revert PlayerNotActive();
        if (player.inCombat) revert PlayerInCombat();
        _;
    }

    function initialize(
        address _hub,
        address _catalog,
        uint8[] calldata _excludedCards,
        uint256 _drawCost,
        uint256 _shuffleCost,
        uint256 _peekCost,
        address _gameOracle
    ) external initializer {
        if (
            _hub == address(0) ||
            _catalog == address(0) ||
            _gameOracle == address(0)
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
        catalog = _catalog;
        gameOracle = _gameOracle;

        drawCost = _drawCost;
        shuffleCost = _shuffleCost;
        peekCost = _peekCost;

        excludedCardIds = _excludedCards;
    }

    function initializeDeck() external onlyHub {
        if (initialized) revert DeckAlreadyInitialized();

        uint8[] memory allCardIds = TournamentDeckCatalog(catalog)
            .getAllCardIds();
        uint256 deckSize = _calculateDeckSize(allCardIds) * 50;

        uint64 sequenceNumber = uint64(block.number);

        initialSize = deckSize;
        cardsRemaining = deckSize;
        lastShuffleTime = uint32(block.timestamp);
        initialized = true;

        emit DeckInitialized(deckSize, sequenceNumber, uint32(block.timestamp));
    }

    function drawCard()
        external
        deckInitialized
        tournamentActive
        onlyActivePlayer
    {
        if (cardsRemaining == 0) revert NotEnoughCardsRemaining();

        address hubCache = hub;
        TournamentCore.PlayerResources memory player = ITournamentHub(hubCache)
            .getCurrentPlayerResources(msg.sender);

        if (player.coins < drawCost) revert InsufficientCoins();

        unchecked {
            player.coins -= drawCost;
            cardsRemaining--;
            drawCount++;
        }

        ITournamentHub(hubCache).updatePlayerResources(msg.sender, player);
        emit CardDrawn(
            msg.sender,
            drawCost,
            drawCount,
            cardsRemaining,
            uint32(block.timestamp)
        );
    }

    function shuffleDeck()
        external
        deckInitialized
        tournamentActive
        onlyActivePlayer
    {
        if (cardsRemaining == 0) revert NotEnoughCardsRemaining();

        address hubCache = hub;
        uint256 costCache = shuffleCost;

        TournamentCore.PlayerResources memory player = ITournamentHub(hubCache)
            .getCurrentPlayerResources(msg.sender);

        if (player.coins < costCache) revert InsufficientCoins();

        uint32 timestamp = uint32(block.timestamp);
        unchecked {
            player.coins -= costCache;
            shuffleCount++;
        }
        lastShuffleTime = timestamp;

        ITournamentHub(hubCache).updatePlayerResources(msg.sender, player);
        emit DeckShuffled(msg.sender, costCache, shuffleCount, timestamp);
    }

    function peekCards(
        uint8 count
    ) external deckInitialized tournamentActive onlyActivePlayer {
        if (count == 0 || count > MAX_PEEK_CARDS) revert InvalidPeekCount();
        if (cardsRemaining < count) revert NotEnoughCardsRemaining();

        address hubCache = hub;
        uint256 totalCost = peekCost * count;

        TournamentCore.PlayerResources memory player = ITournamentHub(hubCache)
            .getCurrentPlayerResources(msg.sender);

        if (player.coins < totalCost) revert InsufficientCoins();

        unchecked {
            player.coins -= totalCost;
        }

        ITournamentHub(hubCache).updatePlayerResources(msg.sender, player);
        emit CardsPeeked(msg.sender, count, totalCost, uint32(block.timestamp));
    }

    function addCards(
        uint8 count
    ) external deckInitialized tournamentActive onlyActivePlayer {
        if (count == 0) revert InvalidCount();
        if (cardsRemaining + count < cardsRemaining) revert ResourceOverflow();

        address hubCache = hub;
        uint256 totalCost = (drawCost * ADD_REMOVE_COST_MULTIPLIER * count) /
            100;

        TournamentCore.PlayerResources memory player = ITournamentHub(hubCache)
            .getCurrentPlayerResources(msg.sender);

        if (player.coins < totalCost) revert InsufficientCoins();

        uint32 timestamp = uint32(block.timestamp);
        unchecked {
            player.coins -= totalCost;
            cardsRemaining += count;
        }

        ITournamentHub(hubCache).updatePlayerResources(msg.sender, player);
        emit CardsAdded(
            msg.sender,
            count,
            totalCost,
            cardsRemaining,
            timestamp
        );
    }

    function removeCards(
        uint8 count
    ) external deckInitialized tournamentActive onlyActivePlayer {
        if (count == 0) revert InvalidCount();
        if (cardsRemaining < count) revert NotEnoughCardsRemaining();

        address hubCache = hub;
        uint256 totalCost = (drawCost * ADD_REMOVE_COST_MULTIPLIER * count) /
            100;

        TournamentCore.PlayerResources memory player = ITournamentHub(hubCache)
            .getCurrentPlayerResources(msg.sender);

        if (player.coins < totalCost) revert InsufficientCoins();

        unchecked {
            player.coins -= totalCost;
            cardsRemaining -= count;
        }

        ITournamentHub(hubCache).updatePlayerResources(msg.sender, player);
        emit CardsRemoved(
            msg.sender,
            count,
            totalCost,
            cardsRemaining,
            uint32(block.timestamp)
        );
    }

    function updateShuffleSeed(
        uint256 seed,
        bytes32 secretHash
    ) external onlyGameOracle {
        currentShuffleSeed = seed;
        backendSecretHash = secretHash;

        emit ShuffleSeedUpdated(seed, secretHash, uint32(block.timestamp));
    }

    function _calculateDeckSize(
        uint8[] memory allCardIds
    ) internal view returns (uint256 size) {
        uint256 totalCards = allCardIds.length;
        uint256 excludedCount = excludedCardIds.length;

        if (excludedCount == 0) {
            return totalCards;
        }

        for (uint256 i = 0; i < totalCards; ) {
            bool isExcluded = false;

            for (uint256 j = 0; j < excludedCount; ) {
                if (allCardIds[i] == excludedCardIds[j]) {
                    isExcluded = true;
                    break;
                }
                unchecked {
                    j++;
                }
            }

            if (!isExcluded) {
                unchecked {
                    size++;
                }
            }

            unchecked {
                i++;
            }
        }
    }

    function getDeckState()
        external
        view
        returns (
            uint256 _initialSize,
            uint256 _cardsRemaining,
            uint32 _drawCount,
            uint32 _shuffleCount
        )
    {
        return (initialSize, cardsRemaining, drawCount, shuffleCount);
    }

    function calculateAddRemoveCost(
        uint8 count
    ) external view returns (uint256 cost) {
        return (drawCost * ADD_REMOVE_COST_MULTIPLIER * count) / 100;
    }
}
