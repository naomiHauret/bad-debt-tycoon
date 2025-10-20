// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {TournamentCore} from "./../../../../core/TournamentCore.sol";
import {TournamentHub} from "./../../../../modules/hub/TournamentHub.sol";
import {TournamentCombat} from "./../../../../modules/combat/TournamentCombat.sol";
import {TournamentMysteryDeck} from "./../../../../modules/mystery-deck/TournamentMysteryDeck.sol";
import {TournamentTrading} from "./../../../../modules/trading/TournamentTrading.sol";
import {TournamentRandomizer} from "./../../../../modules/randomizer/TournamentRandomizer.sol";
import {TournamentRegistry} from "./../../../registry/TournamentRegistry.sol";
import {TournamentTokenWhitelist} from "./../../../token-whitelist/TournamentTokenWhitelist.sol";
import {TournamentDeckCatalog} from "./../../../deck-catalog/TournamentDeckCatalog.sol";

library TournamentFactoryDeployment {
    using Clones for address;

    struct DeployedSystem {
        address hub;
        address combat;
        address mysteryDeck;
        address trading;
        address randomizer;
    }

    struct InitConfig {
        address registry;
        address whitelist;
        address deckCatalog;
        address pythEntropy;
        address entropyProvider;
        address platformAdmin;
        address rngOracle;
    }

    error InsufficientETHForSeed();

    function deployContracts(
        address hubImpl,
        address combatImpl,
        address mysteryDeckImpl,
        address tradingImpl,
        address randomizerImpl
    ) external returns (DeployedSystem memory system) {
        system.hub = hubImpl.clone();
        system.combat = combatImpl.clone();
        system.mysteryDeck = mysteryDeckImpl.clone();
        system.trading = tradingImpl.clone();
        system.randomizer = randomizerImpl.clone();
    }

    function initializeContracts(
        DeployedSystem memory system,
        TournamentCore.Params calldata params,
        InitConfig memory config,
        address creator
    ) external {
        TournamentHub(system.hub).initialize(
            params,
            creator,
            system.combat,
            system.mysteryDeck,
            system.trading,
            system.randomizer,
            config.registry,
            config.whitelist,
            config.platformAdmin
        );

        TournamentCombat(system.combat).initialize(
            system.hub,
            system.randomizer
        );

        TournamentMysteryDeck(system.mysteryDeck).initialize(
            system.hub,
            config.deckCatalog,
            system.randomizer,
            params.excludedCardIds,
            params.deckDrawCost,
            params.deckShuffleCost,
            params.deckPeekCost,
            params.deckOracle
        );

        TournamentTrading(system.trading).initialize(system.hub);

        initializeRandomizer(system, config);
    }

    function initializeRandomizer(
        DeployedSystem memory system,
        InitConfig memory config
    ) public {
        TournamentRandomizer(system.randomizer).initialize(
            system.hub,
            config.pythEntropy,
            config.entropyProvider,
            config.platformAdmin
        );

        TournamentRandomizer(system.randomizer).setMysteryDeck(
            system.mysteryDeck
        );

        TournamentRandomizer(system.randomizer).grantOracleRole(
            config.rngOracle
        );

        uint256 pythFee = TournamentRandomizer(system.randomizer).getFee();
        if (address(this).balance < pythFee) revert InsufficientETHForSeed();

        TournamentRandomizer(system.randomizer).requestSeed{value: pythFee}(
            address(0)
        );
    }
}
