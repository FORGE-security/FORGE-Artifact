// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/VRFCoordinatorV2.sol

import "./interfaces/IPrepayment.sol";
import "./interfaces/ITypeAndVersion.sol";
import "./interfaces/IVRFCoordinatorBase.sol";
import "./libraries/VRF.sol";
import "./VRFConsumerBase.sol";
import "./CoordinatorBase.sol";

/// @title Orakl Network VRFCoordinator
/// @author Bisonai
/// @notice Accepts requests for random words either through [regular]
/// or [temporary] account by calling `requestRandomWords`
/// function. Consumers can choose which random words provider they
/// want to request random number from by specifying a keyHash that is
/// associated with such provider. Random words are partially
/// generated using unique seed created during request
/// transaction. The request for random words is concluded by emitting
/// `RandomWordsRequested` event which includes all necessary metadata
/// to provide requested random words. Off-chain oracle that was
/// requested to provide random words generates a proof using seed and
/// its private key, and submits it back to VRFCoordinator through
/// `fulfillRandomWords` function. Proof is validated that it was
/// generated by the requested oracle, and the requested number of
/// random words are populated from it. Eventually, the random words
/// are passed to consumer smart contract.
contract VRFCoordinator is IVRFCoordinatorBase, CoordinatorBase, ITypeAndVersion {
    uint32 public constant MAX_NUM_WORDS = 500;

    bytes32[] public sKeyHashes;

    struct Oracle {
        bool registered;
        address[] oracles;
    }

    /* keyHash */
    /* Oracle */
    mapping(bytes32 => Oracle) private sKeyHashToOracle;

    /* oracle */
    /* keyHash */
    mapping(address => bytes32) private sOracleToKeyHash;

    error InvalidKeyHash(bytes32 keyHash);
    error NumWordsTooBig(uint32 have, uint32 want);
    error NoSuchProvingKey(bytes32 keyHash);

    event OracleRegistered(address indexed oracle, bytes32 keyHash);
    event OracleDeregistered(address indexed oracle, bytes32 keyHash);
    event RandomWordsRequested(
        bytes32 indexed keyHash,
        uint256 requestId,
        uint256 preSeed,
        uint64 indexed accId,
        uint32 callbackGasLimit,
        uint32 numWords,
        address indexed sender,
        bool isDirectPayment
    );
    event RandomWordsFulfilled(
        uint256 indexed requestId,
        uint256 outputSeed,
        uint256 payment,
        bool success
    );
    event PrepaymentSet(address prepayment);

    modifier onlyValidKeyHash(bytes32 keyHash) {
        if (!sKeyHashToOracle[keyHash].registered) {
            revert InvalidKeyHash(keyHash);
        }
        _;
    }

    constructor(address prepayment) {
        sPrepayment = IPrepayment(prepayment);
        emit PrepaymentSet(prepayment);
    }

    /**
     * @notice Registers an oracle and its proving key.
     * @param oracle address of the oracle
     * @param publicProvingKey key that oracle can use to submit VRF fulfillments
     */
    function registerOracle(
        address oracle,
        uint256[2] calldata publicProvingKey
    ) external onlyOwner {
        if (sOracleToKeyHash[oracle] != bytes32(0)) {
            revert OracleAlreadyRegistered(oracle);
        }

        bytes32 kh = hashOfKey(publicProvingKey);
        if (!sKeyHashToOracle[kh].registered) {
            sKeyHashToOracle[kh].registered = true;
            sKeyHashes.push(kh);
        }

        sKeyHashToOracle[kh].oracles.push(oracle);
        sOracleToKeyHash[oracle] = kh;

        emit OracleRegistered(oracle, kh);
    }

    /**
     * @notice Deregisters an oracle.
     * @param oracle address representing oracle that can submit VRF fulfillments
     */
    function deregisterOracle(address oracle) external onlyOwner {
        bytes32 kh = sOracleToKeyHash[oracle];
        if (kh == bytes32(0) || !sKeyHashToOracle[kh].registered) {
            revert NoSuchOracle(oracle);
        }
        delete sOracleToKeyHash[oracle];

        address[] storage oracles = sKeyHashToOracle[kh].oracles;
        uint256 oraclesLength = oracles.length;
        for (uint256 i; i < oraclesLength; ++i) {
            if (oracles[i] == oracle) {
                // oracles
                address lastOracle = oracles[oraclesLength - 1];
                oracles[i] = lastOracle;
                oracles.pop();

                // key hashes
                if (oraclesLength == 1) {
                    bytes32 lastKeyHash = sKeyHashes[oraclesLength - 1];
                    sKeyHashes[i] = lastKeyHash;
                    sKeyHashes.pop();

                    delete sKeyHashToOracle[kh];
                }

                break;
            }
        }

        emit OracleDeregistered(oracle, kh);
    }

    /**
     * @inheritdoc IVRFCoordinatorBase
     */
    function getRequestConfig() external view returns (uint32, bytes32[] memory) {
        return (sConfig.maxGasLimit, sKeyHashes);
    }

    /**
     * @inheritdoc IVRFCoordinatorBase
     */
    function requestRandomWords(
        bytes32 keyHash,
        uint64 accId,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external nonReentrant onlyValidKeyHash(keyHash) returns (uint256) {
        (uint256 balance, uint64 reqCount, , ) = sPrepayment.getAccount(accId);
        uint8 numSubmission = 1;
        uint256 minBalance = estimateFee(reqCount, numSubmission, callbackGasLimit);
        if (balance < minBalance) {
            revert InsufficientPayment(balance, minBalance);
        }

        bool isDirectPayment = false;
        uint256 requestId = requestRandomWords(
            keyHash,
            accId,
            callbackGasLimit,
            numWords,
            isDirectPayment
        );

        return requestId;
    }

    /**
     * @inheritdoc IVRFCoordinatorBase
     */
    function requestRandomWords(
        bytes32 keyHash,
        uint32 callbackGasLimit,
        uint32 numWords,
        address refundRecipient
    ) external payable nonReentrant onlyValidKeyHash(keyHash) returns (uint256) {
        uint64 reqCount = 0;
        uint8 numSubmission = 1;
        uint256 fee = estimateFee(reqCount, numSubmission, callbackGasLimit);
        if (msg.value < fee) {
            revert InsufficientPayment(msg.value, fee);
        }

        uint64 accId = sPrepayment.createTemporaryAccount();
        bool isDirectPayment = true;
        uint256 requestId = requestRandomWords(
            keyHash,
            accId,
            callbackGasLimit,
            numWords,
            isDirectPayment
        );
        sPrepayment.depositTemporary{value: fee}(accId);

        // Refund extra $KLAY
        uint256 remaining = msg.value - fee;
        if (remaining > 0) {
            (bool sent, ) = refundRecipient.call{value: remaining}("");
            if (!sent) {
                revert RefundFailure();
            }
        }

        return requestId;
    }

    /*
     * @notice Fulfill a randomness request
     * @param proof contains the proof and randomness
     * @param rc request commitment pre-image, committed to at request time
     * @dev simulated offchain to determine if sufficient balance is present to fulfill the request
     */
    function fulfillRandomWords(
        VRF.Proof memory proof,
        RequestCommitment memory rc,
        bool isDirectPayment
    ) external nonReentrant {
        uint256 startGas = gasleft();
        (uint256 requestId, uint256 randomness) = getRandomnessFromProof(proof, rc);

        uint256[] memory randomWords = new uint256[](rc.numWords);
        for (uint256 i = 0; i < rc.numWords; i++) {
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        delete sRequestIdToCommitment[requestId];
        delete sRequestOwner[requestId];

        bytes memory resp = abi.encodeWithSelector(
            VRFConsumerBase.rawFulfillRandomWords.selector,
            requestId,
            randomWords
        );

        // Call with explicitly the amount of callback gas requested
        // Important to not let them exhaust the gas budget and avoid oracle payment.
        // Do not allow any non-view/non-pure coordinator functions to be called
        // during the consumers callback code via reentrancyLock.
        // Note that callWithExactGas will revert if we do not have sufficient gas
        // to give the callee their requested amount.
        sConfig.reentrancyLock = true;
        bool success = callWithExactGas(rc.callbackGasLimit, rc.sender, resp);
        sConfig.reentrancyLock = false;

        uint256 payment = pay(rc, isDirectPayment, startGas);
        emit RandomWordsFulfilled(requestId, randomness, payment, success);
    }

    function pay(
        RequestCommitment memory rc,
        bool isDirectPayment,
        uint256 startGas
    ) internal returns (uint256) {
        if (isDirectPayment) {
            // [temporary] account
            (uint256 totalFee, uint256 operatorFee) = sPrepayment.chargeFeeTemporary(rc.accId);
            if (operatorFee > 0) {
                sPrepayment.chargeOperatorFeeTemporary(operatorFee, msg.sender);
            }

            return totalFee;
        } else {
            // [regular] account
            uint64 reqCount = sPrepayment.getReqCount(rc.accId);
            uint256 serviceFee = calculateServiceFee(reqCount);
            uint256 operatorFee = sPrepayment.chargeFee(rc.accId, serviceFee);
            uint256 gasFee = calculateGasCost(startGas);
            uint256 fee = operatorFee + gasFee;
            if (fee > 0) {
                sPrepayment.chargeOperatorFee(rc.accId, fee, msg.sender);
            }

            return serviceFee + gasFee;
        }
    }

    /**
     * @notice The type and version of this contract
     * @return Type and version string
     */
    function typeAndVersion() external pure virtual override returns (string memory) {
        return "VRFCoordinator v0.1";
    }

    /**
     * @notice Find key hash associated with given oracle address.
     * @return keyhash
     */
    function oracleToKeyHash(address oracle) external view returns (bytes32) {
        return sOracleToKeyHash[oracle];
    }

    /**
     * @notice Find oracles associated with given key hash.
     * @return oracle addresses
     */
    function keyHashToOracles(bytes32 keyHash) external view returns (address[] memory) {
        return sKeyHashToOracle[keyHash].oracles;
    }

    /**
     * @inheritdoc ICoordinatorBase
     */
    function pendingRequestExists(
        address consumer,
        uint64 accId,
        uint64 nonce
    ) public view returns (bool) {
        uint256 keyHashesLength = sKeyHashes.length;
        for (uint256 i = 0; i < keyHashesLength; ++i) {
            (uint256 requestId, ) = computeRequestId(sKeyHashes[i], consumer, accId, nonce);
            if (isValidRequestId(requestId)) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Returns the proving key hash key associated with this public key
     * @param publicKey the key to return the hash of
     */
    function hashOfKey(uint256[2] memory publicKey) public pure returns (bytes32) {
        return keccak256(abi.encode(publicKey));
    }

    function requestRandomWords(
        bytes32 keyHash,
        uint64 accId,
        uint32 callbackGasLimit,
        uint32 numWords,
        bool isDirectPayment
    ) private returns (uint256) {
        if (!sPrepayment.isValidAccount(accId, msg.sender)) {
            revert InvalidConsumer(accId, msg.sender);
        }

        // No lower bound on the requested gas limit. A user could request 0
        // and they would simply be billed for the proof verification and wouldn't be
        // able to do anything with the random value.
        if (callbackGasLimit > sConfig.maxGasLimit) {
            revert GasLimitTooBig(callbackGasLimit, sConfig.maxGasLimit);
        }

        if (numWords > MAX_NUM_WORDS) {
            revert NumWordsTooBig(numWords, MAX_NUM_WORDS);
        }

        uint64 nonce = sPrepayment.increaseNonce(accId, msg.sender);
        (uint256 requestId, uint256 preSeed) = computeRequestId(keyHash, msg.sender, accId, nonce);

        sRequestIdToCommitment[requestId] = computeCommitment(
            requestId,
            block.number,
            accId,
            callbackGasLimit,
            numWords,
            msg.sender
        );
        sRequestOwner[requestId] = msg.sender;

        emit RandomWordsRequested(
            keyHash,
            requestId,
            preSeed,
            accId,
            callbackGasLimit,
            numWords,
            msg.sender,
            isDirectPayment
        );

        return requestId;
    }

    function computeRequestId(
        bytes32 keyHash,
        address sender,
        uint64 accId,
        uint64 nonce
    ) private pure returns (uint256, uint256) {
        uint256 preSeed = uint256(keccak256(abi.encode(keyHash, sender, accId, nonce)));
        uint256 requestId = uint256(keccak256(abi.encode(keyHash, preSeed)));
        return (requestId, preSeed);
    }

    function computeCommitment(
        uint256 requestId,
        uint256 blockNumber,
        uint64 accId,
        uint32 callbackGasLimit,
        uint32 numWords,
        address sender
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(requestId, blockNumber, accId, callbackGasLimit, numWords, sender)
            );
    }

    function getRandomnessFromProof(
        VRF.Proof memory proof,
        RequestCommitment memory rc
    ) private view returns (uint256 requestId, uint256 randomness) {
        bytes32 keyHash = hashOfKey(proof.pk);
        if (sOracleToKeyHash[msg.sender] != keyHash) {
            revert NoSuchProvingKey(keyHash);
        }
        requestId = uint256(keccak256(abi.encode(keyHash, proof.seed)));
        bytes32 commitment = sRequestIdToCommitment[requestId];
        if (commitment == 0) {
            revert NoCorrespondingRequest();
        }
        if (
            commitment !=
            computeCommitment(
                requestId,
                rc.blockNum,
                rc.accId,
                rc.callbackGasLimit,
                rc.numWords,
                rc.sender
            )
        ) {
            revert IncorrectCommitment();
        }

        bytes32 blockHash = blockhash(rc.blockNum);

        // The seed actually used by the VRF machinery, mixing in the blockhash
        bytes memory actualSeed = abi.encodePacked(
            keccak256(abi.encodePacked(proof.seed, blockHash))
        );
        randomness = VRF.randomValueFromVRFProof(proof, actualSeed); // Reverts on failure
    }
}
