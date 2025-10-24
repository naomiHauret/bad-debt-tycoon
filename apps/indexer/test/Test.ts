import assert from "assert";
import { 
  TestHelpers,
  TournamentCombat_CombatResolved
} from "generated";
const { MockDb, TournamentCombat } = TestHelpers;

describe("TournamentCombat contract CombatResolved event tests", () => {
  // Create mock db
  const mockDb = MockDb.createMockDb();

  // Creating mock for TournamentCombat contract CombatResolved event
  const event = TournamentCombat.CombatResolved.createMockEvent({/* It mocks event fields with default values. You can overwrite them if you need */});

  it("TournamentCombat_CombatResolved is created correctly", async () => {
    // Processing the event
    const mockDbUpdated = await TournamentCombat.CombatResolved.processEvent({
      event,
      mockDb,
    });

    // Getting the actual entity from the mock database
    let actualTournamentCombatCombatResolved = mockDbUpdated.entities.TournamentCombat_CombatResolved.get(
      `${event.chainId}_${event.block.number}_${event.logIndex}`
    );

    // Creating the expected entity
    const expectedTournamentCombatCombatResolved: TournamentCombat_CombatResolved = {
      id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
      resolution: event.params.resolution,
      resolution: event.params.resolution,
      resolution: event.params.resolution,
      resolution: event.params.resolution,
      resolution: event.params.resolution,
      resolution: event.params.resolution,
      resolution: event.params.resolution,
      resolution: event.params.resolution,
      resolution: event.params.resolution,
      resolution: event.params.resolution,
      resolution: event.params.resolution,
      resolution: event.params.resolution,
      resolution: event.params.resolution,
      combatId: event.params.combatId,
      timestamp: event.params.timestamp,
    };
    // Asserting that the entity in the mock database is the same as the expected entity
    assert.deepEqual(actualTournamentCombatCombatResolved, expectedTournamentCombatCombatResolved, "Actual TournamentCombatCombatResolved should be the same as the expectedTournamentCombatCombatResolved");
  });
});
