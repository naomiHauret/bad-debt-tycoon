import { encodeAbiParameters, type Hex, parseAbiParameters } from "viem"
import { AMOUNT, type AmountValue } from "./amount"
import { DISTRIBUTION, type ValidDistributionConfig } from "./distribution"
import { type ResourceValue } from "./resources"

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
 * Combat cards a player can use during RPS match
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
  /** Dummy/Blank card (no combat card added) */
  None: 0,
  Rock: 1,
  Paper: 2,
  Scissors: 3,
} as const
export type ResourceCardValue = (typeof RESOURCE_CARD)[keyof typeof RESOURCE_CARD]

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
  // Special
  | {
      action: typeof CARD_ACTION.AddCombatCard
      cardType: CombatCardValue
    }
  | {
      action: typeof CARD_ACTION.NoEffect
    }

/**
 * Encode card effect into bytes for smart contract
 */
function encodeCardEffect(effect: CardEffect): Hex {
  switch (effect.action) {
    case CARD_ACTION.TransferResource: {
      if (effect.direction === TRANSFER_DIRECTION.Exchange) {
        // Exchange: no amount/range
        return encodeAbiParameters(
          parseAbiParameters('string, string, string, string, string'),
          [effect.action, effect.resource, effect.direction, effect.from, effect.to]
        );
      } else {
        // Transfer/Gain/Lose: with amount and distribution
        const validValues = effect.tiers ?? generateRangeArray(effect.range!);
        const distParams = encodeDistributionParams(effect.distribution);
        
        return encodeAbiParameters(
          parseAbiParameters('string, string, string, string, string, string, uint16, uint16, uint8, string, bytes'),
          [
            effect.action,
            effect.resource,
            effect.amountType,
            effect.direction,
            effect.from,
            effect.to,
            validValues[0],
            validValues[validValues.length - 1],
            effect.range?.step ?? 1,
            effect.distribution.type,
            distParams,
          ]
        );
      }
    }

    case CARD_ACTION.MultiplyGain:
    case CARD_ACTION.MultiplyLoss: {
      const validValues = effect.tiers ?? generateRangeArray(effect.range!);
      const distParams = encodeDistributionParams(effect.distribution);
      
      return encodeAbiParameters(
        parseAbiParameters('string, string, string, string, uint16, uint16, uint8, string, bytes'),
        [
          effect.action,
          effect.resource,
          effect.amountType,
          effect.target,
          validValues[0],
          validValues[validValues.length - 1],
          effect.range?.step ?? 1,
          effect.distribution.type,
          distParams,
        ]
      );
    }

    case CARD_ACTION.ProtectResource:
      return encodeAbiParameters(
        parseAbiParameters('string, string, string'),
        [effect.action, effect.resource, effect.target]
      );

    case CARD_ACTION.ModifyOutcome:
      return encodeAbiParameters(
        parseAbiParameters('string, string'),
        [effect.action, effect.outcomeType]
      );

    case CARD_ACTION.AddCombatCard:
      return encodeAbiParameters(
        parseAbiParameters('string, uint8'),
        [effect.action, effect.cardType]
      );

    case CARD_ACTION.NoEffect:
      return encodeAbiParameters(parseAbiParameters('string'), [effect.action]);
  }
}

/**
 * Encode distribution parameters
 */
function encodeDistributionParams(distribution: ValidDistributionConfig): Hex {
  switch (distribution.type) {
    case DISTRIBUTION.Uniform:
      return '0x'; // No params

    case DISTRIBUTION.Gaussian:
      return encodeAbiParameters(
        parseAbiParameters('uint256, uint256'),
        [BigInt(distribution.params.mean), BigInt(distribution.params.stdDev)]
      );

    case DISTRIBUTION.Exponential:
      return encodeAbiParameters(
        parseAbiParameters('uint256'),
        [BigInt(Math.floor(distribution.params.lambda * 1000))] // Store as fixed-point
      );

    case DISTRIBUTION.Geometric:
      return encodeAbiParameters(
        parseAbiParameters('uint256'),
        [BigInt(Math.floor(distribution.params.probability * 1000))] // Store as fixed-point
      );
  }
}

/**
 * Generate array from range specification
 */
function generateRangeArray(range: { min: number; max: number; step: number }): number[] {
  const result: Array<number> = [];
  for (let i = range.min; i <= range.max; i += range.step) {
    result.push(i);
  }
  return result;
}


/**
 * Card meta template definition
 */
export interface CardMetaTemplate {
  templateId: number
  category: CardCategoryValue
  trigger: ModifierTriggerValue
  resourceType: ResourceCardValue
  baseWeight: number
  effect: CardEffect
}

type PreparedCard = Pick<CardMetaTemplate, Exclude<keyof CardMetaTemplate, 'effect' | 'templateId'>> & {
  effectData: `0x${string}`,
  exists: boolean
  paused: boolean
  cardId: number
}
/**
 * Prepare card template for contract registration
 */
export function prepareCardForRegistration(card: CardMetaTemplate): PreparedCard {
  return {
    exists: true,
    paused: false,
    cardId: card.templateId,
    category: card.category,
    trigger: card.trigger,
    resourceType: card.resourceType,
    baseWeight: card.baseWeight,
    effectData: encodeCardEffect(card.effect),
  };
}
