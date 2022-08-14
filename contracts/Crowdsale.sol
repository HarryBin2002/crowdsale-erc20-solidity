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
    }

    using SafeMath for uint256;


    /**
    @title CREATE AND DEFINE MAIN VARIABLE
    */   
    /// @dev funding wallet. Address will receive usdt return.
    address payable fundingWallet; 
    /// @dev address holding token
    address tokenAddress; 
    /// @dev address holding usdt
    address usdtAddress; 
    uint256 public constant decimals = 18; // constant decimals
    /// @dev checking investor is accepted to buy token
    mapping(address => bool) public isInvestor; 
    /// @dev list address => info of address's investor
    mapping(address => InvestorInfor) public investorInfor; 



    /**
    @title CREATE AND DEFINE FUNCTIONALITY VARIABLES IN CONTRACTS 
     */
    /// @dev set amount of token for Crowdsale: 50,000,000
    uint256 public constant crowdsaleAmount = 10000000 * (10**18);
    /// @dev set token price: 0.01 usdt
    uint256 public constant tokenPrice = 1 * 10**(-2) * (10**18);
    /// @dev set minimum deposit: 100 USDT 
    uint256 public constant minDeposit = 100 * (10**18);
    /// @dev set maximum deposit: 500 USDT
    uint256 public constant maxDeposit = 500 * (10**18);
    /**
    @dev Token remaining. 
    @dev Set initial value is equal to crowdsaleAmount. 
    @dev During the crowdsale, tokenRemaining is decrease.
     */ 
    uint256 public tokenRemaining = crowdsaleAmount;
    /**
    @dev Total raised.
    @dev Set initial value is equal to 0.
    @dev During the crowdsale, the raised money(USDT) is increase
     */
    uint256 totalRaised = 0;



    /**
    @title CROWDSALE TIMING AND VESTING TIMING
     */
    /// @dev Open crowdsale time (depends on testing case)
    uint256 public openCrowdsale = 1659941000;
    /// @dev Close crowdsale time (depends on testing case)
    uint256 public closeCrowdsale = 1659941180;
    /// @dev time to start release token to investor (depends on testing case)
    uint256 public releaseTime = 1659941300;
    /// @dev cliff period: 10 minutes.
    uint256 public constant cliffTime = 1 minutes;

    enum VestingStages {
        TGE,
        P2,
        P3,
        P4,
        P5
    }

    /// @dev how many percent of tokens is released per stage.
    mapping(VestingStages => uint256) public unlockPercentTokenPerStage;
    /// @dev which time to release token per stage.
    mapping(VestingStages => uint256) public releaseDatePerStage;

    /// @notice define constructor 
    constructor(
        address payable _fundingWallet,
        address _tokenAddress,
        address _usdtAddress
    ) {
        fundingWallet = _fundingWallet;
        tokenAddress = _tokenAddress;
        usdtAddress = _usdtAddress;

        setUpVestingPlan();
    }

    /**
    @notice the function to set up logic to Vesting plan.
    @dev set how many percent of amount of token is released per stage.
    @dev set when each stage start
     */
    function setUpVestingPlan() internal onlyOwner {
        uint256 firstTimeListingToken = releaseTime;

        unlockPercentTokenPerStage[VestingStages.TGE] = 20;
        unlockPercentTokenPerStage[VestingStages.P2] = 40;
        unlockPercentTokenPerStage[VestingStages.P3] = 60;
        unlockPercentTokenPerStage[VestingStages.P4] = 80;
        unlockPercentTokenPerStage[VestingStages.P5] = 100;


        unlockPercentTokenPerStage[VestingStages.TGE] = firstTimeListingToken;
        unlockPercentTokenPerStage[VestingStages.P2] = firstTimeListingToken + 1 minutes; 
        unlockPercentTokenPerStage[VestingStages.P3] = firstTimeListingToken + 2 minutes;
        unlockPercentTokenPerStage[VestingStages.P4] = firstTimeListingToken + 3 minutes;
        unlockPercentTokenPerStage[VestingStages.P5] = firstTimeListingToken + 4 minutes;
    }



    /**
    @title SET FUNCTION
     */
    
    /**
    @notice set token address.
    @param _tokenAddress a address's wallet is holding the amount of token.
     */
    function setTokenAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
    }

    /**
    @notice set funding wallet.
    @param _fundingWallet the address's wallet is set to the funding wallet.
     */
    function setFundingWallet(address payable _fundingWallet) public onlyOwner {
        fundingWallet = _fundingWallet;
    }



    /**
    @title INVESTOR LIST: ADD AND REMOVE AN ADDRESS'S INVESTOR TO THE LIST
     */

    /**
    @notice create and define a function to add investor into a valid list from an array.
    @param _addressArr an array store a list of address's investor
     */ 
    function addInvestors(address[] memory _addressArr) public onlyOwner {
        for(uint256 index = 0; index < _addressArr.length; index++) {
            address currentAddress = _addressArr[index];
            isInvestor[currentAddress] = true;
        } 
    }

    /**
    @notice remove an investor from the lsit
    @param _addressInvestor an address's investor is needed to remove
     */
    function removeInvestors(address _addressInvestor) public onlyOwner {
        isInvestor[_addressInvestor] = false;
    }



    /**
    @notice deposit amountUSDT of USDT to buy token
    @param amountUSDT the amountUSDT of USDT is deposited 
     */
    function depositUSDT(uint256 amountUSDT) public {
        uint256 pointTimestamp = block.timestamp;

        // checking crowdsale is opening
        require(isOpenCrowdsale(pointTimestamp), "Crowdsale does not open.");

        // checking the address that calls this function is a valid investor
        require(isInvestor[msg.sender], "Invalid Investor");

        // Checking minimum and maximun value deposit
        require(amountUSDT >= minDeposit, "Your value deposit is smaller than minimum deposit");
        require(amountUSDT <= maxDeposit, "Your value deposit is greater than maximun deposit");

        // Calculate the amount of token investor can receive 
        uint256 amountOfTokenInvestorReceive = amountUSDT.div(tokenPrice).mul(10**18);
        require(amountOfTokenInvestorReceive <= tokenRemaining, "Not enough Token for depositing");


        /**
        @dev UPDATING DATA AFTER EACH DEPOSIT AND BUY TOKEN
         */
        // update investor's information
        investorInfor[msg.sender].totalDeposit += amountUSDT;
        investorInfor[msg.sender].totalClaim += amountOfTokenInvestorReceive;

        // update remaining token 
        tokenRemaining -= amountOfTokenInvestorReceive;
        // update raised token
        totalRaised += amountUSDT;


        // Transder amountUSDT from address's investor to funding wallet
        // checking success of that process
        bool transferUSDTSuccess = ERC20(usdtAddress).transferFrom(msg.sender, fundingWallet, amountUSDT);
        require(transferUSDTSuccess, "Transaction failed.");
    }

    /**
    @notice checking crowdsale is opening
    @param _pointTimestamp the time that block is created 
     */
    function isOpenCrowdsale(uint256 _pointTimestamp) public view returns (bool) {
        return (_pointTimestamp > openCrowdsale) && (_pointTimestamp < closeCrowdsale);
    }

    /**
    @notice claimimg token process 
     */
    function claimTokens() public {
        uint256 pointTimestamp = block.timestamp;

        // checking crowdsale is opening
        require(isOpenClaimingProcess(pointTimestamp), "Crowdsale does not open.");

        // checking the address that calls this function is a valid investor
        require(isInvestor[msg.sender], "Invalid Investor");

        // checking the amount of available token can claim
        uint256 availableTokenCanClaim = calculateTokenCanClaim(msg.sender);
        require(availableTokenCanClaim > 0, "There is no Tokens");

        // updating total claimed for investor
        investorInfor[msg.sender].totalClaimed += availableTokenCanClaim;

        // send token to investor 
        // checking success of that process
        bool transferTokenSuccess = ERC20(tokenAddress).transfer(msg.sender, availableTokenCanClaim);
        require(transferTokenSuccess);
    }

    /**
    @notice checking claiming process is opening
     */
    function isOpenClaimingProcess(uint256 _pointTimestamp) public view returns (bool) {
        return _pointTimestamp > (releaseTime + cliffTime);
    }

    /**
    @notice checking the amount of token can be claimed by investor
    @param _addressInvestor the address of investor needs to check the amount of token can be claimed
     */
    function calculateTokenCanClaim(address _addressInvestor) public view returns (uint256) {
        // get total unlocked token of the address's investor
        uint256 totalUnlockedToken = getUnlockedAmountToken(_addressInvestor);
        // calculate the available remaining token that investor can claim
        return totalUnlockedToken - investorInfor[_addressInvestor].totalClaimed;
    }   

    /**
    @notice get the amount of unlocked token
    @param _addressInvestor the address;s investor 
     */
    function getUnlockedAmountToken(address _addressInvestor) internal view returns (uint256) {
        // get index of the vesting stage
        uint256 vestingStageIndex = getVestingStageIndex();

        return (vestingStageIndex == 100) ? 0 : (investorInfor[_addressInvestor].totalClaim).mul(unlockPercentTokenPerStage[VestingStages(vestingStageIndex)]).div(100);
    }

    /**
    @notice get vesting stage index timestamp
     */
    function getVestingStageIndex() public view returns (uint256 idx) {
        uint256 pointTimestamp = block.timestamp;

        if(pointTimestamp < releaseDatePerStage[VestingStages(0)]) {
            return 100;
        } else {
            for(uint256 index = 0; index < 5; ++index) {
                if(pointTimestamp < releaseDatePerStage[VestingStages(index)]) {
                    return index - 1;
                }
            }
        }

        return 4;
    }

    /**
    @title GET FUNCTION - INEVESTOR'S INFORMATION
     */

    /**
    @notice get total deposit of investor 
    @param _addressInvestor the address of investor
     */
    function getTotalDeposit(address _addressInvestor) public view returns (uint256) {
        return investorInfor[_addressInvestor].totalDeposit;
    }

    /**
    @notice get total claim: total amount token can be claimed of investor
    @param _addressInvestor the address of investor
     */
    function getTotalClaim(address _addressInvestor) public view returns (uint256) {
        return investorInfor[_addressInvestor].totalClaim;
    }

    /**
    @notice get total claimed: total amount token is claimed by investor
    @param _addressInvestor the address of investor
     */
    function getTotalClaimed(address _addressInvestor) public view returns (uint256) {
        return investorInfor[_addressInvestor].totalClaimed;
    }

    /**
    @notice get the amount remaining token
    @param _addressInvestor the address of investor
     */
    function getRemainingToken(address _addressInvestor) public view returns (uint256) {
        return investorInfor[_addressInvestor].totalClaim - investorInfor[_addressInvestor].totalClaimed;
    }



    /**
    @title SET FUNCTION: UPDATING TIME CROWDSALE INFORMATION
     */

    /**
    @notice set open and close time crowdsale
    @param _openCrowdsale the time to crowdsale start
    @param _closeCrowdsale the time to crowdsale close
     */
    function _setTimedCrowdsale(uint256 _openCrowdsale, uint256 _closeCrowdsale) public onlyOwner {
        require(_openCrowdsale < _closeCrowdsale);

        openCrowdsale = _openCrowdsale;
        closeCrowdsale = _closeCrowdsale;
    }

    /**
    @notice set release time: claiming process start
    @param _releaseTime the time to claiming process start
     */
    function _setReleaseTime(uint256 _releaseTime) public onlyOwner {
        require(closeCrowdsale < _releaseTime);

        releaseTime = _releaseTime;

        setUpVestingPlan();
    }
}