// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {TournamentCore} from "./../../core/TournamentCore.sol";

interface ITournamentHub {
    function getPlayer(
        address player
    ) external view returns (TournamentCore.PlayerResources memory);
    function updatePlayerResources(
        address player,
        TournamentCore.PlayerResources calldata resources
    ) external;
    function status() external view returns (TournamentCore.Status);
}

contract TournamentCombat is Initializable {
    address public hub;
    uint96 public totalCombats;
    address public gameOracle;
    uint256 public nextCombatId;
    uint32 public constant COMBAT_TIMEOUT = 300; // 5 minutes

    enum Outcome {
        P1Win,
        P2Win,
        Draw
    }

    struct CombatSession {
        address player1;
        address player2;
        uint32 startedAt;
        bool active;
    }

    struct Resolution {
        uint256 combatId;
        address player1;
        address player2;
        uint8 p1CardsBurned;
        uint8 p2CardsBurned;
        Outcome rpsOutcome;
        Outcome decision;
        bool modifierApplied;
        int16 p1LifeDelta;
        int16 p2LifeDelta;
        int256 p1CoinDelta;
        int256 p2CoinDelta;
        bytes32 proofHash;
    }

    mapping(uint256 => CombatSession) public combats;

    event CombatStarted(
        uint256 indexed combatId,
        address indexed p1,
        address indexed p2,
        uint32 timestamp
    );
    event CombatResolved(
        Resolution resolution,
        uint256 combatId,
        uint32 timestamp
    );
    event CombatTimedOut(
        uint256 indexed combatId,
        address indexed p1,
        address indexed p2,
        uint32 timestamp
    );

    error InvalidAddress();
    error OnlyGameOracle();
    error PlayerNotFound();
    error PlayerNotActive();
    error PlayerAlreadyInCombat();
    error PlayerNotInCombat();
    error InvalidOutcome();
    error SamePlayer();
    error InsufficientCards();
    error ResourceOverflow();
    error TournamentNotActive();
    error CombatNotFound();
    error CombatNotActive();
    error CombatNotTimedOut();
    error PlayerMismatch();

    modifier onlyGameOracle() {
        if (msg.sender != gameOracle) revert OnlyGameOracle();
        _;
    }

    modifier tournamentActive() {
        if (ITournamentHub(hub).status() != TournamentCore.Status.Active)
            revert TournamentNotActive();
        _;
    }

    function initialize(
        address _hub,
        address _gameOracle
    ) external initializer {
        if (_hub == address(0) || _gameOracle == address(0))
            revert InvalidAddress();
        hub = _hub;
        gameOracle = _gameOracle;
        nextCombatId = 1;
    }

    function startCombat(
        address p1,
        address p2
    ) external onlyGameOracle tournamentActive returns (uint256 combatId) {
        if (p1 == p2) revert SamePlayer();

        TournamentCore.PlayerResources memory player1 = ITournamentHub(hub)
            .getPlayer(p1);
        TournamentCore.PlayerResources memory player2 = ITournamentHub(hub)
            .getPlayer(p2);

        if (!player1.exists || !player2.exists) revert PlayerNotFound();
        if (
            player1.status != TournamentCore.PlayerStatus.Active ||
            player2.status != TournamentCore.PlayerStatus.Active
        ) revert PlayerNotActive();
        if (player1.inCombat || player2.inCombat)
            revert PlayerAlreadyInCombat();

        combatId = nextCombatId;
        unchecked {
            nextCombatId++;
        }

        combats[combatId] = CombatSession({
            player1: p1,
            player2: p2,
            startedAt: uint32(block.timestamp),
            active: true
        });

        player1.inCombat = true;
        player2.inCombat = true;

        ITournamentHub(hub).updatePlayerResources(p1, player1);
        ITournamentHub(hub).updatePlayerResources(p2, player2);

        emit CombatStarted(combatId, p1, p2, uint32(block.timestamp));
    }

    function resolveCombat(
        Resolution calldata r
    ) external onlyGameOracle tournamentActive {
        CombatSession storage combat = combats[r.combatId];

        if (!combat.active) revert CombatNotActive();
        if (combat.player1 != r.player1 || combat.player2 != r.player2)
            revert PlayerMismatch();

        address hubCache = hub;

        TournamentCore.PlayerResources memory p1 = ITournamentHub(hubCache)
            .getPlayer(r.player1);
        TournamentCore.PlayerResources memory p2 = ITournamentHub(hubCache)
            .getPlayer(r.player2);

        if (!p1.exists || !p2.exists) revert PlayerNotFound();
        if (
            p1.status != TournamentCore.PlayerStatus.Active ||
            p2.status != TournamentCore.PlayerStatus.Active
        ) revert PlayerNotActive();
        if (!p1.inCombat || !p2.inCombat) revert PlayerNotInCombat();

        if (r.rpsOutcome > Outcome.Draw || r.decision > Outcome.Draw)
            revert InvalidOutcome();
        if (p1.totalCards < r.p1CardsBurned || p2.totalCards < r.p2CardsBurned)
            revert InsufficientCards();

        p1.lives = _applyLife(p1.lives, r.p1LifeDelta);
        p2.lives = _applyLife(p2.lives, r.p2LifeDelta);
        p1.coins = _applyCoin(p1.coins, r.p1CoinDelta);
        p2.coins = _applyCoin(p2.coins, r.p2CoinDelta);

        p1.inCombat = false;
        p2.inCombat = false;

        unchecked {
            p1.totalCards -= r.p1CardsBurned;
            p2.totalCards -= r.p2CardsBurned;
            p1.combatCount++;
            p2.combatCount++;
            totalCombats++;
        }

        combat.active = false;

        ITournamentHub(hubCache).updatePlayerResources(r.player1, p1);
        ITournamentHub(hubCache).updatePlayerResources(r.player2, p2);

        emit CombatResolved(r, r.combatId, uint32(block.timestamp));
    }

    function timeoutCombat(uint256 combatId) external {
        CombatSession storage combat = combats[combatId];

        if (!combat.active) revert CombatNotActive();
        if (block.timestamp < combat.startedAt + COMBAT_TIMEOUT)
            revert CombatNotTimedOut();

        // Release players from combat
        TournamentCore.PlayerResources memory p1 = ITournamentHub(hub)
            .getPlayer(combat.player1);
        TournamentCore.PlayerResources memory p2 = ITournamentHub(hub)
            .getPlayer(combat.player2);

        p1.inCombat = false;
        p2.inCombat = false;

        combat.active = false;

        ITournamentHub(hub).updatePlayerResources(combat.player1, p1);
        ITournamentHub(hub).updatePlayerResources(combat.player2, p2);

        emit CombatTimedOut(
            combatId,
            combat.player1,
            combat.player2,
            uint32(block.timestamp)
        );
    }

    function _applyLife(
        uint8 current,
        int16 delta
    ) internal pure returns (uint8) {
        if (delta >= 0) {
            uint256 result = uint256(current) + uint256(uint16(delta));
            if (result > type(uint8).max) revert ResourceOverflow();
            return uint8(result);
        }
        uint16 abs = uint16(-delta);
        return current < abs ? 0 : current - uint8(abs);
    }

    function _applyCoin(
        uint256 current,
        int256 delta
    ) internal pure returns (uint256) {
        if (delta >= 0) return current + uint256(delta);
        uint256 abs = uint256(-delta);
        return current < abs ? 0 : current - abs;
    }

    function getCombat(
        uint256 combatId
    ) external view returns (CombatSession memory) {
        return combats[combatId];
    }

    function isCombatActive(uint256 combatId) external view returns (bool) {
        return combats[combatId].active;
    }
}
