// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {TournamentDeckCatalog} from "./TournamentDeckCatalog.sol";

contract TournamentDeckCatalogCardsTest is Test {
    TournamentDeckCatalog catalog;
    address owner;
    address nonOwner;

    function mockNoEffectData() internal pure returns (bytes memory) {
        return abi.encode("NoEffect");
    }

    function mockTransferResourceData(
        string memory resource,
        string memory direction,
        uint16 min,
        uint16 max
    ) internal pure returns (bytes memory) {
        return
            abi.encode(
                "TransferResource",
                resource,
                "Percent",
                direction,
                "Self",
                "Self",
                min,
                max,
                uint8(10),
                "uniform"
            );
    }

    function setUp() public {
        owner = address(this);
        nonOwner = address(0x1234);
        catalog = new TournamentDeckCatalog();
    }

    // should allow owner to register a valid instant card
    function test_RegisterInstantCard() public {
        TournamentDeckCatalog.CardDefinition memory card = TournamentDeckCatalog
            .CardDefinition({
                exists: true,
                paused: false,
                cardId: 1,
                category: TournamentDeckCatalog.CardCategory.Instant,
                trigger: TournamentDeckCatalog.ModifierTrigger.None,
                mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
                baseWeight: 100,
                effectData: mockNoEffectData()
            });

        catalog.registerCard(card);

        require(catalog.cardExists(1), "Card should exist");
        require(catalog.cardCount() == 1, "Card count should be 1");
        require(catalog.isCardActive(1), "Card should be active");
    }

    // should allow owner to register a valid modifier card
    function test_RegisterModifierCard() public {
        TournamentDeckCatalog.CardDefinition memory card = TournamentDeckCatalog
            .CardDefinition({
                exists: true,
                paused: false,
                cardId: 2,
                category: TournamentDeckCatalog.CardCategory.Modifier,
                trigger: TournamentDeckCatalog.ModifierTrigger.OnNextFight,
                mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
                baseWeight: 200,
                effectData: mockNoEffectData()
            });

        catalog.registerCard(card);

        require(catalog.cardExists(2), "Card should exist");
        require(catalog.isCardActive(2), "Card should be active");
    }

    // should allow owner to register a valid resource card
    function test_RegisterMysteryGrantCard() public {
        TournamentDeckCatalog.CardDefinition memory card = TournamentDeckCatalog
            .CardDefinition({
                exists: true,
                paused: false,
                cardId: 3,
                category: TournamentDeckCatalog.CardCategory.Combat,
                trigger: TournamentDeckCatalog.ModifierTrigger.None,
                mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.Rock,
                baseWeight: 50,
                effectData: mockNoEffectData()
            });

        catalog.registerCard(card);

        require(catalog.cardExists(3), "Card should exist");
        require(catalog.isCardActive(3), "Card should be active");
    }

    // shouldn't allow registering a card with id 0
    function test_RegisterCard_RevertWhen_CardIdZero() public {
        TournamentDeckCatalog.CardDefinition memory card = TournamentDeckCatalog
            .CardDefinition({
                exists: true,
                paused: false,
                cardId: 0,
                category: TournamentDeckCatalog.CardCategory.Instant,
                trigger: TournamentDeckCatalog.ModifierTrigger.None,
                mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
                baseWeight: 100,
                effectData: mockNoEffectData()
            });

        vm.expectRevert(TournamentDeckCatalog.InvalidCardId.selector);
        catalog.registerCard(card);
    }

    // shouldn't allow registering a card with duplicate id
    function test_RegisterCard_RevertWhen_CardIdTaken() public {
        TournamentDeckCatalog.CardDefinition memory card = TournamentDeckCatalog
            .CardDefinition({
                exists: true,
                paused: false,
                cardId: 1,
                category: TournamentDeckCatalog.CardCategory.Instant,
                trigger: TournamentDeckCatalog.ModifierTrigger.None,
                mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
                baseWeight: 100,
                effectData: mockNoEffectData()
            });

        catalog.registerCard(card);

        vm.expectRevert(TournamentDeckCatalog.CardIdTaken.selector);
        catalog.registerCard(card);
    }

    // shouldn't allow instant card with non-None trigger
    function test_RegisterInstantCard_RevertWhen_HasTrigger() public {
        TournamentDeckCatalog.CardDefinition memory card = TournamentDeckCatalog
            .CardDefinition({
                exists: true,
                paused: false,
                cardId: 1,
                category: TournamentDeckCatalog.CardCategory.Instant,
                trigger: TournamentDeckCatalog.ModifierTrigger.OnNextFight,
                mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
                baseWeight: 100,
                effectData: mockNoEffectData()
            });

        vm.expectRevert(TournamentDeckCatalog.InvalidModifierTrigger.selector);
        catalog.registerCard(card);
    }

    // shouldn't allow instant card with non-None resource
    function test_RegisterInstantCard_RevertWhen_HasResource() public {
        TournamentDeckCatalog.CardDefinition memory card = TournamentDeckCatalog
            .CardDefinition({
                exists: true,
                paused: false,
                cardId: 1,
                category: TournamentDeckCatalog.CardCategory.Instant,
                trigger: TournamentDeckCatalog.ModifierTrigger.None,
                mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.Rock,
                baseWeight: 100,
                effectData: mockNoEffectData()
            });

        vm.expectRevert(TournamentDeckCatalog.InvalidResource.selector);
        catalog.registerCard(card);
    }

    // shouldn't allow modifier card with None trigger
    function test_RegisterModifierCard_RevertWhen_NoTrigger() public {
        TournamentDeckCatalog.CardDefinition memory card = TournamentDeckCatalog
            .CardDefinition({
                exists: true,
                paused: false,
                cardId: 1,
                category: TournamentDeckCatalog.CardCategory.Modifier,
                trigger: TournamentDeckCatalog.ModifierTrigger.None,
                mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
                baseWeight: 100,
                effectData: mockNoEffectData()
            });

        vm.expectRevert(TournamentDeckCatalog.InvalidModifierTrigger.selector);
        catalog.registerCard(card);
    }

    // shouldn't allow modifier card with non-None resource
    function test_RegisterModifierCard_RevertWhen_HasResource() public {
        TournamentDeckCatalog.CardDefinition memory card = TournamentDeckCatalog
            .CardDefinition({
                exists: true,
                paused: false,
                cardId: 1,
                category: TournamentDeckCatalog.CardCategory.Modifier,
                trigger: TournamentDeckCatalog.ModifierTrigger.OnNextWin,
                mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.Paper,
                baseWeight: 100,
                effectData: mockNoEffectData()
            });

        vm.expectRevert(TournamentDeckCatalog.InvalidResource.selector);
        catalog.registerCard(card);
    }

    // shouldn't allow resource card with None resource
    function test_RegisterMysteryGrantCard_RevertWhen_NoResource() public {
        TournamentDeckCatalog.CardDefinition memory card = TournamentDeckCatalog
            .CardDefinition({
                exists: true,
                paused: false,
                cardId: 1,
                category: TournamentDeckCatalog.CardCategory.Combat,
                trigger: TournamentDeckCatalog.ModifierTrigger.None,
                mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
                baseWeight: 100,
                effectData: mockNoEffectData()
            });

        vm.expectRevert(TournamentDeckCatalog.InvalidResource.selector);
        catalog.registerCard(card);
    }

    // shouldn't allow resource card with non-None trigger
    function test_RegisterMysteryGrantCard_RevertWhen_HasTrigger() public {
        TournamentDeckCatalog.CardDefinition memory card = TournamentDeckCatalog
            .CardDefinition({
                exists: true,
                paused: false,
                cardId: 1,
                category: TournamentDeckCatalog.CardCategory.Combat,
                trigger: TournamentDeckCatalog.ModifierTrigger.OnNextLoss,
                mysteryGrantCard: TournamentDeckCatalog
                    .MysteryGrantCard
                    .Scissors,
                baseWeight: 100,
                effectData: mockNoEffectData()
            });

        vm.expectRevert(TournamentDeckCatalog.InvalidModifierTrigger.selector);
        catalog.registerCard(card);
    }

    // shouldn't allow non-owner to register card
    function test_RegisterCard_RevertWhen_NotOwner() public {
        TournamentDeckCatalog.CardDefinition memory card = TournamentDeckCatalog
            .CardDefinition({
                exists: true,
                paused: false,
                cardId: 1,
                category: TournamentDeckCatalog.CardCategory.Instant,
                trigger: TournamentDeckCatalog.ModifierTrigger.None,
                mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
                baseWeight: 100,
                effectData: mockNoEffectData()
            });

        vm.prank(nonOwner);
        vm.expectRevert();
        catalog.registerCard(card);
    }

    // Should revert with no effectData
    function test_RegisterCard_RevertWhen_EffectDataEmpty() public {
        TournamentDeckCatalog.CardDefinition memory card = TournamentDeckCatalog
            .CardDefinition({
                exists: true,
                paused: false,
                cardId: 1,
                category: TournamentDeckCatalog.CardCategory.Instant,
                trigger: TournamentDeckCatalog.ModifierTrigger.None,
                mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
                baseWeight: 100,
                effectData: ""
            });

        vm.prank(nonOwner);
        vm.expectRevert();
        catalog.registerCard(card);
    }

    // should allow owner to register multiple cards at once
    function test_RegisterCards_Batch() public {
        TournamentDeckCatalog.CardDefinition[]
            memory cards = new TournamentDeckCatalog.CardDefinition[](3);

        cards[0] = TournamentDeckCatalog.CardDefinition({
            exists: true,
            paused: false,
            cardId: 1,
            category: TournamentDeckCatalog.CardCategory.Instant,
            trigger: TournamentDeckCatalog.ModifierTrigger.None,
            mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
            baseWeight: 100,
            effectData: mockNoEffectData()
        });

        cards[1] = TournamentDeckCatalog.CardDefinition({
            exists: true,
            paused: false,
            cardId: 2,
            category: TournamentDeckCatalog.CardCategory.Modifier,
            trigger: TournamentDeckCatalog.ModifierTrigger.OnNextFight,
            mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
            baseWeight: 200,
            effectData: mockNoEffectData()
        });

        cards[2] = TournamentDeckCatalog.CardDefinition({
            exists: true,
            paused: false,
            cardId: 3,
            category: TournamentDeckCatalog.CardCategory.Combat,
            trigger: TournamentDeckCatalog.ModifierTrigger.None,
            mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.Rock,
            baseWeight: 50,
            effectData: mockNoEffectData()
        });

        catalog.registerCards(cards);

        require(catalog.cardCount() == 3, "Should have 3 cards");
        require(catalog.cardExists(1), "Card 1 should exist");
        require(catalog.cardExists(2), "Card 2 should exist");
        require(catalog.cardExists(3), "Card 3 should exist");
    }

    // shouldn't allow batch registration with duplicate ids within batch
    function test_RegisterCards_RevertWhen_DuplicateInBatch() public {
        TournamentDeckCatalog.CardDefinition[]
            memory cards = new TournamentDeckCatalog.CardDefinition[](2);

        cards[0] = TournamentDeckCatalog.CardDefinition({
            exists: true,
            paused: false,
            cardId: 1,
            category: TournamentDeckCatalog.CardCategory.Instant,
            trigger: TournamentDeckCatalog.ModifierTrigger.None,
            mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
            baseWeight: 100,
            effectData: mockNoEffectData()
        });

        cards[1] = TournamentDeckCatalog.CardDefinition({
            exists: true,
            paused: false,
            cardId: 1,
            category: TournamentDeckCatalog.CardCategory.Instant,
            trigger: TournamentDeckCatalog.ModifierTrigger.None,
            mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
            baseWeight: 100,
            effectData: mockNoEffectData()
        });

        vm.expectRevert(TournamentDeckCatalog.CardIdTaken.selector);
        catalog.registerCards(cards);
    }

    // shouldn't allow batch registration when it would exceed max cards (255)
    function test_RegisterCards_RevertWhen_ExceedsMaxCards() public {
        TournamentDeckCatalog.CardDefinition[]
            memory cards = new TournamentDeckCatalog.CardDefinition[](256);

        for (uint256 i = 0; i < 256; i++) {
            cards[i] = TournamentDeckCatalog.CardDefinition({
                exists: true,
                paused: false,
                cardId: uint8(i + 1),
                category: TournamentDeckCatalog.CardCategory.Instant,
                trigger: TournamentDeckCatalog.ModifierTrigger.None,
                mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
                baseWeight: 100,
                effectData: mockNoEffectData()
            });
        }

        vm.expectRevert(TournamentDeckCatalog.ExceedsMaxCards.selector);
        catalog.registerCards(cards);
    }

    // shouldn't allow batch registration with invalid card in batch
    function test_RegisterCards_RevertWhen_InvalidCardInBatch() public {
        TournamentDeckCatalog.CardDefinition[]
            memory cards = new TournamentDeckCatalog.CardDefinition[](2);

        cards[0] = TournamentDeckCatalog.CardDefinition({
            exists: true,
            paused: false,
            cardId: 1,
            category: TournamentDeckCatalog.CardCategory.Instant,
            trigger: TournamentDeckCatalog.ModifierTrigger.None,
            mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
            baseWeight: 100,
            effectData: mockNoEffectData()
        });

        cards[1] = TournamentDeckCatalog.CardDefinition({
            exists: true,
            paused: false,
            cardId: 2,
            category: TournamentDeckCatalog.CardCategory.Modifier,
            trigger: TournamentDeckCatalog.ModifierTrigger.None,
            mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
            baseWeight: 100,
            effectData: mockNoEffectData()
        });

        vm.expectRevert(TournamentDeckCatalog.InvalidModifierTrigger.selector);
        catalog.registerCards(cards);
    }

    // shouldn't allow non-owner to batch register cards
    function test_RegisterCards_RevertWhen_NotOwner() public {
        TournamentDeckCatalog.CardDefinition[]
            memory cards = new TournamentDeckCatalog.CardDefinition[](1);

        cards[0] = TournamentDeckCatalog.CardDefinition({
            exists: true,
            paused: false,
            cardId: 1,
            category: TournamentDeckCatalog.CardCategory.Instant,
            trigger: TournamentDeckCatalog.ModifierTrigger.None,
            mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
            baseWeight: 100,
            effectData: mockNoEffectData()
        });

        vm.prank(nonOwner);
        vm.expectRevert();
        catalog.registerCards(cards);
    }

    // should allow owner to pause a card
    function test_PauseCard() public {
        TournamentDeckCatalog.CardDefinition memory card = TournamentDeckCatalog
            .CardDefinition({
                exists: true,
                paused: false,
                cardId: 1,
                category: TournamentDeckCatalog.CardCategory.Instant,
                trigger: TournamentDeckCatalog.ModifierTrigger.None,
                mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
                baseWeight: 100,
                effectData: mockNoEffectData()
            });

        catalog.registerCard(card);
        catalog.pauseCard(1);

        require(catalog.isCardPaused(1), "Card should be paused");
        require(!catalog.isCardActive(1), "Card should not be active");
    }

    // shouldn't allow pausing non-existent card
    function test_PauseCard_RevertWhen_CardNotFound() public {
        vm.expectRevert(TournamentDeckCatalog.CardNotFound.selector);
        catalog.pauseCard(1);
    }

    // shouldn't allow pausing already paused card
    function test_PauseCard_RevertWhen_AlreadyPaused() public {
        TournamentDeckCatalog.CardDefinition memory card = TournamentDeckCatalog
            .CardDefinition({
                exists: true,
                paused: false,
                cardId: 1,
                category: TournamentDeckCatalog.CardCategory.Instant,
                trigger: TournamentDeckCatalog.ModifierTrigger.None,
                mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
                baseWeight: 100,
                effectData: mockNoEffectData()
            });

        catalog.registerCard(card);
        catalog.pauseCard(1);

        vm.expectRevert(TournamentDeckCatalog.CardAlreadyPaused.selector);
        catalog.pauseCard(1);
    }

    // shouldn't allow non-owner to pause card
    function test_PauseCard_RevertWhen_NotOwner() public {
        TournamentDeckCatalog.CardDefinition memory card = TournamentDeckCatalog
            .CardDefinition({
                exists: true,
                paused: false,
                cardId: 1,
                category: TournamentDeckCatalog.CardCategory.Instant,
                trigger: TournamentDeckCatalog.ModifierTrigger.None,
                mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
                baseWeight: 100,
                effectData: mockNoEffectData()
            });

        catalog.registerCard(card);

        vm.prank(nonOwner);
        vm.expectRevert();
        catalog.pauseCard(1);
    }

    // should allow owner to unpause a card
    function test_UnpauseCard() public {
        TournamentDeckCatalog.CardDefinition memory card = TournamentDeckCatalog
            .CardDefinition({
                exists: true,
                paused: false,
                cardId: 1,
                category: TournamentDeckCatalog.CardCategory.Instant,
                trigger: TournamentDeckCatalog.ModifierTrigger.None,
                mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
                baseWeight: 100,
                effectData: mockNoEffectData()
            });

        catalog.registerCard(card);
        catalog.pauseCard(1);
        catalog.unpauseCard(1);

        require(!catalog.isCardPaused(1), "Card should not be paused");
        require(catalog.isCardActive(1), "Card should be active");
    }

    // shouldn't allow unpausing non-existent card
    function test_UnpauseCard_RevertWhen_CardNotFound() public {
        vm.expectRevert(TournamentDeckCatalog.CardNotFound.selector);
        catalog.unpauseCard(1);
    }

    // shouldn't allow unpausing non-paused card
    function test_UnpauseCard_RevertWhen_NotPaused() public {
        TournamentDeckCatalog.CardDefinition memory card = TournamentDeckCatalog
            .CardDefinition({
                exists: true,
                paused: false,
                cardId: 1,
                category: TournamentDeckCatalog.CardCategory.Instant,
                trigger: TournamentDeckCatalog.ModifierTrigger.None,
                mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
                baseWeight: 100,
                effectData: mockNoEffectData()
            });

        catalog.registerCard(card);

        vm.expectRevert(TournamentDeckCatalog.CardNotPaused.selector);
        catalog.unpauseCard(1);
    }

    // shouldn't allow non-owner to unpause card
    function test_UnpauseCard_RevertWhen_NotOwner() public {
        TournamentDeckCatalog.CardDefinition memory card = TournamentDeckCatalog
            .CardDefinition({
                exists: true,
                paused: false,
                cardId: 1,
                category: TournamentDeckCatalog.CardCategory.Instant,
                trigger: TournamentDeckCatalog.ModifierTrigger.None,
                mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
                baseWeight: 100,
                effectData: mockNoEffectData()
            });

        catalog.registerCard(card);
        catalog.pauseCard(1);

        vm.prank(nonOwner);
        vm.expectRevert();
        catalog.unpauseCard(1);
    }

    // should return correct card data
    function test_GetCard() public {
        TournamentDeckCatalog.CardDefinition memory card = TournamentDeckCatalog
            .CardDefinition({
                exists: true,
                paused: false,
                cardId: 1,
                category: TournamentDeckCatalog.CardCategory.Instant,
                trigger: TournamentDeckCatalog.ModifierTrigger.None,
                mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
                baseWeight: 100,
                effectData: bytes("test")
            });

        catalog.registerCard(card);

        TournamentDeckCatalog.CardDefinition memory retrieved = catalog.getCard(
            1
        );
        require(retrieved.cardId == 1, "Card ID should match");
        require(
            retrieved.category == TournamentDeckCatalog.CardCategory.Instant,
            "Category should match"
        );
        require(retrieved.baseWeight == 100, "Base cost should match");
    }

    // shouldn't allow getting non-existent card
    function test_GetCard_RevertWhen_CardNotFound() public {
        vm.expectRevert(TournamentDeckCatalog.CardNotFound.selector);
        catalog.getCard(1);
    }

    // should return all card ids
    function test_GetAllCardIds() public {
        TournamentDeckCatalog.CardDefinition[]
            memory cards = new TournamentDeckCatalog.CardDefinition[](3);

        for (uint8 i = 0; i < 3; i++) {
            cards[i] = TournamentDeckCatalog.CardDefinition({
                exists: true,
                paused: false,
                cardId: i + 1,
                category: TournamentDeckCatalog.CardCategory.Instant,
                trigger: TournamentDeckCatalog.ModifierTrigger.None,
                mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
                baseWeight: 100,
                effectData: mockNoEffectData()
            });
        }

        catalog.registerCards(cards);

        uint8[] memory ids = catalog.getAllCardIds();
        require(ids.length == 3, "Should have 3 card IDs");
        require(ids[0] == 1, "First ID should be 1");
        require(ids[1] == 2, "Second ID should be 2");
        require(ids[2] == 3, "Third ID should be 3");
    }

    // should return multiple cards by ids
    function test_GetCards() public {
        TournamentDeckCatalog.CardDefinition[]
            memory cards = new TournamentDeckCatalog.CardDefinition[](3);

        for (uint8 i = 0; i < 3; i++) {
            cards[i] = TournamentDeckCatalog.CardDefinition({
                exists: true,
                paused: false,
                cardId: i + 1,
                category: TournamentDeckCatalog.CardCategory.Instant,
                trigger: TournamentDeckCatalog.ModifierTrigger.None,
                mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
                baseWeight: 100,
                effectData: mockNoEffectData()
            });
        }

        catalog.registerCards(cards);

        uint8[] memory idsToFetch = new uint8[](2);
        idsToFetch[0] = 1;
        idsToFetch[1] = 3;

        TournamentDeckCatalog.CardDefinition[] memory retrieved = catalog
            .getCards(idsToFetch);
        require(retrieved.length == 2, "Should return 2 cards");
        require(retrieved[0].cardId == 1, "First card should be ID 1");
        require(retrieved[1].cardId == 3, "Second card should be ID 3");
    }

    // shouldn't allow getting cards with non-existent id
    function test_GetCards_RevertWhen_CardNotFound() public {
        TournamentDeckCatalog.CardDefinition memory card = TournamentDeckCatalog
            .CardDefinition({
                exists: true,
                paused: false,
                cardId: 1,
                category: TournamentDeckCatalog.CardCategory.Instant,
                trigger: TournamentDeckCatalog.ModifierTrigger.None,
                mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
                baseWeight: 100,
                effectData: mockNoEffectData()
            });

        catalog.registerCard(card);

        uint8[] memory idsToFetch = new uint8[](2);
        idsToFetch[0] = 1;
        idsToFetch[1] = 99;

        vm.expectRevert(TournamentDeckCatalog.CardNotFound.selector);
        catalog.getCards(idsToFetch);
    }

    // should fuzz test valid instant card registration
    function testFuzz_RegisterValidInstantCard(
        uint8 cardId,
        uint16 baseWeight
    ) public {
        vm.assume(cardId > 0);
        vm.assume(baseWeight > 0);

        TournamentDeckCatalog.CardDefinition memory card = TournamentDeckCatalog
            .CardDefinition({
                exists: true,
                paused: false,
                cardId: cardId,
                category: TournamentDeckCatalog.CardCategory.Instant,
                trigger: TournamentDeckCatalog.ModifierTrigger.None,
                mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
                baseWeight: baseWeight,
                effectData: mockNoEffectData()
            });

        catalog.registerCard(card);

        require(catalog.cardExists(cardId), "Card should exist");
        TournamentDeckCatalog.CardDefinition memory retrieved = catalog.getCard(
            cardId
        );
        require(retrieved.baseWeight == baseWeight, "Base cost should match");
    }

    // should fuzz test valid modifier card registration with all triggers
    function testFuzz_RegisterValidModifierCard(
        uint8 cardId,
        uint8 triggerIndex,
        uint16 baseWeight
    ) public {
        vm.assume(cardId > 0);
        vm.assume(triggerIndex >= 1 && triggerIndex <= 3);
        vm.assume(baseWeight > 0);

        TournamentDeckCatalog.ModifierTrigger trigger = TournamentDeckCatalog
            .ModifierTrigger(triggerIndex);

        TournamentDeckCatalog.CardDefinition memory card = TournamentDeckCatalog
            .CardDefinition({
                exists: true,
                paused: false,
                cardId: cardId,
                category: TournamentDeckCatalog.CardCategory.Modifier,
                trigger: trigger,
                mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
                baseWeight: baseWeight,
                effectData: mockNoEffectData()
            });

        catalog.registerCard(card);

        require(catalog.cardExists(cardId), "Card should exist");
        TournamentDeckCatalog.CardDefinition memory retrieved = catalog.getCard(
            cardId
        );
        require(retrieved.trigger == trigger, "Trigger should match");
    }

    // should fuzz test valid resource card registration with all types
    function testFuzz_RegisterValidMysteryGrantCard(
        uint8 cardId,
        uint8 resourceIndex,
        uint16 baseWeight
    ) public {
        vm.assume(cardId > 0);
        vm.assume(resourceIndex >= 1 && resourceIndex <= 3);
        vm.assume(baseWeight > 0);
        TournamentDeckCatalog.MysteryGrantCard mysteryGrantCard = TournamentDeckCatalog
                .MysteryGrantCard(resourceIndex);

        TournamentDeckCatalog.CardDefinition memory card = TournamentDeckCatalog
            .CardDefinition({
                exists: true,
                paused: false,
                cardId: cardId,
                category: TournamentDeckCatalog.CardCategory.Combat,
                trigger: TournamentDeckCatalog.ModifierTrigger.None,
                mysteryGrantCard: mysteryGrantCard,
                baseWeight: baseWeight,
                effectData: mockNoEffectData()
            });

        catalog.registerCard(card);

        require(catalog.cardExists(cardId), "Card should exist");
        TournamentDeckCatalog.CardDefinition memory retrieved = catalog.getCard(
            cardId
        );
        require(
            retrieved.mysteryGrantCard == mysteryGrantCard,
            "Resource type should match"
        );
    }

    // should maintain correct card count after multiple registrations
    function test_CardCount_ConsistentAfterMultipleRegistrations() public {
        for (uint8 i = 1; i <= 10; i++) {
            TournamentDeckCatalog.CardDefinition
                memory card = TournamentDeckCatalog.CardDefinition({
                    exists: true,
                    paused: false,
                    cardId: i,
                    category: TournamentDeckCatalog.CardCategory.Instant,
                    trigger: TournamentDeckCatalog.ModifierTrigger.None,
                    mysteryGrantCard: TournamentDeckCatalog
                        .MysteryGrantCard
                        .None,
                    baseWeight: 100,
                    effectData: mockNoEffectData()
                });

            catalog.registerCard(card);
            require(catalog.cardCount() == i, "Card count should increment");
        }
    }

    // should maintain paused state correctly through pause/unpause cycles
    function test_PausedState_ConsistentThroughCycles() public {
        TournamentDeckCatalog.CardDefinition memory card = TournamentDeckCatalog
            .CardDefinition({
                exists: true,
                paused: false,
                cardId: 1,
                category: TournamentDeckCatalog.CardCategory.Instant,
                trigger: TournamentDeckCatalog.ModifierTrigger.None,
                mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
                baseWeight: 100,
                effectData: mockNoEffectData()
            });

        catalog.registerCard(card);

        require(!catalog.isCardPaused(1), "Should not be paused initially");
        require(catalog.isCardActive(1), "Should be active initially");

        catalog.pauseCard(1);
        require(catalog.isCardPaused(1), "Should be paused after pause");
        require(!catalog.isCardActive(1), "Should not be active after pause");

        catalog.unpauseCard(1);
        require(!catalog.isCardPaused(1), "Should not be paused after unpause");
        require(catalog.isCardActive(1), "Should be active after unpause");
    }

    // should maintain card existence state correctly
    function test_CardExistence_ConsistentAfterRegistration() public {
        require(!catalog.cardExists(1), "Card should not exist initially");

        TournamentDeckCatalog.CardDefinition memory card = TournamentDeckCatalog
            .CardDefinition({
                exists: true,
                paused: false,
                cardId: 1,
                category: TournamentDeckCatalog.CardCategory.Instant,
                trigger: TournamentDeckCatalog.ModifierTrigger.None,
                mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
                baseWeight: 100,
                effectData: mockNoEffectData()
            });

        catalog.registerCard(card);

        require(catalog.cardExists(1), "Card should exist after registration");
    }

    // should maintain correct state for multiple cards with different categories
    function test_MultipleCards_DifferentCategories_StateConsistent() public {
        TournamentDeckCatalog.CardDefinition[]
            memory cards = new TournamentDeckCatalog.CardDefinition[](3);

        cards[0] = TournamentDeckCatalog.CardDefinition({
            exists: true,
            paused: false,
            cardId: 1,
            category: TournamentDeckCatalog.CardCategory.Instant,
            trigger: TournamentDeckCatalog.ModifierTrigger.None,
            mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
            baseWeight: 100,
            effectData: mockNoEffectData()
        });

        cards[1] = TournamentDeckCatalog.CardDefinition({
            exists: true,
            paused: false,
            cardId: 2,
            category: TournamentDeckCatalog.CardCategory.Modifier,
            trigger: TournamentDeckCatalog.ModifierTrigger.OnNextFight,
            mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
            baseWeight: 200,
            effectData: mockNoEffectData()
        });

        cards[2] = TournamentDeckCatalog.CardDefinition({
            exists: true,
            paused: false,
            cardId: 3,
            category: TournamentDeckCatalog.CardCategory.Combat,
            trigger: TournamentDeckCatalog.ModifierTrigger.None,
            mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.Rock,
            baseWeight: 50,
            effectData: mockNoEffectData()
        });

        catalog.registerCards(cards);

        TournamentDeckCatalog.CardDefinition memory card1 = catalog.getCard(1);
        TournamentDeckCatalog.CardDefinition memory card2 = catalog.getCard(2);
        TournamentDeckCatalog.CardDefinition memory card3 = catalog.getCard(3);

        require(
            card1.category == TournamentDeckCatalog.CardCategory.Instant,
            "Card 1 should be Instant"
        );
        require(
            card2.category == TournamentDeckCatalog.CardCategory.Modifier,
            "Card 2 should be Modifier"
        );
        require(
            card3.category == TournamentDeckCatalog.CardCategory.Combat,
            "Card 3 should be Resource"
        );
    }

    // should not overflow card count at boundary (254 -> 255)
    function test_CardCount_NoOverflowAtBoundary() public {
        TournamentDeckCatalog.CardDefinition[]
            memory cards = new TournamentDeckCatalog.CardDefinition[](255);

        for (uint256 i = 0; i < 255; i++) {
            cards[i] = TournamentDeckCatalog.CardDefinition({
                exists: true,
                paused: false,
                cardId: uint8(i + 1),
                category: TournamentDeckCatalog.CardCategory.Instant,
                trigger: TournamentDeckCatalog.ModifierTrigger.None,
                mysteryGrantCard: TournamentDeckCatalog.MysteryGrantCard.None,
                baseWeight: 100,
                effectData: mockNoEffectData()
            });
        }

        catalog.registerCards(cards);

        require(catalog.cardCount() == 255, "Card count should be 255");
        require(catalog.cardExists(255), "Card 255 should exist");
    }

    // should maintain consistent state when pausing multiple cards
    function test_MultiplePausedCards_StateConsistent() public {
        for (uint8 i = 1; i <= 5; i++) {
            TournamentDeckCatalog.CardDefinition
                memory card = TournamentDeckCatalog.CardDefinition({
                    exists: true,
                    paused: false,
                    cardId: i,
                    category: TournamentDeckCatalog.CardCategory.Instant,
                    trigger: TournamentDeckCatalog.ModifierTrigger.None,
                    mysteryGrantCard: TournamentDeckCatalog
                        .MysteryGrantCard
                        .None,
                    baseWeight: 100,
                    effectData: mockNoEffectData()
                });

            catalog.registerCard(card);
        }

        catalog.pauseCard(2);
        catalog.pauseCard(4);

        require(!catalog.isCardPaused(1), "Card 1 should not be paused");
        require(catalog.isCardPaused(2), "Card 2 should be paused");
        require(!catalog.isCardPaused(3), "Card 3 should not be paused");
        require(catalog.isCardPaused(4), "Card 4 should be paused");
        require(!catalog.isCardPaused(5), "Card 5 should not be paused");
    }
}
