// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TournamentRegistry} from "./../registry/TournamentRegistry.sol";
import {TournamentTokenWhitelist} from "./../token-whitelist/TournamentTokenWhitelist.sol";
import {TournamentDeckCatalog} from "./../deck-catalog/TournamentDeckCatalog.sol";
import {TournamentCore} from "../../core/TournamentCore.sol";
import {TournamentHub} from "./../../modules/hub/TournamentHub.sol";
import {TournamentCombat} from "./../../modules/combat/TournamentCombat.sol";
import {TournamentMysteryDeck} from "./../../modules/mystery-deck/TournamentMysteryDeck.sol";
import {TournamentTrading} from "./../../modules/trading/TournamentTrading.sol";
import {TournamentRandomizer} from "./../../modules/randomizer/TournamentRandomizer.sol";

/**
 * Deploys complete tournament systems (5 minimal proxies per tournament)
 */
contract TournamentFactory is Ownable {
    using Clones for address;

    address public immutable hubImplementation;
    address public immutable combatImplementation;
    address public immutable mysteryDeckImplementation;
    address public immutable tradingImplementation;
    address public immutable randomizerImplementation;

    address public immutable platformAdmin;
    TournamentRegistry public immutable registry;
    TournamentTokenWhitelist public immutable whitelist;
    TournamentDeckCatalog public immutable deckCatalog;

    address public immutable pythEntropy; // Pyth Entropy contract for randomness
    uint8 public platformFeePercent;

    event TournamentSystemCreated(
        address indexed hub,
        address indexed combat,
        address mysteryDeck,
        address trading,
        address randomizer,
        address indexed creator,
        address stakeToken,
        uint32 startTimestamp,
        uint32 duration
    );

    event PlatformFeeUpdated(uint8 newFee);

    error InvalidParameters();
    error InvalidAddress();
    error PlatformFeeTooHigh();
    error InvalidStartTimestamp();
    error InvalidCardsPerType();
    error MinPlayersInvalid();
    error MaxPlayersInvalid();
    error StartPlayerCountExceedsMax();
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
    error InvalidDeckCatalog();
    error InvalidDeckCost();

    constructor(
        address _hubImpl,
        address _combatImpl,
        address _mysteryDeckImpl,
        address _tradingImpl,
        address _randomizerImpl,
        address _registry,
        address _whitelist,
        address _deckCatalog,
        address _pythEntropy,
        address _platformAdmin,
        uint8 _platformFeePercent
    ) Ownable(msg.sender) {
        if (
            // Implementation
            _hubImpl == address(0) ||
            _combatImpl == address(0) ||
            _combatImpl == address(0) ||
            _mysteryDeckImpl == address(0) ||
            _tradingImpl == address(0) ||
            _randomizerImpl == address(0) ||
            // Infra
            _registry == address(0) ||
            _whitelist == address(0) ||
            _deckCatalog == address(0) ||
            _pythEntropy == address(0)
        ) revert InvalidAddress();

        if (_platformFeePercent > 5) revert PlatformFeeTooHigh();

        hubImplementation = _hubImpl;
        combatImplementation = _combatImpl;
        mysteryDeckImplementation = _mysteryDeckImpl;
        tradingImplementation = _tradingImpl;
        randomizerImplementation = _randomizerImpl;
        registry = TournamentRegistry(_registry);
        whitelist = TournamentTokenWhitelist(_whitelist);
        deckCatalog = TournamentDeckCatalog(_deckCatalog);
        pythEntropy = _pythEntropy;

        platformAdmin = _platformAdmin == address(0)
            ? msg.sender
            : _platformAdmin;
        platformFeePercent = _platformFeePercent;
    }

    function createTournamentSystem(
        TournamentCore.Params calldata params
    ) external returns (address hub) {
        _validateParams(params);

        hub = hubImplementation.clone();
        address combat = combatImplementation.clone();
        address mysteryDeck = mysteryDeckImplementation.clone();
        address trading = tradingImplementation.clone();
        address randomizer = randomizerImplementation.clone();

        TournamentHub(hub).initialize(
            params,
            msg.sender,
            combat,
            mysteryDeck,
            trading,
            randomizer,
            address(registry),
            address(whitelist),
            platformAdmin
        );

        TournamentCombat(combat).initialize(hub, randomizer);

        TournamentMysteryDeck(mysteryDeck).initialize(
            hub,
            address(deckCatalog),
            randomizer,
            params.excludedCardIds,
            params.mysteryDeckDrawCost,
            params.mysteryDeckShuffleCost,
            params.mysteryDeckPeekCost,
            params.mysteryDeckOracle
        );

        TournamentTrading(trading).initialize(hub);

        TournamentRandomizer(randomizer).initialize(hub, pythEntropy);

        registry.registerTournamentSystem(
            hub,
            combat,
            mysteryDeck,
            trading,
            randomizer
        );

        emit TournamentSystemCreated(
            hub,
            combat,
            mysteryDeck,
            trading,
            randomizer,
            msg.sender,
            params.stakeToken,
            params.startTimestamp,
            params.duration
        );

        return hub;
    }

    /**
     * @notice Validate all tournament parameters before deployment
     * @dev Comprehensive validation to ensure tournament is viable and safe
     */
    function _validateParams(
        TournamentCore.Params calldata params
    ) internal view {
        if (params.coinConversionRate == 0) revert InvalidCoinConversionRate();
        if (params.decayAmount == 0) revert InvalidDecayAmount();
        if (params.initialLives == 0) revert InvalidInitialLives();
        if (params.exitLivesRequired == 0) revert InvalidExitLivesRequired();
        if (params.exitCostBasePercentBPS == 0) revert InvalidExitCostBase();
        if (params.deckDrawCost == 0) revert InvalidDeckCost();
        if (params.deckShuffleCost == 0) revert InvalidDeckCost();
        if (params.deckPeekCost == 0) revert InvalidDeckCost();
        if (params.deckCatalog == address(0) || params.deckOracle == address(0))
            revert InvalidAddress();

        // Time & duration checks
        if (params.startTimestamp <= block.timestamp)
            revert InvalidStartTimestamp();
        if (params.duration < TournamentCore.MIN_DURATION)
            revert DurationTooShort();
        if (params.gameInterval < TournamentCore.MIN_GAME_INTERVAL)
            revert IntervalTooShort();

        uint256 maxIntervals = params.duration / params.gameInterval;
        if (maxIntervals < TournamentCore.MIN_INTERVALS_REQUIRED)
            revert DurationTooShortForInterval();

        // Player bounds
        if (params.minPlayers < TournamentCore.MIN_PLAYERS_REQUIRED)
            revert MinPlayersInvalid();
        if (params.maxPlayers > 0) {
            if (params.maxPlayers < params.minPlayers)
                revert MaxPlayersInvalid();
            if (params.startPlayerCount > params.maxPlayers)
                revert StartPlayerCountExceedsMax();
        }

        // Cards validation
        if (params.cardsPerType < TournamentCore.MIN_CARDS_PER_TYPE)
            revert InvalidCardsPerType();
        if (params.cardsPerType * 3 > 255) revert InvalidCardsPerType();

        // Economic validation
        if (
            params.minStake > 0 &&
            params.maxStake > 0 &&
            params.minStake > params.maxStake
        ) revert MinStakeExceedsMaxStake();

        // Decay overflow protection (critical for `unchecked` in calculations)
        if (params.decayAmount > type(uint128).max / maxIntervals) {
            revert InvalidDecayAmount();
        }

        // Fee validation
        if (params.creatorFeePercent > TournamentCore.MAX_CREATOR_FEE_PERCENT)
            revert CreatorFeeTooHigh();
        if (
            params.creatorFeePercent + params.platformFeePercent >
            TournamentCore.MAX_COMBINED_FEE_PERCENT
        ) revert CombinedFeesTooHigh();

        // Forfeit validation
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

    /**
     * @notice Update platform fee percentage
     * @dev Only affects tournaments created after this update
     */
    function setPlatformFee(uint8 newFee) external onlyOwner {
        if (newFee > 5) revert PlatformFeeTooHigh();
        platformFeePercent = newFee;
        emit PlatformFeeUpdated(newFee);
    }

    /**
     * @notice Get all implementation addresses
     */
    function getImplementations()
        external
        view
        returns (
            address hub,
            address combat,
            address mysteryDeck,
            address trading,
            address randomizer
        )
    {
        return (
            hubImplementation,
            combatImplementation,
            mysteryDeckImplementation,
            tradingImplementation,
            randomizerImplementation
        );
    }
}
