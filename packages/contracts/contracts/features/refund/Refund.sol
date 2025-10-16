// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {TournamentCore} from "../../core/TournamentCore.sol";
import {TournamentRegistry} from "../tournament-registry/TournamentRegistry.sol";
import {TournamentLifecycle} from "./../lifecycle/Lifecycle.sol";

library TournamentRefund {
    using SafeERC20 for IERC20;

    event RefundClaimed(address indexed player, uint256 amount);

    struct RefundContext {
        TournamentCore.Status status;
        address stakeToken;
        uint16 maxPlayers;
        uint16 startPlayerCount;
        uint256 startPoolAmount;
    }

    function processRefund(
        TournamentCore.PlayerResources storage player,
        RefundContext memory context,
        TournamentRegistry registry,
        address sender,
        uint16 playerCount,
        uint256 totalStaked
    )
        external
        returns (
            bool shouldDecrementCount,
            uint16 newPlayerCount,
            uint256 newTotalStaked,
            TournamentCore.Status newStatus
        )
    {
        uint256 refundAmount = player.stakeAmount;
        newStatus = context.status;
        newPlayerCount = playerCount;
        newTotalStaked = totalStaked;
        shouldDecrementCount = false;

        // Voluntary withdrawal (Open/Locked/PendingStart)
        if (context.status != TournamentCore.Status.Cancelled) {
            player.exists = false;
            shouldDecrementCount = true;
            newPlayerCount = playerCount - 1;
            newTotalStaked = totalStaked - refundAmount;

            // Unlock tournament if needed
            if (
                context.status == TournamentCore.Status.Locked &&
                (context.maxPlayers == 0 || newPlayerCount < context.maxPlayers)
            ) {
                newStatus = TournamentCore.Status.Open;
                TournamentLifecycle.transitionToOpen(registry);
            }

            // Revert PendingStart to Open if conditions broken
            if (
                context.status == TournamentCore.Status.PendingStart &&
                !areStartConditionsMet(
                    context.startPlayerCount,
                    context.startPoolAmount,
                    newPlayerCount,
                    newTotalStaked
                )
            ) {
                newStatus = TournamentCore.Status.Open;
                TournamentLifecycle.transitionToOpen(registry);
                TournamentLifecycle.emitRevertToOpen();
            }
        }

        player.status = TournamentCore.PlayerStatus.Refunded;
        IERC20(context.stakeToken).safeTransfer(sender, refundAmount);
        emit RefundClaimed(sender, refundAmount);
    }

    function areStartConditionsMet(
        uint16 startPlayerCount,
        uint256 startPoolAmount,
        uint16 currentPlayerCount,
        uint256 currentTotalStaked
    ) internal pure returns (bool) {
        if (startPlayerCount > 0 && currentPlayerCount < startPlayerCount) {
            return false;
        }
        if (startPoolAmount > 0 && currentTotalStaked < startPoolAmount) {
            return false;
        }
        return true;
    }
}
