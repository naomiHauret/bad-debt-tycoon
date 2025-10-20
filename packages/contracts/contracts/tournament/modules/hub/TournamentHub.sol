// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {TournamentCore} from "./../../core/TournamentCore.sol";
import {TournamentLifecycle} from "./../../core/libraries/lifecycle/Lifecycle.sol";
import {TournamentViews} from "./../../core/libraries/views/Views.sol";
import {TournamentRefund} from "./../../core/libraries/refund/Refund.sol";
import {TournamentHubPrize} from "./libraries/prize/Prize.sol";
import {TournamentHubPlayer} from "./libraries/player/Player.sol";
import {TournamentHubStatus} from "./libraries/status/Status.sol";
import {TournamentTokenWhitelist} from "./../../infrastructure/token-whitelist/TournamentTokenWhitelist.sol";
import {TournamentRegistry} from "./../../infrastructure/registry/TournamentRegistry.sol";

contract TournamentHub is Initializable {
    address public platformAdmin;
    bool public emergencyCancelled;
    TournamentCore.Status public status;
    uint16 public playerCount;
    uint16 public activePlayerCount;
    bool public creatorFeesCollected;

    address public creator;
    uint32 public actualStartTime;
    uint32 public endTime;
    uint32 public exitWindowStart;

    address public combat;
    address public mysteryDeck;
    address public trading;
    address public randomizer;

    uint256 public totalStaked;
    uint256 public totalForfeitPenalties;

    mapping(address => bool) private _hasModuleRole;
    mapping(address => TournamentCore.PlayerResources) internal players;

    address[] public winners;

    TournamentTokenWhitelist public tokenWhitelist;
    TournamentCore.Params internal params;
    TournamentRegistry public registry;

    event ExitWindowOpened(uint32 windowStart, uint32 windowEnd);
    event PlayerResourcesUpdated(
        address indexed player,
        address indexed module
    );
    event EmergencyCancellation(
        address indexed platformAdmin,
        uint32 calledAtTime
    );
    event RandomnessFailure(uint32 timestamp);

    error EmergencyCancelled();
    error OnlyPlatformAdmin();
    error NotFound();
    error CannotRefundAfterStart();
    error AlreadyClaimed();
    error InvalidStatus();
    error InvalidAddress();
    error Unauthorized();
    error AlreadyCancelled();
    error AlreadyEnded();

    modifier notEmergencyCancelled() {
        if (emergencyCancelled) revert EmergencyCancelled();
        _;
    }

    modifier onlyPlayer() {
        if (!players[msg.sender].exists) revert NotFound();
        _;
    }

    function initialize(
        TournamentCore.Params calldata _params,
        address _creator,
        address _combat,
        address _mysteryDeck,
        address _trading,
        address _randomizer,
        address _registry,
        address _whitelist,
        address _platformAdmin
    ) external initializer {
        if (
            _combat == address(0) ||
            _mysteryDeck == address(0) ||
            _trading == address(0) ||
            _randomizer == address(0)
        ) revert InvalidAddress();

        combat = _combat;
        mysteryDeck = _mysteryDeck;
        trading = _trading;
        randomizer = _randomizer;

        _hasModuleRole[_combat] = true;
        _hasModuleRole[_mysteryDeck] = true;
        _hasModuleRole[_trading] = true;

        params = _params;
        creator = _creator;
        tokenWhitelist = TournamentTokenWhitelist(_whitelist);
        registry = TournamentRegistry(_registry);
        status = TournamentCore.Status.Open;
        platformAdmin = _platformAdmin;
    }

    function hasModuleRole(address m) external view returns (bool) {
        return _hasModuleRole[m];
    }
}
