// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Project {
    // State variables
    address public owner;
    string public title;
    string public description;
    uint256 public goalAmount;
    uint256 public deadline;
    uint256 public raisedAmount;
    bool public isCompleted;
    bool public isWithdrawn;
    
    // Mapping to track contributions
    mapping(address => uint256) public contributions;
    address[] public contributors;
    
    // Events
    event ContributionMade(address indexed contributor, uint256 amount);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    event RefundIssued(address indexed contributor, uint256 amount);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only project owner can call this function");
        _;
    }
    
    modifier onlyBeforeDeadline() {
        require(block.timestamp < deadline, "Contribution period has ended");
        _;
    }
    
    modifier onlyAfterDeadline() {
        require(block.timestamp >= deadline, "Deadline has not passed yet");
        _;
    }
    
    modifier goalNotReached() {
        require(raisedAmount < goalAmount, "Goal has already been reached");
        _;
    }
    
    // Constructor
    constructor(
        string memory _title,
        string memory _description,
        uint256 _goalAmount,
        uint256 _durationInDays
    ) {
        owner = msg.sender;
        title = _title;
        description = _description;
        goalAmount = _goalAmount;
        deadline = block.timestamp + (_durationInDays * 1 days);
        raisedAmount = 0;
        isCompleted = false;
        isWithdrawn = false;
    }
    
    // Core Function 1: Contribute to the project
    function contribute() external payable onlyBeforeDeadline {
        require(msg.value > 0, "Contribution must be greater than 0");
        require(!isCompleted, "Project funding is already completed");
        
        // If this is a new contributor, add to contributors array
        if (contributions[msg.sender] == 0) {
            contributors.push(msg.sender);
        }
        
        contributions[msg.sender] += msg.value;
        raisedAmount += msg.value;
        
        // Check if goal is reached
        if (raisedAmount >= goalAmount) {
            isCompleted = true;
        }
        
        emit ContributionMade(msg.sender, msg.value);
    }
    
    // Core Function 2: Withdraw funds (only if goal is reached)
    function withdrawFunds() external onlyOwner onlyAfterDeadline {
        require(isCompleted, "Goal was not reached");
        require(!isWithdrawn, "Funds have already been withdrawn");
        require(raisedAmount > 0, "No funds to withdraw");
        
        isWithdrawn = true;
        uint256 amount = raisedAmount;
        
        // Transfer funds to project owner
        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(owner, amount);
    }
    
    // Core Function 3: Get refund (only if goal is not reached after deadline)
    function getRefund() external onlyAfterDeadline goalNotReached {
        require(contributions[msg.sender] > 0, "No contribution found");
        
        uint256 contributionAmount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        
        // Transfer refund to contributor
        (bool success, ) = payable(msg.sender).call{value: contributionAmount}("");
        require(success, "Refund transfer failed");
        
        emit RefundIssued(msg.sender, contributionAmount);
    }
    
    // View functions
    function getProjectDetails() external view returns (
        address projectOwner,
        string memory projectTitle,
        string memory projectDescription,
        uint256 goal,
        uint256 raised,
        uint256 timeLeft,
        bool completed,
        bool withdrawn
    ) {
        uint256 timeRemaining = block.timestamp >= deadline ? 0 : deadline - block.timestamp;
        
        return (
            owner,
            title,
            description,
            goalAmount,
            raisedAmount,
            timeRemaining,
            isCompleted,
            isWithdrawn
        );
    }
    
    function getContributorCount() external view returns (uint256) {
        return contributors.length;
    }
    
    function getContribution(address contributor) external view returns (uint256) {
        return contributions[contributor];
    }
    
    function isGoalReached() external view returns (bool) {
        return raisedAmount >= goalAmount;
    }
    
    function isDeadlinePassed() external view returns (bool) {
        return block.timestamp >= deadline;
    }
}
