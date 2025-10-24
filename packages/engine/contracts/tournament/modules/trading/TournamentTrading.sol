// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {TournamentCore} from "./../../core/TournamentCore.sol";

interface ITournamentHub {
    function getPlayer(address player) external view returns (TournamentCore.PlayerResources memory);
    function updatePlayerResources(address player, TournamentCore.PlayerResources calldata resources) external;
    function getParams() external view returns (TournamentCore.Params memory);
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
        uint32 expiresAt
    );
    
    event OfferCancelled(uint256 indexed offerId, address indexed creator);
    
    event TradeExecuted(
        uint256 indexed offerId,
        address indexed creator,
        address indexed acceptor,
        ResourceBundle offered,
        ResourceBundle requested
    );
    
    error InvalidAddress();
    error OnlyGameOracle();
    error PlayerNotFound();
    error PlayerNotActive();
    error OfferNotFound();
    error OfferExpired();
    error OfferNotActive();
    error NotOfferCreator();
    error InsufficientResources();
    error ResourceOverflow();
    
    modifier onlyGameOracle() {
        if (msg.sender != gameOracle) revert OnlyGameOracle();
        _;
    }
    
    modifier onlyActivePlayer() {
        TournamentCore.PlayerResources memory player = ITournamentHub(hub).getPlayer(msg.sender);
        if (!player.exists) revert PlayerNotFound();
        if (player.status != TournamentCore.PlayerStatus.Active) revert PlayerNotActive();
        _;
    }
    
    function initialize(address _hub, address _gameOracle) external initializer {
        if (_hub == address(0) || _gameOracle == address(0)) revert InvalidAddress();
        hub = _hub;
        gameOracle = _gameOracle;
        nextOfferId = 1;
    }
    
    function createOffer(
        ResourceBundle calldata offered,
        ResourceBundle calldata requested
    ) external onlyActivePlayer returns (uint256 offerId) {
        TournamentCore.Params memory params = ITournamentHub(hub).getParams();
        uint32 expiresAt = uint32(block.timestamp) + params.gameInterval;
        
        offerId = nextOfferId;
        unchecked { nextOfferId++; }
        
        offers[offerId] = TradeOffer({
            creator: msg.sender,
            expiresAt: expiresAt,
            status: OfferStatus.Open,
            exists: true,
            offered: offered,
            requested: requested
        });
        
        playerOffers[msg.sender].push(offerId);
        
        emit OfferCreated(offerId, msg.sender, offered, requested, expiresAt);
    }
    
    function cancelOffer(uint256 offerId) external {
        TradeOffer storage offer = offers[offerId];
        
        if (!offer.exists) revert OfferNotFound();
        if (offer.creator != msg.sender) revert NotOfferCreator();
        if (offer.status != OfferStatus.Open) revert OfferNotActive();
        
        offer.status = OfferStatus.Cancelled;
        
        emit OfferCancelled(offerId, msg.sender);
    }
    
    function executeTradeResolution(
        uint256 offerId,
        address acceptor
    ) external onlyGameOracle {
        TradeOffer storage offer = offers[offerId];
        
        if (!offer.exists) revert OfferNotFound();
        if (offer.status != OfferStatus.Open) revert OfferNotActive();
        if (block.timestamp >= offer.expiresAt) revert OfferExpired();
        
        TournamentCore.PlayerResources memory creator = ITournamentHub(hub).getPlayer(offer.creator);
        TournamentCore.PlayerResources memory acceptorData = ITournamentHub(hub).getPlayer(acceptor);
        
        if (!creator.exists || !acceptorData.exists) revert PlayerNotFound();
        if (creator.status != TournamentCore.PlayerStatus.Active || 
            acceptorData.status != TournamentCore.PlayerStatus.Active) revert PlayerNotActive();
        
        _validateAndApplyTrade(creator, acceptorData, offer.offered, offer.requested);
        
        offer.status = OfferStatus.Executed;
        unchecked { totalTradesExecuted++; }
        
        ITournamentHub(hub).updatePlayerResources(offer.creator, creator);
        ITournamentHub(hub).updatePlayerResources(acceptor, acceptorData);
        
        emit TradeExecuted(offerId, offer.creator, acceptor, offer.offered, offer.requested);
    }
    
    function _validateAndApplyTrade(
        TournamentCore.PlayerResources memory creator,
        TournamentCore.PlayerResources memory acceptor,
        ResourceBundle memory offered,
        ResourceBundle memory requested
    ) internal pure {
        if (creator.lives < offered.lives) revert InsufficientResources();
        if (creator.coins < offered.coins) revert InsufficientResources();
        if (creator.rockCards < offered.rockCards) revert InsufficientResources();
        if (creator.paperCards < offered.paperCards) revert InsufficientResources();
        if (creator.scissorsCards < offered.scissorsCards) revert InsufficientResources();
        
        if (acceptor.lives < requested.lives) revert InsufficientResources();
        if (acceptor.coins < requested.coins) revert InsufficientResources();
        if (acceptor.rockCards < requested.rockCards) revert InsufficientResources();
        if (acceptor.paperCards < requested.paperCards) revert InsufficientResources();
        if (acceptor.scissorsCards < requested.scissorsCards) revert InsufficientResources();
        
        creator.lives = _sub(creator.lives, offered.lives);
        creator.coins -= offered.coins;
        creator.rockCards = _sub(creator.rockCards, offered.rockCards);
        creator.paperCards = _sub(creator.paperCards, offered.paperCards);
        creator.scissorsCards = _sub(creator.scissorsCards, offered.scissorsCards);
        
        creator.lives = _add(creator.lives, requested.lives);
        creator.coins += requested.coins;
        creator.rockCards = _add(creator.rockCards, requested.rockCards);
        creator.paperCards = _add(creator.paperCards, requested.paperCards);
        creator.scissorsCards = _add(creator.scissorsCards, requested.scissorsCards);
        
        acceptor.lives = _sub(acceptor.lives, requested.lives);
        acceptor.coins -= requested.coins;
        acceptor.rockCards = _sub(acceptor.rockCards, requested.rockCards);
        acceptor.paperCards = _sub(acceptor.paperCards, requested.paperCards);
        acceptor.scissorsCards = _sub(acceptor.scissorsCards, requested.scissorsCards);
        
        acceptor.lives = _add(acceptor.lives, offered.lives);
        acceptor.coins += offered.coins;
        acceptor.rockCards = _add(acceptor.rockCards, offered.rockCards);
        acceptor.paperCards = _add(acceptor.paperCards, offered.paperCards);
        acceptor.scissorsCards = _add(acceptor.scissorsCards, offered.scissorsCards);
        
        creator.totalCards = creator.rockCards + creator.paperCards + creator.scissorsCards;
        acceptor.totalCards = acceptor.rockCards + acceptor.paperCards + acceptor.scissorsCards;
    }
    
    function _sub(uint8 a, uint8 b) internal pure returns (uint8) {
        return a >= b ? a - b : 0;
    }
    
    function _add(uint8 a, uint8 b) internal pure returns (uint8) {
        uint256 result = uint256(a) + uint256(b);
        if (result > type(uint8).max) revert ResourceOverflow();
        return uint8(result);
    }
    
    function getOffer(uint256 offerId) external view returns (TradeOffer memory) {
        return offers[offerId];
    }
    
    function getOfferStatus(uint256 offerId) external view returns (OfferStatus) {
        if (!offers[offerId].exists) revert OfferNotFound();
        return offers[offerId].status;
    }
    
    function getPlayerOffers(address player) external view returns (uint256[] memory) {
        return playerOffers[player];
    }
    
    function isOfferActive(uint256 offerId) external view returns (bool) {
        TradeOffer memory offer = offers[offerId];
        return offer.exists && offer.status == OfferStatus.Open && block.timestamp < offer.expiresAt;
    }
}