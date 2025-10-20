// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {TournamentCore} from "./../../../../core/TournamentCore.sol";
import {TournamentViews} from "./../../../../core/libraries/views/Views.sol";

library TournamentHubPrize {
    using SafeERC20 for IERC20;

    event PrizeClaimed(address indexed player, uint256 amount);
    event CreatorFeesCollected(address indexed creator, uint256 amount);

    error NotWinner();
    error AlreadyClaimed();
    error InvalidStatus();
    error NoWinners();
    error OnlyCreator();

    function claimPrize(
        mapping(address => TournamentCore.PlayerResources) storage players,
        TournamentCore.Params storage params,
        TournamentCore.Status status,
        uint256 totalStaked,
        uint256 totalForfeitPenalties,
        uint256 winnersLength,
        address sender
    ) external {
        if (status != TournamentCore.Status.Ended) revert InvalidStatus();
        if (winnersLength == 0) revert NoWinners();

        TournamentCore.PlayerResources storage player = players[sender];
        if (player.status == TournamentCore.PlayerStatus.PrizeClaimed)
            revert AlreadyClaimed();
        if (player.status != TournamentCore.PlayerStatus.Exited)
            revert NotWinner();

        uint256 prizePerWinner = TournamentViews.calculatePrizePerWinner(
            totalStaked,
            totalForfeitPenalties,
            params.platformFeePercent,
            params.creatorFeePercent,
            winnersLength
        );

        player.status = TournamentCore.PlayerStatus.PrizeClaimed;

        IERC20(params.stakeToken).safeTransfer(sender, prizePerWinner);
        emit PrizeClaimed(sender, prizePerWinner);
    }

    function collectCreatorFees(
        TournamentCore.Params storage params,
        TournamentCore.Status status,
        uint256 totalStaked,
        uint256 totalForfeitPenalties,
        address creator,
        address sender
    ) external returns (bool) {
        if (sender != creator) revert OnlyCreator();
        if (status != TournamentCore.Status.Ended) revert InvalidStatus();

        uint256 totalPrizePool = totalStaked + totalForfeitPenalties;

        unchecked {
            uint256 creatorFee = (totalPrizePool * params.creatorFeePercent) /
                100;
            IERC20(params.stakeToken).safeTransfer(creator, creatorFee);
            emit CreatorFeesCollected(creator, creatorFee);
        }

        return true;
    }
}
