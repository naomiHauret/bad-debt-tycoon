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

        player.initialCoins = initialCoins;
        player.coins = initialCoins;
        player.stakeAmount = stakeAmount;
        player.lastDecayTimestamp = uint32(block.timestamp);
        player.lives = initialLives;
        player.totalCards = cardsPerType * 3;
        player.status = TournamentCore.PlayerStatus.Active;
        player.exists = true;

        emit PlayerJoined(
            sender,
            stakeAmount,
            initialCoins,
            uint32(block.timestamp)
        );
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
        refundAmount = player.stakeAmount - penaltyAmount;
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
        uint256 intervalsPassed = (block.timestamp -
            player.lastDecayTimestamp) / gameInterval;

        if (intervalsPassed > 0) {
            uint256 totalDecay = decayAmount * intervalsPassed;
            uint256 actualDecay;

            if (player.coins > totalDecay) {
                actualDecay = totalDecay;
                player.coins -= totalDecay;
            } else {
                actualDecay = player.coins;
                player.coins = 0;
            }

            player.lastDecayTimestamp = uint32(block.timestamp);
            emit DecayApplied(sender, actualDecay, player.coins);
        }
    }

    function countActivePlayers(
        address[] storage playerAddresses,
        mapping(address => TournamentCore.PlayerResources) storage players
    ) external view returns (uint256 activeCount) {
        for (uint256 i = 0; i < playerAddresses.length; i++) {
            if (
                players[playerAddresses[i]].status ==
                TournamentCore.PlayerStatus.Active
            ) {
                activeCount++;
            }
        }
    }
}
