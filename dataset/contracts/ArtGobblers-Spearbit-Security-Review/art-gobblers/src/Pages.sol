// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {VRGDA} from "./utils/vrgda/VRGDA.sol";
import {LibString} from "./utils/lib/LibString.sol";
import {PagesERC721} from "./utils/token/PagesERC721.sol";
import {LogisticVRGDA} from "./utils/vrgda/LogisticVRGDA.sol";
import {PostSwitchVRGDA} from "./utils/vrgda/PostSwitchVRGDA.sol";

import {Goo} from "./Goo.sol";

/// @title Pages NFT
/// @author FrankieIsLost <frankie@paradigm.xyz>
/// @author transmissions11 <t11s@paradigm.xyz>
/// @notice Pages is an ERC721 that can hold custom art.
contract Pages is PagesERC721, LogisticVRGDA, PostSwitchVRGDA {
    using LibString for uint256;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice The address of the goo ERC20 token contract.
    Goo public immutable goo;

    /// @notice The address which receives pages reserved for the community.
    address public immutable community;

    /*//////////////////////////////////////////////////////////////
                                  URIS
    //////////////////////////////////////////////////////////////*/

    /// @notice Base URI for minted pages.
    string public BASE_URI;

    /*//////////////////////////////////////////////////////////////
                            VRGDA INPUT STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Timestamp for the start of the VRGDA mint.
    uint256 public immutable mintStart;

    /// @notice Id of the most recently minted page.
    /// @dev Will be 0 if no pages have been minted yet.
    uint128 public currentId;

    /*//////////////////////////////////////////////////////////////
                          COMMUNITY PAGES STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice The number of pages minted to the community reserve.
    uint128 public numMintedForCommunity;

    /*//////////////////////////////////////////////////////////////
                            PRICING CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @dev The day the switch from a logistic to translated linear VRGDA is targeted to occur.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal constant SWITCH_DAY_WAD = 270e18;

    /// @notice The minimum amount of pages that must be sold for the VRGDA issuance
    /// schedule to switch from logistic to the "post switch" translated linear formula.
    /// @dev Computed off-chain by plugging the switch day into the uninverted pacing formula.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal constant SOLD_BY_SWITCH_WAD = 8598.35810341741976233e18;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event PagePurchased(address indexed user, uint256 indexed pageId, uint256 price);

    event CommunityPagesMinted(address indexed user, uint256 lastMintedPageId, uint256 numPages);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error ReserveImbalance();

    error PriceExceededMax(uint256 currentPrice);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        // Mint config:
        uint256 _mintStart,
        // Addresses:
        Goo _goo,
        address _community,
        address _artGobblers,
        // URIs:
        string memory _baseUri
    )
        VRGDA(
            4.2069e18, // Initial price.
            0.31e18 // Per period price decrease.
        )
        LogisticVRGDA(
            9000e18, // Asymptote.
            0.014e18 // Time scale.
        )
        PostSwitchVRGDA(
            SOLD_BY_SWITCH_WAD, // Sold by switch.
            SWITCH_DAY_WAD, // Target switch day.
            10e18 // Pages to target per day.
        )
        PagesERC721(_artGobblers, "Pages", "PAGE")
    {
        mintStart = _mintStart;

        goo = _goo;

        community = _community;

        BASE_URI = _baseUri;
    }

    /*//////////////////////////////////////////////////////////////
                              MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint a page with goo, burning the cost.
    /// @param maxPrice Maximum price to pay to mint the page.
    /// @return pageId The id of the page that was minted.
    function mintFromGoo(uint256 maxPrice) external returns (uint256 pageId) {
        // Will revert if prior to mint start.
        uint256 currentPrice = pagePrice();

        // If the current price is above the user's specified max, revert.
        if (currentPrice > maxPrice) revert PriceExceededMax(currentPrice);

        goo.burnForPages(msg.sender, currentPrice);

        unchecked {
            emit PagePurchased(msg.sender, pageId = ++currentId, currentPrice);

            _mint(msg.sender, pageId);
        }
    }

    /// @notice Calculate the mint cost of a page.
    /// @dev If the number of sales is below a pre-defined threshold, we use the
    /// VRGDA pricing algorithm, otherwise we use the post-switch pricing formula.
    /// @dev Reverts due to underflow if minting hasn't started yet. Done to save gas.
    function pagePrice() public view returns (uint256) {
        // We need checked math here to cause overflow
        // before minting has begun, preventing mints.
        uint256 timeSinceStart = block.timestamp - mintStart;

        unchecked {
            // The number of pages minted for the community reserve
            // cannot ever exceed 10% of the total supply of pages.
            return getPrice(timeSinceStart, currentId - numMintedForCommunity);
        }
    }

    function getTargetDayForNextSale(int256 tokens)
        internal
        view
        override(LogisticVRGDA, PostSwitchVRGDA)
        returns (int256)
    {
        return
            tokens < SOLD_BY_SWITCH_WAD
                ? LogisticVRGDA.getTargetDayForNextSale(tokens)
                : PostSwitchVRGDA.getTargetDayForNextSale(tokens);
    }

    /*//////////////////////////////////////////////////////////////
                      COMMUNITY PAGES MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint a number of pages to the community reserve.
    /// @param numPages The number of pages to mint to the reserve.
    /// @dev Pages minted to the reserve cannot compromise more than 10% of the sum of the
    /// supply of goo minted pages and the supply of pages minted to the community reserve.
    function mintCommunityPages(uint256 numPages) external returns (uint256 lastMintedPageId) {
        unchecked {
            // Optimistically increment numMintedForCommunity, may be reverted below.
            // Overflow in this calculation is possible but numPages would have to
            // be so large that it would cause the loop to run out of gas quickly.
            uint256 newNumMintedForCommunity = numMintedForCommunity += uint128(numPages);

            // Ensure that after this mint pages minted to the community reserve won't compromise more than
            // 10% of the new total page supply. currentId is equivalent to the current total supply of pages.
            if (newNumMintedForCommunity > ((lastMintedPageId = currentId) + numPages) / 10) revert ReserveImbalance();

            // Mint the pages to the community reserve while updating lastMintedPageId.
            for (uint256 i = 0; i < numPages; i++) _mint(community, ++lastMintedPageId);

            currentId = uint128(lastMintedPageId); // Update currentId with the last minted page id.

            emit CommunityPagesMinted(msg.sender, lastMintedPageId, numPages);
        }
    }

    /*//////////////////////////////////////////////////////////////
                             TOKEN URI LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns a pages's URI if it has been minted.
    /// @param pageId The id of the page to get the URI for.
    function tokenURI(uint256 pageId) public view virtual override returns (string memory) {
        if (pageId > currentId) return "";

        return string(abi.encodePacked(BASE_URI, pageId.toString()));
    }
}
