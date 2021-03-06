// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import "../libraries/SharedStructs.sol";

interface IRevenueManager {
    function initialize(address _axoneRegistry) external;

    function setAssetManager(address _assetManager) external;

    function createAccount(
        uint256 asset_id,
        uint256[] calldata parents_ids,
        uint8[] calldata parents_weights,
        uint256[] calldata children_ids,
        uint8[] calldata children_weights,
        uint256 usage_price
    )   external;

    function distributeRevenue() external;
    
    function setChildWeight(uint256 asset_id, uint256 child_asset_id, uint8 weight) external;

    function setParentWeight(uint256 asset_id, uint256 parent_asset_id, uint8 weight) external;

    function getParentsWeights(uint256 asset_id, uint256[] calldata parents_ids) external view returns(uint8[] memory);

    function getChildrenWeights(uint256 asset_id, uint256[] calldata children_ids) external view returns(uint8[] memory);

    function payForAssetUse(uint256 asset_id) payable external;

    function payRoyalties() external;
    
    function getRevenueAccount(uint256 asset_id) 
        external 
        view 
        returns(SharedStructs.RevenueAccountDetails memory);
}
