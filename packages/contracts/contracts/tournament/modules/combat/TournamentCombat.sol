// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract TournamentCombat is Initializable {
    address public hub;
    address public randomizer;

    error InvalidAddress();
    error Unauthorized();

    modifier onlyHub() {
        if (msg.sender != hub) revert Unauthorized();
        _;
    }

    function initialize(
        address _hub,
        address _randomizer
    ) external initializer {
        if (_hub == address(0) || _randomizer == address(0)) {
            revert InvalidAddress();
        }

        hub = _hub;
        randomizer = _randomizer;
    }

    // Future implementation:
    // - Fight resolution (rock-paper-scissors)
    // - Modifier application (from mystery cards)
    // - Life changes
    // - Combat oracle integration
}
