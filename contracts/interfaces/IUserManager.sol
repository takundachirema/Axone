// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUserManager {
    function initialize(address _axoneRegistry) external;

    function _registerUser(string calldata _profile_uri, address _userAddress)
        external
        returns (uint256);

    function isAddressRegistered(address _userAddress)
        external
        view
        returns (bool);

    function getUserId(address _userAddress) external view returns (uint256);

    function getUserAddress(uint256 _user_Id) external view returns (address);

    function getAddressArray(uint256[] calldata _user_Ids)
        external
        view
        returns (address[] memory returnedAddresses_);
}
