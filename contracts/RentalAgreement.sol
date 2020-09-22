// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import './SafeMath.sol';
import './ProductManager.sol';
import './RentingDappManager.sol';
import './Abstracts/Dayswappers.sol';
import './Abstracts/IKycDapp.sol';

contract RentalAgreement
{
    using SafeMath for uint256;
    
    // This declares a new complex type which will hold the paid rents
    struct PaidRent
    {
        uint256 id;
        uint256 value;
    }
    
    // Variables used
    //Dayswappers public dayswappersContract;
    
    RentingDappManager public manager;
    
    PaidRent[] public paidrents;
    uint256 public createdTimestamp;
    uint256 public maxRent;
    uint256 public payingRent;
    uint256 public security;
    uint256 public cancellationFee;
    uint256 public incentive;
    uint256 public amt;
    uint256[] public possibleRents;
    
    string public item;
    address public lessor;
    address public lessee;
    address public productManager;
    
    bool status;
    uint48 checkLessee;
    uint48 checkLessor;
    uint48 byLessor;
    uint48 byLessee;
    
    enum State { Created, Checked, Started, Terminated }
    enum Check { Lessor_Confirmed, Lessee_Confirmed, Initial_Check, Return_Lessor_Confirmed, Return_Lessee_Confirmed, Final_Check }
    State public state;
    Check public check;
    
    // Deployed by Lessor
    constructor (address _lessor, address _lessee, uint256 _maxrent, uint256 _security, uint256 _cancellationFee, uint256 _incentive, string memory _item, bool _status, uint256[] memory _possibleRents, address _manager) {
        
        //uint256 kyc_level = KYCDApp(msg.sender);
        //require(kyc_level >= 3, "Lessor needs to have minimum KYC level of 3 to proceed ahead");
        //productManager = msg.sender;
        manager = RentingDappManager(_manager);
        lessor = payable(_lessor);
        lessee = payable(_lessee);
        maxRent = _maxrent;
        item = _item;
        security = _security;
        cancellationFee = _cancellationFee;
        incentive = _incentive;
        status = _status;
        
        possibleRents = _possibleRents;
        
        createdTimestamp = block.timestamp;
        state = State.Created;
    }
    
    // Modifiers used
    modifier onlyLessor() {
        require (msg.sender == lessor);
    _;
    }
    modifier onlyLessee() {
        require (msg.sender == lessee);
    _;
    }
    modifier inState(State _state) {
        require (state == _state);
    _;
    }
    modifier inCheck(Check _check) {
        require (check == _check);
    _;
    }
    
    
    // Getters for info from blockchain
    function getPaidRents() view public returns (PaidRent[] memory) {
        return paidrents;
    }
    function getItem() view public returns (string memory) {
        return item;
    }
    function getLessor() view public returns (address) {
        return lessor;
    }
    function getLessee() view public returns (address) {
        return lessee;
    }
    function getRent() view public returns (uint256) {
        return payingRent;
    }
    function getContractCreated() view public returns (uint256) {
        return createdTimestamp;
    }
    function getContractAddress() view public returns (address) {
        return address(this);
    }
    function getState() view public returns (State) {
        return state;
    }
    
    // Events for DApps to listen to
    event checked(Check);
    event agreementConfirmed();
    event paidRent();
    event contractTerminated();
    
    // Functions
    function initialCheckByLessor(uint48 _condition) inState(State.Created) public
    {
        //require(_condition==true, "Condition of item is bad -Lessor");
        require(lessor == msg.sender, "Only lessor can call");
        checkLessor = _condition;
        emit checked(Check.Lessor_Confirmed);
        check = Check.Lessor_Confirmed;
    }
    
    function initialCheckByLessee(uint48 _condition) inCheck(Check.Lessor_Confirmed) public payable
    {
        require(msg.sender != lessor, "Not lessee");
        //require(_condition==true, "Condition of item is bad -Lessee");
        checkLessee = _condition;
        emit checked(Check.Lessee_Confirmed);
        lessee = msg.sender;
        require(msg.value == security, "Security amount needed");
        check = Check.Lessee_Confirmed;
        
        initialCheck();
    }
    
    function initialCheck() inState(State.Created) inCheck(Check.Lessee_Confirmed) public payable
    {
        if(checkLessee == checkLessor && checkLessee == 1)
        {
            emit checked(Check.Initial_Check);
            check = Check.Initial_Check;
            state = State.Checked;
            
            confirmAgreement();
        }
        else
        {
            payable(lessee).transfer(security);
            
            state = State.Terminated;
        }
    }
    
    function confirmAgreement() inState(State.Checked) inCheck(Check.Initial_Check) public
    {
        require(msg.sender == lessee);
        emit agreementConfirmed();
        state = State.Started;
    }
    
    function cancelRent() public payable
    {
        require(state != State.Terminated, "You cannot cancel at this stage");
        require(amt == 0, "You have already started paying your rent");
        
        payable(lessee).transfer(security);
        require(msg.value == cancellationFee);
        emit contractTerminated();
        payable(lessor).transfer(msg.value);
        amt = amt.add(cancellationFee);
        state = State.Terminated;
    }
    
    function payRent() onlyLessee inState(State.Started) payable public
    {
        //require(msg.value == rent);
        
        uint256 f=0;
        
        for(uint256 i=0; i<possibleRents.length; i++)
        {
            if(msg.value == possibleRents[i])
            {
                f=1;
                payingRent = possibleRents[i];
                break;
            }
        }
        
        require(f == 1, "Rent value doesn't come under available rents");
        
        //require(msg.value == payingRent);

        emit paidRent();
        payable(lessor).transfer(msg.value);
        amt = amt.add(payingRent);
        paidrents.push(PaidRent({
        id : paidrents.length + 1,
        value : payingRent
        }));
    }
    
    function finalCheckByLessor(uint48 _condition) onlyLessor inState(State.Started) public
    {
        byLessor = _condition;
        //require(_condition==true, "Condition of item returned is damage -Lessor");
        emit checked(Check.Return_Lessor_Confirmed);
        check = Check.Return_Lessor_Confirmed;
    }
    
    function finalCheckByLessee(uint48 _condition) onlyLessee inState(State.Started) inCheck(Check.Return_Lessor_Confirmed) public
    {
        byLessee = _condition;
        //require(_condition==true, "Condition of item returned is damage -Lessee");
        emit checked(Check.Return_Lessee_Confirmed);
        check = Check.Return_Lessee_Confirmed;
        
        finalCheck();
    }
    
    function finalCheck() inState(State.Started) inCheck(Check.Return_Lessee_Confirmed) private
    {
        require(byLessor==byLessee, "Dispute case: need for Faith Minus");
        emit checked(Check.Final_Check);
        check = Check.Final_Check;
    }
    
    
    function terminateNormally() onlyLessor inState(State.Started) inCheck(Check.Final_Check) public payable
    {
        emit contractTerminated();
        require(byLessee == 1, "Please terminate contract using the 'terminatetWithAdditionalCharges' function");
        payable(lessee).transfer(security);
        
        /* platform fees = 1% incentive % */
        
        state = State.Terminated;
        
        //_payToPlatform();
        //_payIncentive();
    }
    
    function terminateWithAdditionalCharges(uint256 additionalCharges) onlyLessor inState(State.Started) inCheck(Check.Final_Check) public payable
    {
        emit contractTerminated();
        require(byLessee == 0, "You must terminate the contract normally");
        require(additionalCharges <= security, "You cannot charge penalty more than security");
        payable(lessor).transfer(additionalCharges);
        uint256 refund = security.sub(additionalCharges);
        payable(lessee).transfer(refund);
        amt = amt.add(additionalCharges);
        
        /*platform fees = 1% */
        
        state = State.Terminated;
        
        //_payToPlatform();
        //_payIncentive();
    }
    
    function _payToPlatform() onlyLessor inState(State.Terminated) private
    {
        IKycDapp kycDapp = manager.kycContract();
        Dayswappers daySwappers = Dayswappers(kycDapp.resolveAddress("DAYSWAPPERS"));
        
        uint256 _txAmount = amt.mul(1).div(100); 
        uint256 _treeAmount = _txAmount.mul(20).div(100); // 20% of txAmount
        uint256 _introducerAmount = _txAmount.mul(20).div(100); // 20% of txAmount
        
        /// @dev sending value to a payable function along with giving an argument to the method in regard to lessee
        daySwappers.payToTree{value: _treeAmount}(lessee, [uint256(50), uint256(0), uint256(50)]);
        daySwappers.payToIntroducer{value: _introducerAmount}(lessee, [uint256(50), uint256(0), uint256(50)]);
        
        /// @dev sending value to a payable function along with giving an argument to the method in regard to lessor
        daySwappers.payToTree{value: _treeAmount}(lessor, [uint256(50), uint256(0), uint256(50)]);
        daySwappers.payToIntroducer{value: _introducerAmount}(lessor, [uint256(50), uint256(0), uint256(50)]);
        
        /// @dev report volume generated. useful for user to attain a active status.
        daySwappers.reportVolume(lessee, _txAmount);
    }
    
    function _payIncentive() onlyLessor inState(State.Terminated) private
    {
        IKycDapp kycDapp = manager.kycContract();
        Dayswappers daySwappers = Dayswappers(kycDapp.resolveAddress("DAYSWAPPERS"));
        
        require(byLessee == 1, "In cases of dispute or cancellation of rent incentives cannot be paid");
        
        uint256 _txAmount = amt.mul(incentive).div(100);
        uint256 _treeAmount = _txAmount.mul(25).div(100); // 25% of txAmount
        uint256 _introducerAmount = _txAmount.mul(25).div(100); // 25% of txAmount
        
        /// @dev sending value to a payable function along with giving an argument to the method in regard to lessee
        daySwappers.payToTree{value: _treeAmount}(lessee, [uint256(50), uint256(0), uint256(50)]);
        daySwappers.payToIntroducer{value: _introducerAmount}(lessee, [uint256(50), uint256(0), uint256(50)]);
        
        /// @dev sending value to a payable function along with giving an argument to the method in regard to lessor
        daySwappers.payToTree{value: _treeAmount}(lessor, [uint256(50), uint256(0), uint256(50)]);
        daySwappers.payToIntroducer{value: _introducerAmount}(lessor, [uint256(50), uint256(0), uint256(50)]);
        
        /// @dev report volume generated. useful for user to attain a active status.
        daySwappers.reportVolume(lessee, _txAmount);
    }
}