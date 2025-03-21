// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-4.4.1/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-4.4.1/utils/Counters.sol";
import "@openzeppelin/contracts-4.4.1/access/Ownable.sol";
import "@openzeppelin/contracts-4.4.1/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts-4.4.1/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-4.4.1/token/ERC20/utils/SafeERC20.sol";

import "../../interfaces/ISportsAMM.sol";
import "../../interfaces/ISportPositionalMarket.sol";
import "../../interfaces/IPosition.sol";

contract OvertimeVoucher is ERC721URIStorage, Ownable {
    /* ========== LIBRARIES ========== */

    using Counters for Counters.Counter;
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    Counters.Counter private _tokenIds;

    string public _name = "Overtime Voucher";
    string public _symbol = "OVER";
    bool public paused = false;
    string public tokenURITwenty;
    string public tokenURIFifty;
    string public tokenURIHundred;
    string public tokenURITwoHundred;
    string public tokenURIFiveHundred;
    string public tokenURIThousand;

    ISportsAMM public sportsAMM;

    IERC20 public sUSD;
    mapping(uint => uint) public amountInVoucher;

    /* ========== CONSTANTS ========== */
    uint private constant ONE = 1e18;
    uint private constant TWENTY = 20 * 1e18;
    uint private constant FIFTY = 50 * 1e18;
    uint private constant HUNDRED = 100 * 1e18;
    uint private constant TWO_HUNDRED = 200 * 1e18;
    uint private constant FIVE_HUNDRED = 500 * 1e18;
    uint private constant THOUSAND = 1000 * 1e18;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _sUSD,
        string memory _tokenURITwenty,
        string memory _tokenURIFifty,
        string memory _tokenURIHundred,
        string memory _tokenURITwoHundred,
        string memory _tokenURIFiveHundred,
        string memory _tokenURIThousand,
        address _sportsamm
    ) ERC721(_name, _symbol) {
        sUSD = IERC20(_sUSD);
        tokenURITwenty = _tokenURITwenty;
        tokenURIFifty = _tokenURIFifty;
        tokenURIHundred = _tokenURIHundred;
        tokenURITwoHundred = _tokenURITwoHundred;
        tokenURIFiveHundred = _tokenURIFiveHundred;
        tokenURIThousand = _tokenURIThousand;
        sportsAMM = ISportsAMM(_sportsamm);
        sUSD.approve(_sportsamm, type(uint256).max);
    }

    /* ========== TRV ========== */

    function mint(address recipient, uint amount) external returns (uint newItemId) {
        require(!paused, "Cant mint while paused");

        require(
            amount == TWENTY ||
                amount == FIFTY ||
                amount == HUNDRED ||
                amount == TWO_HUNDRED ||
                amount == FIVE_HUNDRED ||
                amount == THOUSAND,
            "Invalid amount"
        );

        sUSD.safeTransferFrom(msg.sender, address(this), amount);

        _tokenIds.increment();

        newItemId = _tokenIds.current();

        _mint(recipient, newItemId);

        _setTokenURI(
            newItemId,
            amount == TWENTY ? tokenURITwenty : amount == FIFTY ? tokenURIFifty : amount == HUNDRED
                ? tokenURIHundred
                : amount == TWO_HUNDRED
                ? tokenURITwoHundred
                : amount == FIVE_HUNDRED
                ? tokenURIFiveHundred
                : tokenURIThousand
        );

        amountInVoucher[newItemId] = amount;
    }

    function buyFromAMMWithVoucher(
        address market,
        ISportsAMM.Position position,
        uint amount,
        uint tokenId
    ) external {
        require(!paused, "Cant buy while paused");
        require(ERC721.ownerOf(tokenId) == msg.sender, "You are not the voucher owner!");

        uint quote = sportsAMM.buyFromAmmQuote(market, position, amount);
        require(quote < amountInVoucher[tokenId], "Insufficient amount in voucher");

        sportsAMM.buyFromAMM(market, position, amount, quote, 0);
        amountInVoucher[tokenId] = amountInVoucher[tokenId] - quote;

        (IPosition home, IPosition away, IPosition draw) = ISportPositionalMarket(market).getOptions();
        IPosition target = position == ISportsAMM.Position.Home ? home : position == ISportsAMM.Position.Away ? away : draw;

        IERC20(address(target)).safeTransfer(msg.sender, amount);

        //if less than 1 sUSD, transfer the rest to the owner and burn
        if (amountInVoucher[tokenId] < 1e18) {
            sUSD.safeTransfer(address(msg.sender), amountInVoucher[tokenId]);
            super._burn(tokenId);
        }
    }

    /* ========== VIEW ========== */

    /* ========== INTERNALS ========== */

    /* ========== CONTRACT MANAGEMENT ========== */

    /// @notice Retrieve sUSD from the contract
    /// @param account whom to send the sUSD
    /// @param amount how much sUSD to retrieve
    function retrieveSUSDAmount(address payable account, uint amount) external onlyOwner {
        sUSD.safeTransfer(account, amount);
    }

    function setTokenUris(
        string memory _tokenURITwenty,
        string memory _tokenURIFifty,
        string memory _tokenURIHundred,
        string memory _tokenURITwoHundred,
        string memory _tokenURIFiveHundred,
        string memory _tokenURIThousand
    ) external onlyOwner {
        tokenURITwenty = _tokenURITwenty;
        tokenURIFifty = _tokenURIFifty;
        tokenURIHundred = _tokenURIHundred;
        tokenURITwoHundred = _tokenURITwoHundred;
        tokenURIFiveHundred = _tokenURIFiveHundred;
        tokenURIThousand = _tokenURIThousand;
    }

    function setPause(bool _state) external onlyOwner {
        paused = _state;
        emit Paused(_state);
    }

    function setSportsAMM(address _sportsAMM) external onlyOwner {
        if (address(_sportsAMM) != address(0)) {
            sUSD.approve(address(sportsAMM), 0);
        }
        sportsAMM = ISportsAMM(_sportsAMM);
        sUSD.approve(_sportsAMM, type(uint256).max);
        emit NewSportsAMM(_sportsAMM);
    }

    /* ========== EVENTS ========== */

    event NewTokenUri(string _tokenURI);
    event NewSportsAMM(address _thalesRoyaleAddress);
    event Paused(bool _state);
}
