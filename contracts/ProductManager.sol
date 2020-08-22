// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import './SafeMath.sol';
import './RentalAgreement.sol';

contract ProductManager
{
    using SafeMath for uint256;
     
    address[] public rents;
    address public manager;
     
    mapping(address => bool) public isAuthorised;
    mapping(address => bool) public isRentValid;
    
    uint256[] public discounts;
    
    string public lessorName;
    string public location;
    address public lessorAddress;
    uint256 public itemId;
    uint256 public maxRent;
    uint256 public security;
    uint256 public cancellationFee;
    
    string public description;
    bool public isRented; 
     
    event NewRentalContract(
        address indexed _deployer, 
        address _contractAddress, 
        uint256 _rent, 
        uint256 _security, 
        uint256 _cancellationFee,
        uint256 _incentive,
        string _item
    );
    
    event NewRenting(
        address indexed _rentAddress,
        address indexed _lessorAddress,
        address indexed _lesseeAddress,
        string _item
    );
    
    event EndRentalContract(
        address indexed _lessor,
        address indexed _contractAddress
    );
     
    modifier onlyManager()
    {
        require(msg.sender == manager, "Only manager can call this");
        _;
    }
     
    modifier onlyAuthorised()
    {
        require(msg.sender == lessorAddress, "Only authorised (Lessor) can call");
        _;
    }
     
    modifier onlyRentalContract()
    {
        require(isRentValid[msg.sender], "Only rental contract can call");
        _;
    }
     

    
    constructor(string memory _name, string memory _location, address _address, uint256 _id, uint256 _maxRent, uint256 _security, uint256 _cancellationFee, string memory _description, bool _status)
    {
        manager = msg.sender;
        //isAuthorised[msg.sender] = true;
        
        lessorName = _name;
        location = _location;
        lessorAddress = _address;
        itemId = _id;
        maxRent = _maxRent;
        security = _security;
        cancellationFee = _cancellationFee;
        description = _description;
        isRented = _status;
        
        isAuthorised[lessorAddress] = true;
    }
     


    function addDiscount(uint256 _discount) public onlyAuthorised
    {
        discounts.push(_discount);        
    }
    
    function removeDiscount(uint256 _discount) public onlyAuthorised
    {
        for(uint256 i=0; i<discounts.length; i++)
        {
            if(discounts[i] == _discount)
            discounts[i] = 0;
        }
    }
     
    function createAgreement(uint256 _incentive, uint256 _time) public onlyAuthorised returns (address)
    {
        //require(msg.sender != manager, "Only Lessor can create a rental agreement for his listing");
        
        require(isRented == false, "Item currently under rent...not available");
        
        RentalAgreement _newRentalAgreement = new RentalAgreement(lessorAddress, maxRent, security, cancellationFee, _incentive, description, _time, isRented, discounts);

        rents.push(address(_newRentalAgreement));
        isRentValid[address(_newRentalAgreement)] = true;
        isRented = true;
     
        emit NewRentalContract(lessorAddress, address(_newRentalAgreement), maxRent, security, cancellationFee, _incentive, description);
        
        return address(_newRentalAgreement); 
    }
     
    function getNumberOfRents() public view returns (uint256) {
        return rents.length;
    }
    
    
    function emitNewRentingEvent(address _lessorAddress, address _lesseeAddress, string memory _item) public onlyRentalContract {
        emit NewRenting(msg.sender, _lessorAddress, _lesseeAddress, _item);
    }
    
    function getDiscounts() public view returns(uint256[] memory)
    {
        return discounts;
    }
    
    function emitEndEvent(address _lessor) public onlyRentalContract {
        emit EndRentalContract(_lessor, msg.sender);
    }
    
    function endAgreement() public onlyRentalContract
    {
        isRented = false;
    }
}