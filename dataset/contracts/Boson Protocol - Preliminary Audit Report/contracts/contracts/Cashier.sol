// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.7.6;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IVoucherKernel.sol";
import "./interfaces/ICashier.sol";
import "./UsingHelpers.sol";

/**
 * @title Contract for managing funds
 * Roughly following OpenZeppelin's Escrow at https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/payment/
 */
contract Cashier is ICashier, UsingHelpers, ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;
    using Address for address payable;
    using SafeMath for uint256;

    address private voucherKernel;
    address private bosonRouterAddress;
    address private tokensContractAddress;
    bool private disasterState;

    enum PaymentType {PAYMENT, DEPOSIT_SELLER, DEPOSIT_BUYER}

    mapping(address => uint256) private escrow; // both types of deposits AND payments >> can be released token-by-token if checks pass
    // slashedDepositPool can be obtained through getEscrowAmount(poolAddress)
    mapping(address => mapping(address => uint256)) private escrowTokens; //token address => mgsSender => amount

    uint256 internal constant CANCELFAULT_SPLIT = 2; //for POC purposes, this is hardcoded; e.g. each party gets depositSe / 2

    event LogBosonRouterSet(address _newBosonRouter, address _triggeredBy);

    event LogTokenContractSet(address _newTokenContract, address _triggeredBy);

    event LogWithdrawal(address _caller, address _payee, uint256 _payment);

    event LogAmountDistribution(
        uint256 indexed _tokenIdVoucher,
        address _to,
        uint256 _payment,
        PaymentType _type
    );

    event LogDisasterStateSet(bool _disasterState, address _triggeredBy);
    event LogWithdrawEthOnDisaster(uint256 _amount, address _triggeredBy);
    event LogWithdrawTokensOnDisaster(
        uint256 _amount,
        address _tokenAddress,
        address _triggeredBy
    );

    modifier onlyFromRouter() {
        require(bosonRouterAddress != address(0), "UNSPECIFIED_BR");
        require(msg.sender == bosonRouterAddress, "UNAUTHORIZED_BR");
        _;
    }

    modifier notZeroAddress(address _addressToCheck) {
        require(_addressToCheck != address(0), "0A");
        _;
    }

    /**
     * @notice The only caller must be tokensContractAddress, otherwise reverts.
     */
    modifier onlyTokensContract() {
        require(msg.sender == tokensContractAddress, "UT"); // Unauthorized token address
        _;
    }

    /**
     * @notice Construct and initialze the contract. Iniialises associated contract addresses. Iniialises disaster state to false.    
     * @param _voucherKernel address of the associated VocherKernal contract instance
     */
    constructor(address _voucherKernel) 
     notZeroAddress(_voucherKernel)
    {
        voucherKernel = _voucherKernel;
        disasterState = false;
    }

    /**
     * @notice Pause the process of interaction with voucherID's (ERC-721), in case of emergency.
     * Only BR contract is in control of this function.
     */
    function pause() external override onlyFromRouter {
        _pause();
    }

    /**
     * @notice Unpause the process of interaction with voucherID's (ERC-721).
     * Only BR contract is in control of this function.
     */
    function unpause() external override onlyFromRouter {
        _unpause();
    }

    /**
     * @notice If once disaster state has been set to true, the contract could never be unpaused.
     */
    function canUnpause() external view override returns (bool) {
        return !disasterState;
    }

    /**
     * @notice Once this functions is triggered, contracts cannot be unpaused anymore
     * Only BR contract is in control of this function.
     */
    function setDisasterState() external onlyOwner whenPaused {
        disasterState = true;
        LogDisasterStateSet(disasterState, msg.sender);
    }

    /**
     * @notice In case of a disaster this function allow the caller to withdraw all pooled funds kept in the escrow for the address provided. Funds are sent in ETH
     */
    function withdrawEthOnDisaster() external whenPaused nonReentrant {
        require(disasterState, "Owner did not allow manual withdraw");

        uint256 amount = escrow[msg.sender];

        require(amount > 0, "ESCROW_EMPTY");
        escrow[msg.sender] = 0;
        msg.sender.sendValue(amount);

        LogWithdrawEthOnDisaster(amount, msg.sender);
    }

    /**
     * @notice In case of a disaster this function allow the caller to withdraw all pooled funds kept in the escrowTokens for the address provided.
     * @param _token address of a token, that the caller sent the funds, while interacting with voucher or voucher-set
     */
    function withdrawTokensOnDisaster(address _token)
        external
        whenPaused
        nonReentrant
        notZeroAddress(_token)
    {
        require(disasterState, "Owner did not allow manual withdraw");

        uint256 amount = escrowTokens[_token][msg.sender];
        require(amount > 0, "ESCROW_EMPTY");
        escrowTokens[_token][msg.sender] = 0;

        SafeERC20.safeTransfer(IERC20(_token), msg.sender, amount);
        LogWithdrawTokensOnDisaster(amount, _token, msg.sender);
    }

    /**
     * @notice Trigger withdrawals of what funds are releasable
     * The caller of this function triggers transfers to all involved entities (pool, issuer, token holder), also paying for gas.
     * @dev This function would be optimized a lot, here verbose for readability.
     * @param _tokenIdVoucher  ID of a voucher token (ERC-721) to try withdraw funds from
     */
    function withdraw(uint256 _tokenIdVoucher)
        external
        override
        nonReentrant
        whenNotPaused
    {
        VoucherDetails memory voucherDetails;

        require(_tokenIdVoucher != 0, "UNSPECIFIED_ID");

        voucherDetails.tokenIdVoucher = _tokenIdVoucher;
        voucherDetails.tokenIdSupply = IVoucherKernel(voucherKernel)
            .getIdSupplyFromVoucher(voucherDetails.tokenIdVoucher);
        voucherDetails.paymentMethod = IVoucherKernel(voucherKernel)
            .getVoucherPaymentMethod(voucherDetails.tokenIdSupply);

        require(
            voucherDetails.paymentMethod > 0 &&
                voucherDetails.paymentMethod <= 4,
            "INVALID PAYMENT METHOD"
        );

        (
            voucherDetails.currStatus.status,
            voucherDetails.currStatus.isPaymentReleased,
            voucherDetails.currStatus.isDepositsReleased,
            ,
        ) = IVoucherKernel(voucherKernel).getVoucherStatus(
            voucherDetails.tokenIdVoucher
        );

        (
            voucherDetails.price,
            voucherDetails.depositSe,
            voucherDetails.depositBu
        ) = IVoucherKernel(voucherKernel).getOrderCosts(
            voucherDetails.tokenIdSupply
        );

        voucherDetails.issuer = payable(
            IVoucherKernel(voucherKernel).getSupplyHolder(
                voucherDetails.tokenIdSupply
            )
        );
        voucherDetails.holder = payable(
            IVoucherKernel(voucherKernel).getVoucherHolder(
                voucherDetails.tokenIdVoucher
            )
        );

        //process the RELEASE OF PAYMENTS - only depends on the redeemed/not-redeemed, a voucher need not be in the final status
        if (!voucherDetails.currStatus.isPaymentReleased) {
            releasePayments(voucherDetails);
        }

        //process the RELEASE OF DEPOSITS - only when vouchers are in the FINAL status
        if (
            !voucherDetails.currStatus.isDepositsReleased &&
            isStatus(voucherDetails.currStatus.status, IDX_FINAL)
        ) {
            releaseDeposits(voucherDetails);
        }

        if (voucherDetails.deposit2pool > 0) {
            _withdrawDeposits(
                owner(),
                voucherDetails.deposit2pool,
                voucherDetails.paymentMethod,
                voucherDetails.tokenIdSupply
            );
        }

        if (voucherDetails.price2issuer > 0) {
            _withdrawPayments(
                voucherDetails.issuer,
                voucherDetails.price2issuer,
                voucherDetails.paymentMethod,
                voucherDetails.tokenIdSupply
            );
        }

        if (voucherDetails.deposit2issuer > 0) {
            _withdrawDeposits(
                voucherDetails.issuer,
                voucherDetails.deposit2issuer,
                voucherDetails.paymentMethod,
                voucherDetails.tokenIdSupply
            );
        }

        if (voucherDetails.price2holder > 0) {
            _withdrawPayments(
                voucherDetails.holder,
                voucherDetails.price2holder,
                voucherDetails.paymentMethod,
                voucherDetails.tokenIdSupply
            );
        }

        if (voucherDetails.deposit2holder > 0) {
            _withdrawDeposits(
                voucherDetails.holder,
                voucherDetails.deposit2holder,
                voucherDetails.paymentMethod,
                voucherDetails.tokenIdSupply
            );
        }

        delete voucherDetails;
    }

    /**
     * @notice Release of payments, for a voucher which payments had not been released already.
     * Based on the voucher status(e.g. redeemed, refunded, etc), the voucher price will be sent to either buyer or seller.
     * @param _voucherDetails keeps all required information of the voucher which the payment should be released for.
     */
    function releasePayments(VoucherDetails memory _voucherDetails) internal {
        if (isStatus(_voucherDetails.currStatus.status, IDX_REDEEM)) {
            releasePaymentToSeller(_voucherDetails);
        } else if (
            isStatus(_voucherDetails.currStatus.status, IDX_REFUND) ||
            isStatus(_voucherDetails.currStatus.status, IDX_EXPIRE) ||
            (isStatus(_voucherDetails.currStatus.status, IDX_CANCEL_FAULT) &&
                !isStatus(_voucherDetails.currStatus.status, IDX_REDEEM))
        ) {
            releasePaymentToBuyer(_voucherDetails);
        }
    }

    /**
     * @notice Following function `releasePayments`, if certain conditions for the voucher status are met, the voucher price will be sent to the seller
     * @param _voucherDetails keeps all required information of the voucher which the payment should be released for.
     */
    function releasePaymentToSeller(VoucherDetails memory _voucherDetails)
        internal
    {
        if (
            _voucherDetails.paymentMethod == ETHETH ||
            _voucherDetails.paymentMethod == ETHTKN
        ) {
            escrow[_voucherDetails.holder] = escrow[_voucherDetails.holder].sub(
                _voucherDetails.price
            );
        }
        if (
            _voucherDetails.paymentMethod == TKNETH ||
            _voucherDetails.paymentMethod == TKNTKN
        ) {
            address addressTokenPrice =
                IVoucherKernel(voucherKernel).getVoucherPriceToken(
                    _voucherDetails.tokenIdSupply
                );

            escrowTokens[addressTokenPrice][
                _voucherDetails.holder
            ] = escrowTokens[addressTokenPrice][_voucherDetails.holder].sub(
                _voucherDetails.price
            );
        }

        _voucherDetails.price2issuer = _voucherDetails.price2issuer.add(
            _voucherDetails.price
        );

        IVoucherKernel(voucherKernel).setPaymentReleased(
            _voucherDetails.tokenIdVoucher
        );

        LogAmountDistribution(
            _voucherDetails.tokenIdVoucher,
            _voucherDetails.issuer,
            _voucherDetails.price,
            PaymentType.PAYMENT
        );
    }

    /**
     * @notice Following function `releasePayments`, if certain conditions for the voucher status are met, the voucher price will be sent to the buyer
     * @param _voucherDetails keeps all required information of the voucher, which the payment should be released for.
     */
    function releasePaymentToBuyer(VoucherDetails memory _voucherDetails)
        internal
    {
        if (
            _voucherDetails.paymentMethod == ETHETH ||
            _voucherDetails.paymentMethod == ETHTKN
        ) {
            escrow[_voucherDetails.holder] = escrow[_voucherDetails.holder].sub(
                _voucherDetails.price
            );
        }

        if (
            _voucherDetails.paymentMethod == TKNETH ||
            _voucherDetails.paymentMethod == TKNTKN
        ) {
            address addressTokenPrice =
                IVoucherKernel(voucherKernel).getVoucherPriceToken(
                    _voucherDetails.tokenIdSupply
                );

            escrowTokens[addressTokenPrice][
                _voucherDetails.holder
            ] = escrowTokens[addressTokenPrice][_voucherDetails.holder].sub(
                _voucherDetails.price
            );
        }

        _voucherDetails.price2holder = _voucherDetails.price2holder.add(
            _voucherDetails.price
        );

        IVoucherKernel(voucherKernel).setPaymentReleased(
            _voucherDetails.tokenIdVoucher
        );

        LogAmountDistribution(
            _voucherDetails.tokenIdVoucher,
            _voucherDetails.holder,
            _voucherDetails.price,
            PaymentType.PAYMENT
        );
    }

    /**
     * @notice Release of deposits, for a voucher which deposits had not been released already, and had been marked as `finalized`
     * Based on the voucher status(e.g. complained, redeemed, refunded, etc), the voucher deposits will be sent to either buyer, seller, or pool owner.
     * Depending on the payment type (e.g ETH, or Token) escrow funds will be held in the `escrow` || escrowTokens mappings
     * @param _voucherDetails keeps all required information of the voucher which the deposits should be released for.
     */
    function releaseDeposits(VoucherDetails memory _voucherDetails) internal {
        //first, depositSe
        if (isStatus(_voucherDetails.currStatus.status, IDX_COMPLAIN)) {
            //slash depositSe
            distributeIssuerDepositOnHolderComplain(_voucherDetails);
        } else {
            if (isStatus(_voucherDetails.currStatus.status, IDX_CANCEL_FAULT)) {
                //slash depositSe
                distributeIssuerDepositOnIssuerCancel(_voucherDetails);
            } else {
                //release depositSe
                distributeFullIssuerDeposit(_voucherDetails);
            }
        }

        //second, depositBu
        if (
            isStatus(_voucherDetails.currStatus.status, IDX_REDEEM) ||
            isStatus(_voucherDetails.currStatus.status, IDX_CANCEL_FAULT)
        ) {
            //release depositBu
            distributeFullHolderDeposit(_voucherDetails);
        } else {
            //slash depositBu
            distributeHolderDepositOnNotRedeemedNotCancelled(_voucherDetails);
        }

        IVoucherKernel(voucherKernel).setDepositsReleased(
            _voucherDetails.tokenIdVoucher
        );
    }

    /**
     * @notice Following function `releaseDeposits` this function will be triggered if a voucher had been complained by the buyer.
     * Also checks if the voucher had been cancelled
     * @param _voucherDetails keeps all required information of the voucher which the payment should be released for.
     */
    function distributeIssuerDepositOnHolderComplain(
        VoucherDetails memory _voucherDetails
    ) internal {
        if (isStatus(_voucherDetails.currStatus.status, IDX_CANCEL_FAULT)) {
            //appease the conflict three-ways
            if (
                _voucherDetails.paymentMethod == ETHETH ||
                _voucherDetails.paymentMethod == TKNETH
            ) {
                escrow[_voucherDetails.issuer] = escrow[_voucherDetails.issuer]
                    .sub(_voucherDetails.depositSe);
            }

            if (
                _voucherDetails.paymentMethod == ETHTKN ||
                _voucherDetails.paymentMethod == TKNTKN
            ) {
                address addressTokenDeposits =
                    IVoucherKernel(voucherKernel).getVoucherDepositToken(
                        _voucherDetails.tokenIdSupply
                    );

                escrowTokens[addressTokenDeposits][
                    _voucherDetails.issuer
                ] = escrowTokens[addressTokenDeposits][_voucherDetails.issuer]
                    .sub(_voucherDetails.depositSe);
            }

            uint256 tFraction = _voucherDetails.depositSe.div(CANCELFAULT_SPLIT);
            _voucherDetails.deposit2holder = _voucherDetails.deposit2holder.add(
                tFraction
            ); //Bu gets, say, a half
            _voucherDetails.deposit2issuer = _voucherDetails.deposit2issuer.add(
                tFraction.div(CANCELFAULT_SPLIT)
            ); //Se gets, say, a quarter
            _voucherDetails.deposit2pool = _voucherDetails.deposit2pool.add(
                (_voucherDetails.depositSe.sub(tFraction)).sub(
                    tFraction.div(CANCELFAULT_SPLIT)
                )
            ); //slashing the rest

            LogAmountDistribution(
                _voucherDetails.tokenIdVoucher,
                _voucherDetails.holder,
                tFraction,
                PaymentType.DEPOSIT_SELLER
            );
            LogAmountDistribution(
                _voucherDetails.tokenIdVoucher,
                _voucherDetails.issuer,
                tFraction.div(CANCELFAULT_SPLIT),
                PaymentType.DEPOSIT_SELLER
            );
            LogAmountDistribution(
                _voucherDetails.tokenIdVoucher,
                owner(),
                (_voucherDetails.depositSe.sub(tFraction)).sub(
                    tFraction.div(CANCELFAULT_SPLIT)
                ),
                PaymentType.DEPOSIT_SELLER
            );

            tFraction = 0;
        } else {
            //slash depositSe
            if (
                _voucherDetails.paymentMethod == ETHETH ||
                _voucherDetails.paymentMethod == TKNETH
            ) {
                escrow[_voucherDetails.issuer] = escrow[_voucherDetails.issuer]
                    .sub(_voucherDetails.depositSe);
            } else {
                address addressTokenDeposits =
                    IVoucherKernel(voucherKernel).getVoucherDepositToken(
                        _voucherDetails.tokenIdSupply
                    );

                escrowTokens[addressTokenDeposits][
                    _voucherDetails.issuer
                ] = escrowTokens[addressTokenDeposits][_voucherDetails.issuer]
                    .sub(_voucherDetails.depositSe);
            }

            _voucherDetails.deposit2pool = _voucherDetails.deposit2pool.add(
                _voucherDetails.depositSe
            );

            LogAmountDistribution(
                _voucherDetails.tokenIdVoucher,
                owner(),
                _voucherDetails.depositSe,
                PaymentType.DEPOSIT_SELLER
            );
        }
    }

    /**
     * @notice Following function `releaseDeposits` this function will be triggered if a voucher had been cancelled by the seller.
     * Will be triggered if the voucher had not been complained.
     * @param _voucherDetails keeps all required information of the voucher which the deposits should be released for.
     */
    function distributeIssuerDepositOnIssuerCancel(
        VoucherDetails memory _voucherDetails
    ) internal {
        if (
            _voucherDetails.paymentMethod == ETHETH ||
            _voucherDetails.paymentMethod == TKNETH
        ) {
            escrow[_voucherDetails.issuer] = escrow[_voucherDetails.issuer].sub(
                _voucherDetails.depositSe
            );
        }

        if (
            _voucherDetails.paymentMethod == ETHTKN ||
            _voucherDetails.paymentMethod == TKNTKN
        ) {
            address addressTokenDeposits =
                IVoucherKernel(voucherKernel).getVoucherDepositToken(
                    _voucherDetails.tokenIdSupply
                );

            escrowTokens[addressTokenDeposits][
                _voucherDetails.issuer
            ] = escrowTokens[addressTokenDeposits][_voucherDetails.issuer].sub(
                _voucherDetails.depositSe
            );
        }

        _voucherDetails.deposit2issuer = _voucherDetails.deposit2issuer.add(
            _voucherDetails.depositSe.div(CANCELFAULT_SPLIT)
        );

        _voucherDetails.deposit2holder = _voucherDetails.deposit2holder.add(
            _voucherDetails.depositSe.sub(
                _voucherDetails.depositSe.div(CANCELFAULT_SPLIT)
            )
        );

        LogAmountDistribution(
            _voucherDetails.tokenIdVoucher,
            _voucherDetails.issuer,
            _voucherDetails.depositSe.div(CANCELFAULT_SPLIT),
            PaymentType.DEPOSIT_SELLER
        );

        LogAmountDistribution(
            _voucherDetails.tokenIdVoucher,
            _voucherDetails.holder,
            _voucherDetails.depositSe.sub(
                _voucherDetails.depositSe.div(CANCELFAULT_SPLIT)
            ),
            PaymentType.DEPOSIT_SELLER
        );
    }

    /**
     * @notice Following function `releaseDeposits` this function will be triggered if no complain, nor cancel had been made.
     * All seller deposit is returned to seller.
     * @param _voucherDetails keeps all required information of the voucher which the deposits should be released for.
     */
    function distributeFullIssuerDeposit(VoucherDetails memory _voucherDetails)
        internal
    {
        if (
            _voucherDetails.paymentMethod == ETHETH ||
            _voucherDetails.paymentMethod == TKNETH
        ) {
            escrow[_voucherDetails.issuer] = escrow[_voucherDetails.issuer].sub(
                _voucherDetails.depositSe
            );
        }

        if (
            _voucherDetails.paymentMethod == ETHTKN ||
            _voucherDetails.paymentMethod == TKNTKN
        ) {
            address addressTokenDeposits =
                IVoucherKernel(voucherKernel).getVoucherDepositToken(
                    _voucherDetails.tokenIdSupply
                );

            escrowTokens[addressTokenDeposits][
                _voucherDetails.issuer
            ] = escrowTokens[addressTokenDeposits][_voucherDetails.issuer].sub(
                _voucherDetails.depositSe
            );
        }

        _voucherDetails.deposit2issuer = _voucherDetails.deposit2issuer.add(
            _voucherDetails.depositSe
        );

        LogAmountDistribution(
            _voucherDetails.tokenIdVoucher,
            _voucherDetails.issuer,
            _voucherDetails.depositSe,
            PaymentType.DEPOSIT_SELLER
        );
    }

    /**
     * @notice Following function `releaseDeposits` this function will be triggered if voucher had been redeemed, or the seller had cancelled.
     * All buyer deposit is returned to buyer.
     * @param _voucherDetails keeps all required information of the voucher which the deposits should be released for.
     */
    function distributeFullHolderDeposit(VoucherDetails memory _voucherDetails)
        internal
    {
        if (
            _voucherDetails.paymentMethod == ETHETH ||
            _voucherDetails.paymentMethod == TKNETH
        ) {
            escrow[_voucherDetails.holder] = escrow[_voucherDetails.holder].sub(
                _voucherDetails.depositBu
            );
        }

        if (
            _voucherDetails.paymentMethod == ETHTKN ||
            _voucherDetails.paymentMethod == TKNTKN
        ) {
            address addressTokenDeposits =
                IVoucherKernel(voucherKernel).getVoucherDepositToken(
                    _voucherDetails.tokenIdSupply
                );

            escrowTokens[addressTokenDeposits][
                _voucherDetails.holder
            ] = escrowTokens[addressTokenDeposits][_voucherDetails.holder].sub(
                _voucherDetails.depositBu
            );
        }

        _voucherDetails.deposit2holder = _voucherDetails.deposit2holder.add(
            _voucherDetails.depositBu
        );

        LogAmountDistribution(
            _voucherDetails.tokenIdVoucher,
            _voucherDetails.holder,
            _voucherDetails.depositBu,
            PaymentType.DEPOSIT_BUYER
        );
    }

    /**
     * @notice Following function `releaseDeposits` this function will be triggered if voucher had not been redeemed or cancelled after finalization.
     * @param _voucherDetails keeps all required information of the voucher which the deposits should be released for.
     * All buyer deposit goes to Boson.
     */
    function distributeHolderDepositOnNotRedeemedNotCancelled(
        VoucherDetails memory _voucherDetails
    ) internal {
        if (
            _voucherDetails.paymentMethod == ETHETH ||
            _voucherDetails.paymentMethod == TKNETH
        ) {
            escrow[_voucherDetails.holder] = escrow[_voucherDetails.holder].sub(
                _voucherDetails.depositBu
            );
        }

        if (
            _voucherDetails.paymentMethod == ETHTKN ||
            _voucherDetails.paymentMethod == TKNTKN
        ) {
            address addressTokenDeposits =
                IVoucherKernel(voucherKernel).getVoucherDepositToken(
                    _voucherDetails.tokenIdSupply
                );

            escrowTokens[addressTokenDeposits][
                _voucherDetails.holder
            ] = escrowTokens[addressTokenDeposits][_voucherDetails.holder].sub(
                _voucherDetails.depositBu
            );
        }

        _voucherDetails.deposit2pool = _voucherDetails.deposit2pool.add(
            _voucherDetails.depositBu
        );

        LogAmountDistribution(
            _voucherDetails.tokenIdVoucher,
            owner(),
            _voucherDetails.depositBu,
            PaymentType.DEPOSIT_BUYER
        );
    }

    /**
     * @notice External function for withdrawing deposits. Caller must be the seller of the goods, otherwise reverts.
     * @notice Seller triggers withdrawals of remaining deposits for a given supply, in case the voucher set is no longer in exchange.
     * @param _tokenIdSupply an ID of a supply token (ERC-1155) which will be burned and deposits will be returned for
     * @param _burnedQty burned quantity that the deposits should be withdrawn for
     * @param _messageSender owner of the voucher set
     */
    function withdrawDepositsSe(
        uint256 _tokenIdSupply,
        uint256 _burnedQty,
        address payable _messageSender
    ) external override nonReentrant onlyFromRouter {
        uint256 deposit =
            IVoucherKernel(voucherKernel).getSellerDeposit(_tokenIdSupply);

        uint256 depositAmount = deposit.mul(_burnedQty);

        uint8 paymentMethod =
            IVoucherKernel(voucherKernel).getVoucherPaymentMethod(
                _tokenIdSupply
            );

        require(
            paymentMethod > 0 && paymentMethod <= 4,
            "INVALID PAYMENT METHOD"
        );

        if (paymentMethod == ETHETH || paymentMethod == TKNETH) {
            escrow[_messageSender] = escrow[_messageSender].sub(depositAmount);
        }

        if (paymentMethod == ETHTKN || paymentMethod == TKNTKN) {
            address addressTokenDeposits =
                IVoucherKernel(voucherKernel).getVoucherDepositToken(
                    _tokenIdSupply
                );

            escrowTokens[addressTokenDeposits][_messageSender] = escrowTokens[
                addressTokenDeposits
            ][_messageSender]
                .sub(depositAmount);
        }

        _withdrawDeposits(
            _messageSender,
            depositAmount,
            paymentMethod,
            _tokenIdSupply
        );
    }

    /**
     * @notice Internal function for withdrawing payments.
     * As unbelievable as it is, neither .send() nor .transfer() are now secure to use due to EIP-1884
     *  So now transferring funds via the last remaining option: .call()
     *  See https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/
     * @param _recipient    address of the account receiving funds from the escrow
     * @param _amount       amount to be released from escrow
     * @param _paymentMethod payment method that should be used to determine, how to do the payouts
     * @param _tokenIdSupply       _tokenIdSupply of the voucher set this is related to
     */
    function _withdrawPayments(
        address _recipient,
        uint256 _amount,
        uint8 _paymentMethod,
        uint256 _tokenIdSupply
    ) internal
      notZeroAddress(_recipient)
    {
        require(_amount > 0, "");

        if (_paymentMethod == ETHETH || _paymentMethod == ETHTKN) {
            payable(_recipient).sendValue(_amount);
            emit LogWithdrawal(msg.sender, _recipient, _amount);
        }

        if (_paymentMethod == TKNETH || _paymentMethod == TKNTKN) {
            address addressTokenPrice =
                IVoucherKernel(voucherKernel).getVoucherPriceToken(
                    _tokenIdSupply
                );

            SafeERC20.safeTransfer(
                IERC20(addressTokenPrice),
                _recipient,
                _amount
            );
        }
    }

    /**
     * @notice Internal function for withdrawing deposits.
     * @param _recipient    address of the account receiving funds from the escrow
     * @param _amount       amount to be released from escrow
     * @param _paymentMethod       payment method that should be used to determine, how to do the payouts
     * @param _tokenIdSupply       _tokenIdSupply of the voucher set this is related to
     */
    function _withdrawDeposits(
        address _recipient,
        uint256 _amount,
        uint8 _paymentMethod,
        uint256 _tokenIdSupply
    ) internal    
      notZeroAddress(_recipient)
    {
        require(_amount > 0, "");

        if (_paymentMethod == ETHETH || _paymentMethod == TKNETH) {
            payable(_recipient).sendValue(_amount);
            emit LogWithdrawal(msg.sender, _recipient, _amount);
        }

        if (_paymentMethod == ETHTKN || _paymentMethod == TKNTKN) {
            address addressTokenDeposits =
                IVoucherKernel(voucherKernel).getVoucherDepositToken(
                    _tokenIdSupply
                );

            SafeERC20.safeTransfer(
                IERC20(addressTokenDeposits),
                _recipient,
                _amount
            );
        }
    }

    /**
     * @notice Set the address of the BR contract
     * @param _bosonRouterAddress   The address of the Boson Route contract
     */
    function setBosonRouterAddress(address _bosonRouterAddress)
        external
        override
        onlyOwner
    {
        require(_bosonRouterAddress != address(0), "UNSPECIFIED_ADDRESS");

        bosonRouterAddress = _bosonRouterAddress;

        emit LogBosonRouterSet(_bosonRouterAddress, msg.sender);
    }

    /**
     * @notice Set the address of the ERC1155ERC721 contract
     * @param _tokensContractAddress   The address of the ERC1155ERC721 contract
     */
    function setTokenContractAddress(address _tokensContractAddress)
        external
        override
        onlyOwner
    {
     
        require(_tokensContractAddress != address(0), "UNSPECIFIED_ADDRESS");
        tokensContractAddress = _tokensContractAddress;
        emit LogTokenContractSet(_tokensContractAddress, msg.sender);
    }


    /**
     * @notice Update the amount in escrow of an address with the new value, based on VoucherSet/Voucher interaction
     * @param _account  The address of an account to update
     */
    function addEscrowAmount(address _account)
        external
        override
        payable
        onlyFromRouter
    {
        escrow[_account] = escrow[_account].add(msg.value);
    }

    /**
     * @notice Update the amount in escrowTokens of an address with the new value, based on VoucherSet/Voucher interaction
     * @param _token  The address of a token to query
     * @param _account  The address of an account to query
     * @param _newAmount  New amount to be set
     */
    function addEscrowTokensAmount(
        address _token,
        address _account,
        uint256 _newAmount
    ) external override onlyFromRouter {
        escrowTokens[_token][_account] =  escrowTokens[_token][_account].add(_newAmount);
    }

    /**
     * @notice Hook which will be triggered when a _tokenIdVoucher will be transferred. Escrow funds should be allocated to the new owner.
     * @param _from prev owner of the _tokenIdVoucher
     * @param _to next owner of the _tokenIdVoucher
     * @param _tokenIdVoucher _tokenIdVoucher that has been transferred
     */
    function onERC721Transfer(
        address _from,
        address _to,
        uint256 _tokenIdVoucher
    ) external override onlyTokensContract {
        address tokenAddress;

        uint256 tokenSupplyId =
            IVoucherKernel(voucherKernel).getIdSupplyFromVoucher(
                _tokenIdVoucher
            );

        uint8 paymentType =
            IVoucherKernel(voucherKernel).getVoucherPaymentMethod(
                tokenSupplyId
            );

        (uint256 price, uint256 depositBu) =
            IVoucherKernel(voucherKernel).getBuyerOrderCosts(tokenSupplyId);

        if (paymentType == ETHETH) {
            uint256 totalAmount = price.add(depositBu);

            //Reduce _from escrow amount and increase _to escrow amount
            escrow[_from] = escrow[_from].sub(totalAmount);
            escrow[_to] = escrow[_to].add(totalAmount);
        }


        if (paymentType == ETHTKN) {

            //Reduce _from escrow amount and increase _to escrow amount - price
            escrow[_from] = escrow[_from].sub(price);
            escrow[_to] = escrow[_to].add(price);

            tokenAddress = IVoucherKernel(voucherKernel).getVoucherDepositToken(
                tokenSupplyId
            );

            //Reduce _from escrow token amount and increase _to escrow token amount - deposit
            escrowTokens[tokenAddress][_from] = escrowTokens[tokenAddress][_from].sub(depositBu);
            escrowTokens[tokenAddress][_to] = escrowTokens[tokenAddress][_to].add(depositBu);

        }

        if (paymentType == TKNETH) {
            tokenAddress = IVoucherKernel(voucherKernel).getVoucherPriceToken(
                tokenSupplyId
            );
        

            //Reduce _from escrow token amount and increase _to escrow token amount - price 
            escrowTokens[tokenAddress][_from] = escrowTokens[tokenAddress][_from].sub(price);
            escrowTokens[tokenAddress][_to] = escrowTokens[tokenAddress][_to].add(price);

            //Reduce _from escrow amount and increase _to escrow amount - deposit
            escrow[_from] = escrow[_from].sub(depositBu);
            escrow[_to] = escrow[_to].add(depositBu);
        }

        if (paymentType == TKNTKN) {
            tokenAddress = IVoucherKernel(voucherKernel).getVoucherPriceToken(
                tokenSupplyId
            );


            //Reduce _from escrow token amount and increase _to escrow token amount - price 
            escrowTokens[tokenAddress][_from] = escrowTokens[tokenAddress][_from].sub(price);
            escrowTokens[tokenAddress][_to] = escrowTokens[tokenAddress][_to].add(price);

            tokenAddress = IVoucherKernel(voucherKernel).getVoucherDepositToken(
                tokenSupplyId
            );

            //Reduce _from escrow token amount and increase _to escrow token amount - deposit 
            escrowTokens[tokenAddress][_from] = escrowTokens[tokenAddress][_from].sub(depositBu);
            escrowTokens[tokenAddress][_to] = escrowTokens[tokenAddress][_to].add(depositBu);

        }
    }

    /**
     * @notice After the transfer happens the _tokenSupplyId should be updated in the promise. Escrow funds for the seller's deposits (If in ETH) should be allocated to the new owner as well.
     * @param _from prev owner of the _tokenSupplyId
     * @param _to nex owner of the _tokenSupplyId
     * @param _tokenSupplyId _tokenSupplyId for transfer
     * @param _value qty which has been transferred
     */
    function onERC1155Transfer(
        address _from,
        address _to,
        uint256 _tokenSupplyId,
        uint256 _value
    ) external override onlyTokensContract {
        uint8 paymentType =
            IVoucherKernel(voucherKernel).getVoucherPaymentMethod(
                _tokenSupplyId
            );

        uint256 depositSe;
        uint256 totalAmount;

        if (paymentType == ETHETH || paymentType == TKNETH) {
            depositSe = IVoucherKernel(voucherKernel).getSellerDeposit(
                _tokenSupplyId
            );
            totalAmount = depositSe.mul(_value);

            //Reduce _from escrow amount and increase _to escrow amount
            escrow[_from] = escrow[_from].sub(totalAmount);
            escrow[_to] = escrow[_to].add(totalAmount);
        }

        if (paymentType == ETHTKN || paymentType == TKNTKN) {
            address tokenDepositAddress =
                IVoucherKernel(voucherKernel).getVoucherDepositToken(
                    _tokenSupplyId
                );

            depositSe = IVoucherKernel(voucherKernel).getSellerDeposit(
                _tokenSupplyId
            );
            totalAmount = depositSe.mul(_value);

            //Reduce _from escrow token amount and increase _to escrow token amount - deposit
            escrowTokens[tokenDepositAddress][_from] = escrowTokens[tokenDepositAddress][_from].sub(totalAmount);
            escrowTokens[tokenDepositAddress][_to] = escrowTokens[tokenDepositAddress][_to].add(totalAmount);
        }

        IVoucherKernel(voucherKernel).setSupplyHolderOnTransfer(
            _tokenSupplyId,
            _to
        );
    }

    /**
     * @notice Only accept ETH via fallback from the BR Contract
     */
    receive() external payable {
        require(msg.sender == bosonRouterAddress, "INVALID_PAYEE");
    }

    // // // // // // // //
    // GETTERS
    // // // // // // // //

    /**
     * @notice Get the address of Voucher Kernel contract
     * @return Address of Voucher Kernel contract
     */
    function getVoucherKernelAddress() 
        external 
        view 
        override
        returns (address)
    {
        return voucherKernel;
    }

    /**
     * @notice Get the address of Boson Router contract
     * @return Address of Boson Router contract
     */
    function getBosonRouterAddress() 
        external 
        view 
        override
        returns (address)
    {
        return bosonRouterAddress;
    }

    /**
     * @notice Get the address of ERC1155ERC721 contract
     * @return Address of ERC1155ERC721 contract
     */
    function getTokensContractAddress() 
        external 
        view 
        override
        returns (address)
    {
        return tokensContractAddress;
    }

    /**
     * @notice Ensure whether or not contract has been set to disaster state 
     * @return disasterState
     */
    function isDisasterStateSet() external view override returns(bool) {
        return disasterState;
    }

    /**
     * @notice Get the amount in escrow of an address
     * @param _account  The address of an account to query
     * @return          The balance in escrow
     */
    function getEscrowAmount(address _account)
        external
        view
        override
        returns (uint256)
    {
        return escrow[_account];
    }

    /**
     * @notice Get the amount in escrow of an address
     * @param _token  The address of a token to query
     * @param _account  The address of an account to query
     * @return          The balance in escrow
     */
    function getEscrowTokensAmount(address _token, address _account)
        external
        view
        override
        returns (uint256)
    {
        return escrowTokens[_token][_account];
    }
}
