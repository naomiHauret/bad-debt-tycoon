/**
 * The different categories of cards that can be drawn from the shared deck.
 */
export const CARD_CATEGORY = {
  /** Immediatly applies effect when drawn (typically coins/lives adjustment */
  Instant: 0,
  /** Delayed effect (triggers on CARD_MODIFIER_TRIGGER) */
  Modifier: 1,
  /** Add Rock/Paper/Scissors card to player's hand */
  Resource: 2,
} as const
export type CardCategoryValue = (typeof CARD_CATEGORY)[keyof typeof CARD_CATEGORY]

/**
 * What makes a card drawn from the mystery deck activate
 */
export const CARD_MODIFIER_TRIGGER = {
  /** Applies instantly. For Instant/Resource cards. */
  None: 0,
  /** Triggers when player enters next combat */
  OnNextFight: 1,
  /** Triggers when player wins  their next fight */
  OnNextWin: 2,
  /** Triggers when player loses their next fight */
  OnNextLoss: 3,
  /** Triggers when player accepts next trade*/
  OnTrade: 4,
} as const
export type CardModifierTriggerValue = (typeof CARD_MODIFIER_TRIGGER)[keyof typeof CARD_MODIFIER_TRIGGER]

/**
 * Cards a player can use during a RPS match.
 */
export const COMBAT_CARD = {
  Rock: 0,
  Paper: 1,
  Scissors: 2,
} as const
export type CombatCardValue = (typeof COMBAT_CARD)[keyof typeof COMBAT_CARD]

/**
 * The different resource cards the player can draw from the mystery deck
 */
export const RESOURCE_CARD = {
  /**
   * Dummy/Blank card.
   */
  None: 0,
  Rock: 1,
  Paper: 2,
  Scissors: 3,
} as const
export type ResourceCardValue = (typeof RESOURCE_CARD)[keyof typeof RESOURCE_CARD]
