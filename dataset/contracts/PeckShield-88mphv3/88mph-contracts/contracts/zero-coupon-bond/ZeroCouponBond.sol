// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.3;

import {
    ERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {
    SafeERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {
    IERC721ReceiverUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import {NFT} from "../tokens/NFT.sol";
import {DInterest} from "../DInterest.sol";
import {Vesting02} from "../rewards/Vesting02.sol";
import {Sponsorable} from "../libs/Sponsorable.sol";

contract ZeroCouponBond is
    ERC20Upgradeable,
    ReentrancyGuardUpgradeable,
    IERC721ReceiverUpgradeable,
    Sponsorable
{
    using SafeERC20Upgradeable for ERC20Upgradeable;

    DInterest public pool;
    ERC20Upgradeable public stablecoin;
    NFT public depositNFT;
    Vesting02 public vesting;
    uint256 public maturationTimestamp;
    uint256 public depositID;
    uint8 public _decimals;

    event WithdrawDeposit();
    event EarlyRedeem(address indexed sender, uint256 bondAmount);
    event RedeemStablecoin(address indexed sender, uint256 amount);

    function initialize(
        address _creator,
        address _pool,
        address _vesting,
        uint256 _maturationTimestamp,
        uint256 _initialDepositAmount,
        string calldata _tokenName,
        string calldata _tokenSymbol
    ) external initializer {
        __ERC20_init(_tokenName, _tokenSymbol);
        __ReentrancyGuard_init();

        pool = DInterest(_pool);
        stablecoin = pool.stablecoin();
        depositNFT = pool.depositNFT();
        maturationTimestamp = _maturationTimestamp;
        vesting = Vesting02(_vesting);

        // set decimals to be the same as the underlying stablecoin
        _decimals = ERC20Upgradeable(address(pool.stablecoin())).decimals();

        // create deposit
        stablecoin.safeTransferFrom(
            _creator,
            address(this),
            _initialDepositAmount
        );
        stablecoin.safeApprove(address(pool), type(uint256).max);
        uint256 interestAmount;
        (depositID, interestAmount) = pool.deposit(
            _initialDepositAmount,
            maturationTimestamp
        );
        _mint(_creator, _initialDepositAmount + interestAmount);
        vesting.safeTransferFrom(
            address(this),
            _creator,
            vesting.depositIDToVestID(depositID)
        );
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
        Public action functions
     */
    /**
        @notice Mint zero coupon bonds by depositing `depositAmount` stablecoins.
        @param depositAmount The amount to deposit for minting zero coupon bonds
        @return mintedAmount The amount of bonds minted
     */
    function mint(uint256 depositAmount)
        external
        nonReentrant
        returns (uint256 mintedAmount)
    {
        return _mintInternal(msg.sender, depositAmount);
    }

    /**
        @notice Redeems zero coupon bonds for the underlying stablecoins before the
                zero coupon bond is mature.
        @param bondAmount The amount of zero coupon bonds to burn
        @return stablecoinsRedeemed The amount of stablecoins redeemed
     */
    function earlyRedeem(uint256 bondAmount)
        external
        nonReentrant
        returns (uint256 stablecoinsRedeemed)
    {
        return _earlyRedeem(msg.sender, bondAmount);
    }

    /**
        @notice Withdraws the underlying deposit from the DInterest pool.
     */
    function withdrawDeposit() external nonReentrant {
        uint256 balance = pool.getDeposit(depositID).virtualTokenTotalSupply;
        require(balance > 0, "ZeroCouponBond: already withdrawn");
        pool.withdraw(depositID, balance, false);

        emit WithdrawDeposit();
    }

    /**
        @notice Redeems zero coupon bonds 1-for-1 for the underlying stablecoins.
        @param amount The amount of zero coupon bonds to burn
        @param withdrawDepositIfNeeded True if withdrawDeposit() should be called if needed, false otherwise (to save gas)
     */
    function redeem(uint256 amount, bool withdrawDepositIfNeeded)
        external
        nonReentrant
    {
        _redeem(msg.sender, amount, withdrawDepositIfNeeded);
    }

    /**
        Sponsored action functions
     */
    /**
        @dev See {mint}
     */
    function sponsoredMint(
        uint256 depositAmount,
        Sponsorship calldata sponsorship
    )
        external
        nonReentrant
        sponsored(
            sponsorship,
            this.sponsoredMint.selector,
            abi.encode(depositAmount)
        )
        returns (uint256 mintedAmount)
    {
        return _mintInternal(sponsorship.sender, depositAmount);
    }

    /**
        @dev See {earlyRedeem}
     */
    function sponsoredEarlyRedeem(
        uint256 bondAmount,
        Sponsorship calldata sponsorship
    )
        external
        nonReentrant
        sponsored(
            sponsorship,
            this.sponsoredEarlyRedeem.selector,
            abi.encode(bondAmount)
        )
        returns (uint256 stablecoinsRedeemed)
    {
        return _earlyRedeem(sponsorship.sender, bondAmount);
    }

    /**
        @dev See {redeem}
     */
    function sponsoredRedeem(
        uint256 amount,
        bool withdrawDepositIfNeeded,
        Sponsorship calldata sponsorship
    )
        external
        nonReentrant
        sponsored(
            sponsorship,
            this.sponsoredRedeem.selector,
            abi.encode(amount, withdrawDepositIfNeeded)
        )
    {
        _redeem(sponsorship.sender, amount, withdrawDepositIfNeeded);
    }

    /**
        Public getter functions
     */

    /**
        @notice Checks whether withdrawDeposit() needs to be called.
        @return True if withdrawDeposit() should be called, false otherwise.
     */
    function withdrawDepositNeeded() external view returns (bool) {
        return pool.getDeposit(depositID).virtualTokenTotalSupply > 0;
    }

    /**
        Internal action functions
     */

    /**
        @dev See {mint}
     */
    function _mintInternal(address sender, uint256 depositAmount)
        internal
        returns (uint256 mintedAmount)
    {
        // transfer stablecoins from `sender`
        stablecoin.safeTransferFrom(sender, address(this), depositAmount);

        // topup deposit
        mintedAmount =
            depositAmount +
            pool.topupDeposit(depositID, depositAmount);

        // mint zero coupon bonds to `msg.sender`
        _mint(sender, mintedAmount);
    }

    /**
        @dev See {earlyRedeem}
     */
    function _earlyRedeem(address sender, uint256 bondAmount)
        internal
        returns (uint256 stablecoinsRedeemed)
    {
        // burn bonds
        _burn(sender, bondAmount);

        // withdraw funds from the pool
        stablecoinsRedeemed = pool.withdraw(depositID, bondAmount, true);

        // transfer funds to sender
        stablecoin.safeTransfer(sender, stablecoinsRedeemed);

        emit EarlyRedeem(sender, bondAmount);
    }

    /**
        @dev See {redeem}
     */
    function _redeem(
        address sender,
        uint256 amount,
        bool withdrawDepositIfNeeded
    ) internal {
        require(
            block.timestamp >= maturationTimestamp,
            "ZeroCouponBond: not mature"
        );

        if (withdrawDepositIfNeeded) {
            uint256 balance =
                pool.getDeposit(depositID).virtualTokenTotalSupply;
            if (balance > 0) {
                pool.withdraw(depositID, balance, false);
                emit WithdrawDeposit();
            }
        }

        // burn `amount` zero coupon bonds from `sender`
        _burn(sender, amount);

        // transfer `amount` stablecoins to `sender`
        stablecoin.safeTransfer(sender, amount);

        emit RedeemStablecoin(sender, amount);
    }

    function onERC721Received(
        address, /*operator*/
        address, /*from*/
        uint256, /*tokenId*/
        bytes memory /*data*/
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    uint256[43] private __gap;
}
