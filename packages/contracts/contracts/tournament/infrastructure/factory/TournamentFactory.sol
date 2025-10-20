// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TournamentRegistry} from "./../registry/TournamentRegistry.sol";
import {TournamentTokenWhitelist} from "./../token-whitelist/TournamentTokenWhitelist.sol";
import {TournamentDeckCatalog} from "./../deck-catalog/TournamentDeckCatalog.sol";
import {TournamentCore} from "./../../core/TournamentCore.sol";
import {TournamentFactoryValidation} from "./libraries/validation/FactoryValidation.sol";
import {TournamentFactoryDeployment} from "./libraries/deployment/FactoryDeployment.sol";

contract TournamentFactory is Ownable {
    struct FactoryConfig {
        address hubImpl;
        address combatImpl;
        address mysteryDeckImpl;
        address tradingImpl;
        address randomizerImpl;
        address registry;
        address whitelist;
        address deckCatalog;
        address pythEntropy;
        address entropyProvider;
        address platformAdmin;
        address rngOracle;
        uint8 platformFeePercent;
    }

    address public immutable hubImplementation;
    address public immutable combatImplementation;
    address public immutable mysteryDeckImplementation;
    address public immutable tradingImplementation;
    address public immutable randomizerImplementation;

    address public immutable platformAdmin;
    TournamentRegistry public immutable registry;
    TournamentTokenWhitelist public immutable whitelist;
    TournamentDeckCatalog public immutable deckCatalog;

    address public immutable pythEntropy;
    address public immutable entropyProvider;
    uint8 public platformFeePercent;

    address public rngOracle;

    event TournamentSystemCreated(
        address indexed hub,
        address indexed combat,
        address mysteryDeck,
        address trading,
        address randomizer,
        address indexed creator,
        address stakeToken,
        uint32 startTimestamp,
        uint32 duration
    );

    event PlatformFeeUpdated(uint8 newFee);
    event RngOracleUpdated(address indexed newOracle);
    event ETHDeposited(address indexed from, uint256 amount);
    event ETHWithdrawn(address indexed to, uint256 amount);

    error InvalidAddress();
    error PlatformFeeTooHigh();
    error InsufficientETHForSeed();

    constructor(FactoryConfig memory config) Ownable(msg.sender) {
        if (
            config.hubImpl == address(0) ||
            config.combatImpl == address(0) ||
            config.mysteryDeckImpl == address(0) ||
            config.tradingImpl == address(0) ||
            config.randomizerImpl == address(0) ||
            config.registry == address(0) ||
            config.whitelist == address(0) ||
            config.deckCatalog == address(0) ||
            config.pythEntropy == address(0) ||
            config.entropyProvider == address(0)
        ) revert InvalidAddress();

        if (config.platformFeePercent > 5) revert PlatformFeeTooHigh();

        hubImplementation = config.hubImpl;
        combatImplementation = config.combatImpl;
        mysteryDeckImplementation = config.mysteryDeckImpl;
        tradingImplementation = config.tradingImpl;
        randomizerImplementation = config.randomizerImpl;
        registry = TournamentRegistry(config.registry);
        whitelist = TournamentTokenWhitelist(config.whitelist);
        deckCatalog = TournamentDeckCatalog(config.deckCatalog);
        pythEntropy = config.pythEntropy;
        entropyProvider = config.entropyProvider;

        platformAdmin = config.platformAdmin == address(0)
            ? msg.sender
            : config.platformAdmin;
        rngOracle = config.rngOracle == address(0)
            ? msg.sender
            : config.rngOracle;
        platformFeePercent = config.platformFeePercent;
    }

    receive() external payable {
        emit ETHDeposited(msg.sender, msg.value);
    }

    function createTournamentSystem(
        TournamentCore.Params calldata params
    ) external returns (address hub) {
        TournamentFactoryValidation.validateParams(params, whitelist);

        TournamentFactoryDeployment.DeployedSystem
            memory system = TournamentFactoryDeployment.deployContracts(
                hubImplementation,
                combatImplementation,
                mysteryDeckImplementation,
                tradingImplementation,
                randomizerImplementation
            );

        TournamentFactoryDeployment.InitConfig
            memory initConfig = TournamentFactoryDeployment.InitConfig({
                registry: address(registry),
                whitelist: address(whitelist),
                deckCatalog: address(deckCatalog),
                pythEntropy: pythEntropy,
                entropyProvider: entropyProvider,
                platformAdmin: platformAdmin,
                rngOracle: rngOracle
            });

        TournamentFactoryDeployment.initializeContracts(
            system,
            params,
            initConfig,
            msg.sender
        );

        // Register
        registry.registerTournamentSystem(
            system.hub,
            system.combat,
            system.mysteryDeck,
            system.trading,
            system.randomizer
        );

        emit TournamentSystemCreated(
            system.hub,
            system.combat,
            system.mysteryDeck,
            system.trading,
            system.randomizer,
            msg.sender,
            params.stakeToken,
            params.startTimestamp,
            params.duration
        );

        return system.hub;
    }

    function setPlatformFee(uint8 newFee) external onlyOwner {
        if (newFee > TournamentCore.MAX_PLATFORM_FEE)
            revert PlatformFeeTooHigh();
        platformFeePercent = newFee;
        emit PlatformFeeUpdated(newFee);
    }

    function setRngOracle(address newOracle) external onlyOwner {
        if (newOracle == address(0)) revert InvalidAddress();
        rngOracle = newOracle;
        emit RngOracleUpdated(newOracle);
    }

    function withdrawETH(uint256 amount) external onlyOwner {
        if (address(this).balance < amount) revert InsufficientETHForSeed();
        payable(msg.sender).transfer(amount);
        emit ETHWithdrawn(msg.sender, amount);
    }

    function getImplementations()
        external
        view
        returns (
            address hub,
            address combat,
            address mysteryDeck,
            address trading,
            address randomizer
        )
    {
        return (
            hubImplementation,
            combatImplementation,
            mysteryDeckImplementation,
            tradingImplementation,
            randomizerImplementation
        );
    }
}
