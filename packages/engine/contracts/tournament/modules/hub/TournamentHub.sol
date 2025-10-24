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
    address public admin;
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
    event EmergencyCancellation(address indexed admin, uint32 calledAtTime);
    event RandomnessFailure(uint32 timestamp);

    error EmergencyCancelled();
    error OnlyPlatformAdmin();
    error NotFound();
    error CannotRefundAfterStart();
    error AlreadyClaimed();
    error InvalidStatus();
    error InvalidAddress();
    error UnauthorizedRandomizer();
    error UnauthorizedHub();
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
        TournamentCore.Params calldata _p,
        address _creator,
        address _combat,
        address _deck,
        address _trading,
        address _rand,
        address _registry,
        address _tokens,
        address _admin
    ) external initializer {
        if (
            _combat == address(0) ||
            _deck == address(0) ||
            _trading == address(0) ||
            _rand == address(0)
        ) revert InvalidAddress();

        combat = _combat;
        mysteryDeck = _deck;
        trading = _trading;
        randomizer = _rand;

        _hasModuleRole[_combat] = true;
        _hasModuleRole[_deck] = true;
        _hasModuleRole[_trading] = true;

        params = _p;
        creator = _creator;
        tokenWhitelist = TournamentTokenWhitelist(_tokens);
        registry = TournamentRegistry(_registry);
        status = TournamentCore.Status.Open;
        admin = _admin;
    }

    function updatePlayerResources(
        address p,
        TournamentCore.PlayerResources calldata resources
    ) external {
        if (!_hasModuleRole[msg.sender]) revert UnauthorizedHub();
        players[p] = resources;
        emit PlayerResourcesUpdated(p, msg.sender);
    }

    function emergencyCancel() external {
        if (msg.sender != admin) revert OnlyPlatformAdmin();
        if (status == TournamentCore.Status.Ended) revert AlreadyEnded();
        if (emergencyCancelled) revert AlreadyCancelled();

        emergencyCancelled = true;
        status = TournamentCore.Status.Cancelled;
        TournamentLifecycle.emergencyCancel(registry, admin);
        emit EmergencyCancellation(admin, uint32(block.timestamp));
    }

    function handleFailedRandomness() external {
        if (msg.sender != randomizer) revert UnauthorizedRandomizer();
        if (
            status != TournamentCore.Status.Open &&
            status != TournamentCore.Status.Locked
        ) revert InvalidStatus();

        status = TournamentCore.Status.Cancelled;
        TournamentLifecycle.emergencyCancel(registry, randomizer);
        emit RandomnessFailure(uint32(block.timestamp));
    }

    function joinTournament(uint256 stake) external notEmergencyCancelled {
        TournamentHubPlayer.JoinResult memory r = TournamentHubPlayer
            .processJoin(
                players,
                params,
                status,
                playerCount,
                totalStaked,
                registry,
                msg.sender,
                stake
            );

        unchecked {
            playerCount++;
            activePlayerCount++;
        }
        totalStaked += stake;

        status = r.newStatus;
        if (r.newActualStartTime > 0) actualStartTime = r.newActualStartTime;
        if (r.newEndTime > 0) endTime = r.newEndTime;
        if (r.newExitWindowStart > 0) {
            exitWindowStart = r.newExitWindowStart;
            emit ExitWindowOpened(exitWindowStart, endTime);
        }
    }

    function exit() external onlyPlayer notEmergencyCancelled {
        if (status != TournamentCore.Status.Active) revert InvalidStatus();

        TournamentHubStatus.StatusUpdateResult memory r = TournamentHubStatus
            .applyDecayAndUpdateStatus(
                players,
                params,
                status,
                playerCount,
                totalStaked,
                totalForfeitPenalties,
                endTime,
                winners.length,
                registry,
                msg.sender
            );

        _applyStatusUpdate(r);

        TournamentHubPlayer.processExit(
            players,
            winners,
            status,
            exitWindowStart,
            msg.sender,
            TournamentViews.canExitFromStorage(
                players,
                params,
                status,
                actualStartTime,
                msg.sender
            )
        );

        unchecked {
            activePlayerCount--;
        }

        if (
            TournamentHubStatus.checkEarlyEnd(
                activePlayerCount,
                totalStaked,
                totalForfeitPenalties,
                winners.length,
                registry
            )
        ) {
            status = TournamentCore.Status.Ended;
        }
    }

    function forfeit() external onlyPlayer {
        if (status != TournamentCore.Status.Active) revert InvalidStatus();

        TournamentHubStatus.StatusUpdateResult memory r = TournamentHubStatus
            .applyDecayAndUpdateStatus(
                players,
                params,
                status,
                playerCount,
                totalStaked,
                totalForfeitPenalties,
                endTime,
                winners.length,
                registry,
                msg.sender
            );

        _applyStatusUpdate(r);

        uint256 penalty = TournamentViews.calculateForfeitPenaltyFromStorage(
            players,
            params,
            endTime,
            msg.sender
        );

        TournamentHubPlayer.processForfeit(
            players,
            params,
            status,
            msg.sender,
            penalty
        );

        unchecked {
            activePlayerCount--;
        }
        totalForfeitPenalties += penalty;

        if (
            TournamentHubStatus.checkEarlyEnd(
                activePlayerCount,
                totalStaked,
                totalForfeitPenalties,
                winners.length,
                registry
            )
        ) {
            status = TournamentCore.Status.Ended;
        }
    }

    function claimPrize() external onlyPlayer {
        TournamentHubStatus.StatusUpdateResult memory r = TournamentHubStatus
            .updateStatusOnly(
                params,
                status,
                playerCount,
                totalStaked,
                totalForfeitPenalties,
                endTime,
                winners.length,
                registry
            );

        _applyStatusUpdate(r);

        TournamentHubPrize.claimPrize(
            players,
            params,
            status,
            totalStaked,
            totalForfeitPenalties,
            winners.length,
            msg.sender
        );
    }

    function claimRefund() external onlyPlayer {
        TournamentCore.Status s = status;

        if (
            s == TournamentCore.Status.Active ||
            s == TournamentCore.Status.Ended
        ) revert CannotRefundAfterStart();

        TournamentCore.PlayerResources storage p = players[msg.sender];
        if (p.status == TournamentCore.PlayerStatus.Refunded)
            revert AlreadyClaimed();

        (
            bool shouldDec,
            uint16 newPC,
            uint256 newTS,
            TournamentCore.Status newS
        ) = TournamentRefund.processRefund(
                p,
                TournamentRefund.RefundContext({
                    stakeToken: params.stakeToken,
                    status: s,
                    maxPlayers: params.maxPlayers,
                    startPlayerCount: params.startPlayerCount,
                    startPoolAmount: params.startPoolAmount
                }),
                registry,
                msg.sender,
                playerCount,
                totalStaked
            );

        if (shouldDec) {
            unchecked {
                playerCount = newPC;
                totalStaked = newTS;
            }
        }

        if (newS != s) status = newS;
    }

    function collectCreatorFees() external {
        TournamentHubStatus.StatusUpdateResult memory r = TournamentHubStatus
            .updateStatusOnly(
                params,
                status,
                playerCount,
                totalStaked,
                totalForfeitPenalties,
                endTime,
                winners.length,
                registry
            );

        _applyStatusUpdate(r);

        if (creatorFeesCollected) revert AlreadyClaimed();

        creatorFeesCollected = TournamentHubPrize.collectCreatorFees(
            params,
            status,
            totalStaked,
            totalForfeitPenalties,
            creator,
            msg.sender
        );
    }

    function updateStatus() external {
        TournamentHubStatus.StatusUpdateResult memory r = TournamentHubStatus
            .updateStatusOnly(
                params,
                status,
                playerCount,
                totalStaked,
                totalForfeitPenalties,
                endTime,
                winners.length,
                registry
            );

        _applyStatusUpdate(r);
    }

    function _applyStatusUpdate(
        TournamentHubStatus.StatusUpdateResult memory r
    ) private {
        status = r.newStatus;
        if (r.newActualStartTime > 0) actualStartTime = r.newActualStartTime;
        if (r.newEndTime > 0) endTime = r.newEndTime;
        if (r.shouldEmitExitWindow) {
            exitWindowStart = r.newExitWindowStart;
            emit ExitWindowOpened(exitWindowStart, endTime);
        }
    }

    function getCurrentCoins(address p) public view returns (uint256) {
        return TournamentViews.getCurrentCoinsFromStorage(players, params, p);
    }

    function calculateExitCost(address p) public view returns (uint256) {
        return
            TournamentViews.calculateExitCostFromStorage(
                players,
                params,
                status,
                actualStartTime,
                p
            );
    }

    function canExit(address p) public view returns (bool) {
        return
            TournamentViews.canExitFromStorage(
                players,
                params,
                status,
                actualStartTime,
                p
            );
    }

    function calculateForfeitPenalty(address p) public view returns (uint256) {
        return
            TournamentViews.calculateForfeitPenaltyFromStorage(
                players,
                params,
                endTime,
                p
            );
    }

    function getCurrentPlayerResources(
        address p
    ) external view returns (TournamentCore.PlayerResources memory) {
        return
            TournamentViews.getCurrentPlayerResourcesFromStorage(
                players,
                params,
                p
            );
    }

    function getPlayer(
        address p
    ) external view returns (TournamentCore.PlayerResources memory) {
        return TournamentViews.getPlayerFromStorage(players, p);
    }

    function getParams() external view returns (TournamentCore.Params memory) {
        return params;
    }

    function getExitWindow()
        external
        view
        returns (uint32 windowStart, uint32 windowEnd, bool isOpen)
    {
        return TournamentViews.getExitWindow(exitWindowStart, endTime);
    }

    function hasModuleRole(address m) external view returns (bool) {
        return _hasModuleRole[m];
    }
}
