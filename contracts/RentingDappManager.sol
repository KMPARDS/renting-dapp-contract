// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import './SafeMath.sol';
import './ProductManager.sol';

contract RentingDappManager  
{
    using SafeMath for uint256;
    
    address public manager;
    address[] public items;
    mapping(address => bool) public isAuthorised;
    mapping(address => bool) public isAvailable;
    
    event Details(uint256 id, address item);
    
    modifier onlyManager()
    {
        require(msg.sender == manager, "Only manager can call this");
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
        manager = msg.sender;
        isAuthorised[msg.sender] = true;
    }
    
    function addItem (string memory _name, string memory _location, uint256 _maxRent, uint256 _security, uint256 _cancellationFee, string memory _description) public onlyAuthorised
    {
        ProductManager _newProduct = new ProductManager(
            _name,
            _location,
            msg.sender,
            items.length + 1,
            _maxRent,
            _security,
            _cancellationFee,
            _description,
            false  
        );
        
        items.push(address(_newProduct));
        isAvailable[address(_newProduct)] = true;
        
        emit Details(items.length, address(_newProduct));
    }
    
    function removeItem (address _item) public onlyAuthorised
    {
        isAvailable[_item] = false;
    }
    
    function addLessor(address _lessor) public onlyManager {
        isAuthorised[_lessor] = true;
    }
    
    function removeLessor(address _lessor) public onlyManager {
        isAuthorised[_lessor] = false;
    }
}