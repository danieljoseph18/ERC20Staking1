// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

//WARNING: UPDATE TOKENOMICS IF UTILISING, INFLATION VERY HIGH

/// @custom:security-contact contact@altify.io
contract DanStakingToken is ERC20, ERC20Burnable, Ownable, ReentrancyGuard {

    //Max Supply = 1T
    uint64 immutable maxSupply = 1000000000000;
    //Claim = Airdrop Token Claim
    uint32 claim = 100000;

    //Number of tokens currently staked by User.
    mapping(address => uint) public amountStaked;
    //Current Staking Rewards available to User.
    mapping(address => uint) stakingRewards;
    
    //Timer to calculate Stake Earning Rate
    mapping(address => uint) public stakeTimer;
    mapping(address => bool) public hasClaimed;


    constructor() ERC20("DanToken", "DTK") {
        //90% to Contract for Distribution, 10% to Team
        uint _toContract = (maxSupply/10)*9;
        uint _toTeam = (maxSupply/10);

        _mint(msg.sender, _toTeam);
        _mint(address(this), _toContract);
    }

    receive() external payable {}


    //Every Wallet Address can claim 100,000 Tokens.
    function claimTokens() external {
        require(hasClaimed[msg.sender] == false, "You have already claimed your allocated tokens.");
        hasClaimed[msg.sender] = true;
        _transfer(address(this), msg.sender, claim);
    }

    //Claims All Earnings from Staking Pool.
    function claimEarnings() external {
        uint _earnings = _getAllRewards();
        require(_earnings > 0, "You haven't earned anything");
        require(balanceOf(address(this)) > _earnings, "Inflation limit reached");

        stakingRewards[msg.sender] = 0;
        stakeTimer[msg.sender] = block.timestamp;

        _transfer(address(this), msg.sender, _earnings);
    }

    //Withdraw any ETH Sent to the Contract.
    function withdrawFunds() external onlyOwner returns(bool){
        uint _withdrawable = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: _withdrawable}("");
        return success;
    }


    //Stake tokens at a rate of 1 per token per second.
    function stake(uint _amount) external nonReentrant {
        require(_amount > 0, "Amount to stake cannot be 0");
        require(balanceOf(msg.sender) >= _amount, "You don't own that many tokens");
        
        stakingRewards[msg.sender] += calculateEarnings();
        stakeTimer[msg.sender] = block.timestamp;

        amountStaked[msg.sender] += _amount;
        _transfer(msg.sender, address(this), _amount);
    }

    //Unstake a given amount of tokens.
    function unstake(uint _amount) external  nonReentrant {
        require(_amount > 0, "Amount to unstake cannot be 0");
        require(amountStaked[msg.sender] >= _amount, "You don't have that many tokens staked");

        stakingRewards[msg.sender] += calculateEarnings();
        stakeTimer[msg.sender] = block.timestamp;
        
        amountStaked[msg.sender] -= _amount;
        _transfer(address(this), msg.sender, _amount);
    }

    //Stakes Entire Balance.
    function stakeAll() external {
        uint _balance = balanceOf(msg.sender);
        require(_balance > 0, "You don't have anything to stake");
        
        stakingRewards[msg.sender] += calculateEarnings();
        stakeTimer[msg.sender] = block.timestamp;

        amountStaked[msg.sender] += _balance;
        _transfer(msg.sender, address(this), _balance);
    }

    //Unstakes All Staked Tokens.
    function unstakeAll() external {
        require(amountStaked[msg.sender] > 0, "You haven't got any tokens staked");

        stakingRewards[msg.sender] += calculateEarnings();
        uint _stake = amountStaked[msg.sender];

        amountStaked[msg.sender] = 0;
        stakeTimer[msg.sender] = 0;
        _transfer(address(this), msg.sender, _stake);
    }

    //Burns Entire Balance.
    function burnAll() external {
        uint _balance = balanceOf(msg.sender);
        require(_balance > 0, "You don't have anything to burn");
        _burn(msg.sender, _balance);
    }

    //Calculates Current Earnings from Staking.
    function calculateEarnings() internal view returns(uint) {
        if(stakeTimer[msg.sender] == 0){
            return 0;
        }

        uint _duration = block.timestamp - stakeTimer[msg.sender];
        uint _currentStakeAmount = amountStaked[msg.sender];

        if(_currentStakeAmount == 0){
            return stakingRewards[msg.sender];
        } else {
            return (_currentStakeAmount * _duration);    
        }
    }

    //Getter Function for Stake Earnings.
    function getAllRewards() external view returns(uint){
        return _getAllRewards();
    }

    //Displays Earnings from Staking Rewards.
    function _getAllRewards() internal view returns(uint){
        if(calculateEarnings() > 0){
            return stakingRewards[msg.sender] + calculateEarnings();
        } else {
            return stakingRewards[msg.sender];
        }
    }

}