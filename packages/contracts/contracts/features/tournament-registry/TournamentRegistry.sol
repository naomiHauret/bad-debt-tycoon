// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import {TournamentCore} from "./../../core/TournamentCore.sol";

contract TournamentRegistry is Ownable {
    // Mapping contract address  -> flag
    mapping(address => bool) private _hasFactoryRole;

    address[] private _allTournaments;

    // Mapping tournament address  -> flag
    mapping(address => bool) private _isRegistered;

    // Mapping tournament address -> status
    mapping(address => TournamentCore.Status) private _tournamentStatus;

    // Mapping status -> tournament addresses
    mapping(TournamentCore.Status => address[]) private _tournamentsByStatus;

    // Mapping tournament address -> index in status-specific array
    mapping(address => mapping(TournamentCore.Status => uint256))
        private _tournamentStatusIndex;

    event FactoryRoleGranted(address indexed factory);
    event FactoryRoleRevoked(address indexed factory);
    event TournamentRegistered(
        address indexed tournament,
        TournamentCore.Status status
    );
    event TournamentStatusUpdated(
        address indexed tournament,
        TournamentCore.Status oldStatus,
        TournamentCore.Status newStatus
    );

    error InvalidAddress();
    error OnlyFactory();
    error OnlyTournament();
    error AlreadyRegistered();
    error NotRegistered();

    modifier onlyRegisteredTournament(address tournament) {
        if (!_isRegistered[tournament]) {
            revert NotRegistered();
        }
        _;
    }

    constructor() Ownable(msg.sender) {}

    function grantFactoryRole(address factory) external onlyOwner {
        if (factory == address(0)) {
            revert InvalidAddress();
        }
        _hasFactoryRole[factory] = true;
        emit FactoryRoleGranted(factory);
    }

    function revokeFactoryRole(address factory) external onlyOwner {
        _hasFactoryRole[factory] = false;
        emit FactoryRoleRevoked(factory);
    }

    function hasFactoryRole(address factory) external view returns (bool) {
        return _hasFactoryRole[factory];
    }

    function registerTournament(address tournament) external {
        if (!_hasFactoryRole[msg.sender]) {
            revert OnlyFactory();
        }
        if (tournament == address(0)) {
            revert InvalidAddress();
        }
        if (_isRegistered[tournament]) {
            revert AlreadyRegistered();
        }

        _isRegistered[tournament] = true;
        _allTournaments.push(tournament);

        TournamentCore.Status initialStatus = TournamentCore.Status.Open;
        _tournamentStatus[tournament] = initialStatus;
        _tournamentStatusIndex[tournament][
            initialStatus
        ] = _tournamentsByStatus[initialStatus].length;
        _tournamentsByStatus[initialStatus].push(tournament);

        emit TournamentRegistered(tournament, initialStatus);
    }

    function updateTournamentStatus(TournamentCore.Status newStatus) external {
        if (!_isRegistered[msg.sender]) {
            revert NotRegistered();
        }

        address tournament = msg.sender;
        TournamentCore.Status oldStatus = _tournamentStatus[tournament];

        // Exit if status hasn't changed
        if (oldStatus == newStatus) {
            return;
        }

        _removeFromStatusArray(tournament, oldStatus);

        _tournamentStatusIndex[tournament][newStatus] = _tournamentsByStatus[
            newStatus
        ].length;
        _tournamentsByStatus[newStatus].push(tournament);
        _tournamentStatus[tournament] = newStatus;
        emit TournamentStatusUpdated(tournament, oldStatus, newStatus);
    }

    function _removeFromStatusArray(
        address tournament,
        TournamentCore.Status status
    ) private onlyRegisteredTournament(tournament) {
        uint256 indexToRemove = _tournamentStatusIndex[tournament][status];
        uint256 lastIndex = _tournamentsByStatus[status].length - 1;

        if (indexToRemove != lastIndex) {
            address lastTournament = _tournamentsByStatus[status][lastIndex];
            _tournamentsByStatus[status][indexToRemove] = lastTournament;
            _tournamentStatusIndex[lastTournament][status] = indexToRemove;
        }

        _tournamentsByStatus[status].pop();
    }

    function getAllTournaments() external view returns (address[] memory) {
        return _allTournaments;
    }

    function getTournamentsByStatus(
        TournamentCore.Status status
    ) external view returns (address[] memory) {
        return _tournamentsByStatus[status];
    }

    function getTournamentStatus(
        address tournament
    ) external view onlyRegisteredTournament(tournament) returns (uint8) {
        return uint8(_tournamentStatus[tournament]);
    }

    function isTournamentRegistered(
        address tournament
    ) external view returns (bool) {
        return _isRegistered[tournament];
    }

    function getTournamentCount() external view returns (uint256) {
        return _allTournaments.length;
    }
}
