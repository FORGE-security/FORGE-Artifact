pragma solidity >=0.5.16;

abstract contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    /**
     * @notice Get the underlying price of a vToken asset
     * @param vToken The vToken address to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(address vToken) external view virtual returns (uint256);

    function updatePrice(address vToken) external virtual;
}
