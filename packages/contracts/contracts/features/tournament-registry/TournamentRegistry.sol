// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Central registry for tracking all tournaments and their statuses
 */
contract TournamentRegistry is Ownable {
    enum TournamentStatus {
        Open, // Accepting players
        Active, // Game in progress
        Ended, // Finished normally
        Cancelled // Start conditions not met
    }

    // Addresses authorized to register tournaments
    mapping(address => bool) private _hasFactoryRole;

    address[] private _allTournaments;

    // Mapping to check if a tournament is registered
    mapping(address => bool) private _isRegistered;

    // Mapping from tournament address to its current status
    mapping(address => TournamentStatus) private _tournamentStatus;

    // Mapping from status to array of tournament addresses
    mapping(TournamentStatus => address[]) private _tournamentsByStatus;

    // Mapping from tournament to its index in status-specific array
    mapping(address => mapping(TournamentStatus => uint256))
        private _tournamentStatusIndex;

    // Events
    event FactoryRoleGranted(address indexed factory);
    event FactoryRoleRevoked(address indexed factory);
    event TournamentRegistered(
        address indexed tournament,
        TournamentStatus status
    );
    event TournamentStatusUpdated(
        address indexed tournament,
        TournamentStatus oldStatus,
        TournamentStatus newStatus
    );

    // Errors
    error InvalidAddress();
    error OnlyFactory();
    error OnlyTournament();
    error TournamentAlreadyRegistered();
    error TournamentNotRegistered();

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
            revert TournamentAlreadyRegistered();
        }

        _isRegistered[tournament] = true;
        _allTournaments.push(tournament);

        // Initialize with "open" status
        TournamentStatus initialStatus = TournamentStatus.Open;
        _tournamentStatus[tournament] = initialStatus;
        _tournamentStatusIndex[tournament][
            initialStatus
        ] = _tournamentsByStatus[initialStatus].length;
        _tournamentsByStatus[initialStatus].push(tournament);

        emit TournamentRegistered(tournament, initialStatus);
    }

    /**
     * Update tournament status
     * Only callable by the tournament contract itself
     */
    function updateTournamentStatus(TournamentStatus newStatus) external {
        if (!_isRegistered[msg.sender]) {
            revert TournamentNotRegistered();
        }

        address tournament = msg.sender;
        TournamentStatus oldStatus = _tournamentStatus[tournament];

        // Exit if status hasn't changed
        if (oldStatus == newStatus) {
            return;
        }

        // Remove from old status array
        _removeFromStatusArray(tournament, oldStatus);

        // Add to new status array
        _tournamentStatusIndex[tournament][newStatus] = _tournamentsByStatus[
            newStatus
        ].length;
        _tournamentsByStatus[newStatus].push(tournament);

        // Update status mapping
        _tournamentStatus[tournament] = newStatus;

        emit TournamentStatusUpdated(tournament, oldStatus, newStatus);
    }

    function _removeFromStatusArray(
        address tournament,
        TournamentStatus status
    ) private {
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
        TournamentStatus status
    ) external view returns (address[] memory) {
        return _tournamentsByStatus[status];
    }

    function getTournamentStatus(
        address tournament
    ) external view returns (uint8) {
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
