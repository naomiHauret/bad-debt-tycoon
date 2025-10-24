import type { AMOUNT, AmountValue } from "./amount"
import type { ValidDistributionConfig } from "./distribution"
import type { ResourceValue } from "./resources"

/**
 * The different categories of cards that can be drawn from the shared deck.
 */
export const CARD_CATEGORY = {
  /** Immediately applies effect when drawn (typically resource adjustment) */
  Instant: 0,
  /** Delayed effect (triggers on ModifierTrigger) */
  Modifier: 1,
  /** Add Rock/Paper/Scissors card to player's hand */
  Combat: 2,
} as const
export type CardCategoryValue = (typeof CARD_CATEGORY)[keyof typeof CARD_CATEGORY]

/**
 * What makes a card drawn from the mystery deck activate
 */
export const MODIFIER_TRIGGER = {
  /** Applies instantly. For Instant/Combat cards. */
  None: 0,
  /** Triggers when player enters next combat (pre-fight) */
  OnNextFight: 1,
  /** Triggers when player wins their next fight (post-fight) */
  OnNextWin: 2,
  /** Triggers when player loses their next fight (post-fight) */
  OnNextLoss: 3,
} as const
export type ModifierTriggerValue = (typeof MODIFIER_TRIGGER)[keyof typeof MODIFIER_TRIGGER]

/**
 * Mystery deck cards (Combat category) specify which combat card to grant.
 * This is used in the card struct field to indicate what the card does.
 */
export const MYSTERY_GRANT_CARD = {
  /** Not a combat card (used by Instant/Modifier categories) */
  None: 0,
  Rock: 1,
  Paper: 2,
  Scissors: 3,
} as const
export type MysteryGrantCardValue = (typeof MYSTERY_GRANT_CARD)[keyof typeof MYSTERY_GRANT_CARD]

/**
 * Combat cards in player's hand used during RPS battles.
 * These are the actual cards played during combat matches.
 */
export const COMBAT_CARD = {
  Rock: 0,
  Paper: 1,
  Scissors: 2,
} as const
export type CombatCardValue = (typeof COMBAT_CARD)[keyof typeof COMBAT_CARD]

/**
 * Card actions
 */
export const CARD_ACTION = {
  TransferResource: "TransferResource",
  MultiplyGain: "MultiplyGain",
  MultiplyLoss: "MultiplyLoss",
  ProtectResource: "ProtectResource",
  ModifyOutcome: "ModifyOutcome",
  NoEffect: "NoEffect",
  AddCombatCard: "AddCombatCard",
} as const
export type CardActionValue = (typeof CARD_ACTION)[keyof typeof CARD_ACTION]

/**
 * Transfer directions
 */
export const TRANSFER_DIRECTION = {
  Gain: "Gain", // Resources created from void -> Self
  Lose: "Lose", // Resources destroyed Self -> void
  Transfer: "Transfer", // Resources moved between entities
  Exchange: "Exchange", // Full balance swap
} as const
export type TransferDirectionValue = (typeof TRANSFER_DIRECTION)[keyof typeof TRANSFER_DIRECTION]

/**
 * Transfer targets
 */
export const TRANSFER_TARGET = {
  Self: "Self",
  Opponent: "Opponent",
} as const
export type TransferTargetValue = (typeof TRANSFER_TARGET)[keyof typeof TRANSFER_TARGET]

/**
 * Outcome modifiers
 */
export const OUTCOME_MODIFIER = {
  SwapResult: "SwapResult",
  ForceDraw: "ForceDraw",
  ForceWin: "ForceWin",
  ForceLoss: "ForceLoss",
} as const
export type OutcomeModifierValue = (typeof OUTCOME_MODIFIER)[keyof typeof OUTCOME_MODIFIER]

/**
 * Card effect types
 */
export type CardEffect =
  // Transfer with amount (Gain/Lose/Transfer)
  | {
      action: typeof CARD_ACTION.TransferResource
      resource: Exclude<ResourceValue, "Both">
      amountType: AmountValue
      direction: typeof TRANSFER_DIRECTION.Gain | typeof TRANSFER_DIRECTION.Lose | typeof TRANSFER_DIRECTION.Transfer
      from: TransferTargetValue
      to: TransferTargetValue
      range?: { min: number; max: number; step: number }
      tiers?: number[]
      distribution: ValidDistributionConfig
    }
  // Exchange (full swap, no amount)
  | {
      action: typeof CARD_ACTION.TransferResource
      resource: ResourceValue
      direction: typeof TRANSFER_DIRECTION.Exchange
      from: TransferTargetValue
      to: TransferTargetValue
    }
  // Multiply: Scale the exchange
  | {
      action: typeof CARD_ACTION.MultiplyGain | typeof CARD_ACTION.MultiplyLoss
      resource: Exclude<ResourceValue, "Both">
      amountType: typeof AMOUNT.Multiplier
      target: TransferTargetValue
      range?: { min: number; max: number; step: number }
      tiers?: number[]
      distribution: ValidDistributionConfig
    }
  // Protect: Prevent loss
  | {
      action: typeof CARD_ACTION.ProtectResource
      resource: ResourceValue
      target: TransferTargetValue
    }
  // Outcome: Modify fight result
  | {
      action: typeof CARD_ACTION.ModifyOutcome
      outcomeType: OutcomeModifierValue
    }
  // Special: Add combat card to hand
  | {
      action: typeof CARD_ACTION.AddCombatCard
      cardType: CombatCardValue
    }
  | {
      action: typeof CARD_ACTION.NoEffect
    }

/**
 * Card meta template definition with category-specific constraints
 */
export type CardMetaTemplate = InstantCardTemplate | ModifierCardTemplate | CombatCardTemplate

/**
 * Instant card: immediate resource effect
 * - trigger: MUST be None
 * - mysteryGrantCard: MUST be None (doesn't grant cards to player hand)
 * - effect: Affects game resources (Lives/Coins)
 */
export interface InstantCardTemplate {
  templateId: number
  category: typeof CARD_CATEGORY.Instant
  trigger: typeof MODIFIER_TRIGGER.None
  mysteryGrantCard: typeof MYSTERY_GRANT_CARD.None
  baseWeight: number
  effect: InstantCardEffect
}

/**
 * Modifier card: delayed resource effect
 * - trigger: MUST NOT be None (OnNextFight/OnNextWin/OnNextLoss)
 * - mysteryGrantCard: MUST be None (doesn't grant cards to player hand)
 * - effect: Affects game resources (Lives/Coins) with delayed trigger
 */
export interface ModifierCardTemplate {
  templateId: number
  category: typeof CARD_CATEGORY.Modifier
  trigger: Exclude<ModifierTriggerValue, typeof MODIFIER_TRIGGER.None>
  mysteryGrantCard: typeof MYSTERY_GRANT_CARD.None
  baseWeight: number
  effect: ModifierCardEffect
}

/**
 * Combat card: adds RPS card to player's hand
 * - trigger: MUST be None (immediate effect)
 * - mysteryGrantCard: MUST be Rock/Paper/Scissors, NOT None
 * - effect: Adds combat card to hand
 */
export interface CombatCardTemplate {
  templateId: number
  category: typeof CARD_CATEGORY.Combat
  trigger: typeof MODIFIER_TRIGGER.None
  mysteryGrantCard: Exclude<MysteryGrantCardValue, typeof MYSTERY_GRANT_CARD.None>
  baseWeight: number
  effect: CombatCardEffect
}

type InstantCardEffect = Extract<
  CardEffect,
  { action: typeof CARD_ACTION.TransferResource } | { action: typeof CARD_ACTION.NoEffect }
>

type ModifierCardEffect = Extract<
  CardEffect,
  | { action: typeof CARD_ACTION.TransferResource }
  | { action: typeof CARD_ACTION.MultiplyGain }
  | { action: typeof CARD_ACTION.MultiplyLoss }
  | { action: typeof CARD_ACTION.ProtectResource }
  | { action: typeof CARD_ACTION.ModifyOutcome }
>

type CombatCardEffect = Extract<CardEffect, { action: typeof CARD_ACTION.AddCombatCard }>
