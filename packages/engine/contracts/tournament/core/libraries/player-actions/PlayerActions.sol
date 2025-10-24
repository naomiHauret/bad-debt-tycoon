// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {TournamentCore} from "./../../TournamentCore.sol";

library TournamentPlayerActions {
    using SafeERC20 for IERC20;

    event PlayerJoined(
        address indexed player,
        uint256 stakeAmount,
        uint256 initialCoins,
        uint32 exitTime
    );
    event PlayerExited(address indexed player, uint32 exitTime);
    event PlayerForfeited(
        address indexed player,
        uint256 penaltyAmount,
        uint256 refundAmount,
        uint32 exitTime
    );
    event DecayApplied(
        address indexed player,
        uint256 decayAmount,
        uint256 remainingCoins
    );

    error StakeTooLow();
    error StakeTooHigh();
    error TournamentFull();

    function validateEntry(
        uint256 minStake,
        uint256 maxStake,
        uint16 maxPlayers,
        uint256 stakeAmount,
        uint16 playerCount
    ) external pure {
        if (minStake > 0 && stakeAmount < minStake) revert StakeTooLow();
        if (maxStake > 0 && stakeAmount > maxStake) revert StakeTooHigh();
        if (maxPlayers > 0 && playerCount >= maxPlayers)
            revert TournamentFull();
    }

    function processJoin(
        TournamentCore.PlayerResources storage player,
        address stakeToken,
        address sender,
        uint256 stakeAmount,
        uint40 coinConversionRate,
        uint8 initialLives,
        uint8 cardsPerType
    ) external returns (uint256 initialCoins) {
        IERC20(stakeToken).safeTransferFrom(sender, address(this), stakeAmount);

        initialCoins = stakeAmount * coinConversionRate;
        uint32 timestamp = uint32(block.timestamp);

        player.initialCoins = initialCoins;
        player.coins = initialCoins;
        player.stakeAmount = stakeAmount;
        player.lastDecayTimestamp = timestamp;
        player.lives = initialLives;
        player.totalCards = cardsPerType * 3;
        player.status = TournamentCore.PlayerStatus.Active;
        player.exists = true;
        player.inCombat = false;

        emit PlayerJoined(sender, stakeAmount, initialCoins, timestamp);
    }

    function processExit(
        TournamentCore.PlayerResources storage player,
        address sender
    ) external {
        player.status = TournamentCore.PlayerStatus.Exited;
        emit PlayerExited(sender, uint32(block.timestamp));
    }

    function processForfeit(
        TournamentCore.PlayerResources storage player,
        address stakeToken,
        address sender,
        uint256 penaltyAmount
    ) external returns (uint256 refundAmount) {
        unchecked {
            refundAmount = player.stakeAmount - penaltyAmount;
        }
        player.status = TournamentCore.PlayerStatus.Forfeited;

        IERC20(stakeToken).safeTransfer(sender, refundAmount);
        emit PlayerForfeited(
            sender,
            penaltyAmount,
            refundAmount,
            uint32(block.timestamp)
        );
    }

    function applyDecay(
        TournamentCore.PlayerResources storage player,
        address sender,
        uint256 decayAmount,
        uint32 gameInterval
    ) external {
        uint32 timestamp = uint32(block.timestamp);
        uint256 intervalsPassed;

        unchecked {
            // Safe: tournament duration limits + validated decayAmount
            // make overflow mathematically impossible
            intervalsPassed =
                (timestamp - player.lastDecayTimestamp) /
                gameInterval;
        }

        if (intervalsPassed > 0) {
            uint256 currentCoins = player.coins;
            uint256 totalDecay;
            uint256 remainingCoins;

            totalDecay = decayAmount * intervalsPassed;

            // Clamp to available coins
            if (currentCoins > totalDecay) {
                unchecked {
                    remainingCoins = currentCoins - totalDecay;
                }
            } else {
                totalDecay = currentCoins; // Adjust to actual decay
                remainingCoins = 0;
            }

            player.coins = remainingCoins;
            player.lastDecayTimestamp = timestamp;

            emit DecayApplied(sender, totalDecay, remainingCoins);
        }
    }
}
