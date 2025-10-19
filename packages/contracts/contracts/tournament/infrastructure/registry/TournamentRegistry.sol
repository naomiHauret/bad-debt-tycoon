// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import {TournamentCore} from "./../../core/TournamentCore.sol";

/**
 * Architecture:
 * - Each tournament = 5 contracts (Hub and 4 modules: Combat, Deck, Trading, Randomizer)
 * - Hub is the primary contract - owns player state, updates status
 * - Registry tracks complete systems and provides reverse lookups
 */
contract TournamentRegistry is Ownable {
    struct TournamentSystem {
        address hub;
        address combat;
        address mysteryDeck;
        address trading;
        address randomizer;
        bool exists;
    }

    mapping(address => bool) private _hasFactoryRole;

    // Tournament tracking (by hub address - primary)
    address[] private _allTournaments;
    mapping(address => TournamentSystem) private _tournamentSystems;
    mapping(address => bool) private _isRegistered;

    // Status tracking (by hub address)
    mapping(address => TournamentCore.Status) private _tournamentStatus;
    mapping(TournamentCore.Status => address[]) private _tournamentsByStatus;
    mapping(address => mapping(TournamentCore.Status => uint256))
        private _tournamentStatusIndex;

    // Reverse lookups (module address => hub address)
    mapping(address => address) private _moduleToHub;

    event FactoryRoleGranted(address indexed factory);
    event FactoryRoleRevoked(address indexed factory);
    event TournamentSystemRegistered(
        address indexed hub,
        address indexed combat,
        address mysteryDeck,
        address trading,
        address randomizer,
        TournamentCore.Status initialStatus
    );
    event TournamentStatusUpdated(
        address indexed hub,
        TournamentCore.Status oldStatus,
        TournamentCore.Status newStatus
    );

    error InvalidAddress();
    error OnlyFactory();
    error OnlyHub();
    error AlreadyRegistered();
    error NotRegistered();
    error ModuleAlreadyUsed();

    modifier onlyRegisteredHub(address hub) {
        if (!_isRegistered[hub]) revert NotRegistered();
        _;
    }

    constructor() Ownable(msg.sender) {}

    function grantFactoryRole(address factory) external onlyOwner {
        if (factory == address(0)) revert InvalidAddress();
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

    /**
     * @notice Register a complete tournament system (5 contracts)
     * @dev Called by TournamentFactory after deploying all 5 minimal proxies
     * Validates all addresses and ensures no module is reused across tournaments
     */
    function registerTournamentSystem(
        address hub,
        address combat,
        address mysteryDeck,
        address trading,
        address randomizer
    ) external {
        if (!_hasFactoryRole[msg.sender]) revert OnlyFactory();
        if (_isRegistered[hub]) revert AlreadyRegistered();
        if (
            hub == address(0) ||
            combat == address(0) ||
            randomizer == address(0) ||
            trading == address(0) ||
            mysteryDeck == address(0)
        ) revert InvalidAddress();

        if (
            _moduleToHub[combat] != address(0) ||
            _moduleToHub[randomizer] != address(0) ||
            _moduleToHub[mysteryDeck] != address(0) ||
            _moduleToHub[trading] != address(0)
        ) revert ModuleAlreadyUsed();

        _tournamentSystems[hub] = TournamentSystem({
            hub: hub,
            combat: combat,
            mysteryDeck: mysteryDeck,
            trading: trading,
            randomizer: randomizer,
            exists: true
        });

        _isRegistered[hub] = true;
        _allTournaments.push(hub);

        // Setup reverse lookup
        _moduleToHub[hub] = hub; // Hub points to itself
        _moduleToHub[combat] = hub;
        _moduleToHub[mysteryDeck] = hub;
        _moduleToHub[trading] = hub;
        _moduleToHub[randomizer] = hub;

        // Status tracking
        TournamentCore.Status initialStatus = TournamentCore.Status.Open;
        _tournamentStatus[hub] = initialStatus;

        uint256 statusArrayLength = _tournamentsByStatus[initialStatus].length;
        _tournamentStatusIndex[hub][initialStatus] = statusArrayLength;
        _tournamentsByStatus[initialStatus].push(hub);

        emit TournamentSystemRegistered(
            hub,
            combat,
            mysteryDeck,
            trading,
            randomizer,
            initialStatus
        );
    }

    function updateTournamentStatus(TournamentCore.Status newStatus) external {
        address hub = msg.sender;

        if (!_isRegistered[hub]) revert NotRegistered();
        if (_tournamentSystems[hub].hub != hub) revert OnlyHub();

        TournamentCore.Status oldStatus = _tournamentStatus[hub];

        // Early exit if status hasn't changed
        if (oldStatus == newStatus) return;

        // Remove from old status array
        _removeFromStatusArray(hub, oldStatus);

        // Add to new status array
        uint256 newStatusArrayLength = _tournamentsByStatus[newStatus].length;
        _tournamentStatusIndex[hub][newStatus] = newStatusArrayLength;
        _tournamentsByStatus[newStatus].push(hub);
        _tournamentStatus[hub] = newStatus;

        emit TournamentStatusUpdated(hub, oldStatus, newStatus);
    }

    function _removeFromStatusArray(
        address hub,
        TournamentCore.Status status
    ) private onlyRegisteredHub(hub) {
        uint256 indexToRemove = _tournamentStatusIndex[hub][status];

        unchecked {
            // Safe: array length is always > 0 when removing (hub is registered in this status)
            uint256 lastIndex = _tournamentsByStatus[status].length - 1;

            if (indexToRemove != lastIndex) {
                address lastTournament = _tournamentsByStatus[status][
                    lastIndex
                ];
                _tournamentsByStatus[status][indexToRemove] = lastTournament;
                _tournamentStatusIndex[lastTournament][status] = indexToRemove;
            }

            _tournamentsByStatus[status].pop();
        }
    }

    /**
     * @notice Get complete tournament system by hub address
     */
    function getTournamentSystem(
        address hub
    ) external view onlyRegisteredHub(hub) returns (TournamentSystem memory) {
        return _tournamentSystems[hub];
    }

    /**
     * @notice Get hub address from any module address
     * @dev Useful when you have a Combat/Deck/Trading/Randomizer address
     */
    function getHubAddress(
        address moduleAddress
    ) external view returns (address) {
        address hub = _moduleToHub[moduleAddress];
        if (hub == address(0)) revert NotRegistered();
        return hub;
    }

    /**
     * @notice Get tournament system by any module address
     */
    function getTournamentSystemByModule(
        address moduleAddress
    ) external view returns (TournamentSystem memory) {
        address hub = _moduleToHub[moduleAddress];
        if (hub == address(0)) revert NotRegistered();
        return _tournamentSystems[hub];
    }

    /**
     * @notice Get all tournament hub addresses
     */
    function getAllTournaments() external view returns (address[] memory) {
        return _allTournaments;
    }

    /**
     * @notice Get tournaments by status (returns hub addresses)
     */
    function getTournamentsByStatus(
        TournamentCore.Status status
    ) external view returns (address[] memory) {
        return _tournamentsByStatus[status];
    }

    function getTournamentStatus(
        address hub
    ) external view onlyRegisteredHub(hub) returns (uint8) {
        return uint8(_tournamentStatus[hub]);
    }

    function isTournamentRegistered(address hub) external view returns (bool) {
        return _isRegistered[hub];
    }

    function isModuleRegistered(
        address moduleAddress
    ) external view returns (bool) {
        return _moduleToHub[moduleAddress] != address(0);
    }

    function getTournamentCount() external view returns (uint256) {
        return _allTournaments.length;
    }
}
