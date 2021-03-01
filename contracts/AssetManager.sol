// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./libraries/SharedStructs.sol";
import "./interfaces/IRevenueManager.sol";

contract AssetManager is Initializable {

    using SafeMath for uint256;

    IRevenueManager private revenueManager;

    enum PricingStrategy { PrivateAuction, FixedRate, PrivateAuctionHarberger }

    SharedStructs.Asset[] public assets;

    mapping(uint256 => uint256[]) public assetOwners;

    address registry;

    uint256 internal maxDepth;

    modifier onlyRegistry() {
        require(msg.sender == registry, "Can only be called by registry");
        _;
    }
    
    function setRevenueManager(address _revenueManager) public onlyRegistry {
        revenueManager = IRevenueManager(_revenueManager);
    }

    function initialize(address _axonRegistry) public initializer {
        registry = _axonRegistry;
        maxDepth = 3;
    }

    function setMaxDepth(uint256 _maxDepth) public onlyRegistry {
        maxDepth = _maxDepth;
    }

    function createAsset
    (
        string memory asset_uri, 
        uint256 owner_id,
        uint256[] memory parents, 
        uint8[] memory parents_weights, 
        uint256 child_id,
        uint8 child_weight
    )   public onlyRegistry returns (uint256) {

        require(bytes(asset_uri).length > 0, "Asset URI should not be empty.");
        require(parents.length == parents_weights.length, "Each parent must have a corresponding weight.");

        uint256[] memory children;
        uint256 assetId = assets.length + 1;
        SharedStructs.Asset memory asset = SharedStructs.Asset(
            assetId, 
            asset_uri, 
            parents, 
            children,
            owner_id, 
            0,
            0,
            0,
            0
        );

        revenueManager.createAccount(
            assetId,
            parents_weights
        );

        assets.push(asset);

        // get asset parents and put in the asset as a child
        for (uint256 i = 0; i < parents.length; i++) {
            uint256 parent_id = parents[i];

            if (parent_id > 0 && parent_id <= assets.length){
                assets[parent_id - 1].children.push(assetId);
                revenueManager.setChildWeight(parent_id, parents_weights[i]);
            }
        }

        // get asset child an put this asset as its parent
        if (child_id > 0 && child_id <= assets.length){
            assets[assetId - 1].children.push(child_id);
            assets[child_id - 1].parents.push(assetId);
            revenueManager.setChildWeight(assetId, child_weight);
            revenueManager.setParentWeight(child_id, child_weight);
        }

        return assetId;
    }

    function getAsset(uint256 asset_id)
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
        require(asset_id > 0 && assets.length >= asset_id, "SharedStructs.Asset does not exist");
        SharedStructs.Asset memory asset = assets[asset_id - 1];

        SharedStructs.RevenueAccount memory account = revenueManager.getRevenueAccount(asset_id);

        return (
            asset.asset_id,
            asset.asset_uri,
            asset.parents,
            asset.children,
            account.parents_weights,
            account.children_weights,
            asset.owner_id,
            asset.sell_price,
            asset.revenue,
            asset.total_revenue,
            asset.pricing_strategy
        );
    }

    function getChildren(uint256 asset_id) public view returns (SharedStructs.Asset[] memory) {
        require(asset_id <= assets.length, "SharedStructs.Asset not found");
        
        SharedStructs.Asset memory asset = assets[asset_id];
        uint256[] memory children = asset.children;
        SharedStructs.Asset[] memory results = new SharedStructs.Asset[](children.length);

        for (uint256 i = 0; i < children.length; i++) {
            SharedStructs.Asset memory child = assets[children[i] - 1];
            results[i] = child;
        }

        return results;
    }

    function getChildrenIds(uint256 asset_id) public view returns (uint256[] memory) {
        require(asset_id <= assets.length, "Asset not found");
        return assets[asset_id].children;
    }

    function getParentIds(uint256 asset_id) public view returns (uint256[] memory) {
        require(asset_id <= assets.length, "Asset not found");
        return assets[asset_id].parents;
    }

    function getAssets() public view returns (SharedStructs.Asset[] memory) {
        return assets;
    }

    function useAsset(uint256 asset_id, uint256 revenue) public onlyRegistry {
        require(assets.length > asset_id, "Asset does not exist");
        SharedStructs.Asset storage asset = assets[asset_id-1];
        asset.revenue = asset.revenue.add(revenue);
        asset.total_revenue = asset.total_revenue.add(revenue);
    }

    function getNumberOfAssets() public view returns (uint256) {
        return assets.length;
    }

    function setAssetPrice(uint256 _asset_id, uint256 sell_price) public onlyRegistry {
        require(sell_price > 0, "Sell price should be more than 0");
        assets[_asset_id - 1].sell_price = sell_price;
    }

    function setAssetPricingStrategy(uint256 _asset_id, uint8 pricing_strategy) public onlyRegistry {
        require(pricing_strategy > 0, "Pricing strategy should be more than 0");
        assets[_asset_id].pricing_strategy = pricing_strategy;
    }

    function addAssetRevenue(uint256 _asset_id, uint256 revenue) public onlyRegistry {
        require(revenue > 0, "Revenue should be more than 0");
        uint256 currentRevenue = assets[_asset_id].total_revenue;
        assets[_asset_id].total_revenue = currentRevenue + revenue;
    }

    function getAssetRevenue(uint256 asset_id) public view returns (uint256) {
        require(assets.length > asset_id, "SharedStructs.Asset does not exist");
        return assets[asset_id].total_revenue;
    }

    function getOwnerId(uint256 _asset_id) public view returns (uint256) {
        return assets[_asset_id].owner_id;
    }

    function getAssetLength() public view returns (uint256) {
        return assets.length;
    }

    function GetAssetPricingStrategy(uint256 _asset_id) public view returns (uint8) {
        return uint8(assets[_asset_id].pricing_strategy);
    }

    function getOwnerAssets(uint256 _owner_id) public view returns (uint256[] memory) {
        return assetOwners[_owner_id];
    }
}
