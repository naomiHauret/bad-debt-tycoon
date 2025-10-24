// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {TournamentCore} from "./../../../../core/TournamentCore.sol";
import {TournamentHub} from "./../../../../modules/hub/TournamentHub.sol";
import {TournamentCombat} from "./../../../../modules/combat/TournamentCombat.sol";
import {TournamentMysteryDeck} from "./../../../../modules/mystery-deck/TournamentMysteryDeck.sol";
import {TournamentTrading} from "./../../../../modules/trading/TournamentTrading.sol";
import {TournamentRandomizer} from "./../../../../modules/randomizer/TournamentRandomizer.sol";

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
        address gameOracle;
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
            config.gameOracle
        );

        TournamentMysteryDeck(system.mysteryDeck).initialize(
            system.hub,
            config.deckCatalog,
            params.excludedCardIds,
            params.deckDrawCost,
            params.deckShuffleCost,
            params.deckPeekCost,
            config.gameOracle
        );

        TournamentTrading(system.trading).initialize(
            system.hub,
            config.gameOracle
        );

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
            config.platformAdmin,
            config.gameOracle
        );

        TournamentRandomizer(system.randomizer).setMysteryDeck(
            system.mysteryDeck
        );
    }
}
