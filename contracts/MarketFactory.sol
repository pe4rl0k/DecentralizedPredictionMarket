pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PredictionMarket {
    function distributeRewards() public returns (bool) {
        return true;
    }

    function isActive() public view returns (bool) {
        return true;
    }
}

contract MarketFactory is Ownable {
    address[] private activeMarkets;

    event MarketCreated(address indexed marketAddress);
    event MarketRemoved(address indexed marketAddress);

    function createMarket() external onlyOwner {
        PredictionMarket newMarket = new PredictionMarket();
        activeMarkets.push(address(newMarket));
        emit MarketCreated(address(newMarket));
    }

    function getActiveMarkets() external view returns (address[] memory) {
        return activeMarkets;
    }

    function removeMarket(address marketAddress) external onlyOwner {
        require(PredictionMarket(marketAddress).distributeRewards(), "Distribution of rewards failed.");
        for (uint256 i = 0; i < activeMarkets.length; i++) {
            if (activeMarkets[i] == marketAddress) {
                activeMarkets[i] = activeMarkets[activeMarkets.length - 1];
                activeMarkets.pop();
                emit MarketRemoved(marketAddress);
                break;
            }
        }
    }

    function cleanupInactiveMarkets() external onlyOwner {
        uint256 i = 0;
        while (i < activeMarkets.length) {
            if (!PredictionMarket(activeMarkets[i]).isActive()) {
                emit MarketRemoved(activeMarkets[i]);
                activeMarkets[i] = activeMarkets[activeMarkets.length - 1];
                activeMarkets.pop();
            } else {
                i++;
            }
        }
    }
}