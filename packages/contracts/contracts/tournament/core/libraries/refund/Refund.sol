// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {TournamentRegistry} from "./../../../infrastructure/registry/TournamentRegistry.sol";
import {TournamentCore} from "./../../TournamentCore.sol";
import {TournamentLifecycle} from "./../lifecycle/Lifecycle.sol";

library TournamentRefund {
    using SafeERC20 for IERC20;

    event RefundClaimed(address indexed player, uint256 amount);

    struct RefundContext {
        address stakeToken;
        TournamentCore.Status status;
        uint16 maxPlayers;
        uint16 startPlayerCount;
        uint256 startPoolAmount;
    }

    function processRefund(
        TournamentCore.PlayerResources storage player,
        RefundContext calldata context,
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
        TournamentCore.Status currentStatus = context.status;

        // Handle cancelled tournament (simple case)
        if (currentStatus == TournamentCore.Status.Cancelled) {
            newStatus = currentStatus;
            newPlayerCount = playerCount;
            newTotalStaked = totalStaked;
            shouldDecrementCount = false;
        }
        // Handle voluntary withdrawal
        else {
            player.exists = false;
            shouldDecrementCount = true;

            unchecked {
                newPlayerCount = playerCount - 1;
                newTotalStaked = totalStaked - refundAmount;
            }

            // Determine new status based on current status
            if (currentStatus == TournamentCore.Status.Locked) {
                if (
                    context.maxPlayers == 0 ||
                    newPlayerCount < context.maxPlayers
                ) {
                    newStatus = TournamentCore.Status.Open;
                    TournamentLifecycle.transitionToOpen(registry);
                } else {
                    newStatus = currentStatus;
                }
            } else if (currentStatus == TournamentCore.Status.PendingStart) {
                if (
                    !_areStartConditionsMet(
                        context.startPlayerCount,
                        context.startPoolAmount,
                        newPlayerCount,
                        newTotalStaked
                    )
                ) {
                    newStatus = TournamentCore.Status.Open;
                    TournamentLifecycle.transitionToOpen(registry);
                    TournamentLifecycle.emitRevertToOpen();
                } else {
                    newStatus = currentStatus;
                }
            } else {
                newStatus = currentStatus;
            }
        }

        player.status = TournamentCore.PlayerStatus.Refunded;
        IERC20(context.stakeToken).safeTransfer(sender, refundAmount);
        emit RefundClaimed(sender, refundAmount);
    }

    function _areStartConditionsMet(
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
