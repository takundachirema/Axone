// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import "../libraries/SharedStructs.sol";

interface IRevenueManager {
    function initialize(address _axoneRegistry) external;

    function setAssetManager(address _assetManager) external;

    function createAccount(
        uint256 asset_id,
        uint8[] calldata parents_weights,
        uint256 usage_price
    )   external;

    function distributeRevenue() external;
    
    function setChildWeight(uint256 asset_id, uint8 weight) external;

    function setParentWeight(uint256 asset_id, uint8 weight) external;

    function getParentsWeights(uint256 asset_id) external view returns(uint8[] memory);

    function getChildrenWeights(uint256 asset_id) external view returns(uint8[] memory);

    function payForAssetUse(uint256 asset_id) payable external;

    function getRevenueAccount(uint256 asset_id) 
        external 
        view 
        returns(SharedStructs.RevenueAccount memory);
}
