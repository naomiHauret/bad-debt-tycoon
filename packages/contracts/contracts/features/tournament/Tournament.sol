// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {TournamentCore} from "./../../core/TournamentCore.sol";
import {TournamentRegistry} from "../tournament-registry/TournamentRegistry.sol";
import {TournamentTokenWhitelist} from "./../token-whitelist/TournamentTokenWhitelist.sol";
import {TournamentLifecycle} from "./../lifecycle/Lifecycle.sol";
import {TournamentPlayerActions} from "./../player-actions/PlayerActions.sol";
import {TournamentViews} from "./Views.sol";
import {TournamentRefund} from "./../refund/Refund.sol";

contract Tournament is Initializable {
    using SafeERC20 for IERC20;

    address public platformAdmin;
    bool public emergencyCancelled;

    TournamentTokenWhitelist public tokenWhitelist;
    TournamentCore.TournamentParams internal params;
    address public creator;
    TournamentRegistry public registry;

    TournamentCore.Status public status;
    uint32 public actualStartTime;
    uint32 public endTime;
    uint16 public playerCount;
    uint256 public totalStaked;
    uint256 public totalForfeitPenalties;

    mapping(address => TournamentCore.PlayerResources) internal players;
    address[] public playerAddresses;
    address[] public winners;

    bool public creatorFeesCollected;

    event PrizeClaimed(address indexed player, uint256 amount);
    event CreatorFeesCollected(address indexed creator, uint256 amount);
    event EmergencyCancellation(
        address indexed platformAdmin,
        uint256 calledAtTime
    );

    error EmergencyCancelled();
    error OnlyPlatformAdmin();
    error OnlyCreator();
    error NotFound();
    error AlreadyJoined();
    error CannotExit();
    error ForfeitNotAllowed();
    error AlreadyExited();
    error AlreadyCancelled();
    error AlreadyEnded();
    error AlreadyForfeited();
    error CannotRefundAfterStart();
    error NotWinner();
    error AlreadyClaimed();
    error InvalidStatus();

    modifier notEmergencyCancelled() {
        if (emergencyCancelled) revert EmergencyCancelled();
        _;
    }

    modifier onlyPlayer() {
        if (!players[msg.sender].exists) revert NotFound();
        _;
    }

    modifier onlyStatus(TournamentCore.Status _status) {
        if (status != _status) revert InvalidStatus();
        _;
    }

    modifier applyDecayFirst() {
        TournamentPlayerActions.applyDecay(
            players[msg.sender],
            msg.sender,
            params.decayAmount,
            params.decayInterval
        );
        _;
    }

    modifier autoEndIfTimeUp() {
        if (
            status == TournamentCore.Status.Active && block.timestamp >= endTime
        ) {
            TournamentLifecycle.transitionToEnded(
                registry,
                totalStaked,
                totalForfeitPenalties,
                winners.length
            );
            status = TournamentCore.Status.Ended;
        }
        _;
    }

    modifier autoUpdateStatus() {
        (
            TournamentCore.Status newStatus,
            uint32 newActualStartTime,
            uint32 newEndTime
        ) = TournamentLifecycle.checkAndTransition(
                status,
                params,
                playerCount,
                totalStaked,
                registry
            );

        status = newStatus;
        if (newActualStartTime > 0) actualStartTime = newActualStartTime;
        if (newEndTime > 0) endTime = newEndTime;

        if (
            status == TournamentCore.Status.Active && block.timestamp >= endTime
        ) {
            TournamentLifecycle.transitionToEnded(
                registry,
                totalStaked,
                totalForfeitPenalties,
                winners.length
            );
            status = TournamentCore.Status.Ended;
        }
        _;
    }

    function _checkEarlyEnd() internal {
        uint256 activeCount = TournamentPlayerActions.countActivePlayers(
            playerAddresses,
            players
        );
        if (activeCount == 0) {
            TournamentLifecycle.transitionToEnded(
                registry,
                totalStaked,
                totalForfeitPenalties,
                winners.length
            );
            status = TournamentCore.Status.Ended;
        }
    }

    function initialize(
        TournamentCore.TournamentParams calldata _params,
        address _creator,
        address _registry,
        address _whitelist,
        address _platformAdmin
    ) external initializer {
        params = _params;
        creator = _creator;
        tokenWhitelist = TournamentTokenWhitelist(_whitelist);
        registry = TournamentRegistry(_registry);
        status = TournamentCore.Status.Open;
        platformAdmin = _platformAdmin;
    }

    function emergencyCancel() external {
        if (msg.sender != platformAdmin) revert OnlyPlatformAdmin();
        if (status == TournamentCore.Status.Ended) revert AlreadyEnded();
        if (emergencyCancelled) revert AlreadyCancelled();

        emergencyCancelled = true;
        status = TournamentCore.Status.Cancelled;
        TournamentLifecycle.emergencyCancel(registry, platformAdmin);
        emit EmergencyCancellation(platformAdmin, block.timestamp);
    }

    function joinTournament(
        uint256 stakeAmount
    ) external notEmergencyCancelled {
        if (status != TournamentCore.Status.Open) revert InvalidStatus();
        if (players[msg.sender].exists) revert AlreadyJoined();

        TournamentPlayerActions.validateEntry(
            params.minStake,
            params.maxStake,
            params.maxPlayers,
            stakeAmount,
            playerCount
        );

        TournamentPlayerActions.processJoin(
            players[msg.sender],
            params.stakeToken,
            msg.sender,
            stakeAmount,
            params.coinConversionRate,
            params.initialLives,
            params.cardsPerType
        );

        playerAddresses.push(msg.sender);
        playerCount++;
        totalStaked += stakeAmount;

        // Check transition
        (
            TournamentCore.Status newStatus,
            uint32 newActualStartTime,
            uint32 newEndTime
        ) = TournamentLifecycle.checkAndTransition(
                status,
                params,
                playerCount,
                totalStaked,
                registry
            );

        status = newStatus;
        if (newActualStartTime > 0) actualStartTime = newActualStartTime;
        if (newEndTime > 0) endTime = newEndTime;
    }

    function exit()
        external
        onlyPlayer
        notEmergencyCancelled
        applyDecayFirst
        autoEndIfTimeUp
        onlyStatus(TournamentCore.Status.Active)
    {
        if (!canExit(msg.sender)) revert CannotExit();

        TournamentPlayerActions.processExit(players[msg.sender], msg.sender);
        winners.push(msg.sender);
        _checkEarlyEnd();
    }

    function forfeit()
        external
        onlyPlayer
        applyDecayFirst
        autoEndIfTimeUp
        onlyStatus(TournamentCore.Status.Active)
    {
        if (!params.forfeitAllowed) revert ForfeitNotAllowed();

        TournamentCore.PlayerResources storage player = players[msg.sender];
        if (player.status == TournamentCore.PlayerStatus.Forfeited)
            revert AlreadyForfeited();
        if (player.status == TournamentCore.PlayerStatus.Exited)
            revert AlreadyExited();

        uint256 penaltyAmount = calculateForfeitPenalty(msg.sender);

        TournamentPlayerActions.processForfeit(
            player,
            params.stakeToken,
            msg.sender,
            penaltyAmount
        );

        totalForfeitPenalties += penaltyAmount;
        _checkEarlyEnd();
    }

    function claimPrize() external onlyPlayer autoEndIfTimeUp {
        if (status != TournamentCore.Status.Ended) revert InvalidStatus();

        TournamentCore.PlayerResources storage player = players[msg.sender];
        if (player.status == TournamentCore.PlayerStatus.PrizeClaimed)
            revert AlreadyClaimed();
        if (player.status != TournamentCore.PlayerStatus.Exited)
            revert NotWinner();

        uint256 prizePerWinner = TournamentViews.calculatePrizePerWinner(
            totalStaked,
            totalForfeitPenalties,
            params.platformFeePercent,
            params.creatorFeePercent,
            winners.length
        );

        player.status = TournamentCore.PlayerStatus.PrizeClaimed;

        IERC20(params.stakeToken).safeTransfer(msg.sender, prizePerWinner);
        emit PrizeClaimed(msg.sender, prizePerWinner);
    }

    function claimRefund() external onlyPlayer {
        if (
            status == TournamentCore.Status.Active ||
            status == TournamentCore.Status.Ended
        ) {
            revert CannotRefundAfterStart();
        }

        TournamentCore.PlayerResources storage player = players[msg.sender];
        if (player.status == TournamentCore.PlayerStatus.Refunded)
            revert AlreadyClaimed();

        TournamentRefund.RefundContext memory context = TournamentRefund
            .RefundContext({
                status: status,
                stakeToken: params.stakeToken,
                maxPlayers: params.maxPlayers,
                startPlayerCount: params.startPlayerCount,
                startPoolAmount: params.startPoolAmount
            });

        (
            bool shouldDecrementCount,
            uint16 newPlayerCount,
            uint256 newTotalStaked,
            TournamentCore.Status newStatus
        ) = TournamentRefund.processRefund(
                player,
                context,
                registry,
                msg.sender,
                playerCount,
                totalStaked
            );

        if (shouldDecrementCount) {
            playerCount = newPlayerCount;
            totalStaked = newTotalStaked;
        }
        status = newStatus;
    }

    function collectCreatorFees() external autoEndIfTimeUp {
        if (msg.sender != creator) revert OnlyCreator();
        if (status != TournamentCore.Status.Ended) revert InvalidStatus();
        if (creatorFeesCollected) revert AlreadyClaimed();

        uint256 totalPrizePool = totalStaked + totalForfeitPenalties;
        uint256 creatorFee = (totalPrizePool * params.creatorFeePercent) / 100;

        creatorFeesCollected = true;

        IERC20(params.stakeToken).safeTransfer(creator, creatorFee);
        emit CreatorFeesCollected(creator, creatorFee);
    }

    function updateStatus() external autoUpdateStatus {}

    function getCurrentCoins(address player) public view returns (uint256) {
        return
            TournamentViews.getCurrentCoins(
                players[player],
                params.decayAmount,
                params.decayInterval
            );
    }

    function calculateExitCost(address player) public view returns (uint256) {
        return
            TournamentViews.calculateExitCost(
                status,
                players[player],
                actualStartTime,
                params.exitCostBasePercentBPS,
                params.exitCostCompoundRateBPS,
                params.exitCostInterval
            );
    }

    function canExit(address player) public view returns (bool) {
        uint256 currentCoins = getCurrentCoins(player);
        uint256 exitCost = calculateExitCost(player);

        return
            TournamentViews.canExit(
                status,
                players[player],
                currentCoins,
                exitCost,
                params.exitLivesRequired
            );
    }

    function calculateForfeitPenalty(
        address player
    ) public view returns (uint256) {
        return
            TournamentViews.calculateForfeitPenalty(
                players[player],
                endTime,
                params.duration,
                uint8(params.forfeitPenaltyType),
                params.forfeitMaxPenalty,
                params.forfeitMinPenalty
            );
    }

    function getCurrentPlayerResources(
        address player
    ) external view returns (TournamentCore.PlayerResources memory) {
        if (!players[player].exists) revert NotFound();
        uint256 currentCoins = getCurrentCoins(player);
        return
            TournamentViews.getCurrentPlayerResources(
                players[player],
                currentCoins
            );
    }

    function getWinners() external view returns (address[] memory) {
        return winners;
    }

    function getPlayerCount() external view returns (uint256) {
        return playerCount;
    }

    function getParams()
        external
        view
        returns (TournamentCore.TournamentParams memory)
    {
        return params;
    }

    function getPlayer(
        address player
    ) external view returns (TournamentCore.PlayerResources memory) {
        if (!players[player].exists) revert NotFound();
        return players[player];
    }

    function calculateRecommendedDuration(
        uint8 cardsPerType
    ) public pure returns (uint32) {
        return
            TournamentViews.calculateRecommendedDuration(
                cardsPerType,
                TournamentCore.RECOMMENDED_SECONDS_PER_CARD,
                TournamentCore.MIN_DURATION
            );
    }
}
