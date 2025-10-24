// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {TournamentCore} from "./../../core/TournamentCore.sol";

interface ITournamentHub {
    function getPlayer(
        address player
    ) external view returns (TournamentCore.PlayerResources memory);
    function updatePlayerResources(
        address player,
        TournamentCore.PlayerResources calldata resources
    ) external;
    function getParams() external view returns (TournamentCore.Params memory);
    function status() external view returns (TournamentCore.Status);
}

contract TournamentTrading is Initializable {
    address public hub;
    address public gameOracle;

    uint256 public nextOfferId;
    uint256 public totalTradesExecuted;

    enum OfferStatus {
        Open,
        Cancelled,
        Executed
    }

    struct ResourceBundle {
        uint8 lives;
        uint256 coins;
        uint8 rockCards;
        uint8 paperCards;
        uint8 scissorsCards;
    }

    struct TradeOffer {
        address creator;
        uint32 expiresAt;
        OfferStatus status;
        bool exists;
        ResourceBundle offered;
        ResourceBundle requested;
    }

    mapping(uint256 => TradeOffer) public offers;
    mapping(address => uint256[]) private playerOffers;

    event OfferCreated(
        uint256 indexed offerId,
        address indexed creator,
        ResourceBundle offered,
        ResourceBundle requested,
        uint32 expiresAt,
        uint32 createdAt
    );

    event OfferCancelled(
        uint256 indexed offerId,
        address indexed creator,
        uint32 timestamp
    );

    event TradeExecuted(
        uint256 indexed offerId,
        address indexed creator,
        address indexed acceptor,
        uint8 creatorTotalCardsDelta,
        uint8 acceptorTotalCardsDelta,
        uint32 timestamp
    );

    error InvalidAddress();
    error OnlyGameOracle();
    error PlayerNotFound();
    error PlayerNotActive();
    error PlayerInCombat();
    error OfferNotFound();
    error OfferExpired();
    error OfferNotActive();
    error NotOfferCreator();
    error InsufficientResources();
    error ResourceOverflow();
    error TournamentNotActive();
    error InvalidCardDeltas();

    modifier onlyGameOracle() {
        if (msg.sender != gameOracle) revert OnlyGameOracle();
        _;
    }

    modifier onlyActivePlayer() {
        TournamentCore.PlayerResources memory player = ITournamentHub(hub)
            .getPlayer(msg.sender);
        if (!player.exists) revert PlayerNotFound();
        if (player.status != TournamentCore.PlayerStatus.Active)
            revert PlayerNotActive();
        if (player.inCombat) revert PlayerInCombat();
        _;
    }

    modifier tournamentActive() {
        if (ITournamentHub(hub).status() != TournamentCore.Status.Active)
            revert TournamentNotActive();
        _;
    }

    function initialize(
        address _hub,
        address _gameOracle
    ) external initializer {
        if (_hub == address(0) || _gameOracle == address(0))
            revert InvalidAddress();
        hub = _hub;
        gameOracle = _gameOracle;
        nextOfferId = 1;
    }

    function createOffer(
        ResourceBundle calldata offered,
        ResourceBundle calldata requested
    ) external onlyActivePlayer tournamentActive returns (uint256 offerId) {
        TournamentCore.Params memory params = ITournamentHub(hub).getParams();
        uint32 expiresAt = uint32(block.timestamp) + params.gameInterval;

        offerId = nextOfferId;
        unchecked {
            nextOfferId++;
        }

        offers[offerId] = TradeOffer({
            creator: msg.sender,
            expiresAt: expiresAt,
            status: OfferStatus.Open,
            exists: true,
            offered: offered,
            requested: requested
        });

        playerOffers[msg.sender].push(offerId);

        emit OfferCreated(
            offerId,
            msg.sender,
            offered,
            requested,
            expiresAt,
            uint32(block.timestamp)
        );
    }

    function cancelOffer(
        uint256 offerId
    ) external onlyActivePlayer tournamentActive {
        TradeOffer storage offer = offers[offerId];

        if (!offer.exists) revert OfferNotFound();
        if (offer.creator != msg.sender) revert NotOfferCreator();
        if (offer.status != OfferStatus.Open) revert OfferNotActive();

        offer.status = OfferStatus.Cancelled;

        emit OfferCancelled(offerId, msg.sender, uint32(block.timestamp));
    }

    function executeTradeResolution(
        uint256 offerId,
        address acceptor,
        uint8 creatorTotalCardsDelta,
        uint8 acceptorTotalCardsDelta
    ) external onlyGameOracle tournamentActive {
        TradeOffer storage offer = offers[offerId];

        if (!offer.exists) revert OfferNotFound();
        if (offer.status != OfferStatus.Open) revert OfferNotActive();
        if (block.timestamp >= offer.expiresAt) revert OfferExpired();

        // Validate deltas match bundles
        uint8 offeredTotal = offer.offered.rockCards +
            offer.offered.paperCards +
            offer.offered.scissorsCards;
        uint8 requestedTotal = offer.requested.rockCards +
            offer.requested.paperCards +
            offer.requested.scissorsCards;

        if (
            creatorTotalCardsDelta != offeredTotal ||
            acceptorTotalCardsDelta != requestedTotal
        ) revert InvalidCardDeltas();

        TournamentCore.PlayerResources memory creator = ITournamentHub(hub)
            .getPlayer(offer.creator);
        TournamentCore.PlayerResources memory acceptorData = ITournamentHub(hub)
            .getPlayer(acceptor);

        if (!creator.exists || !acceptorData.exists) revert PlayerNotFound();
        if (
            creator.status != TournamentCore.PlayerStatus.Active ||
            acceptorData.status != TournamentCore.PlayerStatus.Active
        ) revert PlayerNotActive();
        if (creator.inCombat || acceptorData.inCombat) revert PlayerInCombat();

        if (creator.lives < offer.offered.lives) revert InsufficientResources();
        if (creator.coins < offer.offered.coins) revert InsufficientResources();
        if (creator.totalCards < creatorTotalCardsDelta)
            revert InsufficientResources();

        if (acceptorData.lives < offer.requested.lives)
            revert InsufficientResources();
        if (acceptorData.coins < offer.requested.coins)
            revert InsufficientResources();
        if (acceptorData.totalCards < acceptorTotalCardsDelta)
            revert InsufficientResources();

        // Validate uint8 overflow on additions
        if (
            creator.totalCards -
                creatorTotalCardsDelta +
                acceptorTotalCardsDelta >
            type(uint8).max
        ) revert ResourceOverflow();
        if (
            acceptorData.totalCards -
                acceptorTotalCardsDelta +
                creatorTotalCardsDelta >
            type(uint8).max
        ) revert ResourceOverflow();

        creator.lives = _sub(creator.lives, offer.offered.lives);
        creator.coins -= offer.offered.coins;
        creator.totalCards -= creatorTotalCardsDelta;

        creator.lives = _add(creator.lives, offer.requested.lives);
        creator.coins += offer.requested.coins;
        creator.totalCards += acceptorTotalCardsDelta;

        acceptorData.lives = _sub(acceptorData.lives, offer.requested.lives);
        acceptorData.coins -= offer.requested.coins;
        acceptorData.totalCards -= acceptorTotalCardsDelta;

        acceptorData.lives = _add(acceptorData.lives, offer.offered.lives);
        acceptorData.coins += offer.offered.coins;
        acceptorData.totalCards += creatorTotalCardsDelta;

        offer.status = OfferStatus.Executed;
        unchecked {
            totalTradesExecuted++;
        }

        ITournamentHub(hub).updatePlayerResources(offer.creator, creator);
        ITournamentHub(hub).updatePlayerResources(acceptor, acceptorData);

        emit TradeExecuted(
            offerId,
            offer.creator,
            acceptor,
            creatorTotalCardsDelta,
            acceptorTotalCardsDelta,
            uint32(block.timestamp)
        );
    }

    function _sub(uint8 a, uint8 b) internal pure returns (uint8) {
        return a >= b ? a - b : 0;
    }

    function _add(uint8 a, uint8 b) internal pure returns (uint8) {
        uint256 result = uint256(a) + uint256(b);
        if (result > type(uint8).max) revert ResourceOverflow();
        return uint8(result);
    }

    function getOffer(
        uint256 offerId
    ) external view returns (TradeOffer memory) {
        return offers[offerId];
    }

    function getOfferStatus(
        uint256 offerId
    ) external view returns (OfferStatus) {
        if (!offers[offerId].exists) revert OfferNotFound();
        return offers[offerId].status;
    }

    function getPlayerOffers(
        address player
    ) external view returns (uint256[] memory) {
        return playerOffers[player];
    }

    function isOfferActive(uint256 offerId) external view returns (bool) {
        TradeOffer memory offer = offers[offerId];
        return
            offer.exists &&
            offer.status == OfferStatus.Open &&
            block.timestamp < offer.expiresAt;
    }
}
