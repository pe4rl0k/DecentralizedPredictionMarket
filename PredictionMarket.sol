pragma solidity ^0.8.0;

contract PredictionMarket {
    event MarketCreated(uint indexed marketId, string title, string[] options, uint deadline);
    event BetPlaced(uint indexed marketId, address indexed participant, uint option);
    event MarketResolved(uint indexed marketId, uint winningOption);

    struct Market {
        string title;
        string[] options;
        uint deadline;
        bool isResolved;
        uint winningOption;
        mapping(address => uint) participantBets;
        mapping(uint => address[]) bettorsPerOption;
        mapping(address => bool) hasClaimedReward;
        uint totalBets;
    }

    mapping(uint => Market) public markets;
    uint public nextMarketId;

    modifier onlyMarketCreator(uint _marketId) {
        require(markets[_marketId].deadline != 0, "Market does not exist.");
        _;
    }

    modifier beforeDeadline(uint _marketId) {
        require(block.timestamp < markets[_marketId].deadline, "Market has concluded.");
        _;
    }

    modifier onlyAfterResolve(uint _marketId) {
        require(markets[_marketId].isResolved, "Market is not resolved yet.");
        _;
    }

    function createMarket(string memory _title, string[] memory _options, uint _deadline) external {
        require(_options.length > 1, "At least two options required.");
        require(_deadline > block.timestamp, "Deadline must be in the future.");

        uint marketId = nextMarketId++;
        
        Market storage newMarket = markets[marketId];
        newMarket.title = _title;
        newMarket.options = _options;
        newMarket.deadline = _deadline;
        
        emit MarketCreated(marketId, _title, _options, _deadline);
    }

    function placeBet(uint _marketId, uint _option) external beforeDeadline(_marketId) {
        Market storage market = markets[_marketId];
        
        require(_option < market.options.length, "Invalid option selected.");
        require(market.participantBets[msg.sender] == 0, "User has already bet.");

        market.participantBets[msg.sender] = _option + 1;
        market.bettorsPerOption[_option].push(msg.sender);
        market.totalBets++;

        emit BetPlaced(_marketId, msg.sender, _option);
    }

    function declareWinner(uint _marketId, uint _winningOption) external onlyMarketCreator(_marketId) afterDeadline(_marketId) {
        Market storage market = markets[_marketId];

        require(!market.isResolved, "Market already resolved.");
        require(_winningOption < market.options.length, "Invalid option.");

        market.isResolved = true;
        market.winningOption = _winningOption;

        emit MarketResolved(_marketId, _winningOption);
    }

    function claimReward(uint _marketId) external onlyAfterResolve(_marketId) {
        Market storage market = markets[_marketId];
        
        require(!market.hasClaimedReward[msg.sender], "Reward already claimed.");
        uint betOption = market.participantBets[msg.sender];
        require(betOption - 1 == market.winningOption, "Not a winner.");
        
        uint winnersCount = market.bettorsPerOption[market.winningOption].length;
        require(winnersCount > 0, "No winners.");
        
        market.hasClaimedReward[msg.sender] = true;
        uint rewardAmount = address(this).balance / winnersCount;
        
        (bool success, ) = msg.sender.call{value: rewardAmount}("");
        require(success, "Failed to send reward.");
    }
    
    function getMarketDetails(uint _marketId) external view returns (string memory title, string[] memory options, uint deadline, bool isResolved, uint winningOption) {
        Market storage market = markets[_marketId];
        return (market.title, market.options, market.deadline, market.isResolved, market.winningOption);
    }

    function getCurrentBet(uint _marketId, address _participant) external view returns (uint) {
        Market storage market = markets[_marketId];
        return market.participantBets[_participant];
    }

    modifier afterDeadline(uint _marketId) {
        require(block.timestamp > markets[_marketId].deadline, "Market is still active.");
        _;
    }

    receive() external payable {}
    fallback() external payable {}
}