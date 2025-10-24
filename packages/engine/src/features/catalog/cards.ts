import { encodeAbiParameters, type Hex, parseAbiParameters } from "viem"
import {
  CARD_ACTION,
  CARD_CATEGORY,
  type CardEffect,
  type CardMetaTemplate,
  type CombatCardTemplate,
  type InstantCardTemplate,
  MODIFIER_TRIGGER,
  type ModifierCardTemplate,
  MYSTERY_GRANT_CARD,
  TRANSFER_DIRECTION,
} from "@/engine/data-structures/cards"
import { DISTRIBUTION, type ValidDistributionConfig } from "@/engine/data-structures/distribution"

/**
 * Encode card effect into bytes for smart contract
 */
function encodeCardEffect(effect: CardEffect): Hex {
  switch (effect.action) {
    case CARD_ACTION.TransferResource: {
      if (effect.direction === TRANSFER_DIRECTION.Exchange) {
        // Exchange: no amount/range
        return encodeAbiParameters(parseAbiParameters("string, string, string, string, string"), [
          effect.action,
          effect.resource,
          effect.direction,
          effect.from,
          effect.to,
        ])
      } else {
        // Transfer/Gain/Lose: with amount and distribution
        const validValues = effect.tiers ?? generateRangeArray(effect.range!)
        const distParams = encodeDistributionParams(effect.distribution)

        return encodeAbiParameters(
          parseAbiParameters("string, string, string, string, string, string, uint16, uint16, uint8, string, bytes"),
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
          ],
        )
      }
    }

    case CARD_ACTION.MultiplyGain:
    case CARD_ACTION.MultiplyLoss: {
      const validValues = effect.tiers ?? generateRangeArray(effect.range!)
      const distParams = encodeDistributionParams(effect.distribution)

      return encodeAbiParameters(
        parseAbiParameters("string, string, string, string, uint16, uint16, uint8, string, bytes"),
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
        ],
      )
    }

    case CARD_ACTION.ProtectResource:
      return encodeAbiParameters(parseAbiParameters("string, string, string"), [
        effect.action,
        effect.resource,
        effect.target,
      ])

    case CARD_ACTION.ModifyOutcome:
      return encodeAbiParameters(parseAbiParameters("string, string"), [effect.action, effect.outcomeType])

    case CARD_ACTION.AddCombatCard:
      return encodeAbiParameters(parseAbiParameters("string, uint8"), [effect.action, effect.cardType])

    case CARD_ACTION.NoEffect:
      return encodeAbiParameters(parseAbiParameters("string"), [effect.action])
  }
}

/**
 * Encode distribution parameters
 */
function encodeDistributionParams(distribution: ValidDistributionConfig): Hex {
  switch (distribution.type) {
    case DISTRIBUTION.Uniform:
      return "0x" // No params

    case DISTRIBUTION.Gaussian:
      return encodeAbiParameters(parseAbiParameters("uint256, uint256"), [
        BigInt(distribution.params.mean),
        BigInt(distribution.params.stdDev),
      ])

    case DISTRIBUTION.Exponential:
      return encodeAbiParameters(
        parseAbiParameters("uint256"),
        [BigInt(Math.floor(distribution.params.lambda * 1000))], // Store as fixed-point
      )

    case DISTRIBUTION.Geometric:
      return encodeAbiParameters(
        parseAbiParameters("uint256"),
        [BigInt(Math.floor(distribution.params.probability * 1000))], // Store as fixed-point
      )
  }
}

/**
 * Generate array from range specification
 */
function generateRangeArray(range: { min: number; max: number; step: number }): number[] {
  const result: Array<number> = []
  for (let i = range.min; i <= range.max; i += range.step) {
    result.push(i)
  }
  return result
}

type PreparedCard = Pick<CardMetaTemplate, Exclude<keyof CardMetaTemplate, "effect" | "templateId">> & {
  effectData: `0x${string}`
  exists: boolean
  paused: boolean
  cardId: number
}

/**
 * Validate card template matches category rules (runtime checks)
 */
export function validateCardTemplate(card: CardMetaTemplate): void {
  switch (card.category) {
    case CARD_CATEGORY.Instant:
      if (card.trigger !== MODIFIER_TRIGGER.None) {
        throw new Error("Instant cards must have trigger=None")
      }
      if (card.mysteryGrantCard !== MYSTERY_GRANT_CARD.None) {
        throw new Error("Instant cards must have mysteryGrantCard=None")
      }
      break

    case CARD_CATEGORY.Modifier:
      if (card.trigger <= MODIFIER_TRIGGER.None) {
        throw new Error("Modifier cards must have non-None trigger")
      }
      if (card.mysteryGrantCard !== MYSTERY_GRANT_CARD.None) {
        throw new Error("Modifier cards must have mysteryGrantCard=None")
      }
      break

    case CARD_CATEGORY.Combat:
      if (card.trigger !== MODIFIER_TRIGGER.None) {
        throw new Error("Combat cards must have trigger=None")
      }
      if (card.mysteryGrantCard <= MYSTERY_GRANT_CARD.None) {
        throw new Error("Combat cards must specify a mysteryGrantCard (Rock/Paper/Scissors)")
      }
      if (card.effect.action !== CARD_ACTION.AddCombatCard) {
        throw new Error(`Combat cards must use AddCombatCard action`)
      }
      break
  }
}

/**
 * Type guards for narrowing card types
 */
// Instant
export function isInstantCard(card: CardMetaTemplate): card is InstantCardTemplate {
  return card.category === CARD_CATEGORY.Instant
}

// Modifier
export function isModifierCard(card: CardMetaTemplate): card is ModifierCardTemplate {
  return card.category === CARD_CATEGORY.Modifier
}

// Combat
export function isCombatCard(card: CardMetaTemplate): card is CombatCardTemplate {
  return card.category === CARD_CATEGORY.Combat
}

/**
 * Prepare card template for contract registration
 */
export function prepareCardForRegistration(card: CardMetaTemplate): PreparedCard {
  // Validate before preparing
  validateCardTemplate(card)

  return {
    exists: true,
    paused: false,
    cardId: card.templateId,
    category: card.category,
    trigger: card.trigger,
    mysteryGrantCard: card.mysteryGrantCard,
    baseWeight: card.baseWeight,
    effectData: encodeCardEffect(card.effect),
  }
}
