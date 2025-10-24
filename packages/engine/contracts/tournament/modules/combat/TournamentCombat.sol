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
}

contract TournamentCombat is Initializable {
    address public hub;
    uint96 public totalCombats;
    address public gameOracle;

    enum Outcome {
        P1Win,
        P2Win,
        Draw
    }

    struct Resolution {
        address player1;
        uint8 p1CardsBurned;
        uint8 p2CardsBurned;
        Outcome rpsOutcome;
        Outcome decision;
        bool modifierApplied;
        int16 p1LifeDelta;
        int16 p2LifeDelta;
        address player2;
        int256 p1CoinDelta;
        int256 p2CoinDelta;
        bytes32 proofHash;
    }

    event CombatResolved(Resolution resolution, uint256 combatId);

    error InvalidAddress();
    error OnlyGameOracle();
    error PlayerNotFound();
    error InvalidOutcome();
    error SamePlayer();
    error InsufficientCards();
    error ResourceOverflow();

    modifier onlyGameOracle() {
        if (msg.sender != gameOracle) revert OnlyGameOracle();
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
    }

    function resolveCombat(Resolution calldata r) external onlyGameOracle {
        if (r.player1 == r.player2) revert SamePlayer();
        address hubCache = hub;

        TournamentCore.PlayerResources memory p1 = ITournamentHub(hubCache)
            .getPlayer(r.player1);
        TournamentCore.PlayerResources memory p2 = ITournamentHub(hubCache)
            .getPlayer(r.player2);

        if (
            !p1.exists ||
            !p2.exists ||
            p1.status != TournamentCore.PlayerStatus.Active ||
            p2.status != TournamentCore.PlayerStatus.Active
        ) revert PlayerNotFound();

        if (r.rpsOutcome > Outcome.Draw || r.decision > Outcome.Draw)
            revert InvalidOutcome();

        if (p1.totalCards < r.p1CardsBurned || p2.totalCards < r.p2CardsBurned)
            revert InsufficientCards();

        p1.lives = _applyLife(p1.lives, r.p1LifeDelta);
        p2.lives = _applyLife(p2.lives, r.p2LifeDelta);

        p1.coins = _applyCoin(p1.coins, r.p1CoinDelta);
        p2.coins = _applyCoin(p2.coins, r.p2CoinDelta);

        unchecked {
            p1.totalCards -= r.p1CardsBurned;
            p2.totalCards -= r.p2CardsBurned;
            p1.combatCount++;
            p2.combatCount++;
            totalCombats++;
        }

        ITournamentHub(hubCache).updatePlayerResources(r.player1, p1);
        ITournamentHub(hubCache).updatePlayerResources(r.player2, p2);

        emit CombatResolved(r, totalCombats);
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
}
