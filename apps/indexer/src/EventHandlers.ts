/*
 * Please refer to https://docs.envio.dev for a thorough guide on all Envio indexer features
 */
import {
  TournamentCombat,
  TournamentCombat_CombatResolved,
  TournamentCombat_CombatStarted,
  TournamentCombat_CombatTimedOut,
  TournamentDeckCatalog,
  TournamentDeckCatalog_CardPaused,
  TournamentDeckCatalog_CardRegistered,
  TournamentDeckCatalog_CardUnpaused,
  TournamentDeckCatalog_ObjectivePaused,
  TournamentDeckCatalog_ObjectiveRegistered,
  TournamentDeckCatalog_ObjectiveUnpaused,
  TournamentFactory,
  TournamentFactory_OwnershipTransferred,
  TournamentFactory_PlatformFeeUpdated,
  TournamentFactory_RngOracleUpdated,
  TournamentFactory_TournamentSystemCreated,
  TournamentHub,
  TournamentHub_EmergencyCancellation,
  TournamentHub_ExitWindowOpened,
  TournamentHub_PlayerResourcesUpdated,
  TournamentHub_RandomnessFailure,
  TournamentMysteryDeck,
  TournamentMysteryDeck_CardDrawn,
  TournamentMysteryDeck_CardsAdded,
  TournamentMysteryDeck_CardsPeeked,
  TournamentMysteryDeck_CardsRemoved,
  TournamentMysteryDeck_DeckInitialized,
  TournamentMysteryDeck_DeckShuffled,
  TournamentMysteryDeck_ShuffleSeedUpdated,
  TournamentRandomizer,
  TournamentRandomizer_CompleteSeedRevealed,
  TournamentRandomizer_MysteryDeckSet,
  TournamentRandomizer_SeedGenerated,
  TournamentRandomizer_SeedRequestCancelled,
  TournamentRandomizer_SeedRequested,
  TournamentRegistry,
  TournamentRegistry_TournamentStatusUpdated,
  TournamentRegistry_TournamentSystemRegistered,
  TournamentTokenWhitelist,
  TournamentTokenWhitelist_TokenPaused,
  TournamentTokenWhitelist_TokenUnpaused,
  TournamentTokenWhitelist_TokenWhitelisted,
  TournamentTrading,
  TournamentTrading_OfferCancelled,
  TournamentTrading_OfferCreated,
  TournamentTrading_TradeExecuted,
} from "generated";

TournamentCombat.CombatResolved.handler(async ({ event, context }) => {
  const entity: TournamentCombat_CombatResolved = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    resolution_0: event.params.resolution
        [0]
    ,
    resolution_1: event.params.resolution
        [1]
    ,
    resolution_2: event.params.resolution
        [2]
    ,
    resolution_3: event.params.resolution
        [3]
    ,
    resolution_4: event.params.resolution
        [4]
    ,
    resolution_5: event.params.resolution
        [5]
    ,
    resolution_6: event.params.resolution
        [6]
    ,
    resolution_7: event.params.resolution
        [7]
    ,
    resolution_8: event.params.resolution
        [8]
    ,
    resolution_9: event.params.resolution
        [9]
    ,
    resolution_10: event.params.resolution
        [10]
    ,
    resolution_11: event.params.resolution
        [11]
    ,
    resolution_12: event.params.resolution
        [12]
    ,
    combatId: event.params.combatId,
    timestamp: event.params.timestamp,
  };

  context.TournamentCombat_CombatResolved.set(entity);
});

TournamentCombat.CombatStarted.handler(async ({ event, context }) => {
  const entity: TournamentCombat_CombatStarted = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    combatId: event.params.combatId,
    p1: event.params.p1,
    p2: event.params.p2,
    timestamp: event.params.timestamp,
  };

  context.TournamentCombat_CombatStarted.set(entity);
});

TournamentCombat.CombatTimedOut.handler(async ({ event, context }) => {
  const entity: TournamentCombat_CombatTimedOut = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    combatId: event.params.combatId,
    p1: event.params.p1,
    p2: event.params.p2,
    timestamp: event.params.timestamp,
  };

  context.TournamentCombat_CombatTimedOut.set(entity);
});

TournamentDeckCatalog.CardPaused.handler(async ({ event, context }) => {
  const entity: TournamentDeckCatalog_CardPaused = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    cardId: event.params.cardId,
    timestamp: event.params.timestamp,
  };

  context.TournamentDeckCatalog_CardPaused.set(entity);
});

TournamentDeckCatalog.CardRegistered.handler(async ({ event, context }) => {
  const entity: TournamentDeckCatalog_CardRegistered = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    cardId: event.params.cardId,
    category: event.params.category,
    baseWeight: event.params.baseWeight,
  };

  context.TournamentDeckCatalog_CardRegistered.set(entity);
});

TournamentDeckCatalog.CardUnpaused.handler(async ({ event, context }) => {
  const entity: TournamentDeckCatalog_CardUnpaused = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    cardId: event.params.cardId,
    timestamp: event.params.timestamp,
  };

  context.TournamentDeckCatalog_CardUnpaused.set(entity);
});

TournamentDeckCatalog.ObjectivePaused.handler(async ({ event, context }) => {
  const entity: TournamentDeckCatalog_ObjectivePaused = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    objectiveId: event.params.objectiveId,
    timestamp: event.params.timestamp,
  };

  context.TournamentDeckCatalog_ObjectivePaused.set(entity);
});

TournamentDeckCatalog.ObjectiveRegistered.handler(async ({ event, context }) => {
  const entity: TournamentDeckCatalog_ObjectiveRegistered = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    objectiveId: event.params.objectiveId,
    objectiveType: event.params.objectiveType,
  };

  context.TournamentDeckCatalog_ObjectiveRegistered.set(entity);
});

TournamentDeckCatalog.ObjectiveUnpaused.handler(async ({ event, context }) => {
  const entity: TournamentDeckCatalog_ObjectiveUnpaused = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    objectiveId: event.params.objectiveId,
    timestamp: event.params.timestamp,
  };

  context.TournamentDeckCatalog_ObjectiveUnpaused.set(entity);
});

TournamentFactory.OwnershipTransferred.handler(async ({ event, context }) => {
  const entity: TournamentFactory_OwnershipTransferred = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    previousOwner: event.params.previousOwner,
    newOwner: event.params.newOwner,
  };

  context.TournamentFactory_OwnershipTransferred.set(entity);
});

TournamentFactory.PlatformFeeUpdated.handler(async ({ event, context }) => {
  const entity: TournamentFactory_PlatformFeeUpdated = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    newFee: event.params.newFee,
  };

  context.TournamentFactory_PlatformFeeUpdated.set(entity);
});

TournamentFactory.RngOracleUpdated.handler(async ({ event, context }) => {
  const entity: TournamentFactory_RngOracleUpdated = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    newOracle: event.params.newOracle,
  };

  context.TournamentFactory_RngOracleUpdated.set(entity);
});

TournamentFactory.TournamentSystemCreated.handler(async ({ event, context }) => {
  const entity: TournamentFactory_TournamentSystemCreated = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    hub: event.params.hub,
    combat: event.params.combat,
    mysteryDeck: event.params.mysteryDeck,
    trading: event.params.trading,
    randomizer: event.params.randomizer,
    creator: event.params.creator,
    stakeToken: event.params.stakeToken,
    startTimestamp: event.params.startTimestamp,
    duration: event.params.duration,
  };

  context.TournamentFactory_TournamentSystemCreated.set(entity);
});

TournamentHub.EmergencyCancellation.handler(async ({ event, context }) => {
  const entity: TournamentHub_EmergencyCancellation = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    platformAdmin: event.params.platformAdmin,
    timestamp: event.params.timestamp,
  };

  context.TournamentHub_EmergencyCancellation.set(entity);
});

TournamentHub.ExitWindowOpened.handler(async ({ event, context }) => {
  const entity: TournamentHub_ExitWindowOpened = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    windowStart: event.params.windowStart,
    windowEnd: event.params.windowEnd,
  };

  context.TournamentHub_ExitWindowOpened.set(entity);
});

TournamentHub.RandomnessFailure.handler(async ({ event, context }) => {
  const entity: TournamentHub_RandomnessFailure = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    timestamp: event.params.timestamp,
  };

  context.TournamentHub_RandomnessFailure.set(entity);
});

TournamentMysteryDeck.CardDrawn.handler(async ({ event, context }) => {
  const entity: TournamentMysteryDeck_CardDrawn = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    player: event.params.player,
    costPaid: event.params.costPaid,
    newDrawCount: event.params.newDrawCount,
    cardsRemaining: event.params.cardsRemaining,
    timestamp: event.params.timestamp,
  };

  context.TournamentMysteryDeck_CardDrawn.set(entity);
});

TournamentMysteryDeck.CardsAdded.handler(async ({ event, context }) => {
  const entity: TournamentMysteryDeck_CardsAdded = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    player: event.params.player,
    cardCount: event.params.cardCount,
    costPaid: event.params.costPaid,
    newCardsRemaining: event.params.newCardsRemaining,
    timestamp: event.params.timestamp,
  };

  context.TournamentMysteryDeck_CardsAdded.set(entity);
});

TournamentMysteryDeck.CardsPeeked.handler(async ({ event, context }) => {
  const entity: TournamentMysteryDeck_CardsPeeked = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    player: event.params.player,
    cardCount: event.params.cardCount,
    costPaid: event.params.costPaid,
    timestamp: event.params.timestamp,
  };

  context.TournamentMysteryDeck_CardsPeeked.set(entity);
});

TournamentMysteryDeck.CardsRemoved.handler(async ({ event, context }) => {
  const entity: TournamentMysteryDeck_CardsRemoved = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    player: event.params.player,
    cardCount: event.params.cardCount,
    costPaid: event.params.costPaid,
    newCardsRemaining: event.params.newCardsRemaining,
    timestamp: event.params.timestamp,
  };

  context.TournamentMysteryDeck_CardsRemoved.set(entity);
});

TournamentMysteryDeck.DeckInitialized.handler(async ({ event, context }) => {
  const entity: TournamentMysteryDeck_DeckInitialized = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    deckSize: event.params.deckSize,
    sequenceNumber: event.params.sequenceNumber,
    timestamp: event.params.timestamp,
  };

  context.TournamentMysteryDeck_DeckInitialized.set(entity);
});

TournamentMysteryDeck.DeckShuffled.handler(async ({ event, context }) => {
  const entity: TournamentMysteryDeck_DeckShuffled = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    player: event.params.player,
    costPaid: event.params.costPaid,
    newShuffleCount: event.params.newShuffleCount,
    timestamp: event.params.timestamp,
  };

  context.TournamentMysteryDeck_DeckShuffled.set(entity);
});

TournamentMysteryDeck.ShuffleSeedUpdated.handler(async ({ event, context }) => {
  const entity: TournamentMysteryDeck_ShuffleSeedUpdated = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    newSeed: event.params.newSeed,
    backendSecretHash: event.params.backendSecretHash,
    timestamp: event.params.timestamp,
  };

  context.TournamentMysteryDeck_ShuffleSeedUpdated.set(entity);
});

TournamentRandomizer.CompleteSeedRevealed.handler(async ({ event, context }) => {
  const entity: TournamentRandomizer_CompleteSeedRevealed = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    completeSeed: event.params.completeSeed,
    backendSecret: event.params.backendSecret,
    timestamp: event.params.timestamp,
  };

  context.TournamentRandomizer_CompleteSeedRevealed.set(entity);
});

TournamentRandomizer.MysteryDeckSet.handler(async ({ event, context }) => {
  const entity: TournamentRandomizer_MysteryDeckSet = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    mysteryDeck: event.params.mysteryDeck,
  };

  context.TournamentRandomizer_MysteryDeckSet.set(entity);
});

TournamentRandomizer.SeedGenerated.handler(async ({ event, context }) => {
  const entity: TournamentRandomizer_SeedGenerated = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    sequenceNumber: event.params.sequenceNumber,
    seedIndex: event.params.seedIndex,
    seed: event.params.seed,
    timestamp: event.params.timestamp,
  };

  context.TournamentRandomizer_SeedGenerated.set(entity);
});

TournamentRandomizer.SeedRequestCancelled.handler(async ({ event, context }) => {
  const entity: TournamentRandomizer_SeedRequestCancelled = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    sequenceNumber: event.params.sequenceNumber,
    timestamp: event.params.timestamp,
  };

  context.TournamentRandomizer_SeedRequestCancelled.set(entity);
});

TournamentRandomizer.SeedRequested.handler(async ({ event, context }) => {
  const entity: TournamentRandomizer_SeedRequested = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    sequenceNumber: event.params.sequenceNumber,
    requester: event.params.requester,
    seedIndex: event.params.seedIndex,
    timestamp: event.params.timestamp,
  };

  context.TournamentRandomizer_SeedRequested.set(entity);
});

TournamentRegistry.TournamentStatusUpdated.handler(async ({ event, context }) => {
  const entity: TournamentRegistry_TournamentStatusUpdated = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    hub: event.params.hub,
    oldStatus: event.params.oldStatus,
    newStatus: event.params.newStatus,
  };

  context.TournamentRegistry_TournamentStatusUpdated.set(entity);
});

TournamentRegistry.TournamentSystemRegistered.handler(async ({ event, context }) => {
  const entity: TournamentRegistry_TournamentSystemRegistered = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    hub: event.params.hub,
    combat: event.params.combat,
    mysteryDeck: event.params.mysteryDeck,
    trading: event.params.trading,
    randomizer: event.params.randomizer,
    initialStatus: event.params.initialStatus,
  };

  context.TournamentRegistry_TournamentSystemRegistered.set(entity);
});

TournamentTokenWhitelist.TokenPaused.handler(async ({ event, context }) => {
  const entity: TournamentTokenWhitelist_TokenPaused = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    token: event.params.token,
    reason: event.params.reason,
  };

  context.TournamentTokenWhitelist_TokenPaused.set(entity);
});

TournamentTokenWhitelist.TokenUnpaused.handler(async ({ event, context }) => {
  const entity: TournamentTokenWhitelist_TokenUnpaused = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    token: event.params.token,
  };

  context.TournamentTokenWhitelist_TokenUnpaused.set(entity);
});

TournamentTokenWhitelist.TokenWhitelisted.handler(async ({ event, context }) => {
  const entity: TournamentTokenWhitelist_TokenWhitelisted = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    token: event.params.token,
  };

  context.TournamentTokenWhitelist_TokenWhitelisted.set(entity);
});

TournamentTrading.OfferCancelled.handler(async ({ event, context }) => {
  const entity: TournamentTrading_OfferCancelled = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    offerId: event.params.offerId,
    creator: event.params.creator,
    timestamp: event.params.timestamp,
  };

  context.TournamentTrading_OfferCancelled.set(entity);
});

TournamentTrading.OfferCreated.handler(async ({ event, context }) => {
  const entity: TournamentTrading_OfferCreated = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    offerId: event.params.offerId,
    creator: event.params.creator,
    offered_0: event.params.offered
        [0]
    ,
    offered_1: event.params.offered
        [1]
    ,
    offered_2: event.params.offered
        [2]
    ,
    offered_3: event.params.offered
        [3]
    ,
    offered_4: event.params.offered
        [4]
    ,
    requested_0: event.params.requested
        [0]
    ,
    requested_1: event.params.requested
        [1]
    ,
    requested_2: event.params.requested
        [2]
    ,
    requested_3: event.params.requested
        [3]
    ,
    requested_4: event.params.requested
        [4]
    ,
    expiresAt: event.params.expiresAt,
    createdAt: event.params.createdAt,
  };

  context.TournamentTrading_OfferCreated.set(entity);
});

TournamentTrading.TradeExecuted.handler(async ({ event, context }) => {
  const entity: TournamentTrading_TradeExecuted = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    offerId: event.params.offerId,
    creator: event.params.creator,
    acceptor: event.params.acceptor,
    creatorTotalCardsDelta: event.params.creatorTotalCardsDelta,
    acceptorTotalCardsDelta: event.params.acceptorTotalCardsDelta,
    timestamp: event.params.timestamp,
  };

  context.TournamentTrading_TradeExecuted.set(entity);
});
