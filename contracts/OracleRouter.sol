// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IOracleRouter.sol";

/// @title OracleRouter
/// @notice Aggregates price feeds from Chainlink or custom oracles and exposes unified interface.
interface AggregatorV3Interface {
        function latestRoundData() external view returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract OracleRouter is IOracleRouter {
    struct Feed {
        address aggregator;
        uint8 decimals;
        bool active;
    }

    mapping(address => Feed) public feeds;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "OracleRouter: not owner");
        _;
    }

    /// @notice Registers or updates a price feed for an asset.
    /// @param asset The address of the asset.
    /// @param aggregator The chainlink aggregator for the asset.
    /// @param decimals The number of decimals returned by the aggregator.
    /// @param active Whether the feed is active.
    function setFeed(address asset, address aggregator, uint8 decimals, bool active) external onlyOwner {
        require(asset != address(0), "OracleRouter: asset zero address");
        require(aggregator != address(0), "OracleRouter: aggregator zero address");
        feeds[asset] = Feed({aggregator: aggregator, decimals: decimals, active: active});
    }

    /// @inheritdoc IOracleRouter
    function getPrice(address asset) external view override returns (uint256) {
        Feed memory feed = feeds[asset];
        require(feed.active, "OracleRouter: inactive feed");
        (, int256 answer,,,) = AggregatorV3Interface(feed.aggregator).latestRoundData();
        require(answer > 0, "OracleRouter: invalid answer");
        // normalise to 18 decimals
        uint256 price = uint256(answer);
        if (feed.decimals < 18) {
            uint256 factor = 10 ** (18 - feed.decimals);
            price = price * factor;
        } else if (feed.decimals > 18) {
            uint256 factor = 10 ** (feed.decimals - 18);
            price = price / factor;
        }
        return price;
  }
}