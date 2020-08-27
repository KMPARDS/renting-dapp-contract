// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

/// KYC DApp
/// @notice if your platform needs to store user information like name, you can instead use KycDapp
/// @dev https://github.com/KMPARDS/esn-contracts/blob/master/contracts/ESN/KycDapp/IKycDapp.sol
interface KycDapp 
{
    function isKycLevel1(address _wallet) external view returns (bool);

    function isKycLevel2(address _wallet, address _platform) external view returns (bool);
    
    function isKycLevel3(address _wallet) external view returns (bool);
}