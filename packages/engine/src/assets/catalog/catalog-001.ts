import { CARDS_001 } from "./cards/cards-001"
import { OBJECTIVES_001 } from "./objectives/objectives-001"

export const CATALOG = {
  cards: {
    list: CARDS_001,
    idStart: CARDS_001[0].templateId,
    idEnd: CARDS_001.length - 1,
  },
  objectives: {
    list: OBJECTIVES_001,
    idStart: OBJECTIVES_001[0].objectiveId,
    idEnd: OBJECTIVES_001.length - 1,
  },
}
