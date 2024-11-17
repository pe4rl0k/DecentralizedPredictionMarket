pragma solidity ^0.8.0;

contract PredictionMarket {
    struct Market {
        string title;
        string[] options;
        uint deadline;
        address creator;
        uint[] optionBets;
        mapping(address => bool) hasBet;
        bool winningOptionSet;
        uint winningOption;
    }

    Market[] public markets;
    mapping(uint => mapping(address => uint)) public bets;

    event MarketCreated(uint indexed marketId, string title, string[] options, uint deadline);
    event BetPlaced(uint indexed marketId, address indexed bettor, uint option);
    event WinningOptionDeclared(uint indexed marketId, uint option);
    event RewardClaimed(address indexed claimer, uint amount);
    event MarketInfo(uint indexed marketId, address creator, uint deadline, uint winningOption, bool winningOptionSet);

    modifier isCreator(uint _marketId) {
        require(msg.sender == markets[_marketId].creator, "Not the market creator.");
        _;
    }

    modifier beforeDeadline(uint _marketId) {
        require(block.timestamp < markets[_marketId].deadline, "Market is closed.");
        _;
    }

    modifier afterDeadline(uint _marketId) {
        require(block.timestamp >= markets[_marketId].deadline, "Market is still open.");
        _;
    }

    modifier hasNotBet(uint _marketId) {
        require(!markets[_marketId].hasBet[msg.sender], "Already bet in this market.");
        _;
    }

    function createMarket(string memory _title, string[] memory _options, uint _deadline) external {
        require(_options.length >= 2, "Need at least two options for a market.");
        require(_deadline > block.timestamp, "Deadline must be in the future.");
        uint[] memory optionBets = new uint[](_options.length);
        Market memory newMarket = Market({
            title: _title,
            options: _options,
            deadline: _deadline,
            creator: msg.sender,
            optionBets: optionBets,
            winningOptionSet: false,
            winningOption: 0
        });
        markets.push(newMarket);
        uint marketId = markets.length - 1;
        
        emit MarketCreated(marketId, _title, _options, _deadline);
    }

    function placeBet(uint _marketId, uint _option) external payable beforeDeadline(_marketId) hasNotBet(_marketId) {
        require(_option < markets[_marketId].options.length, "Invalid option.");

        markets[_marketId].hasBet[msg.sender] = true;
        markets[_marketId].optionBets[_option] += msg.value;
        bets[_marketId][msg.sender] = _option;

        emit BetPlaced(_marketId, msg.sender, _option);
    }

    function declareWinningOption(uint _marketId, uint _winningOption) external isCreator(_marketId) afterDeadline(_marketId) {
        require(_winningOption < markets[_marketId].options.length, "Invalid option.");
        require(!markets[_marketId].winningOptionSet, "Winning option already set.");

        markets[_marketId].winningOption = _winningOption;
        markets[_marketId].winningOptionSet = true;

        emit WinningOptionDeclared(_marketId, _winningOption);
    }

    function claimReward(uint _marketId) external afterDeadline(_marketId) {
        require(markets[_marketId].winningOptionSet, "Winning option not set yet.");
        uint option = bets[_marketId][msg.sender];
        require(option == markets[_marketId].winningOption, "Did not bet on winning option.");

        uint totalBetOnOption = markets[_marketId].optionBets[option];
        uint totalBet = 0;
        for(uint i = 0; i < markets[_marketId].options.length; i++) {
            totalBet += markets[_marketId].optionBets[i];
        }

        uint reward = address(this).balance * totalBetOnOption / totalBet;
        payable(msg.sender).transfer(reward);

        emit RewardClaimed(msg.sender, reward);
    }

    function getMarketDetails(uint _marketId) external view returns (
        string memory title,
        string[] memory options,
        uint deadline,
        address creator,
        bool winningOptionSet,
        uint winningOption
    ) {
        Market memory market = markets[_marketId];
        emit MarketInfo(_marketId, market.creator, market.deadline, market.winningOption, market.winningOptionSet);
        return (market.title, market.options, market.deadline, market.creator, market.winningOptionSet, market.winningOption);
    }

    function getCurrentBetAmount(uint _marketId, uint _option) external view returns (uint) {
        return markets[_marketId].optionBets[_option];
    }
}