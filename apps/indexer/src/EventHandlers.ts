/*
 * Please refer to https://docs.envio.dev for a thorough guide on all Envio indexer features
 */
/** biome-ignore-all lint/style/useNamingConvention: - */
import {
  TournamentCombat,
  type TournamentCombat_CombatResolved,
  type TournamentCombat_CombatStarted,
  type TournamentCombat_CombatTimedOut,
  TournamentDeckCatalog,
  type TournamentDeckCatalog_CardPaused,
  type TournamentDeckCatalog_CardRegistered,
  type TournamentDeckCatalog_CardUnpaused,
  type TournamentDeckCatalog_ObjectivePaused,
  type TournamentDeckCatalog_ObjectiveRegistered,
  type TournamentDeckCatalog_ObjectiveUnpaused,
  TournamentFactory,
  type TournamentFactory_OwnershipTransferred,
  type TournamentFactory_PlatformFeeUpdated,
  type TournamentFactory_RngOracleUpdated,
  type TournamentFactory_TournamentSystemCreated,
  TournamentHub,
  type TournamentHub_EmergencyCancellation,
  type TournamentHub_ExitWindowOpened,
  type TournamentHub_PlayerExited,
  type TournamentHub_PlayerForfeited,
  type TournamentHub_PlayerJoined,
  type TournamentHub_PrizeClaimed,
  type TournamentHub_RefundClaimed,
  type TournamentHub_TournamentCancelled,
  type TournamentHub_TournamentEnded,
  type TournamentHub_TournamentLocked,
  type TournamentHub_TournamentPendingStart,
  type TournamentHub_TournamentRevertedToOpen,
  type TournamentHub_TournamentStarted,
  type TournamentHub_TournamentUnlocked,
  TournamentMysteryDeck,
  type TournamentMysteryDeck_CardDrawn,
  type TournamentMysteryDeck_CardsAdded,
  type TournamentMysteryDeck_CardsPeeked,
  type TournamentMysteryDeck_CardsRemoved,
  type TournamentMysteryDeck_DeckInitialized,
  type TournamentMysteryDeck_DeckShuffled,
  type TournamentMysteryDeck_ShuffleSeedUpdated,
  TournamentRandomizer,
  type TournamentRandomizer_CompleteSeedRevealed,
  type TournamentRandomizer_MysteryDeckSet,
  type TournamentRandomizer_SeedGenerated,
  type TournamentRandomizer_SeedRequestCancelled,
  type TournamentRandomizer_SeedRequested,
  TournamentRegistry,
  type TournamentRegistry_TournamentStatusUpdated,
  type TournamentRegistry_TournamentSystemRegistered,
  TournamentTokenWhitelist,
  type TournamentTokenWhitelist_TokenPaused,
  type TournamentTokenWhitelist_TokenUnpaused,
  type TournamentTokenWhitelist_TokenWhitelisted,
  TournamentTrading,
  type TournamentTrading_OfferCancelled,
  type TournamentTrading_OfferCreated,
  type TournamentTrading_TradeExecuted,
} from "generated"

TournamentCombat.CombatResolved.handler(async ({ event, context }) => {
  const res = event.params.resolution;
  const entity: TournamentCombat_CombatResolved = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    // Resolution struct fields
    player1: res[1],
    player2: res[2],
    p1CardsBurned: res[3],
    p2CardsBurned: res[4],
    rpsOutcome: res[5], // 0=P1Win, 1=P2Win, 2=Draw
    decision: res[6],
    modifierApplied: res[7],
    p1LifeDelta: res[8],
    p2LifeDelta: res[9],
    p1CoinDelta: res[10],
    p2CoinDelta: res[11],
    proofHash: res[12],
    combatId: event.params.combatId,
    timestamp: event.params.timestamp,
  }

  context.TournamentCombat_CombatResolved.set(entity)
})

TournamentCombat.CombatStarted.handler(async ({ event, context }) => {
  const entity: TournamentCombat_CombatStarted = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    combatId: event.params.combatId,
    p1: event.params.p1,
    p2: event.params.p2,
    timestamp: event.params.timestamp,
  }

  context.TournamentCombat_CombatStarted.set(entity)
})

TournamentCombat.CombatTimedOut.handler(async ({ event, context }) => {
  const entity: TournamentCombat_CombatTimedOut = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    combatId: event.params.combatId,
    p1: event.params.p1,
    p2: event.params.p2,
    timestamp: event.params.timestamp,
  }

  context.TournamentCombat_CombatTimedOut.set(entity)
})

TournamentDeckCatalog.CardPaused.handler(async ({ event, context }) => {
  const entity: TournamentDeckCatalog_CardPaused = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    cardId: event.params.cardId,
    timestamp: event.params.timestamp,
  }

  context.TournamentDeckCatalog_CardPaused.set(entity)
})

TournamentDeckCatalog.CardRegistered.handler(async ({ event, context }) => {
  const entity: TournamentDeckCatalog_CardRegistered = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    cardId: event.params.cardId,
    category: event.params.category,
    baseWeight: event.params.baseWeight,
    mysteryGrantCard: event.params.mysteryGrantCard,
    trigger: event.params.trigger,
    effectData: event.params.effectData,
  }
  context.TournamentDeckCatalog_CardRegistered.set(entity)
})

TournamentDeckCatalog.CardUnpaused.handler(async ({ event, context }) => {
  const entity: TournamentDeckCatalog_CardUnpaused = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    cardId: event.params.cardId,
    timestamp: event.params.timestamp,
  }

  context.TournamentDeckCatalog_CardUnpaused.set(entity)
})

TournamentDeckCatalog.ObjectivePaused.handler(async ({ event, context }) => {
  const entity: TournamentDeckCatalog_ObjectivePaused = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    objectiveId: event.params.objectiveId,
    timestamp: event.params.timestamp,
  }

  context.TournamentDeckCatalog_ObjectivePaused.set(entity)
})

TournamentDeckCatalog.ObjectiveRegistered.handler(async ({ event, context }) => {
  const entity: TournamentDeckCatalog_ObjectiveRegistered = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    objectiveId: event.params.objectiveId,
    objectiveType: event.params.objectiveType,
    targetData: event.params.targetData,
  }

  context.TournamentDeckCatalog_ObjectiveRegistered.set(entity)
})

TournamentDeckCatalog.ObjectiveUnpaused.handler(async ({ event, context }) => {
  const entity: TournamentDeckCatalog_ObjectiveUnpaused = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    objectiveId: event.params.objectiveId,
    timestamp: event.params.timestamp,
  }

  context.TournamentDeckCatalog_ObjectiveUnpaused.set(entity)
})

TournamentFactory.OwnershipTransferred.handler(async ({ event, context }) => {
  const entity: TournamentFactory_OwnershipTransferred = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    previousOwner: event.params.previousOwner,
    newOwner: event.params.newOwner,
  }

  context.TournamentFactory_OwnershipTransferred.set(entity)
})

TournamentFactory.PlatformFeeUpdated.handler(async ({ event, context }) => {
  const entity: TournamentFactory_PlatformFeeUpdated = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    newFee: event.params.newFee,
  }

  context.TournamentFactory_PlatformFeeUpdated.set(entity)
})

TournamentFactory.RngOracleUpdated.handler(async ({ event, context }) => {
  const entity: TournamentFactory_RngOracleUpdated = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    newOracle: event.params.newOracle,
  }

  context.TournamentFactory_RngOracleUpdated.set(entity)
})

TournamentFactory.TournamentSystemCreated.contractRegister(async ({ event, context }) => {
  context.addTournamentHub(event.params.hub)
  context.addTournamentMysteryDeck(event.params.mysteryDeck)
  context.addTournamentRandomizer(event.params.randomizer)
  context.addTournamentCombat(event.params.combat)
  context.addTournamentTrading(event.params.trading)

  context.log.info(
    `Registered Hub: ${event.params.hub}\n
    Mystery Deck: ${event.params.mysteryDeck}\n
    Randomizer: ${event.params.randomizer}\n
    Trading: ${event.params.trading}
    Combat: ${event.params.combat}\n`,
  )
})

TournamentFactory.TournamentSystemCreated.handler(async ({ event, context }) => {
  // Envio should expose the tuple - check generated types for exact name
  // It might be event.params.param6 or event.params.params_6 or similar
  const params = event.params._6; // Adjust based on generated types
  
  const entity: TournamentFactory_TournamentSystemCreated = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    hub: event.params.hub,
    combat: event.params.combat,
    mysteryDeck: event.params.mysteryDeck,
    trading: event.params.trading,
    randomizer: event.params.randomizer,
    creator: event.params.creator,
    
    // Flatten the params tuple
    startTimestamp: params[0],
    duration: params[1],
    gameInterval: params[2],
    minPlayers: params[3],
    maxPlayers: params[4],
    startPlayerCount: params[5],
    startPoolAmount: params[6],
    stakeToken: params[7],
    minStake: params[8],
    maxStake: params[9],
    coinConversionRate: params[10],
    decayAmount: params[11],
    initialLives: params[12],
    cardsPerType: params[13],
    exitLivesRequired: params[14],
    exitCostBasePercentBPS: params[15],
    exitCostCompoundRateBPS: params[16],
    creatorFeePercent: params[17],
    platformFeePercent: params[18],
    forfeitAllowed: params[19],
    forfeitPenaltyType: params[20],
    forfeitMaxPenalty: params[21],
    forfeitMinPenalty: params[22],
    deckCatalog: params[23],
    excludedCardIds: params[24],
    deckDrawCost: params[25],
    deckShuffleCost: params[26],
    deckPeekCost: params[27],
  };
  
  context.TournamentFactory_TournamentSystemCreated.set(entity);
})

TournamentHub.PlayerJoined.handler(async ({ event, context }) => {
  const entity: TournamentHub_PlayerJoined = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    player: event.params.player,
    stakeAmount: event.params.stakeAmount,
    initialCoins: event.params.initialCoins,
    timestamp: event.params.timestamp,
  }

  context.TournamentHub_PlayerJoined.set(entity)
})

TournamentHub.PlayerExited.handler(async ({ event, context }) => {
  const entity: TournamentHub_PlayerExited = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    player: event.params.player,
    timestamp: event.params.timestamp,
  }

  context.TournamentHub_PlayerExited.set(entity)
})

TournamentHub.PlayerForfeited.handler(async ({ event, context }) => {
  const entity: TournamentHub_PlayerForfeited = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    player: event.params.player,
    penaltyAmount: event.params.penaltyAmount,
    refundAmount: event.params.refundAmount,
    timestamp: event.params.timestamp,
  }

  context.TournamentHub_PlayerForfeited.set(entity)
})

TournamentHub.TournamentLocked.handler(async ({ event, context }) => {
  const entity: TournamentHub_TournamentLocked = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    timestamp: event.params.timestamp,
  }

  context.TournamentHub_TournamentLocked.set(entity)
})

TournamentHub.TournamentUnlocked.handler(async ({ event, context }) => {
  const entity: TournamentHub_TournamentUnlocked = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    timestamp: event.params.timestamp,
  }

  context.TournamentHub_TournamentUnlocked.set(entity)
})

TournamentHub.TournamentPendingStart.handler(async ({ event, context }) => {
  const entity: TournamentHub_TournamentPendingStart = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    timestamp: event.params.timestamp,
  }

  context.TournamentHub_TournamentPendingStart.set(entity)
})

TournamentHub.TournamentRevertedToOpen.handler(async ({ event, context }) => {
  const entity: TournamentHub_TournamentRevertedToOpen = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    timestamp: event.params.timestamp,
  }

  context.TournamentHub_TournamentRevertedToOpen.set(entity)
})

TournamentHub.TournamentStarted.handler(async ({ event, context }) => {
  const entity: TournamentHub_TournamentStarted = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    startTime: event.params.startTime,
    endTime: event.params.endTime,
    exitWindowStart: event.params.exitWindowStart,
  }

  context.TournamentHub_TournamentStarted.set(entity)
})

TournamentHub.TournamentEnded.handler(async ({ event, context }) => {
  const entity: TournamentHub_TournamentEnded = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    winnerCount: event.params.winnerCount,
    prizePool: event.params.prizePool,
    timestamp: event.params.timestamp,
  }

  context.TournamentHub_TournamentEnded.set(entity)
})

TournamentHub.TournamentCancelled.handler(async ({ event, context }) => {
  const entity: TournamentHub_TournamentCancelled = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    timestamp: event.params.timestamp,
  }

  context.TournamentHub_TournamentCancelled.set(entity)
})

TournamentHub.RefundClaimed.handler(async ({ event, context }) => {
  const entity: TournamentHub_RefundClaimed = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    player: event.params.player,
    amount: event.params.amount,
  }

  context.TournamentHub_RefundClaimed.set(entity)
})

TournamentHub.PrizeClaimed.handler(async ({ event, context }) => {
  const entity: TournamentHub_PrizeClaimed = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    player: event.params.player,
    amount: event.params.amount,
  }

  context.TournamentHub_PrizeClaimed.set(entity)
})

TournamentHub.EmergencyCancellation.handler(async ({ event, context }) => {
  const entity: TournamentHub_EmergencyCancellation = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    platformAdmin: event.params.admin,
    timestamp: event.params.calledAtTime,
  }

  context.TournamentHub_EmergencyCancellation.set(entity)
})

TournamentHub.ExitWindowOpened.handler(async ({ event, context }) => {
  const entity: TournamentHub_ExitWindowOpened = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    windowStart: event.params.windowStart,
    windowEnd: event.params.windowEnd,
  }

  context.TournamentHub_ExitWindowOpened.set(entity)
})

TournamentMysteryDeck.CardDrawn.handler(async ({ event, context }) => {
  const entity: TournamentMysteryDeck_CardDrawn = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    player: event.params.player,
    costPaid: event.params.costPaid,
    newDrawCount: event.params.newDrawCount,
    cardsRemaining: event.params.cardsRemaining,
    timestamp: event.params.timestamp,
  }

  context.TournamentMysteryDeck_CardDrawn.set(entity)
})

TournamentMysteryDeck.CardsAdded.handler(async ({ event, context }) => {
  const entity: TournamentMysteryDeck_CardsAdded = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    player: event.params.player,
    cardCount: event.params.cardCount,
    costPaid: event.params.costPaid,
    newCardsRemaining: event.params.newCardsRemaining,
    timestamp: event.params.timestamp,
  }

  context.TournamentMysteryDeck_CardsAdded.set(entity)
})

TournamentMysteryDeck.CardsPeeked.handler(async ({ event, context }) => {
  const entity: TournamentMysteryDeck_CardsPeeked = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    player: event.params.player,
    cardCount: event.params.cardCount,
    costPaid: event.params.costPaid,
    timestamp: event.params.timestamp,
  }

  context.TournamentMysteryDeck_CardsPeeked.set(entity)
})

TournamentMysteryDeck.CardsRemoved.handler(async ({ event, context }) => {
  const entity: TournamentMysteryDeck_CardsRemoved = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    player: event.params.player,
    cardCount: event.params.cardCount,
    costPaid: event.params.costPaid,
    newCardsRemaining: event.params.newCardsRemaining,
    timestamp: event.params.timestamp,
  }

  context.TournamentMysteryDeck_CardsRemoved.set(entity)
})

TournamentMysteryDeck.DeckInitialized.handler(async ({ event, context }) => {
  const entity: TournamentMysteryDeck_DeckInitialized = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    deckSize: event.params.deckSize,
    sequenceNumber: event.params.sequenceNumber,
    timestamp: event.params.timestamp,
  }

  context.TournamentMysteryDeck_DeckInitialized.set(entity)
})

TournamentMysteryDeck.DeckShuffled.handler(async ({ event, context }) => {
  const entity: TournamentMysteryDeck_DeckShuffled = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    player: event.params.player,
    costPaid: event.params.costPaid,
    newShuffleCount: event.params.newShuffleCount,
    timestamp: event.params.timestamp,
  }

  context.TournamentMysteryDeck_DeckShuffled.set(entity)
})

TournamentMysteryDeck.ShuffleSeedUpdated.handler(async ({ event, context }) => {
  const entity: TournamentMysteryDeck_ShuffleSeedUpdated = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    newSeed: event.params.newSeed,
    backendSecretHash: event.params.backendSecretHash,
    timestamp: event.params.timestamp,
  }

  context.TournamentMysteryDeck_ShuffleSeedUpdated.set(entity)
})

TournamentRandomizer.CompleteSeedRevealed.handler(async ({ event, context }) => {
  const entity: TournamentRandomizer_CompleteSeedRevealed = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    completeSeed: event.params.completeSeed,
    backendSecret: event.params.backendSecret,
    timestamp: event.params.timestamp,
  }

  context.TournamentRandomizer_CompleteSeedRevealed.set(entity)
})

TournamentRandomizer.MysteryDeckSet.handler(async ({ event, context }) => {
  const entity: TournamentRandomizer_MysteryDeckSet = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    mysteryDeck: event.params.mysteryDeck,
  }

  context.TournamentRandomizer_MysteryDeckSet.set(entity)
})

TournamentRandomizer.SeedGenerated.handler(async ({ event, context }) => {
  const entity: TournamentRandomizer_SeedGenerated = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    sequenceNumber: event.params.sequenceNumber,
    seedIndex: event.params.seedIndex,
    seed: event.params.seed,
    timestamp: event.params.timestamp,
  }

  context.TournamentRandomizer_SeedGenerated.set(entity)
})

TournamentRandomizer.SeedRequestCancelled.handler(async ({ event, context }) => {
  const entity: TournamentRandomizer_SeedRequestCancelled = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    sequenceNumber: event.params.sequenceNumber,
    timestamp: event.params.timestamp,
  }

  context.TournamentRandomizer_SeedRequestCancelled.set(entity)
})

TournamentRandomizer.SeedRequested.handler(async ({ event, context }) => {
  const entity: TournamentRandomizer_SeedRequested = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    sequenceNumber: event.params.sequenceNumber,
    requester: event.params.requester,
    seedIndex: event.params.seedIndex,
    timestamp: event.params.timestamp,
  }

  context.TournamentRandomizer_SeedRequested.set(entity)
})

TournamentRegistry.TournamentStatusUpdated.handler(async ({ event, context }) => {
  const entity: TournamentRegistry_TournamentStatusUpdated = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    hub: event.params.hub,
    oldStatus: event.params.oldStatus,
    newStatus: event.params.newStatus,
  }

  context.TournamentRegistry_TournamentStatusUpdated.set(entity)
})

TournamentRegistry.TournamentSystemRegistered.handler(async ({ event, context }) => {
  const entity: TournamentRegistry_TournamentSystemRegistered = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    hub: event.params.hub,
    combat: event.params.combat,
    mysteryDeck: event.params.mysteryDeck,
    trading: event.params.trading,
    randomizer: event.params.randomizer,
    initialStatus: event.params.initialStatus,
  }

  context.TournamentRegistry_TournamentSystemRegistered.set(entity)
})

TournamentTokenWhitelist.TokenPaused.handler(async ({ event, context }) => {
  const entity: TournamentTokenWhitelist_TokenPaused = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    token: event.params.token,
    reason: event.params.reason,
  }

  context.TournamentTokenWhitelist_TokenPaused.set(entity)
})

TournamentTokenWhitelist.TokenUnpaused.handler(async ({ event, context }) => {
  const entity: TournamentTokenWhitelist_TokenUnpaused = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    token: event.params.token,
  }

  context.TournamentTokenWhitelist_TokenUnpaused.set(entity)
})

TournamentTokenWhitelist.TokenWhitelisted.handler(async ({ event, context }) => {
  const entity: TournamentTokenWhitelist_TokenWhitelisted = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    token: event.params.token,
  }

  context.TournamentTokenWhitelist_TokenWhitelisted.set(entity)
})

TournamentTrading.OfferCancelled.handler(async ({ event, context }) => {
  const entity: TournamentTrading_OfferCancelled = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    offerId: event.params.offerId,
    creator: event.params.creator,
    timestamp: event.params.timestamp,
  }

  context.TournamentTrading_OfferCancelled.set(entity)
})

TournamentTrading.OfferCreated.handler(async ({ event, context }) => {
    const offered = event.params.offered;
  const requested = event.params.requested;
  const entity: TournamentTrading_OfferCreated = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    offerId: event.params.offerId,
    creator: event.params.creator,
  
    // Offered bundle: ResourceBundle { lives, coins, rockCards, paperCards, scissorsCards }
    offeredLives: offered[0],
    offeredCoins: offered[1],
    offeredRock: offered[2],
    offeredPaper: offered[3],
    offeredScissors: offered[4],
    
    // Requested bundle
    requestedLives: requested[0],
    requestedCoins: requested[1],
    requestedRock: requested[2],
    requestedPaper: requested[3],
    requestedScissors: requested[4],
    expiresAt: event.params.expiresAt,
    createdAt: event.params.createdAt,
  }

  context.TournamentTrading_OfferCreated.set(entity)
})

TournamentTrading.TradeExecuted.handler(async ({ event, context }) => {
  const entity: TournamentTrading_TradeExecuted = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    offerId: event.params.offerId,
    creator: event.params.creator,
    acceptor: event.params.acceptor,
    creatorTotalCardsDelta: event.params.creatorTotalCardsDelta,
    acceptorTotalCardsDelta: event.params.acceptorTotalCardsDelta,
    timestamp: event.params.timestamp,
  }

  context.TournamentTrading_TradeExecuted.set(entity)
})
