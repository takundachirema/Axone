// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import "../libraries/SharedStructs.sol";

interface IAssetManager {
    function initialize(address _axoneRegistry) external;

    function createAsset
    (
        string calldata asset_uri, 
        uint256 owner_id,
        uint256 asset_usage_price,
        uint256[] calldata parents, 
        uint8[] calldata parents_weights, 
        uint256 child,
        uint8 child_weight
    )   external 
        returns (uint256);

    function setRevenueManager(address _revenueManager) external;

    function getOwnerId(uint256 asset_Id)
        external
        view
        returns (uint256);
    
    function getOwnerAddress(uint256 asset_Id)
        external
            view
            returns (address);

    function getChildrenIds(uint256 asset_id) 
        external 
        view
        returns (uint256[] memory);
    
    function getParentIds(uint256 asset_id) 
        external 
        view
        returns (uint256[] memory, uint256[] memory);

    function getLatestAuctionId(uint256 asset_Id)
        external
        view
        returns (uint256);

    function getAsset(uint256 asset_Id)
        external
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
        );
    
    function useAsset(uint256 asset_id, uint256 revenue)
        external;

    function getAssets()
        external
        view
        returns (SharedStructs.Asset[] memory);

    function getNumberOfAssets() 
        external 
        view 
        returns (uint256);

    function getOwnerAssets(uint256 owner_Id)
        external
        view
        returns (uint256[] memory);
}
