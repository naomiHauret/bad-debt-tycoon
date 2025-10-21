// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TournamentDeckCatalog is Ownable {
    enum CardCategory {
        Instant,
        Modifier,
        Combat
    }

    enum ModifierTrigger {
        None,
        OnNextFight,
        OnNextWin,
        OnNextLoss
    }

    enum CombatCard {
        Rock,
        Paper,
        Scissors
    }

    enum ResourceCard {
        None,
        Rock,
        Paper,
        Scissors
    }

    enum Objective {
        ResourceLives,
        ResourceCoins,
        ResourceAll,
        EliminationCount,
        BattleRate,
        WinStreak,
        LoseStreak,
        VictoryRate,
        PerfectRecord,
        TradeCount,
        TradeVolume
    }

    struct CardDefinition {
        bool exists;
        bool paused;
        uint8 cardId;
        CardCategory category;
        ModifierTrigger trigger;
        ResourceCard resourceType;
        uint16 baseWeight;
        bytes effectData;
    }

    struct ObjectiveDefinition {
        uint8 objectiveId;
        Objective objectiveType;
        bool exists;
        bool paused;
        bytes targetData;
    }

    uint16 public constant LIVES_MULT_1X = 100;
    uint16 public constant LIVES_MULT_2X = 200;
    uint16 public constant LIVES_MULT_3X = 300;
    uint16 public constant MIN_COINS_MULTIPLIER = 50;
    uint16 public constant MAX_COINS_MULTIPLIER = 300;
    uint8 public constant STREAK_TIER_1 = 15;
    uint8 public constant STREAK_TIER_2 = 25;
    uint8 public constant STREAK_TIER_3 = 35;
    uint8 public constant STREAK_TIER_4 = 50;
    uint8 public constant ELIM_TIER_1 = 25;
    uint8 public constant ELIM_TIER_2 = 50;
    uint8 public constant ELIM_TIER_3 = 75;
    uint8 public constant ELIM_TIER_4 = 100;
    uint8 public constant MIN_BATTLE_RATE_PCT = 1;
    uint8 public constant MAX_BATTLE_RATE_PCT = 30;
    uint8 public constant MIN_VICTORY_RATE_PCT = 70;
    uint8 public constant MAX_VICTORY_RATE_PCT = 100;
    uint8 public constant MIN_TRADE_COUNT_PCT = 1;
    uint8 public constant MAX_TRADE_COUNT_PCT = 30;
    uint8 public constant MIN_TRADE_VOLUME_PCT = 1;
    uint8 public constant MAX_TRADE_VOLUME_PCT = 150;

    mapping(uint8 => CardDefinition) private _cards;
    uint8 public cardCount;
    uint8[] private _cardIds;

    mapping(uint8 => ObjectiveDefinition) private _objectives;
    uint8 public objectiveCount;
    uint8[] private _objectiveIds;

    mapping(CardCategory => uint8[]) private _cardsByCategory;
    mapping(ModifierTrigger => uint8[]) private _cardsByTrigger;
    mapping(ResourceCard => uint8[]) private _cardsByResourceType;

    event CardRegistered(
        uint8 indexed cardId,
        CardCategory category,
        uint16 baseWeight
    );
    event ObjectiveRegistered(
        uint8 indexed objectiveId,
        Objective objectiveType
    );
    event CardPaused(uint8 indexed cardId, uint32 timestamp);
    event CardUnpaused(uint8 indexed cardId, uint32 timestamp);
    event ObjectivePaused(uint8 indexed objectiveId, uint32 timestamp);
    event ObjectiveUnpaused(uint8 indexed objectiveId, uint32 timestamp);

    error CardIdTaken();
    error CardNotFound();
    error ObjectiveIdTaken();
    error ObjectiveNotFound();
    error InvalidCardCategory();
    error InvalidModifierTrigger();
    error InvalidResource();
    error InvalidCardId();
    error InvalidObjectiveId();
    error InvalidBaseWeight();
    error InvalidEffectData();
    error CardAlreadyPaused();
    error CardNotPaused();
    error ObjectiveAlreadyPaused();
    error ObjectiveNotPaused();
    error InvalidObjective();
    error InvalidTargetData();
    error InvalidMultiplier();
    error ExceedsMaxCards();
    error ExceedsMaxObjectives();

    constructor() Ownable(msg.sender) {}

    modifier onlyExistingCards(uint8 cardId) {
        if (!_cards[cardId].exists) revert CardNotFound();
        _;
    }

    modifier onlyExistingObjectives(uint8 objectiveId) {
        if (!_objectives[objectiveId].exists) revert ObjectiveNotFound();
        _;
    }

    function registerCard(CardDefinition calldata card) external onlyOwner {
        if (card.cardId == 0) revert InvalidCardId();
        if (_cards[card.cardId].exists) revert CardIdTaken();

        _validateCardDefinition(card);

        _cards[card.cardId] = CardDefinition({
            exists: true,
            paused: false,
            cardId: card.cardId,
            category: card.category,
            trigger: card.trigger,
            resourceType: card.resourceType,
            baseWeight: card.baseWeight,
            effectData: card.effectData
        });

        _cardIds.push(card.cardId);
        unchecked {
            cardCount++;
        }

        _cardsByCategory[card.category].push(card.cardId);
        if (card.category == CardCategory.Modifier) {
            _cardsByTrigger[card.trigger].push(card.cardId);
        }
        if (card.category == CardCategory.Combat) {
            _cardsByResourceType[card.resourceType].push(card.cardId);
        }

        emit CardRegistered(card.cardId, card.category, card.baseWeight);
    }

    function registerCards(CardDefinition[] calldata cards) external onlyOwner {
        uint256 length = cards.length;

        unchecked {
            if (cardCount + length > 255) revert ExceedsMaxCards();
        }

        for (uint256 i = 0; i < length; ) {
            CardDefinition calldata card = cards[i];
            uint8 id = card.cardId;

            if (id == 0) revert InvalidCardId();
            if (_cards[id].exists) revert CardIdTaken();

            _validateCardDefinition(card);

            _cards[id] = CardDefinition({
                exists: true,
                paused: false,
                cardId: id,
                category: card.category,
                trigger: card.trigger,
                resourceType: card.resourceType,
                baseWeight: card.baseWeight,
                effectData: card.effectData
            });

            _cardIds.push(id);
            _cardsByCategory[card.category].push(id);

            if (card.category == CardCategory.Modifier) {
                _cardsByTrigger[card.trigger].push(id);
            }
            if (card.category == CardCategory.Combat) {
                _cardsByResourceType[card.resourceType].push(id);
            }

            emit CardRegistered(id, card.category, card.baseWeight);

            unchecked {
                ++i;
            }
        }

        unchecked {
            cardCount += uint8(length);
        }
    }

    function registerObjective(
        ObjectiveDefinition calldata objective
    ) external onlyOwner {
        if (objective.objectiveId == 0) revert InvalidObjectiveId();
        if (_objectives[objective.objectiveId].exists)
            revert ObjectiveIdTaken();

        _validateObjectiveDefinition(objective);

        _objectives[objective.objectiveId] = ObjectiveDefinition({
            objectiveId: objective.objectiveId,
            objectiveType: objective.objectiveType,
            exists: true,
            paused: false,
            targetData: objective.targetData
        });

        _objectiveIds.push(objective.objectiveId);
        unchecked {
            objectiveCount++;
        }

        emit ObjectiveRegistered(
            objective.objectiveId,
            objective.objectiveType
        );
    }

    function registerObjectives(
        ObjectiveDefinition[] calldata objectives
    ) external onlyOwner {
        uint256 length = objectives.length;

        unchecked {
            if (objectiveCount + length > 255) revert ExceedsMaxObjectives();
        }

        for (uint256 i = 0; i < length; ) {
            ObjectiveDefinition calldata obj = objectives[i];
            uint8 id = obj.objectiveId;

            if (id == 0) revert InvalidObjectiveId();
            if (_objectives[id].exists) revert ObjectiveIdTaken();

            _validateObjectiveDefinition(obj);

            _objectives[id] = ObjectiveDefinition({
                objectiveId: id,
                objectiveType: obj.objectiveType,
                exists: true,
                paused: false,
                targetData: obj.targetData
            });

            _objectiveIds.push(id);

            emit ObjectiveRegistered(id, obj.objectiveType);

            unchecked {
                ++i;
            }
        }

        unchecked {
            objectiveCount += uint8(length);
        }
    }

    function pauseCard(uint8 card) external onlyOwner onlyExistingCards(card) {
        if (_cards[card].paused) revert CardAlreadyPaused();
        _cards[card].paused = true;
        emit CardPaused(card, uint32(block.timestamp));
    }

    function unpauseCard(
        uint8 cardId
    ) external onlyOwner onlyExistingCards(cardId) {
        if (!_cards[cardId].paused) revert CardNotPaused();
        _cards[cardId].paused = false;
        emit CardUnpaused(cardId, uint32(block.timestamp));
    }

    function pauseObjective(
        uint8 objectiveId
    ) external onlyOwner onlyExistingObjectives(objectiveId) {
        if (_objectives[objectiveId].paused) revert ObjectiveAlreadyPaused();
        _objectives[objectiveId].paused = true;
        emit ObjectivePaused(objectiveId, uint32(block.timestamp));
    }

    function unpauseObjective(
        uint8 objectiveId
    ) external onlyOwner onlyExistingObjectives(objectiveId) {
        if (!_objectives[objectiveId].paused) revert ObjectiveNotPaused();
        _objectives[objectiveId].paused = false;
        emit ObjectiveUnpaused(objectiveId, uint32(block.timestamp));
    }

    function getCard(
        uint8 cardId
    ) external view onlyExistingCards(cardId) returns (CardDefinition memory) {
        return _cards[cardId];
    }

    function getAllCardIds() external view returns (uint8[] memory) {
        return _cardIds;
    }

    function getCards(
        uint8[] calldata cardIds
    ) external view returns (CardDefinition[] memory cards) {
        uint256 length = cardIds.length;
        cards = new CardDefinition[](length);

        for (uint256 i = 0; i < length; ) {
            CardDefinition storage card = _cards[cardIds[i]];
            if (!card.exists) revert CardNotFound();
            cards[i] = card;

            unchecked {
                ++i;
            }
        }
    }

    function cardExists(uint8 cardId) external view returns (bool) {
        return _cards[cardId].exists;
    }

    function isCardActive(uint8 cardId) external view returns (bool) {
        return _cards[cardId].exists && !_cards[cardId].paused;
    }

    function isCardPaused(uint8 cardId) external view returns (bool) {
        return _cards[cardId].paused;
    }

    function getObjective(
        uint8 objectiveId
    )
        external
        view
        onlyExistingObjectives(objectiveId)
        returns (ObjectiveDefinition memory)
    {
        return _objectives[objectiveId];
    }

    function getAllObjectiveIds() external view returns (uint8[] memory) {
        return _objectiveIds;
    }

    function getObjectives(
        uint8[] calldata objectiveIds
    ) external view returns (ObjectiveDefinition[] memory objectives) {
        uint256 length = objectiveIds.length;
        objectives = new ObjectiveDefinition[](length);

        for (uint256 i = 0; i < length; ) {
            ObjectiveDefinition storage obj = _objectives[objectiveIds[i]];
            if (!obj.exists) revert ObjectiveNotFound();
            objectives[i] = obj;

            unchecked {
                ++i;
            }
        }
    }

    function objectiveExists(uint8 objectiveId) external view returns (bool) {
        return _objectives[objectiveId].exists;
    }

    function isObjectiveActive(uint8 objectiveId) external view returns (bool) {
        return
            _objectives[objectiveId].exists && !_objectives[objectiveId].paused;
    }

    function isObjectivePaused(uint8 objectiveId) external view returns (bool) {
        return _objectives[objectiveId].paused;
    }

    function _validateCardDefinition(
        CardDefinition calldata card
    ) internal pure {
        if (card.baseWeight == 0) revert InvalidBaseWeight();
        if (card.effectData.length == 0) revert InvalidEffectData();

        CardCategory category = card.category;
        ModifierTrigger trigger = card.trigger;
        ResourceCard resourceType = card.resourceType;

        unchecked {
            // Modifier: trigger != None, resourceType == None
            if (category == CardCategory.Modifier) {
                if (trigger == ModifierTrigger.None)
                    revert InvalidModifierTrigger();
                if (resourceType != ResourceCard.None) revert InvalidResource();
                return;
            }

            if (category == CardCategory.Combat) {
                if (resourceType == ResourceCard.None) revert InvalidResource();
                if (trigger != ModifierTrigger.None)
                    revert InvalidModifierTrigger();
                return;
            }

            if (category == CardCategory.Instant) {
                if (trigger != ModifierTrigger.None)
                    revert InvalidModifierTrigger();
                if (resourceType != ResourceCard.None) revert InvalidResource();
                return;
            }

            revert InvalidCardCategory();
        }
    }

    function _validateObjectiveDefinition(
        ObjectiveDefinition calldata objective
    ) internal pure {
        if (objective.targetData.length == 0) revert InvalidTargetData();

        if (objective.objectiveType == Objective.ResourceLives) {
            if (objective.targetData.length != 32) revert InvalidTargetData();
            uint16 multiplier = abi.decode(objective.targetData, (uint16));
            if (
                multiplier != LIVES_MULT_1X &&
                multiplier != LIVES_MULT_2X &&
                multiplier != LIVES_MULT_3X
            ) {
                revert InvalidMultiplier();
            }
        } else if (objective.objectiveType == Objective.ResourceCoins) {
            if (objective.targetData.length != 32) revert InvalidTargetData();
            uint16 multiplier = abi.decode(objective.targetData, (uint16));
            if (
                multiplier < MIN_COINS_MULTIPLIER ||
                multiplier > MAX_COINS_MULTIPLIER
            ) {
                revert InvalidMultiplier();
            }
        } else if (objective.objectiveType == Objective.ResourceAll) {
            if (objective.targetData.length != 64) revert InvalidTargetData();
            (uint16 livesMult, uint16 coinsMult) = abi.decode(
                objective.targetData,
                (uint16, uint16)
            );

            if (
                livesMult != LIVES_MULT_1X &&
                livesMult != LIVES_MULT_2X &&
                livesMult != LIVES_MULT_3X
            ) {
                revert InvalidMultiplier();
            }

            if (
                coinsMult < MIN_COINS_MULTIPLIER ||
                coinsMult > MAX_COINS_MULTIPLIER
            ) {
                revert InvalidMultiplier();
            }
        } else if (
            objective.objectiveType == Objective.WinStreak ||
            objective.objectiveType == Objective.LoseStreak
        ) {
            if (objective.targetData.length != 32) revert InvalidTargetData();
            uint8 percentage = abi.decode(objective.targetData, (uint8));
            if (
                percentage != STREAK_TIER_1 &&
                percentage != STREAK_TIER_2 &&
                percentage != STREAK_TIER_3 &&
                percentage != STREAK_TIER_4
            ) {
                revert InvalidMultiplier();
            }
        } else if (objective.objectiveType == Objective.EliminationCount) {
            if (objective.targetData.length != 32) revert InvalidTargetData();
            uint8 percentage = abi.decode(objective.targetData, (uint8));
            if (
                percentage != ELIM_TIER_1 &&
                percentage != ELIM_TIER_2 &&
                percentage != ELIM_TIER_3 &&
                percentage != ELIM_TIER_4
            ) {
                revert InvalidMultiplier();
            }
        } else if (objective.objectiveType == Objective.BattleRate) {
            if (objective.targetData.length != 32) revert InvalidTargetData();
            uint8 percentage = abi.decode(objective.targetData, (uint8));
            if (
                percentage < MIN_BATTLE_RATE_PCT ||
                percentage > MAX_BATTLE_RATE_PCT
            ) {
                revert InvalidMultiplier();
            }
        } else if (objective.objectiveType == Objective.VictoryRate) {
            if (objective.targetData.length != 32) revert InvalidTargetData();
            uint8 percentage = abi.decode(objective.targetData, (uint8));
            if (
                percentage < MIN_VICTORY_RATE_PCT ||
                percentage > MAX_VICTORY_RATE_PCT
            ) {
                revert InvalidMultiplier();
            }
        } else if (objective.objectiveType == Objective.PerfectRecord) {
            if (objective.targetData.length != 32) revert InvalidTargetData();
        } else if (objective.objectiveType == Objective.TradeCount) {
            if (objective.targetData.length != 32) revert InvalidTargetData();
            uint8 percentage = abi.decode(objective.targetData, (uint8));
            if (
                percentage < MIN_TRADE_COUNT_PCT ||
                percentage > MAX_TRADE_COUNT_PCT
            ) {
                revert InvalidMultiplier();
            }
        } else if (objective.objectiveType == Objective.TradeVolume) {
            if (objective.targetData.length != 32) revert InvalidTargetData();
            uint8 percentage = abi.decode(objective.targetData, (uint8));
            if (
                percentage < MIN_TRADE_VOLUME_PCT ||
                percentage > MAX_TRADE_VOLUME_PCT
            ) {
                revert InvalidMultiplier();
            }
        } else {
            revert InvalidObjective();
        }
    }
}
