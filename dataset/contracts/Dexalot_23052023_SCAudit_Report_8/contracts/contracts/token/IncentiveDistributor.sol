// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

/**
 * @title Distributor for Dexalot Incentive Program (DIP) rewards
 * @notice IncentiveDistributor distributes 200,000 $ALOT tokens monthly for up to 2 years and
 * potential other tokens to traders based on their trading activity. Token rewards per
 * trader are calculated off-chain and finalized at month's end. To validate, we sign a
 * message containing the trader address, ids and amounts of reward tokens earned to date.
 * This signature is input to the claim function to verify and allow traders to withdraw
 * their earned Dexalot Incentive Program (DIP) rewards.
 */

// The code in this file is part of Dexalot project.
// Please see the LICENSE.txt file for licensing info.
// Copyright 2022 Dexalot.

contract IncentiveDistributor is PausableUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // version
    bytes32 public constant VERSION = bytes32("1.0.0");

    // bitmap representing current reward tokenIds
    uint32 public allTokens;
    address private _signer;
    mapping(uint32 => IERC20Upgradeable) public tokens;
    mapping(address => mapping(uint32 => uint128)) public claimedRewards;

    event Claimed(address indexed claimer, uint32 tokenIds, uint128[] amounts, uint256 timestamp);
    event AddRewardToken(IERC20Upgradeable token, uint32 tokenId, uint256 timestamp);

    /**
     * @notice Initializer of the IncentiveDistributor
     * @dev    Adds ALOT token as the first reward token and defines the signer of claim messages.
     * @param  _alotToken The address of the ALOT token
     * @param  __signer The public address of the signer of claim messages
     */
    function initialize(IERC20Upgradeable _alotToken, address __signer) public initializer {
        __Ownable_init();
        __Pausable_init();

        uint32 tokenId = ~allTokens & (allTokens + 1);
        tokens[tokenId] = _alotToken;
        allTokens |= tokenId;
        _signer = __signer;

        emit AddRewardToken(_alotToken, tokenId, block.timestamp);
    }

    /**
     * @notice Claim DIP token rewards for a given trader
     * @param  _amounts An array of total earned amount for each reward token
     * @param  _tokenIds A bitmap representing which tokens to claim
     * @param  _signature A signed claim message to be verified
     */
    function claim(
        uint128[] memory _amounts,
        uint32 _tokenIds,
        bytes calldata _signature
    ) external whenNotPaused {
        require(_tokenIds | allTokens == allTokens, "ID-TDNE-01");
        require(_checkClaim(msg.sender, _tokenIds, _amounts, _signature), "ID-SIGN-01");

        bool isClaimed;

        for (uint8 i = 0; i < _amounts.length; i++) {
            require(_tokenIds != 0, "ID-TACM-01");
            uint32 tokenId = _tokenIds & ~(_tokenIds - 1);
            _tokenIds -= tokenId;

            uint128 amount = _amounts[i];
            uint128 prevClaimed = claimedRewards[msg.sender][tokenId];
            require(amount >= prevClaimed, "ID-RTPC-01");

            if (amount != prevClaimed) {
                IERC20Upgradeable token = tokens[tokenId];
                uint128 claimableAmount = amount - prevClaimed;
                require(token.balanceOf(address(this)) >= claimableAmount, "ID-RTBI-01");

                claimedRewards[msg.sender][tokenId] += claimableAmount;
                token.safeTransfer(msg.sender, claimableAmount);

                _amounts[i] = claimableAmount;
                isClaimed = true;
            } else {
                _amounts[i] = 0;
            }
        }
        require(isClaimed, "ID-NTTC-01");
        require(_tokenIds == 0, "ID-TACM-02");

        emit Claimed(msg.sender, _tokenIds, _amounts, block.timestamp);
    }

    /**
     * @notice Verifies claim message (_user, _tokenIds, _amount) has been signed by signer
     * @param  _user The trader making a claim
     * @param  _tokenIds A bitmap representing which tokens to claim
     * @param  _amounts An array of total earned amount for each reward token
     * @param  _signature A signed claim message to be verified
     */
    function _checkClaim(
        address _user,
        uint32 _tokenIds,
        uint128[] memory _amounts,
        bytes calldata _signature
    ) internal view returns (bool) {
        bytes32 msgHash = keccak256(abi.encodePacked(_user, _tokenIds, _amounts));
        bytes32 signedMsg = ECDSAUpgradeable.toEthSignedMessageHash(msgHash);
        return ECDSAUpgradeable.recover(signedMsg, _signature) == _signer;
    }

    /**
     * @notice Add new claimable reward token
     * @param  _rewardToken The address of the new reward token
     */
    function addRewardToken(IERC20Upgradeable _rewardToken) external whenPaused onlyOwner {
        uint32 tokenId = ~allTokens & (allTokens + 1);
        tokens[tokenId] = _rewardToken;
        allTokens |= tokenId;

        emit AddRewardToken(_rewardToken, tokenId, block.timestamp);
    }

    /**
     * @notice Retrieve reward token when DIP ends
     * @param  _tokenId The id of the reward token to retrieve
     */
    function retrieveRewardToken(uint32 _tokenId) external whenPaused onlyOwner {
        IERC20Upgradeable token = tokens[_tokenId];
        require(address(token) != address(0), "ID-TDNE-02");

        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(msg.sender, balance);
    }

    /**
     * @notice Retrieve all reward tokens when DIP ends
     */
    function retrieveAllRewardTokens() external whenPaused onlyOwner {
        for (uint32 tokenId = 1; tokenId < allTokens; tokenId <<= 1) {
            IERC20Upgradeable token = tokens[tokenId];
            uint256 balance = token.balanceOf(address(this));
            token.safeTransfer(msg.sender, balance);
        }
    }

    /**
     * @notice Pause to perform admin functions
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @notice Unpause to allow claiming to resume
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }
}
