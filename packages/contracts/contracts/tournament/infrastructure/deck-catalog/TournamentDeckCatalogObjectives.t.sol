// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {TournamentDeckCatalog} from "./TournamentDeckCatalog.sol";

contract TournamentDeckCatalogObjectivesTest is Test {
    TournamentDeckCatalog catalog;
    address owner;
    address nonOwner;

    function setUp() public {
        owner = address(this);
        nonOwner = address(0x1234);
        catalog = new TournamentDeckCatalog();
    }

    // should allow owner to register ResourceLives objective with valid multiplier
    function test_RegisterObjective_ResourceLives_1x() public {
        bytes memory targetData = abi.encode(uint16(catalog.LIVES_MULT_1X()));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.ResourceLives,
                exists: true,
                paused: false,
                targetData: targetData
            });

        catalog.registerObjective(objective);

        require(catalog.objectiveExists(1), "Objective should exist");
        require(catalog.isObjectiveActive(1), "Objective should be active");
    }

    // should allow owner to register ResourceLives objective with 2x multiplier
    function test_RegisterObjective_ResourceLives_2x() public {
        bytes memory targetData = abi.encode(uint16(catalog.LIVES_MULT_2X()));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.ResourceLives,
                exists: true,
                paused: false,
                targetData: targetData
            });

        catalog.registerObjective(objective);

        require(catalog.objectiveExists(1), "Objective should exist");
    }

    // should allow owner to register ResourceLives objective with 3x multiplier
    function test_RegisterObjective_ResourceLives_3x() public {
        bytes memory targetData = abi.encode(uint16(catalog.LIVES_MULT_3X()));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.ResourceLives,
                exists: true,
                paused: false,
                targetData: targetData
            });

        catalog.registerObjective(objective);

        require(catalog.objectiveExists(1), "Objective should exist");
    }

    // shouldn't allow ResourceLives objective with invalid multiplier
    function test_RegisterObjective_ResourceLives_RevertWhen_InvalidMultiplier()
        public
    {
        bytes memory targetData = abi.encode(uint16(150));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.ResourceLives,
                exists: true,
                paused: false,
                targetData: targetData
            });

        vm.expectRevert(TournamentDeckCatalog.InvalidMultiplier.selector);
        catalog.registerObjective(objective);
    }

    // should allow owner to register ResourceCoins objective with valid multipliers
    function test_RegisterObjective_ResourceCoins_ValidMultipliers() public {
        for (
            uint16 mult = catalog.MIN_COINS_MULTIPLIER();
            mult <= catalog.MAX_COINS_MULTIPLIER();
            mult += 50
        ) {
            bytes memory targetData = abi.encode(mult);

            TournamentDeckCatalog.ObjectiveDefinition
                memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                    objectiveId: uint8(mult / 50),
                    objectiveType: TournamentDeckCatalog
                        .Objective
                        .ResourceCoins,
                    exists: true,
                    paused: false,
                    targetData: targetData
                });

            catalog.registerObjective(objective);

            require(
                catalog.objectiveExists(uint8(mult / 50)),
                "Objective should exist"
            );
        }
    }

    // shouldn't allow ResourceCoins objective with multiplier below minimum
    function test_RegisterObjective_ResourceCoins_RevertWhen_BelowMinimum()
        public
    {
        bytes memory targetData = abi.encode(uint16(49));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.ResourceCoins,
                exists: true,
                paused: false,
                targetData: targetData
            });

        vm.expectRevert(TournamentDeckCatalog.InvalidMultiplier.selector);
        catalog.registerObjective(objective);
    }

    // shouldn't allow ResourceCoins objective with multiplier above maximum
    function test_RegisterObjective_ResourceCoins_RevertWhen_AboveMaximum()
        public
    {
        bytes memory targetData = abi.encode(uint16(301));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.ResourceCoins,
                exists: true,
                paused: false,
                targetData: targetData
            });

        vm.expectRevert(TournamentDeckCatalog.InvalidMultiplier.selector);
        catalog.registerObjective(objective);
    }

    // should allow owner to register ResourceAll objective with valid multipliers
    function test_RegisterObjective_ResourceAll() public {
        bytes memory targetData = abi.encode(
            uint16(catalog.LIVES_MULT_2X()),
            uint16(catalog.MIN_COINS_MULTIPLIER() + 50)
        );

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.ResourceAll,
                exists: true,
                paused: false,
                targetData: targetData
            });

        catalog.registerObjective(objective);

        require(catalog.objectiveExists(1), "Objective should exist");
    }

    // shouldn't allow ResourceAll objective with invalid lives multiplier
    function test_RegisterObjective_ResourceAll_RevertWhen_InvalidLivesMultiplier()
        public
    {
        bytes memory targetData = abi.encode(
            uint16(150),
            uint16(catalog.MIN_COINS_MULTIPLIER())
        );

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.ResourceAll,
                exists: true,
                paused: false,
                targetData: targetData
            });

        vm.expectRevert(TournamentDeckCatalog.InvalidMultiplier.selector);
        catalog.registerObjective(objective);
    }

    // shouldn't allow ResourceAll objective with invalid coins multiplier
    function test_RegisterObjective_ResourceAll_RevertWhen_InvalidCoinsMultiplier()
        public
    {
        bytes memory targetData = abi.encode(
            uint16(catalog.LIVES_MULT_1X()),
            uint16(40)
        );

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.ResourceAll,
                exists: true,
                paused: false,
                targetData: targetData
            });

        vm.expectRevert(TournamentDeckCatalog.InvalidMultiplier.selector);
        catalog.registerObjective(objective);
    }

    // should allow owner to register WinStreak objective with valid percentages
    function test_RegisterObjective_WinStreak_ValidPercentages() public {
        uint8[4] memory validPercentages = [
            catalog.STREAK_TIER_1(),
            catalog.STREAK_TIER_2(),
            catalog.STREAK_TIER_3(),
            catalog.STREAK_TIER_4()
        ];

        for (uint8 i = 0; i < 4; i++) {
            bytes memory targetData = abi.encode(validPercentages[i]);

            TournamentDeckCatalog.ObjectiveDefinition
                memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                    objectiveId: i + 1,
                    objectiveType: TournamentDeckCatalog.Objective.WinStreak,
                    exists: true,
                    paused: false,
                    targetData: targetData
                });

            catalog.registerObjective(objective);

            require(catalog.objectiveExists(i + 1), "Objective should exist");
        }
    }

    // shouldn't allow WinStreak objective with invalid percentage
    function test_RegisterObjective_WinStreak_RevertWhen_InvalidPercentage()
        public
    {
        bytes memory targetData = abi.encode(uint8(20));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.WinStreak,
                exists: true,
                paused: false,
                targetData: targetData
            });

        vm.expectRevert(TournamentDeckCatalog.InvalidMultiplier.selector);
        catalog.registerObjective(objective);
    }

    // should allow owner to register LoseStreak objective with valid percentages
    function test_RegisterObjective_LoseStreak_ValidPercentages() public {
        uint8[4] memory validPercentages = [
            catalog.STREAK_TIER_1(),
            catalog.STREAK_TIER_2(),
            catalog.STREAK_TIER_3(),
            catalog.STREAK_TIER_4()
        ];

        for (uint8 i = 0; i < 4; i++) {
            bytes memory targetData = abi.encode(validPercentages[i]);

            TournamentDeckCatalog.ObjectiveDefinition
                memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                    objectiveId: i + 1,
                    objectiveType: TournamentDeckCatalog.Objective.LoseStreak,
                    exists: true,
                    paused: false,
                    targetData: targetData
                });

            catalog.registerObjective(objective);

            require(catalog.objectiveExists(i + 1), "Objective should exist");
        }
    }

    // shouldn't allow LoseStreak objective with invalid percentage
    function test_RegisterObjective_LoseStreak_RevertWhen_InvalidPercentage()
        public
    {
        bytes memory targetData = abi.encode(uint8(10));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.LoseStreak,
                exists: true,
                paused: false,
                targetData: targetData
            });

        vm.expectRevert(TournamentDeckCatalog.InvalidMultiplier.selector);
        catalog.registerObjective(objective);
    }

    // should allow owner to register EliminationCount objective with valid percentages
    function test_RegisterObjective_EliminationCount_ValidPercentages() public {
        uint8[4] memory validPercentages = [
            catalog.ELIM_TIER_1(),
            catalog.ELIM_TIER_2(),
            catalog.ELIM_TIER_3(),
            catalog.ELIM_TIER_4()
        ];

        for (uint8 i = 0; i < 4; i++) {
            bytes memory targetData = abi.encode(validPercentages[i]);

            TournamentDeckCatalog.ObjectiveDefinition
                memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                    objectiveId: i + 1,
                    objectiveType: TournamentDeckCatalog
                        .Objective
                        .EliminationCount,
                    exists: true,
                    paused: false,
                    targetData: targetData
                });

            catalog.registerObjective(objective);

            require(catalog.objectiveExists(i + 1), "Objective should exist");
        }
    }

    // shouldn't allow EliminationCount objective with invalid percentage
    function test_RegisterObjective_EliminationCount_RevertWhen_InvalidPercentage()
        public
    {
        bytes memory targetData = abi.encode(uint8(30));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.EliminationCount,
                exists: true,
                paused: false,
                targetData: targetData
            });

        vm.expectRevert(TournamentDeckCatalog.InvalidMultiplier.selector);
        catalog.registerObjective(objective);
    }

    // should allow owner to register BattleRate objective with valid percentages
    function test_RegisterObjective_BattleRate_ValidRange() public {
        for (
            uint8 pct = catalog.MIN_BATTLE_RATE_PCT();
            pct <= catalog.MAX_BATTLE_RATE_PCT();
            pct += 5
        ) {
            bytes memory targetData = abi.encode(pct);

            TournamentDeckCatalog.ObjectiveDefinition
                memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                    objectiveId: pct,
                    objectiveType: TournamentDeckCatalog.Objective.BattleRate,
                    exists: true,
                    paused: false,
                    targetData: targetData
                });

            catalog.registerObjective(objective);

            require(catalog.objectiveExists(pct), "Objective should exist");
        }
    }

    // shouldn't allow BattleRate objective below minimum percentage
    function test_RegisterObjective_BattleRate_RevertWhen_BelowMinimum()
        public
    {
        bytes memory targetData = abi.encode(uint8(0));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.BattleRate,
                exists: true,
                paused: false,
                targetData: targetData
            });

        vm.expectRevert(TournamentDeckCatalog.InvalidMultiplier.selector);
        catalog.registerObjective(objective);
    }

    // shouldn't allow BattleRate objective above maximum percentage
    function test_RegisterObjective_BattleRate_RevertWhen_AboveMaximum()
        public
    {
        bytes memory targetData = abi.encode(uint8(31));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.BattleRate,
                exists: true,
                paused: false,
                targetData: targetData
            });

        vm.expectRevert(TournamentDeckCatalog.InvalidMultiplier.selector);
        catalog.registerObjective(objective);
    }

    // should allow owner to register VictoryRate objective with valid percentages
    function test_RegisterObjective_VictoryRate_ValidRange() public {
        for (
            uint8 pct = catalog.MIN_VICTORY_RATE_PCT();
            pct <= catalog.MAX_VICTORY_RATE_PCT();
            pct += 10
        ) {
            bytes memory targetData = abi.encode(pct);

            TournamentDeckCatalog.ObjectiveDefinition
                memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                    objectiveId: pct,
                    objectiveType: TournamentDeckCatalog.Objective.VictoryRate,
                    exists: true,
                    paused: false,
                    targetData: targetData
                });

            catalog.registerObjective(objective);

            require(catalog.objectiveExists(pct), "Objective should exist");
        }
    }

    // shouldn't allow VictoryRate objective below minimum percentage
    function test_RegisterObjective_VictoryRate_RevertWhen_BelowMinimum()
        public
    {
        bytes memory targetData = abi.encode(uint8(69));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.VictoryRate,
                exists: true,
                paused: false,
                targetData: targetData
            });

        vm.expectRevert(TournamentDeckCatalog.InvalidMultiplier.selector);
        catalog.registerObjective(objective);
    }

    // shouldn't allow VictoryRate objective above maximum percentage
    function test_RegisterObjective_VictoryRate_RevertWhen_AboveMaximum()
        public
    {
        bytes memory targetData = abi.encode(uint8(101));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.VictoryRate,
                exists: true,
                paused: false,
                targetData: targetData
            });

        vm.expectRevert(TournamentDeckCatalog.InvalidMultiplier.selector);
        catalog.registerObjective(objective);
    }

    // should allow owner to register PerfectRecord objective
    function test_RegisterObjective_PerfectRecord() public {
        bytes memory targetData = abi.encode(uint8(0));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.PerfectRecord,
                exists: true,
                paused: false,
                targetData: targetData
            });

        catalog.registerObjective(objective);

        require(catalog.objectiveExists(1), "Objective should exist");
    }

    // should allow owner to register TradeCount objective with valid percentages
    function test_RegisterObjective_TradeCount_ValidRange() public {
        for (
            uint8 pct = catalog.MIN_TRADE_COUNT_PCT();
            pct <= catalog.MAX_TRADE_COUNT_PCT();
            pct += 5
        ) {
            bytes memory targetData = abi.encode(pct);

            TournamentDeckCatalog.ObjectiveDefinition
                memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                    objectiveId: pct,
                    objectiveType: TournamentDeckCatalog.Objective.TradeCount,
                    exists: true,
                    paused: false,
                    targetData: targetData
                });

            catalog.registerObjective(objective);

            require(catalog.objectiveExists(pct), "Objective should exist");
        }
    }

    // shouldn't allow TradeCount objective below minimum percentage
    function test_RegisterObjective_TradeCount_RevertWhen_BelowMinimum()
        public
    {
        bytes memory targetData = abi.encode(uint8(0));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.TradeCount,
                exists: true,
                paused: false,
                targetData: targetData
            });

        vm.expectRevert(TournamentDeckCatalog.InvalidMultiplier.selector);
        catalog.registerObjective(objective);
    }

    // shouldn't allow TradeCount objective above maximum percentage
    function test_RegisterObjective_TradeCount_RevertWhen_AboveMaximum()
        public
    {
        bytes memory targetData = abi.encode(uint8(31));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.TradeCount,
                exists: true,
                paused: false,
                targetData: targetData
            });

        vm.expectRevert(TournamentDeckCatalog.InvalidMultiplier.selector);
        catalog.registerObjective(objective);
    }

    // should allow owner to register TradeVolume objective with valid percentages
    function test_RegisterObjective_TradeVolume_ValidRange() public {
        for (
            uint8 pct = catalog.MIN_TRADE_VOLUME_PCT();
            pct <= catalog.MAX_TRADE_VOLUME_PCT();
            pct += 25
        ) {
            bytes memory targetData = abi.encode(pct);

            TournamentDeckCatalog.ObjectiveDefinition
                memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                    objectiveId: pct,
                    objectiveType: TournamentDeckCatalog.Objective.TradeVolume,
                    exists: true,
                    paused: false,
                    targetData: targetData
                });

            catalog.registerObjective(objective);

            require(catalog.objectiveExists(pct), "Objective should exist");
        }
    }

    // shouldn't allow TradeVolume objective below minimum percentage
    function test_RegisterObjective_TradeVolume_RevertWhen_BelowMinimum()
        public
    {
        bytes memory targetData = abi.encode(uint8(0));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.TradeVolume,
                exists: true,
                paused: false,
                targetData: targetData
            });

        vm.expectRevert(TournamentDeckCatalog.InvalidMultiplier.selector);
        catalog.registerObjective(objective);
    }

    // shouldn't allow TradeVolume objective above maximum percentage
    function test_RegisterObjective_TradeVolume_RevertWhen_AboveMaximum()
        public
    {
        bytes memory targetData = abi.encode(uint8(151));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.TradeVolume,
                exists: true,
                paused: false,
                targetData: targetData
            });

        vm.expectRevert(TournamentDeckCatalog.InvalidMultiplier.selector);
        catalog.registerObjective(objective);
    }

    // shouldn't allow objective with id 0
    function test_RegisterObjective_RevertWhen_ObjectiveIdZero() public {
        bytes memory targetData = abi.encode(uint16(catalog.LIVES_MULT_1X()));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 0,
                objectiveType: TournamentDeckCatalog.Objective.ResourceLives,
                exists: true,
                paused: false,
                targetData: targetData
            });

        vm.expectRevert(TournamentDeckCatalog.InvalidObjectiveId.selector);
        catalog.registerObjective(objective);
    }

    // shouldn't allow objective with duplicate id
    function test_RegisterObjective_RevertWhen_ObjectiveIdTaken() public {
        bytes memory targetData = abi.encode(uint16(catalog.LIVES_MULT_1X()));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.ResourceLives,
                exists: true,
                paused: false,
                targetData: targetData
            });

        catalog.registerObjective(objective);

        vm.expectRevert(TournamentDeckCatalog.ObjectiveIdTaken.selector);
        catalog.registerObjective(objective);
    }

    // shouldn't allow objective with empty targetData
    function test_RegisterObjective_RevertWhen_EmptyTargetData() public {
        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.ResourceLives,
                exists: true,
                paused: false,
                targetData: bytes("")
            });

        vm.expectRevert(TournamentDeckCatalog.InvalidTargetData.selector);
        catalog.registerObjective(objective);
    }

    // shouldn't allow ResourceLives objective with wrong targetData length
    function test_RegisterObjective_ResourceLives_RevertWhen_WrongDataLength()
        public
    {
        bytes memory targetData = abi.encode(
            uint16(catalog.LIVES_MULT_1X()),
            uint16(100)
        );

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.ResourceLives,
                exists: true,
                paused: false,
                targetData: targetData
            });

        vm.expectRevert(TournamentDeckCatalog.InvalidTargetData.selector);
        catalog.registerObjective(objective);
    }

    // shouldn't allow ResourceAll objective with wrong targetData length
    function test_RegisterObjective_ResourceAll_RevertWhen_WrongDataLength()
        public
    {
        bytes memory targetData = abi.encode(uint16(catalog.LIVES_MULT_1X()));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.ResourceAll,
                exists: true,
                paused: false,
                targetData: targetData
            });

        vm.expectRevert(TournamentDeckCatalog.InvalidTargetData.selector);
        catalog.registerObjective(objective);
    }

    // shouldn't allow non-owner to register objective
    function test_RegisterObjective_RevertWhen_NotOwner() public {
        bytes memory targetData = abi.encode(uint16(catalog.LIVES_MULT_1X()));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.ResourceLives,
                exists: true,
                paused: false,
                targetData: targetData
            });

        vm.prank(nonOwner);
        vm.expectRevert();
        catalog.registerObjective(objective);
    }

    // should allow owner to register multiple objectives at once
    function test_RegisterObjectives_Batch() public {
        TournamentDeckCatalog.ObjectiveDefinition[]
            memory objectives = new TournamentDeckCatalog.ObjectiveDefinition[](
                3
            );

        objectives[0] = TournamentDeckCatalog.ObjectiveDefinition({
            objectiveId: 1,
            objectiveType: TournamentDeckCatalog.Objective.ResourceLives,
            exists: true,
            paused: false,
            targetData: abi.encode(uint16(catalog.LIVES_MULT_1X()))
        });

        objectives[1] = TournamentDeckCatalog.ObjectiveDefinition({
            objectiveId: 2,
            objectiveType: TournamentDeckCatalog.Objective.ResourceCoins,
            exists: true,
            paused: false,
            targetData: abi.encode(uint16(catalog.MIN_COINS_MULTIPLIER()))
        });

        objectives[2] = TournamentDeckCatalog.ObjectiveDefinition({
            objectiveId: 3,
            objectiveType: TournamentDeckCatalog.Objective.WinStreak,
            exists: true,
            paused: false,
            targetData: abi.encode(uint8(catalog.STREAK_TIER_1()))
        });

        catalog.registerObjectives(objectives);

        require(catalog.objectiveCount() == 3, "Should have 3 objectives");
        require(catalog.objectiveExists(1), "Objective 1 should exist");
        require(catalog.objectiveExists(2), "Objective 2 should exist");
        require(catalog.objectiveExists(3), "Objective 3 should exist");
    }

    // shouldn't allow batch registration with duplicate ids within batch
    function test_RegisterObjectives_RevertWhen_DuplicateInBatch() public {
        TournamentDeckCatalog.ObjectiveDefinition[]
            memory objectives = new TournamentDeckCatalog.ObjectiveDefinition[](
                2
            );

        objectives[0] = TournamentDeckCatalog.ObjectiveDefinition({
            objectiveId: 1,
            objectiveType: TournamentDeckCatalog.Objective.ResourceLives,
            exists: true,
            paused: false,
            targetData: abi.encode(uint16(catalog.LIVES_MULT_1X()))
        });

        objectives[1] = TournamentDeckCatalog.ObjectiveDefinition({
            objectiveId: 1,
            objectiveType: TournamentDeckCatalog.Objective.ResourceCoins,
            exists: true,
            paused: false,
            targetData: abi.encode(uint16(catalog.MIN_COINS_MULTIPLIER()))
        });

        vm.expectRevert(TournamentDeckCatalog.ObjectiveIdTaken.selector);
        catalog.registerObjectives(objectives);
    }
    // shouldn't allow batch registration when it would exceed max objectives (255)
    function test_RegisterObjectives_RevertWhen_ExceedsMaxObjectives() public {
        TournamentDeckCatalog.ObjectiveDefinition[]
            memory objectives = new TournamentDeckCatalog.ObjectiveDefinition[](
                256
            );

        for (uint256 i = 0; i < 256; i++) {
            objectives[i] = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: uint8(i + 1),
                objectiveType: TournamentDeckCatalog.Objective.ResourceLives,
                exists: true,
                paused: false,
                targetData: abi.encode(uint16(catalog.LIVES_MULT_1X()))
            });
        }

        vm.expectRevert(TournamentDeckCatalog.ExceedsMaxObjectives.selector);
        catalog.registerObjectives(objectives);
    }

    // shouldn't allow batch registration with invalid objective in batch
    function test_RegisterObjectives_RevertWhen_InvalidObjectiveInBatch()
        public
    {
        TournamentDeckCatalog.ObjectiveDefinition[]
            memory objectives = new TournamentDeckCatalog.ObjectiveDefinition[](
                2
            );

        objectives[0] = TournamentDeckCatalog.ObjectiveDefinition({
            objectiveId: 1,
            objectiveType: TournamentDeckCatalog.Objective.ResourceLives,
            exists: true,
            paused: false,
            targetData: abi.encode(uint16(catalog.LIVES_MULT_1X()))
        });

        objectives[1] = TournamentDeckCatalog.ObjectiveDefinition({
            objectiveId: 2,
            objectiveType: TournamentDeckCatalog.Objective.ResourceLives,
            exists: true,
            paused: false,
            targetData: abi.encode(uint16(150))
        });

        vm.expectRevert(TournamentDeckCatalog.InvalidMultiplier.selector);
        catalog.registerObjectives(objectives);
    }

    // shouldn't allow non-owner to batch register objectives
    function test_RegisterObjectives_RevertWhen_NotOwner() public {
        TournamentDeckCatalog.ObjectiveDefinition[]
            memory objectives = new TournamentDeckCatalog.ObjectiveDefinition[](
                1
            );

        objectives[0] = TournamentDeckCatalog.ObjectiveDefinition({
            objectiveId: 1,
            objectiveType: TournamentDeckCatalog.Objective.ResourceLives,
            exists: true,
            paused: false,
            targetData: abi.encode(uint16(catalog.LIVES_MULT_1X()))
        });

        vm.prank(nonOwner);
        vm.expectRevert();
        catalog.registerObjectives(objectives);
    }

    // should allow owner to pause an objective
    function test_PauseObjective() public {
        bytes memory targetData = abi.encode(uint16(catalog.LIVES_MULT_1X()));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.ResourceLives,
                exists: true,
                paused: false,
                targetData: targetData
            });

        catalog.registerObjective(objective);
        catalog.pauseObjective(1);

        require(catalog.isObjectivePaused(1), "Objective should be paused");
        require(
            !catalog.isObjectiveActive(1),
            "Objective should not be active"
        );
    }

    // shouldn't allow pausing non-existent objective
    function test_PauseObjective_RevertWhen_ObjectiveNotFound() public {
        vm.expectRevert(TournamentDeckCatalog.ObjectiveNotFound.selector);
        catalog.pauseObjective(1);
    }

    // shouldn't allow pausing already paused objective
    function test_PauseObjective_RevertWhen_AlreadyPaused() public {
        bytes memory targetData = abi.encode(uint16(catalog.LIVES_MULT_1X()));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.ResourceLives,
                exists: true,
                paused: false,
                targetData: targetData
            });

        catalog.registerObjective(objective);
        catalog.pauseObjective(1);

        vm.expectRevert(TournamentDeckCatalog.ObjectiveAlreadyPaused.selector);
        catalog.pauseObjective(1);
    }

    // shouldn't allow non-owner to pause objective
    function test_PauseObjective_RevertWhen_NotOwner() public {
        bytes memory targetData = abi.encode(uint16(catalog.LIVES_MULT_1X()));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.ResourceLives,
                exists: true,
                paused: false,
                targetData: targetData
            });

        catalog.registerObjective(objective);

        vm.prank(nonOwner);
        vm.expectRevert();
        catalog.pauseObjective(1);
    }

    // should allow owner to unpause an objective
    function test_UnpauseObjective() public {
        bytes memory targetData = abi.encode(uint16(catalog.LIVES_MULT_1X()));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.ResourceLives,
                exists: true,
                paused: false,
                targetData: targetData
            });

        catalog.registerObjective(objective);
        catalog.pauseObjective(1);
        catalog.unpauseObjective(1);

        require(
            !catalog.isObjectivePaused(1),
            "Objective should not be paused"
        );
        require(catalog.isObjectiveActive(1), "Objective should be active");
    }

    // shouldn't allow unpausing non-existent objective
    function test_UnpauseObjective_RevertWhen_ObjectiveNotFound() public {
        vm.expectRevert(TournamentDeckCatalog.ObjectiveNotFound.selector);
        catalog.unpauseObjective(1);
    }

    // shouldn't allow unpausing non-paused objective
    function test_UnpauseObjective_RevertWhen_NotPaused() public {
        bytes memory targetData = abi.encode(uint16(catalog.LIVES_MULT_1X()));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.ResourceLives,
                exists: true,
                paused: false,
                targetData: targetData
            });

        catalog.registerObjective(objective);

        vm.expectRevert(TournamentDeckCatalog.ObjectiveNotPaused.selector);
        catalog.unpauseObjective(1);
    }

    // shouldn't allow non-owner to unpause objective
    function test_UnpauseObjective_RevertWhen_NotOwner() public {
        bytes memory targetData = abi.encode(uint16(catalog.LIVES_MULT_1X()));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.ResourceLives,
                exists: true,
                paused: false,
                targetData: targetData
            });

        catalog.registerObjective(objective);
        catalog.pauseObjective(1);

        vm.prank(nonOwner);
        vm.expectRevert();
        catalog.unpauseObjective(1);
    }

    // should return correct objective data
    function test_GetObjective() public {
        bytes memory targetData = abi.encode(uint16(catalog.LIVES_MULT_2X()));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.ResourceLives,
                exists: true,
                paused: false,
                targetData: targetData
            });

        catalog.registerObjective(objective);

        TournamentDeckCatalog.ObjectiveDefinition memory retrieved = catalog
            .getObjective(1);
        require(retrieved.objectiveId == 1, "Objective ID should match");
        require(
            retrieved.objectiveType ==
                TournamentDeckCatalog.Objective.ResourceLives,
            "Objective type should match"
        );
    }

    // shouldn't allow getting non-existent objective
    function test_GetObjective_RevertWhen_ObjectiveNotFound() public {
        vm.expectRevert(TournamentDeckCatalog.ObjectiveNotFound.selector);
        catalog.getObjective(1);
    }

    // should return all objective ids
    function test_GetAllObjectiveIds() public {
        TournamentDeckCatalog.ObjectiveDefinition[]
            memory objectives = new TournamentDeckCatalog.ObjectiveDefinition[](
                3
            );

        for (uint8 i = 0; i < 3; i++) {
            objectives[i] = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: i + 1,
                objectiveType: TournamentDeckCatalog.Objective.ResourceLives,
                exists: true,
                paused: false,
                targetData: abi.encode(uint16(catalog.LIVES_MULT_1X()))
            });
        }

        catalog.registerObjectives(objectives);

        uint8[] memory ids = catalog.getAllObjectiveIds();
        require(ids.length == 3, "Should have 3 objective IDs");
        require(ids[0] == 1, "First ID should be 1");
        require(ids[1] == 2, "Second ID should be 2");
        require(ids[2] == 3, "Third ID should be 3");
    }

    // should return multiple objectives by ids
    function test_GetObjectives() public {
        TournamentDeckCatalog.ObjectiveDefinition[]
            memory objectives = new TournamentDeckCatalog.ObjectiveDefinition[](
                3
            );

        objectives[0] = TournamentDeckCatalog.ObjectiveDefinition({
            objectiveId: 1,
            objectiveType: TournamentDeckCatalog.Objective.ResourceLives,
            exists: true,
            paused: false,
            targetData: abi.encode(uint16(catalog.LIVES_MULT_1X()))
        });

        objectives[1] = TournamentDeckCatalog.ObjectiveDefinition({
            objectiveId: 2,
            objectiveType: TournamentDeckCatalog.Objective.ResourceCoins,
            exists: true,
            paused: false,
            targetData: abi.encode(uint16(catalog.MIN_COINS_MULTIPLIER()))
        });

        objectives[2] = TournamentDeckCatalog.ObjectiveDefinition({
            objectiveId: 3,
            objectiveType: TournamentDeckCatalog.Objective.WinStreak,
            exists: true,
            paused: false,
            targetData: abi.encode(uint8(catalog.STREAK_TIER_1()))
        });

        catalog.registerObjectives(objectives);

        uint8[] memory idsToFetch = new uint8[](2);
        idsToFetch[0] = 1;
        idsToFetch[1] = 3;

        TournamentDeckCatalog.ObjectiveDefinition[] memory retrieved = catalog
            .getObjectives(idsToFetch);
        require(retrieved.length == 2, "Should return 2 objectives");
        require(
            retrieved[0].objectiveId == 1,
            "First objective should be ID 1"
        );
        require(
            retrieved[1].objectiveId == 3,
            "Second objective should be ID 3"
        );
    }

    // shouldn't allow getting objectives with non-existent id
    function test_GetObjectives_RevertWhen_ObjectiveNotFound() public {
        bytes memory targetData = abi.encode(uint16(catalog.LIVES_MULT_1X()));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.ResourceLives,
                exists: true,
                paused: false,
                targetData: targetData
            });

        catalog.registerObjective(objective);

        uint8[] memory idsToFetch = new uint8[](2);
        idsToFetch[0] = 1;
        idsToFetch[1] = 99;

        vm.expectRevert(TournamentDeckCatalog.ObjectiveNotFound.selector);
        catalog.getObjectives(idsToFetch);
    }

    // should fuzz test valid ResourceLives objectives
    function testFuzz_RegisterValidResourceLivesObjective(
        uint8 objectiveId,
        uint8 multiplierChoice
    ) public {
        vm.assume(objectiveId > 0);
        vm.assume(multiplierChoice < 3);

        uint16[3] memory validMultipliers = [
            catalog.LIVES_MULT_1X(),
            catalog.LIVES_MULT_2X(),
            catalog.LIVES_MULT_3X()
        ];

        bytes memory targetData = abi.encode(
            validMultipliers[multiplierChoice]
        );

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: objectiveId,
                objectiveType: TournamentDeckCatalog.Objective.ResourceLives,
                exists: true,
                paused: false,
                targetData: targetData
            });

        catalog.registerObjective(objective);

        require(catalog.objectiveExists(objectiveId), "Objective should exist");
    }

    // should fuzz test valid ResourceCoins objectives
    function testFuzz_RegisterValidResourceCoinsObjective(
        uint8 objectiveId,
        uint16 multiplier
    ) public {
        vm.assume(objectiveId > 0);
        vm.assume(
            multiplier >= catalog.MIN_COINS_MULTIPLIER() &&
                multiplier <= catalog.MAX_COINS_MULTIPLIER()
        );

        bytes memory targetData = abi.encode(multiplier);

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: objectiveId,
                objectiveType: TournamentDeckCatalog.Objective.ResourceCoins,
                exists: true,
                paused: false,
                targetData: targetData
            });

        catalog.registerObjective(objective);

        require(catalog.objectiveExists(objectiveId), "Objective should exist");
    }

    // should fuzz test valid BattleRate objectives
    function testFuzz_RegisterValidBattleRateObjective(
        uint8 objectiveId,
        uint8 percentage
    ) public {
        vm.assume(objectiveId > 0);
        vm.assume(
            percentage >= catalog.MIN_BATTLE_RATE_PCT() &&
                percentage <= catalog.MAX_BATTLE_RATE_PCT()
        );

        bytes memory targetData = abi.encode(percentage);

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: objectiveId,
                objectiveType: TournamentDeckCatalog.Objective.BattleRate,
                exists: true,
                paused: false,
                targetData: targetData
            });

        catalog.registerObjective(objective);

        require(catalog.objectiveExists(objectiveId), "Objective should exist");
    }

    // should fuzz test valid VictoryRate objectives
    function testFuzz_RegisterValidVictoryRateObjective(
        uint8 objectiveId,
        uint8 percentage
    ) public {
        vm.assume(objectiveId > 0);
        vm.assume(
            percentage >= catalog.MIN_VICTORY_RATE_PCT() &&
                percentage <= catalog.MAX_VICTORY_RATE_PCT()
        );

        bytes memory targetData = abi.encode(percentage);

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: objectiveId,
                objectiveType: TournamentDeckCatalog.Objective.VictoryRate,
                exists: true,
                paused: false,
                targetData: targetData
            });

        catalog.registerObjective(objective);

        require(catalog.objectiveExists(objectiveId), "Objective should exist");
    }

    // should maintain correct objective count after multiple registrations
    function test_ObjectiveCount_ConsistentAfterMultipleRegistrations() public {
        for (uint8 i = 1; i <= 10; i++) {
            bytes memory targetData = abi.encode(
                uint16(catalog.LIVES_MULT_1X())
            );

            TournamentDeckCatalog.ObjectiveDefinition
                memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                    objectiveId: i,
                    objectiveType: TournamentDeckCatalog
                        .Objective
                        .ResourceLives,
                    exists: true,
                    paused: false,
                    targetData: targetData
                });

            catalog.registerObjective(objective);
            require(
                catalog.objectiveCount() == i,
                "Objective count should increment"
            );
        }
    }

    // should maintain objective existence state correctly
    function test_ObjectiveExistence_ConsistentAfterRegistration() public {
        require(
            !catalog.objectiveExists(1),
            "Objective should not exist initially"
        );

        bytes memory targetData = abi.encode(uint16(catalog.LIVES_MULT_1X()));

        TournamentDeckCatalog.ObjectiveDefinition
            memory objective = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: 1,
                objectiveType: TournamentDeckCatalog.Objective.ResourceLives,
                exists: true,
                paused: false,
                targetData: targetData
            });

        catalog.registerObjective(objective);

        require(
            catalog.objectiveExists(1),
            "Objective should exist after registration"
        );
    }

    // should not overflow objective count at boundary (254 -> 255)
    function test_ObjectiveCount_NoOverflowAtBoundary() public {
        TournamentDeckCatalog.ObjectiveDefinition[]
            memory objectives = new TournamentDeckCatalog.ObjectiveDefinition[](
                255
            );

        for (uint256 i = 0; i < 255; i++) {
            objectives[i] = TournamentDeckCatalog.ObjectiveDefinition({
                objectiveId: uint8(i + 1),
                objectiveType: TournamentDeckCatalog.Objective.ResourceLives,
                exists: true,
                paused: false,
                targetData: abi.encode(uint16(catalog.LIVES_MULT_1X()))
            });
        }

        catalog.registerObjectives(objectives);

        require(
            catalog.objectiveCount() == 255,
            "Objective count should be 255"
        );
        require(catalog.objectiveExists(255), "Objective 255 should exist");
    }
}
