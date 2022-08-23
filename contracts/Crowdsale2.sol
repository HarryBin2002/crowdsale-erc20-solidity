// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract Crowdsale is Ownable {

    struct InvestorInfor {
        uint256 totalDeposit;
        uint256 totalClaim;
        uint256 totalClaimed;
        bool isSecondTimeDepositUSDT; // default is false
    }

    using SafeMath for uint256;

    address tokenAddress;
    address usdtAddress;
    address payable fundingWallet;
    uint256 public constant decimals = 18;

    mapping(address => bool) public isInvestor;
    mapping(address => InvestorInfor) public investorInfor;

    uint256 public constant crowdsalePool = 500000 * (10**18);
    uint256 public constant tokenPrice = 1 * 10**(-1) * (10**18);
    uint256 public constant minDeposit = 200 * (10**18);
    uint256 public constant maxDeposit = 500 * (10**18);

    uint256 public tokenRemaining = crowdsalePool;
    uint256 public totalFunding = 0;

    uint256 public openCrowdsale = 1661239100;
    uint256 public closeCrowdsale = 1661239140;
    uint256 public releaseTime = 1661239160;

    uint256 public constant cliffTime = 3 minutes; // clifftime = timeOf 3 stages

    enum VestingStages {
        TGE,
        P2,
        P3,
        P4,
        P5,
        P6,
        P7,
        P8,
        P9,
        P10
    }

    mapping(VestingStages => uint256) public unlockPercentage;
    mapping(VestingStages => uint256) public releaseDate;

    constructor(
        address payable _fundingWallet,
        address _tokenAddress,
        address _usdtAddress
    ) {
        fundingWallet = _fundingWallet;
        tokenAddress = _tokenAddress;
        usdtAddress = _usdtAddress;


        VestingPlan();
    }

    function VestingPlan() internal onlyOwner {

        uint256 firstListingDate = releaseTime;

        unlockPercentage[VestingStages.TGE] = 10;
        unlockPercentage[VestingStages.P2] = 20;
        unlockPercentage[VestingStages.P3] = 30;
        unlockPercentage[VestingStages.P4] = 40;
        unlockPercentage[VestingStages.P5] = 50;
        unlockPercentage[VestingStages.P6] = 60;
        unlockPercentage[VestingStages.P7] = 70;
        unlockPercentage[VestingStages.P8] = 80;
        unlockPercentage[VestingStages.P9] = 90;
        unlockPercentage[VestingStages.P10] = 100;

        releaseDate[VestingStages.TGE] = firstListingDate;
        releaseDate[VestingStages.P2] = firstListingDate + 1 minutes;
        releaseDate[VestingStages.P3] = firstListingDate + 2 minutes;
        releaseDate[VestingStages.P4] = firstListingDate + 3 minutes;
        releaseDate[VestingStages.P5] = firstListingDate + 4 minutes;
        releaseDate[VestingStages.P6] = firstListingDate + 5 minutes;
        releaseDate[VestingStages.P7] = firstListingDate + 6 minutes;
        releaseDate[VestingStages.P8] = firstListingDate + 7 minutes;
        releaseDate[VestingStages.P9] = firstListingDate + 8 minutes;
        releaseDate[VestingStages.P10] = firstListingDate + 9 minutes;
    }

    address[] public arrAddressInvestor;

    function addInvestors(address[] memory _addressArr) public onlyOwner {
        for (uint256 idx = 0; idx < _addressArr.length; ++idx) {
            address curAddress = _addressArr[idx];
            isInvestor[curAddress] = true;
            arrAddressInvestor.push(curAddress);
        }
    }

    function removeInvestors(address _addressInvestor) public onlyOwner {
        isInvestor[_addressInvestor] = false;
    }
    
    function depositUSDT(uint256 amountUSDT) public {
        require(investorInfor[msg.sender].isSecondTimeDepositUSDT == false, "Your turn is over!");

        uint256 pointTimestamp = block.timestamp;

        require(isOpenCrowdsale(pointTimestamp), "Crowdsale does not open.");

        require(isInvestor[msg.sender], "Invalid Investor");

        require(amountUSDT >= minDeposit, "less than");
        require(amountUSDT <= maxDeposit, "more than");

        uint256 totalTokenReceive = amountUSDT.div(tokenPrice).mul(10**18);
        require(totalTokenReceive <= tokenRemaining, "not enough");

        investorInfor[msg.sender].totalDeposit += amountUSDT;
        investorInfor[msg.sender].totalClaim += totalTokenReceive;

        tokenRemaining = tokenRemaining.sub(totalTokenReceive);
        totalFunding += amountUSDT;

        bool transferUSDTSuccess = ERC20(usdtAddress).transferFrom(msg.sender, fundingWallet, amountUSDT);
        require(transferUSDTSuccess, "Transfer failed");

        investorInfor[msg.sender].isSecondTimeDepositUSDT = true;
    }


    function isOpenCrowdsale(uint256 pointTimestamp) public view returns (bool) {
        return (pointTimestamp > openCrowdsale) && (pointTimestamp < closeCrowdsale);
    }


    function claimTokens() public {
        uint256 pointTimestamp = block.timestamp;

        require(isClaimTiming(pointTimestamp), "Claim Timing does not open");

        require(isInvestor[msg.sender], "Invalid investor");

        uint256 availableTokenToClaim = getAvailableTokenToClaim(msg.sender);
        require(availableTokenToClaim > 0, "available token can be claimed is equal to 0");

        investorInfor[msg.sender].totalClaimed += availableTokenToClaim;

        bool transferTokenSuccess = ERC20(tokenAddress).transfer(msg.sender, availableTokenToClaim);
        require(transferTokenSuccess, "transfer token failed");
    }

    function isClaimTiming(uint256 pointTimestamp) public view returns (bool) {
        return pointTimestamp > (releaseTime + cliffTime);
    }

    function getAvailableTokenToClaim(address _addressInvestor) internal view returns (uint256) {
        uint256 amountUnlockedToken = getAmountUnlockedToken(_addressInvestor);

        return amountUnlockedToken - investorInfor[_addressInvestor].totalClaimed;
    }
    
    function getVestingStageIndex() public view returns (uint256 index) {
        uint256 timestamp = block.timestamp;

        if (timestamp < releaseDate[VestingStages(0)]) {
            return 999;
        } else {
            for (uint256 stageIdx = 0; stageIdx < 10; ++stageIdx) {
                if (timestamp < releaseDate[VestingStages(stageIdx)]) {
                    return stageIdx - 1;
                }
            }
        }

        return 9;
    }

    function getAmountUnlockedToken(address _addressInvestor) internal view returns (uint256) {
        uint256 vestingStageIndex = getVestingStageIndex();

        return vestingStageIndex == 999 
                    ? 0 
                    : investorInfor[_addressInvestor]
                        .totalClaim
                        .mul(unlockPercentage[VestingStages(vestingStageIndex)])
                        .div(100);
    } 


    // CASE: AN ADDRESS IS LOST CONTROLED
    function changeInvestors(address newAddressInvestor, address oldAddressInvestor) public {
        require(msg.sender == oldAddressInvestor);
        investorInfor[newAddressInvestor] = investorInfor[oldAddressInvestor];
        isInvestor[newAddressInvestor] = true;        
        isInvestor[oldAddressInvestor] = false;

        delete investorInfor[oldAddressInvestor];
    }

    //GET FUNCTION - INEVESTOR'S INFORMATION
    function getTotalDeposit(address _addressInvestor) public view returns (uint256) {
        return investorInfor[_addressInvestor].totalDeposit;
    }

    function getTotalClaim(address _addressInvestor) public view returns (uint256) {
        return investorInfor[_addressInvestor].totalClaim;
    }

    function getTotalClaimed(address _addressInvestor) public view returns (uint256) {
        return investorInfor[_addressInvestor].totalClaimed;
    }

    function getRemainingToken(address _addressInvestor) public view returns (uint256) {
        return investorInfor[_addressInvestor].totalClaim - investorInfor[_addressInvestor].totalClaimed;
    }

    /// get whitelist investor
    function getAddressInvestorArr() public view returns (address[] memory) {
        return arrAddressInvestor;
    }


    //SET FUNCTION - CROWDSALE TIME
    function setTimeCrowdsale(uint256 _openCrowdsale, uint256 _closeCrowdsale) public onlyOwner {
        require(_openCrowdsale < _closeCrowdsale);

        openCrowdsale = _openCrowdsale;
        closeCrowdsale = _closeCrowdsale;
    }

    function setReleaseTime(uint256 _releaseTime) public onlyOwner {
        require(closeCrowdsale < _releaseTime);

        releaseTime = _releaseTime;

        VestingPlan();
    }
}