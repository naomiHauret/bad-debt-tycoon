// Design Philosophy:
// - Base weight of 100
// - Higher weights = more common ; lower weight = rarer

import { AMOUNT } from "@/engine/data-structures/amount"
import {
  CARD_ACTION,
  CARD_CATEGORY,
  type CardMetaTemplate,
  COMBAT_CARD,
  MODIFIER_TRIGGER,
  MYSTERY_GRANT_CARD,
  OUTCOME_MODIFIER,
  TRANSFER_DIRECTION,
  TRANSFER_TARGET,
} from "@/engine/data-structures/cards"
import { DISTRIBUTION } from "@/engine/data-structures/distribution"
import { RESOURCE } from "@/engine/data-structures/resources"

// ID: 1-27
export const CARDS_001: Array<CardMetaTemplate> = [
  {
    templateId: 1,
    category: CARD_CATEGORY.Instant,
    trigger: MODIFIER_TRIGGER.None,
    mysteryGrantCard: MYSTERY_GRANT_CARD.None,
    baseWeight: 15,
    effect: {
      action: CARD_ACTION.TransferResource,
      resource: RESOURCE.Coins,
      amountType: AMOUNT.Fixed,
      direction: TRANSFER_DIRECTION.Gain,
      from: TRANSFER_TARGET.Self,
      to: TRANSFER_TARGET.Self,
      range: { min: 5, max: 15, step: 5 },
      distribution: { type: DISTRIBUTION.Uniform },
    },
  },

  {
    templateId: 2,
    category: CARD_CATEGORY.Instant,
    trigger: MODIFIER_TRIGGER.None,
    mysteryGrantCard: MYSTERY_GRANT_CARD.None,
    baseWeight: 5,
    effect: {
      action: CARD_ACTION.TransferResource,
      resource: RESOURCE.Lives,
      amountType: AMOUNT.Fixed,
      direction: TRANSFER_DIRECTION.Gain,
      from: TRANSFER_TARGET.Self,
      to: TRANSFER_TARGET.Self,
      range: { min: 1, max: 3, step: 1 },
      distribution: { type: DISTRIBUTION.Uniform },
    },
  },
  {
    templateId: 3,
    category: CARD_CATEGORY.Instant,
    trigger: MODIFIER_TRIGGER.None,
    mysteryGrantCard: MYSTERY_GRANT_CARD.None,
    baseWeight: 10,
    effect: {
      action: CARD_ACTION.TransferResource,
      resource: RESOURCE.Coins,
      amountType: AMOUNT.Fixed,
      direction: TRANSFER_DIRECTION.Gain,
      from: TRANSFER_TARGET.Self,
      to: TRANSFER_TARGET.Self,
      range: { min: 20, max: 40, step: 10 },
      distribution: { type: DISTRIBUTION.Gaussian, params: { mean: 30, stdDev: 5 } },
    },
  },

  {
    templateId: 4,
    category: CARD_CATEGORY.Instant,
    trigger: MODIFIER_TRIGGER.None,
    mysteryGrantCard: MYSTERY_GRANT_CARD.None,
    baseWeight: 5,
    effect: {
      action: CARD_ACTION.TransferResource,
      resource: RESOURCE.Lives,
      amountType: AMOUNT.Fixed,
      direction: TRANSFER_DIRECTION.Gain,
      from: TRANSFER_TARGET.Self,
      to: TRANSFER_TARGET.Self,
      range: { min: 3, max: 7, step: 1 },
      distribution: { type: DISTRIBUTION.Gaussian, params: { mean: 5, stdDev: 1 } },
    },
  },

  {
    templateId: 5,
    category: CARD_CATEGORY.Instant,
    trigger: MODIFIER_TRIGGER.None,
    mysteryGrantCard: MYSTERY_GRANT_CARD.None,
    baseWeight: 40,
    effect: {
      action: CARD_ACTION.TransferResource,
      resource: RESOURCE.Coins,
      amountType: AMOUNT.Fixed,
      direction: TRANSFER_DIRECTION.Lose,
      from: TRANSFER_TARGET.Self,
      to: TRANSFER_TARGET.Self,
      range: { min: 10, max: 30, step: 10 },
      distribution: { type: DISTRIBUTION.Uniform },
    },
  },

  {
    templateId: 6,
    category: CARD_CATEGORY.Instant,
    trigger: MODIFIER_TRIGGER.None,
    mysteryGrantCard: MYSTERY_GRANT_CARD.None,
    baseWeight: 10,
    effect: {
      action: CARD_ACTION.TransferResource,
      resource: RESOURCE.Lives,
      amountType: AMOUNT.Fixed,
      direction: TRANSFER_DIRECTION.Lose,
      from: TRANSFER_TARGET.Self,
      to: TRANSFER_TARGET.Self,
      range: { min: 2, max: 5, step: 1 },
      distribution: { type: DISTRIBUTION.Uniform },
    },
  },
  {
    templateId: 7,
    category: CARD_CATEGORY.Instant,
    trigger: MODIFIER_TRIGGER.None,
    mysteryGrantCard: MYSTERY_GRANT_CARD.None,
    baseWeight: 5,
    effect: {
      action: CARD_ACTION.TransferResource,
      resource: RESOURCE.Coins,
      amountType: AMOUNT.Fixed,
      direction: TRANSFER_DIRECTION.Transfer,
      from: TRANSFER_TARGET.Opponent,
      to: TRANSFER_TARGET.Self,
      range: { min: 10, max: 25, step: 5 },
      distribution: { type: DISTRIBUTION.Uniform },
    },
  },

  {
    templateId: 8,
    category: CARD_CATEGORY.Instant,
    trigger: MODIFIER_TRIGGER.None,
    mysteryGrantCard: MYSTERY_GRANT_CARD.None,
    baseWeight: 5,
    effect: {
      action: CARD_ACTION.TransferResource,
      resource: RESOURCE.Lives,
      amountType: AMOUNT.Fixed,
      direction: TRANSFER_DIRECTION.Transfer,
      from: TRANSFER_TARGET.Opponent,
      to: TRANSFER_TARGET.Self,
      range: { min: 1, max: 3, step: 1 },
      distribution: { type: DISTRIBUTION.Uniform },
    },
  },

  {
    templateId: 9,
    category: CARD_CATEGORY.Instant,
    trigger: MODIFIER_TRIGGER.None,
    mysteryGrantCard: MYSTERY_GRANT_CARD.None,
    baseWeight: 5,
    effect: {
      action: CARD_ACTION.TransferResource,
      resource: RESOURCE.Coins,
      direction: TRANSFER_DIRECTION.Exchange,
      from: TRANSFER_TARGET.Self,
      to: TRANSFER_TARGET.Opponent,
    },
  },

  {
    templateId: 10,
    category: CARD_CATEGORY.Instant,
    trigger: MODIFIER_TRIGGER.None,
    mysteryGrantCard: MYSTERY_GRANT_CARD.None,
    baseWeight: 20,
    effect: {
      action: CARD_ACTION.TransferResource,
      resource: RESOURCE.Lives,
      direction: TRANSFER_DIRECTION.Exchange,
      from: TRANSFER_TARGET.Self,
      to: TRANSFER_TARGET.Opponent,
    },
  },

  {
    templateId: 11,
    category: CARD_CATEGORY.Instant,
    trigger: MODIFIER_TRIGGER.None,
    mysteryGrantCard: MYSTERY_GRANT_CARD.None,
    baseWeight: 5,
    effect: {
      action: CARD_ACTION.TransferResource,
      resource: RESOURCE.Coins,
      amountType: AMOUNT.Fixed,
      direction: TRANSFER_DIRECTION.Gain,
      from: TRANSFER_TARGET.Self,
      to: TRANSFER_TARGET.Self,
      range: { min: 50, max: 100, step: 25 },
      distribution: { type: DISTRIBUTION.Exponential, params: { lambda: 0.02 } },
    },
  },

  {
    templateId: 12,
    category: CARD_CATEGORY.Instant,
    trigger: MODIFIER_TRIGGER.None,
    mysteryGrantCard: MYSTERY_GRANT_CARD.None,
    baseWeight: 2,
    effect: {
      action: CARD_ACTION.TransferResource,
      resource: RESOURCE.Lives,
      amountType: AMOUNT.Fixed,
      direction: TRANSFER_DIRECTION.Gain,
      from: TRANSFER_TARGET.Self,
      to: TRANSFER_TARGET.Self,
      range: { min: 5, max: 10, step: 1 },
      distribution: { type: DISTRIBUTION.Exponential, params: { lambda: 0.15 } },
    },
  },

  {
    templateId: 13,
    category: CARD_CATEGORY.Modifier,
    trigger: MODIFIER_TRIGGER.OnNextFight,
    mysteryGrantCard: MYSTERY_GRANT_CARD.None,
    baseWeight: 5,
    effect: {
      action: CARD_ACTION.ProtectResource,
      resource: RESOURCE.Coins,
      target: TRANSFER_TARGET.Self,
    },
  },

  {
    templateId: 14,
    category: CARD_CATEGORY.Modifier,
    trigger: MODIFIER_TRIGGER.OnNextFight,
    mysteryGrantCard: MYSTERY_GRANT_CARD.None,
    baseWeight: 10,
    effect: {
      action: CARD_ACTION.ProtectResource,
      resource: RESOURCE.Lives,
      target: TRANSFER_TARGET.Self,
    },
  },
  {
    templateId: 15,
    category: CARD_CATEGORY.Modifier,
    trigger: MODIFIER_TRIGGER.OnNextWin,
    mysteryGrantCard: MYSTERY_GRANT_CARD.None,
    baseWeight: 30,
    effect: {
      action: CARD_ACTION.MultiplyGain,
      resource: RESOURCE.Coins,
      amountType: AMOUNT.Multiplier,
      target: TRANSFER_TARGET.Self,
      range: { min: 150, max: 250, step: 50 },
      distribution: { type: DISTRIBUTION.Uniform },
    },
  },

  {
    templateId: 16,
    category: CARD_CATEGORY.Modifier,
    trigger: MODIFIER_TRIGGER.OnNextWin,
    mysteryGrantCard: MYSTERY_GRANT_CARD.None,
    baseWeight: 10,
    effect: {
      action: CARD_ACTION.MultiplyGain,
      resource: RESOURCE.Lives,
      amountType: AMOUNT.Multiplier,
      target: TRANSFER_TARGET.Self,
      range: { min: 150, max: 250, step: 50 },
      distribution: { type: DISTRIBUTION.Uniform },
    },
  },

  {
    templateId: 17,
    category: CARD_CATEGORY.Modifier,
    trigger: MODIFIER_TRIGGER.OnNextWin,
    mysteryGrantCard: MYSTERY_GRANT_CARD.None,
    baseWeight: 15,
    effect: {
      action: CARD_ACTION.TransferResource,
      resource: RESOURCE.Coins,
      amountType: AMOUNT.Percent,
      direction: TRANSFER_DIRECTION.Transfer,
      from: TRANSFER_TARGET.Opponent,
      to: TRANSFER_TARGET.Self,
      range: { min: 10, max: 30, step: 10 },
      distribution: { type: DISTRIBUTION.Uniform },
    },
  },
  {
    templateId: 18,
    category: CARD_CATEGORY.Modifier,
    trigger: MODIFIER_TRIGGER.OnNextLoss,
    mysteryGrantCard: MYSTERY_GRANT_CARD.None,
    baseWeight: 20,
    effect: {
      action: CARD_ACTION.MultiplyLoss,
      resource: RESOURCE.Coins,
      amountType: AMOUNT.Multiplier,
      target: TRANSFER_TARGET.Self,
      range: { min: 50, max: 100, step: 25 },
      distribution: { type: DISTRIBUTION.Uniform },
    },
  },

  {
    templateId: 19,
    category: CARD_CATEGORY.Modifier,
    trigger: MODIFIER_TRIGGER.OnNextLoss,
    mysteryGrantCard: MYSTERY_GRANT_CARD.None,
    baseWeight: 10,
    effect: {
      action: CARD_ACTION.ModifyOutcome,
      outcomeType: OUTCOME_MODIFIER.ForceDraw,
    },
  },
  {
    templateId: 20,
    category: CARD_CATEGORY.Combat,
    trigger: MODIFIER_TRIGGER.None,
    mysteryGrantCard: MYSTERY_GRANT_CARD.Rock,
    baseWeight: 70,
    effect: {
      action: CARD_ACTION.AddCombatCard,
      cardType: COMBAT_CARD.Rock,
    },
  },

  {
    templateId: 21,
    category: CARD_CATEGORY.Combat,
    trigger: MODIFIER_TRIGGER.None,
    mysteryGrantCard: MYSTERY_GRANT_CARD.Rock,
    baseWeight: 30,
    effect: {
      action: CARD_ACTION.AddCombatCard,
      cardType: COMBAT_CARD.Rock,
    },
  },

  {
    templateId: 22,
    category: CARD_CATEGORY.Combat,
    trigger: MODIFIER_TRIGGER.None,
    mysteryGrantCard: MYSTERY_GRANT_CARD.Paper,
    baseWeight: 70,
    effect: {
      action: CARD_ACTION.AddCombatCard,
      cardType: COMBAT_CARD.Paper,
    },
  },

  {
    templateId: 23,
    category: CARD_CATEGORY.Combat,
    trigger: MODIFIER_TRIGGER.None,
    mysteryGrantCard: MYSTERY_GRANT_CARD.Paper,
    baseWeight: 30,
    effect: {
      action: CARD_ACTION.AddCombatCard,
      cardType: COMBAT_CARD.Paper,
    },
  },

  {
    templateId: 24,
    category: CARD_CATEGORY.Combat,
    trigger: MODIFIER_TRIGGER.None,
    mysteryGrantCard: MYSTERY_GRANT_CARD.Scissors,
    baseWeight: 30,
    effect: {
      action: CARD_ACTION.AddCombatCard,
      cardType: COMBAT_CARD.Scissors,
    },
  },

  {
    templateId: 25,
    category: CARD_CATEGORY.Combat,
    trigger: MODIFIER_TRIGGER.None,
    mysteryGrantCard: MYSTERY_GRANT_CARD.Scissors,
    baseWeight: 70,
    effect: {
      action: CARD_ACTION.AddCombatCard,
      cardType: COMBAT_CARD.Scissors,
    },
  },
  {
    templateId: 26,
    category: CARD_CATEGORY.Instant,
    trigger: MODIFIER_TRIGGER.None,
    mysteryGrantCard: MYSTERY_GRANT_CARD.None,
    baseWeight: 70,
    effect: {
      action: CARD_ACTION.NoEffect,
    },
  },
  {
    templateId: 27,
    category: CARD_CATEGORY.Instant,
    trigger: MODIFIER_TRIGGER.None,
    mysteryGrantCard: MYSTERY_GRANT_CARD.None,
    baseWeight: 40,
    effect: {
      action: CARD_ACTION.NoEffect,
    },
  },
]
