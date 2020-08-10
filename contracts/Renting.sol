// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract RentalAgreement 
{
    /* This declares a new complex type which will hold the paid rents*/
    struct PaidRent 
    {
    uint256 id; /* The paid rent id*/
    uint256 value; /* The amount of rent that is paid*/
    }

    PaidRent[] public paidrents;

    uint256 public createdTimestamp;

    uint256 public rent;
    
    /* Combination of description and id of item*/
    string public item;

    address payable public lessor;

    address public lessee;
    
    enum State {Created, Started, Terminated}
    State public state;

    constructor (uint _rent, string memory _item) {
        rent = _rent;
        item = _item;
        lessor = msg.sender;
        createdTimestamp = block.timestamp;
    }
    
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

    /* Getters so that we can read the values
    from the blockchain at any time */
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


    /* Events for DApps to listen to */
    event agreementConfirmed();

    event paidRent();

    event contractTerminated();

    /* Confirm the lease agreement as lessee*/
    function confirmAgreement()
    inState(State.Created) public 
    {
        require(msg.sender != lessor);
        emit agreementConfirmed();
        lessee = msg.sender;
        state = State.Started;
    }

    /* Pay the lease as lessee*/
    function payRent()
    onlyLessee
    inState(State.Started) payable public 
    {
        require(msg.value == rent);
        emit paidRent();
        lessor.transfer(msg.value);
        paidrents.push(PaidRent({
        id : paidrents.length + 1,
        value : msg.value
        }));
    }
    
    /* Terminate the contract so the lessee can’t pay rent anymore,
    and the contract is terminated */
    function terminateContract()
    onlyLessor public 
    {
        emit contractTerminated();
        lessor.transfer(address(this).balance);
        /* If there is any value on the
               contract send it to the lessor*/
        state = State.Terminated;
    }
}