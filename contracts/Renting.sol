// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
contract RentalAgreement
{
    
    // This declares a new complex type which will hold the paid rents
    struct PaidRent
    {
        uint256 id;
        uint256 value;
    }
    
    // Variables used
    PaidRent[] public paidrents;
    uint256 public createdTimestamp;
    uint256 public rent;
    uint256 public security;
    string public item;
    address payable public lessor;
    address payable public lessee;
    bool checkLessee;
    bool checkLessor;
    bool byLessor;
    bool byLessee;
    
    enum State { Created, Checked, Started, Terminated }
    enum Check { Lessor_Confirmed, Lessee_Confirmed, Initial_Check, Return_Lessor_Confirmed, Return_Lessee_Confirmed, Final_Check }
    State public state;
    Check public check;
    
    // Deployed by Lessor
    constructor (uint256 _rent, uint256 _security, string memory _item) {
        rent = _rent;
        item = _item;
        security = _security;
        lessor = msg.sender;
        createdTimestamp = block.timestamp;
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
        return rent;
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
    function initialCheckByLessor(bool _condition) onlyLessor inState(State.Created) public
    {
        //require(_condition==true, "Condition of item is bad -Lessor");
        checkLessor = _condition;
        emit checked(Check.Lessor_Confirmed);
        check = Check.Lessor_Confirmed;
    }
    
    function initialCheckByLessee(bool _condition) inCheck(Check.Lessor_Confirmed) public payable
    {
        require(msg.sender != lessor);
        //require(_condition==true, "Condition of item is bad -Lessee");
        checkLessee = _condition;
        emit checked(Check.Lessee_Confirmed);
        lessee = msg.sender;
        require(msg.value == security);
        check = Check.Lessee_Confirmed;
    }
    
    function initialCheck() inState(State.Created) inCheck(Check.Lessee_Confirmed) public payable
    {
        if(checkLessee == checkLessor && checkLessee == true)
        {
            emit checked(Check.Initial_Check);
            check = Check.Initial_Check;
            state = State.Checked;
        }
        else
        {
            lessee.transfer(security);
            state = State.Terminated;
        }
    }
    
    function confirmAgreement() inState(State.Checked) inCheck(Check.Initial_Check) public
    {
        require(msg.sender == lessee);
        emit agreementConfirmed();
        state = State.Started;
    }
    
    function payRent() onlyLessee inState(State.Started) payable public
    {
        require(msg.value == rent);
        emit paidRent();
        lessor.transfer(msg.value);
        paidrents.push(PaidRent({
        id : paidrents.length + 1,
        value : rent
        }));
    }
    
    function finalCheckByLessor(bool _condition) onlyLessor inState(State.Started) public
    {
        byLessor = _condition;
        //require(_condition==true, "Condition of item returned is damage -Lessor");
        emit checked(Check.Return_Lessor_Confirmed);
        check = Check.Return_Lessor_Confirmed;
    }
    
    function finalCheckByLessee(bool _condition) onlyLessee inState(State.Started) inCheck(Check.Return_Lessor_Confirmed) public
    {
        byLessee = _condition;
        //require(_condition==true, "Condition of item returned is damage -Lessee");
        emit checked(Check.Return_Lessee_Confirmed);
        check = Check.Return_Lessee_Confirmed;
    }
    
    function finalCheck() inState(State.Started) inCheck(Check.Return_Lessee_Confirmed) public
    {
        require(byLessor==byLessee, "Dispute case: need for Faith Minus");
        emit checked(Check.Final_Check);
        check = Check.Final_Check;
    }
    
    function terminateContractNormally() onlyLessor inState(State.Started) inCheck(Check.Final_Check) public payable
    {
        emit contractTerminated();
        require(byLessee == true, "Please terminate contract using the 'terminateContractWithPenalty' function");
        lessee.transfer(security);
        state = State.Terminated;
    }
    
    function terminateContractNormally(uint256 penalty) onlyLessor inState(State.Started) inCheck(Check.Final_Check) public payable
    {
        emit contractTerminated();
        require(byLessee == false, "You must terminate the contract normally");
        require(penalty <= security, "You cannot charge penalty more than security");
        lessor.transfer(penalty);
        uint256 refund = security-penalty;
        lessee.transfer(refund);
        state = State.Terminated;
    }
}