// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/IAssetManager.sol";
import "./libraries/SharedStructs.sol";

contract RevenueManager is Initializable {

    using SafeMath for uint256;

    //** events **/ 
    event PayForAssetUse(uint256 asset_id, bool use);

    //** variables **/

    // asset use price in USD cents
    uint256 asset_usage_price = 50;

    address registry;

    // this maps the weights of each connection the asset has to it's children
    mapping (uint256 => mapping (uint256 => uint8)) childrenWeights;

    // this maps the weights of each connection the asset has to it's parents
    mapping (uint256 => mapping (uint256 => uint8)) parentsWeights;

    // this maps the revenue receipts the asset got from its children
    mapping (uint256 => mapping (uint256 => uint256)) childrenReceipts;

    // this maps the revenue receipts the asset got from its parents
    mapping (uint256 => mapping (uint256 => uint256)) parentsReceipts;

    // this maps the revenue payments the asset made to its children
    mapping (uint256 => mapping (uint256 => uint256)) childrenPayments;

    // this maps the revenue payments the asset made to its parents
    mapping (uint256 => mapping (uint256 => uint256)) parentsPayments;
    

    IAssetManager private assetManager;

    SharedStructs.RevenueAccount[] accounts;

    modifier onlyRegistry() {
        require(msg.sender == registry, "Can only be called by registry");
        _;
    }

    function initialize(address _axonRegistry) public initializer {
        registry = _axonRegistry;
    }

    function setAssetManager(address _assetManager) public onlyRegistry {
        assetManager = IAssetManager(_assetManager);
    }

    // make this one protected
    function createAccount(
        uint256 asset_id,
        uint256[] memory parents_ids,
        uint8[] memory parents_weights,
        uint256[] memory children_ids,
        uint8[] memory children_weights,
        uint256 usage_price
    ) public {

        if (usage_price == 0){
            usage_price = asset_usage_price;
        }

        for (uint256 i =0; i< parents_ids.length; i++){
            parentsWeights[asset_id][parents_ids[i]] = parents_weights[i];
        }

        for (uint256 i =0; i< children_ids.length; i++){
            childrenWeights[asset_id][children_ids[i]] = children_weights[i];
        }

        SharedStructs.RevenueAccount memory account = SharedStructs.RevenueAccount(
            asset_id,
            usage_price,
            0,
            0,
            0
        );

        accounts.push(account);
    }

    // make this protected
    function setParentWeight(uint256 asset_id, uint256 parent_asset_id, uint8 weight) public {
        parentsWeights[asset_id][parent_asset_id] = weight;
    }

    function setChildWeight(uint256 asset_id, uint256 child_asset_id, uint8 weight) public {
        childrenWeights[asset_id][child_asset_id] = weight;
    }

    function getWeights(bool children, uint256 asset_id, uint256[] memory ids) public view returns(uint8[] memory){
        uint8[] memory weights = new uint8[](ids.length);
        for (uint256 i =0; i < ids.length; i++){
            if (children){
                weights[i] = childrenWeights[asset_id][ids[i]];
            }
            else {
                weights[i] = parentsWeights[asset_id][ids[i]];
            }
        }
        return weights;
    }

    function getChildrenRevenues(
        bool payments, 
        uint256 asset_id, 
        uint256[] memory ids
    ) public view returns(uint256[] memory) {

        uint256[] memory revenues = new uint256[](ids.length);
        for (uint256 i =0; i < ids.length; i++){
            if (payments){
                revenues[i] = childrenPayments[asset_id][ids[i]];
            }
            else {
                revenues[i] = childrenReceipts[asset_id][ids[i]];
            }
        }
        return revenues; 
    }

    function getParentRevenues(
        bool payments, 
        uint256 asset_id, 
        uint256[] memory ids
    ) public view returns(uint256[] memory) {
        
        uint256[] memory revenues = new uint256[](ids.length);
        for (uint256 i =0; i < ids.length; i++){
            if (payments){
                revenues[i] = parentsPayments[asset_id][ids[i]];
            }
            else {
                revenues[i] = parentsReceipts[asset_id][ids[i]];
            }
        }
        return revenues; 
    }

    function getRevenueAccount(uint256 asset_id)
        public view returns(SharedStructs.RevenueAccountDetails memory){

        SharedStructs.RevenueAccount memory account = accounts[asset_id - 1];
        uint256[] memory children_ids = assetManager.getChildrenIds(asset_id); 
        uint256[] memory parent_ids = assetManager.getParentIds(asset_id);
        
        uint8[] memory parents_weights = getWeights(false, asset_id, parent_ids); 
        uint8[] memory children_weights = getWeights(true, asset_id, children_ids); 
        uint256[] memory parents_payments = getParentRevenues(true, asset_id, parent_ids);
        uint256[] memory children_payments = getChildrenRevenues(true, asset_id, children_ids);
        uint256[] memory parents_receipts = getParentRevenues(false, asset_id, parent_ids);
        uint256[] memory children_receipts = getChildrenRevenues(false, asset_id, parent_ids);
    
        SharedStructs.RevenueAccountDetails memory accountDetails = SharedStructs.RevenueAccountDetails(
            account.asset_id,
            account.usage_price,
            account.revenue,
            account.net_revenue,
            account.gross_revenue,
            parents_weights,
            children_weights,
            parents_payments,
            children_payments,
            parents_receipts,
            children_receipts
        );

        return accountDetails;
    }

    function payForAssetUse(uint256 asset_id) payable external {
        require(accounts.length > asset_id, "Asset does not exist");
        SharedStructs.RevenueAccount storage account = accounts[asset_id-1];
        require(msg.value >= account.usage_price,"Payment for asset usage is not enough");

        if (msg.value > account.usage_price){
            msg.sender.transfer(msg.value - account.usage_price);
        }

        account.revenue = account.revenue.add(account.usage_price);

        emit PayForAssetUse(asset_id, true);
    }

    function payRoyalties() public onlyRegistry {
        
        for (uint256 i =0; i < accounts.length; i++){
            SharedStructs.RevenueAccount storage account = accounts[i];
            uint256 assetId = account.asset_id;
            if (account.revenue > 0) {
                uint256[] memory childrenIds = assetManager.getChildrenIds(assetId);
                uint256[] memory parentIds = assetManager.getParentIds(assetId);
                uint256 totalRoyaltyPaid = 0;

                for (uint256 j =0; j < childrenIds.length; j ++){
                    uint256 childId = childrenIds[j];
                    uint256 weight = childrenWeights[assetId][childId];
                    // Distribute revenue to adjacent nodes created before asset
                    // i.e. to adjacent nodes with id < asset_id
                    if (childId < assetId && weight > 0){
                        uint256 rw = account.revenue.mul(weight);
                        uint256 royalty = rw.div(100);
                        address childAddress = assetManager.getOwnerAddress(childId);
                        address payable child_wallet = address(uint160(childAddress));
                        child_wallet.transfer(royalty);

                        totalRoyaltyPaid = totalRoyaltyPaid + royalty;
                        childrenPayments[assetId][childId] = childrenPayments[assetId][childId] + royalty;
                        parentsReceipts[childId][assetId] = parentsReceipts[childId][assetId] + royalty;
                    }
                }

                for (uint256 j =0; j < parentIds.length; j ++){
                    uint256 parentId = parentIds[j];
                    uint256 weight = parentsWeights[assetId][parentId];
                    // Distribute revenue to adjacent nodes created before asset
                    // i.e. to adjacent nodes with id < asset_id
                    if (parentId < assetId && weight > 0){
                        uint256 rw = account.revenue.mul(weight);
                        uint256 royalty = rw.div(100);
                        address parentAddress = assetManager.getOwnerAddress(parentId);
                        address payable parent_wallet = address(uint160(parentAddress));
                        parent_wallet.transfer(royalty);

                        totalRoyaltyPaid = totalRoyaltyPaid + royalty;
                        parentsPayments[assetId][parentId] = parentsPayments[assetId][parentId] + royalty;
                        childrenReceipts[parentId][assetId] = childrenReceipts[parentId][assetId] + royalty;
                    }
                }

                address accountAddress = assetManager.getOwnerAddress(assetId);
                address payable asset_wallet = address(uint160(accountAddress));
                asset_wallet.transfer(account.revenue - totalRoyaltyPaid);

                account.net_revenue = account.net_revenue + account.revenue - totalRoyaltyPaid;
                account.gross_revenue = account.gross_revenue + account.revenue;
                account.revenue = 0;
            }
        }
    }
}