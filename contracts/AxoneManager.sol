// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";

import "./interfaces/IUserManager.sol";
import "./interfaces/IRevenueManager.sol";
import "./interfaces/IAssetManager.sol";

contract AxoneManager is Initializable {
    
    address owner;
    
    using SafeMath for uint256;

    IUserManager private userManager;
    IRevenueManager private revenueManager;
    IAssetManager private assetManager;

    event NewAsset(uint256 asset_id, uint256 indexed owner_id, string asset_uri);
    event UseAsset(uint256 asset_id, bool use);

    function initialize(
        address _userManager,
        address _revenueManager,
        address _assetManager
    ) public initializer {
        owner = msg.sender;

        userManager = IUserManager(_userManager);
        revenueManager = IRevenueManager(_revenueManager);
        assetManager = IAssetManager(_assetManager);
        revenueManager.setAssetManager(_assetManager);
        assetManager.setRevenueManager(_revenueManager);
    }

    function setOwner(address _owner) public {
        require(owner == msg.sender, "Only owner can change the owner address");
        owner = _owner;
    }

    function registerUser(string memory _profile_uri) public returns (uint256) {
        uint256 user_Id = userManager._registerUser(_profile_uri, msg.sender);
        return user_Id;
    }

    function createAsset
    (
        string memory asset_uri,
        uint256[] memory parents_ids, 
        uint8[] memory parents_weights, 
        uint256 child_id,
        uint8 child_weight
    ) public returns(uint256){
        require(isCallerRegistered(), "Cant create a asset if you are not registered");
        uint256 owner_id = getCallerId();
        uint256 assetId = assetManager.createAsset(
            asset_uri, 
            owner_id, 
            parents_ids, 
            parents_weights,
            child_id, 
            child_weight
        );

        emit NewAsset(assetId, owner_id, asset_uri);

        return assetId;
    }

    function isCallerRegistered() public view returns (bool) {
        return userManager.isAddressRegistered(msg.sender);
    }

    function getAssetsOwnerAddress(address _address) public view returns (uint256[] memory) {
        uint256 owner_Id = userManager.getUserId(_address);
        return assetManager.getOwnerAssets(owner_Id);
    }

    function getAssetsOwnerId(uint256 _owner_Id) public view returns (uint256[] memory) {
        return assetManager.getOwnerAssets(_owner_Id);
    }

    function getNumberOfAssets() public view returns (uint256) {
        return assetManager.getNumberOfAssets();
    }

    function getAsset(uint256 asset_Id)
        public
        view
        returns (
            uint256,
            string memory,
            uint256[] memory,
            uint256[] memory,
            uint8[] memory,
            uint8[] memory,
            uint256,
            uint256,
            uint256,
            uint256,
            uint8
        )
    {
        return (assetManager.getAsset(asset_Id));
    }

    function useAsset(uint256 asset_id) external payable {
        require(msg.value > 0, "No payment received for asset use.");
        assetManager.useAsset(asset_id, msg.value);
        emit UseAsset(asset_id, true);
    }

    function getCallerId() public view returns (uint256) {
        uint256 callerId = userManager.getUserId(msg.sender);
        require(callerId != 0, "Caller is not registered!");
        return callerId;
    }

    function getUserAddress(uint256 _user_Id) public view returns (address) {
        return userManager.getUserAddress(_user_Id);
    }

}