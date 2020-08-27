// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import './SafeMath.sol';
import './ProductManager.sol';
import './Abstracts/KycDapp.sol';

contract RentingDappManager  
{
    using SafeMath for uint256;

    KycDapp public kycContract;
    address public owner; //owner
    address[] public items;
    mapping(address => bool) public isAuthorised;
    mapping(address => bool) public isAvailable;
    
    event Details(address lessor, address item);
    
    modifier onlyOwner()
    {
        require(msg.sender == owner, "Only manager can call this");
        _;
    }
    
    modifier onlyAuthorised()
    {
        require(isAuthorised[msg.sender], "Only authorised (Lessee) can call");
        _;
    }
    
    modifier onlyAvailable()
    {
        require(isAvailable[msg.sender], "This item is no longer available");
        _;
    }
    
    constructor()
    {
        owner = msg.sender;
        isAuthorised[msg.sender] = true;
    }
    
    function addItem (string memory _name, string memory _location, uint256 _maxRent, uint256 _security, uint256 _cancellationFee, string memory _description) public onlyAuthorised
    {
        //require(kycContract.isKycLevel3(msg.sender), 'RentingDapp: Require KYC level 3 for listing items');

        ProductManager _newProduct = new ProductManager(
            _name,
            _location,
            msg.sender,
            items.length + 1,
            _maxRent,
            _security,
            _cancellationFee,
            _description,
            false  /*can be managed at product manager*/
        );
        
        items.push(address(_newProduct));
        isAvailable[address(_newProduct)] = true;
        
        emit Details(msg.sender, address(_newProduct)); 
    }
    
    function removeItem (address _item) public onlyAuthorised
    {
        isAvailable[_item] = false;
    }
    
    function addLessor(address _lessor) public onlyOwner {
        require(kycContract.isKycLevel3(msg.sender), 'RentingDapp: Require KYC level 3 for listing items');
        isAuthorised[_lessor] = true;
    }
    
    function removeLessor(address _lessor) public onlyOwner {
        isAuthorised[_lessor] = false;
    }
}