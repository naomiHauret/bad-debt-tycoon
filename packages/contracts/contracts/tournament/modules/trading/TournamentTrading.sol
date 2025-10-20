// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract TournamentTrading is Initializable {
    address public hub;

    error InvalidAddress();
    error Unauthorized();

    modifier onlyHub() {
        if (msg.sender != hub) revert Unauthorized();
        _;
    }

    function initialize(address _hub) external initializer {
        if (_hub == address(0)) revert InvalidAddress();
        hub = _hub;
    }

    // TBD
}
