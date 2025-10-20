// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {IEntropyConsumer} from "@pythnetwork/entropy-sdk-solidity/IEntropyConsumer.sol";
import {IEntropy} from "@pythnetwork/entropy-sdk-solidity/IEntropy.sol";

contract TournamentRandomizer is Initializable, IEntropyConsumer {
    address public hub;
    address public mysteryDeck;
    address public platformAdmin;
    IEntropy public entropy;
    address public entropyProvider;

    uint256 public seedCount;
    bytes32 public revealedCompleteSeed;
    bytes32 public revealedBackendSecret;
    bool public isRevealed;

    mapping(address => bool) public hasOracleRole;
    mapping(uint64 => SeedRequest) public seedRequests;

    struct SeedRequest {
        address requester;
        uint32 timestamp;
        bool fulfilled;
        bool cancelled;
    }

    uint32 public constant SEED_REQUEST_TIMEOUT = 3600;

    event SeedRequested(
        uint64 indexed sequenceNumber,
        address indexed requester,
        uint256 seedIndex,
        uint32 timestamp
    );

    event SeedGenerated(
        uint64 indexed sequenceNumber,
        uint256 seedIndex,
        bytes32 indexed seed,
        uint32 timestamp
    );

    event CompleteSeedRevealed(
        bytes32 completeSeed,
        bytes32 backendSecret,
        uint32 timestamp
    );

    event SeedRequestCancelled(uint64 indexed sequenceNumber, uint32 timestamp);

    event OracleRoleGranted(address indexed oracle);
    event OracleRoleRevoked(address indexed oracle);
    event MysteryDeckSet(address indexed mysteryDeck);

    error InvalidAddress();
    error Unauthorized();
    error TournamentNotEnded();
    error AlreadyRevealed();
    error RequestNotFound();
    error RequestAlreadyFulfilled();
    error RequestAlreadyCancelled();
    error TimeoutNotReached();
    error InsufficientFee();

    modifier onlyPlatformAdmin() {
        if (msg.sender != platformAdmin) revert Unauthorized();
        _;
    }

    modifier onlyOracle() {
        if (!hasOracleRole[msg.sender]) revert Unauthorized();
        _;
    }

    modifier onlyAuthorizedCaller() {
        if (msg.sender != hub && msg.sender != mysteryDeck) {
            revert Unauthorized();
        }
        _;
    }

    function initialize(
        address _hub,
        address _pythEntropy,
        address _entropyProvider,
        address _admin
    ) external initializer {
        if (
            _hub == address(0) ||
            _pythEntropy == address(0) ||
            _entropyProvider == address(0)
        ) {
            revert InvalidAddress();
        }

        hub = _hub;
        entropy = IEntropy(_pythEntropy);
        entropyProvider = _entropyProvider;
        platformAdmin = _admin == address(0) ? msg.sender : _admin;
    }

    function setMysteryDeck(address _mysteryDeck) external {
        if (msg.sender != hub) revert Unauthorized();
        if (_mysteryDeck == address(0)) revert InvalidAddress();
        if (mysteryDeck != address(0)) revert Unauthorized();

        mysteryDeck = _mysteryDeck;
        emit MysteryDeckSet(_mysteryDeck);
    }

    function requestSeed(
        address requester
    ) external payable onlyAuthorizedCaller returns (uint64 sequenceNumber) {
        uint256 fee = entropy.getFee(entropyProvider);
        if (msg.value < fee) revert InsufficientFee();

        bytes32 userRandomNumber = keccak256(
            abi.encodePacked(
                block.timestamp,
                block.prevrandao,
                requester,
                seedCount
            )
        );

        sequenceNumber = entropy.request{value: fee}(
            entropyProvider,
            userRandomNumber,
            true
        );

        seedRequests[sequenceNumber] = SeedRequest({
            requester: requester,
            timestamp: uint32(block.timestamp),
            fulfilled: false,
            cancelled: false
        });

        emit SeedRequested(
            sequenceNumber,
            requester,
            seedCount,
            uint32(block.timestamp)
        );

        return sequenceNumber;
    }

    function entropyCallback(
        uint64 sequenceNumber,
        address,
        bytes32 randomNumber
    ) internal override {
        SeedRequest storage request = seedRequests[sequenceNumber];

        if (request.timestamp == 0) return;
        if (request.fulfilled || request.cancelled) return;

        request.fulfilled = true;

        unchecked {
            seedCount++;
        }

        emit SeedGenerated(
            sequenceNumber,
            seedCount - 1,
            randomNumber,
            uint32(block.timestamp)
        );
    }

    function cancelFailedSeedRequest(uint64 sequenceNumber) external {
        SeedRequest storage request = seedRequests[sequenceNumber];

        if (request.timestamp == 0) revert RequestNotFound();
        if (request.fulfilled) revert RequestAlreadyFulfilled();
        if (request.cancelled) revert RequestAlreadyCancelled();
        if (block.timestamp < request.timestamp + SEED_REQUEST_TIMEOUT) {
            revert TimeoutNotReached();
        }

        request.cancelled = true;

        if (seedCount == 0) {
            ITournamentHub(hub).handleFailedRandomness();
        }

        emit SeedRequestCancelled(sequenceNumber, uint32(block.timestamp));
    }

    function revealCompleteSeed(
        bytes32 seed,
        bytes32 secret
    ) external onlyOracle {
        if (isRevealed) revert AlreadyRevealed();

        (bool success, bytes memory data) = hub.staticcall(
            abi.encodeWithSignature("status()")
        );
        if (!success) revert TournamentNotEnded();

        uint8 status = abi.decode(data, (uint8));
        if (status != 4) revert TournamentNotEnded();

        (success, data) = hub.staticcall(abi.encodeWithSignature("endTime()"));
        if (!success) revert TournamentNotEnded();

        uint32 endTime = abi.decode(data, (uint32));
        if (block.timestamp < endTime) revert TournamentNotEnded();

        isRevealed = true;
        revealedCompleteSeed = seed;
        revealedBackendSecret = secret;

        emit CompleteSeedRevealed(seed, secret, uint32(block.timestamp));
    }

    function grantOracleRole(address o) external onlyPlatformAdmin {
        if (o == address(0)) revert InvalidAddress();
        hasOracleRole[o] = true;
        emit OracleRoleGranted(o);
    }

    function revokeOracleRole(address o) external onlyPlatformAdmin {
        hasOracleRole[o] = false;
        emit OracleRoleRevoked(o);
    }

    function getFee() external view returns (uint256) {
        return entropy.getFee(entropyProvider);
    }

    function getSeedCount() external view returns (uint256) {
        return seedCount;
    }

    function getSeedRequest(
        uint64 sequenceNumber
    ) external view returns (SeedRequest memory) {
        return seedRequests[sequenceNumber];
    }

    function getEntropy() internal view override returns (address) {
        return address(entropy);
    }
}

interface ITournamentHub {
    function handleFailedRandomness() external;
    function status() external view returns (uint8);
    function endTime() external view returns (uint32);
}
