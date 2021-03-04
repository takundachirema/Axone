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

    // this maps the revenue receipts the asset got from its children
    mapping (uint256 => mapping (uint256 => uint256)) childReceipts;

    // this maps the revenue receipts the asset got from its parents
    mapping (uint256 => mapping (uint256 => uint256)) parentReceipts;

    // this maps the revenue payments the asset made to its children
    mapping (uint256 => mapping (uint256 => uint256)) childPayments;

    // this maps the revenue payments the asset made to its parents
    mapping (uint256 => mapping (uint256 => uint256)) parentPayments;
    

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
        uint8[] memory parents_weights,
        uint256 usage_price
    ) public {

        uint8[] memory children_weights;
        uint256[] memory parents_payments;
        uint256[] memory children_payments;
        uint256[] memory parents_receipts;
        uint256[] memory children_receipts;

        if (usage_price == 0){
            usage_price = asset_usage_price;
        }

        SharedStructs.RevenueAccount memory account = SharedStructs.RevenueAccount(
            asset_id,
            parents_weights,
            children_weights,
            parents_payments,
            children_payments,
            parents_receipts,
            children_receipts,
            usage_price,
            0,
            0
        );

        accounts.push(account);
    }

    // make this protected
    function setParentWeight(uint256 asset_id, uint8 weight) public {
        accounts[asset_id - 1].parents_weights.push(weight);
    }

    function setChildWeight(uint256 asset_id, uint8 weight) public {
        accounts[asset_id - 1].children_weights.push(weight);
    }

    function getChildrenWeights(uint256 asset_id) public view returns(uint8[] memory){
        return accounts[asset_id - 1].children_weights;
    }

    function getParentsWeights(uint256 asset_id) public view returns(uint8[] memory){
        return accounts[asset_id - 1].parents_weights;
    }

    function getRevenueAccount(uint256 asset_id) public view returns(SharedStructs.RevenueAccount memory){
        return accounts[asset_id - 1];
    }

    function payForAssetUse(uint256 asset_id) payable external {
        require(accounts.length > asset_id, "Asset does not exist");
        SharedStructs.RevenueAccount storage account = accounts[asset_id-1];
        require(msg.value >= account.usage_price,"Payment for asset usage is not enough");

        if (msg.value > account.usage_price){
            msg.sender.transfer(msg.value - account.usage_price);
        }

        account.revenue = account.revenue.add(account.usage_price);
        account.total_revenue = account.total_revenue.add(account.usage_price);

        emit PayForAssetUse(asset_id, true);
    }

    function payRoyalties() public onlyRegistry {
        
        for (uint256 i =0; i < accounts.length; i++){
            SharedStructs.RevenueAccount memory account = accounts[i];
            if (account.revenue > 0) {
                uint256[] memory childrenIds = assetManager.getChildrenIds(account.asset_id);
                for (uint256 j =0; j < childrenIds.length; j ++){
                    uint256 weight = account.children_weights[j];
                    // Distribute revenue to adjacent nodes created before asset
                    // i.e. to adjacent nodes with id < asset_id
                    if (childrenIds[j] < account.asset_id && weight > 0){
                        uint256 royalty = account.revenue.mul(weight.div(100));
                        address childAddress = assetManager.getOwnerAddress(childrenIds[j]);
                        address payable wallet = address(uint160(childAddress));
                        wallet.transfer(royalty);
                    }
                }
            }
        }
    }

    function payRoyaltiesToAssets(
        SharedStructs.RevenueAccount storage revenue_account, 
        uint256[] memory assetIds
    ) internal
    {   
        for (uint256 j =0; j < assetIds.length; j ++){
            SharedStructs.RevenueAccount storage asset_account = accounts[assetIds[j] - 1];
            uint256 weight = revenue_account.children_weights[j];
            // Distribute revenue to adjacent nodes created before asset
            // i.e. to adjacent nodes with id < asset_id
            if (assetIds[j] < revenue_account.asset_id && weight > 0){
                uint256 royalty = revenue_account.revenue.mul(weight.div(100));
                address childAddress = assetManager.getOwnerAddress(assetIds[j]);
                address payable wallet = address(uint160(childAddress));
                wallet.transfer(royalty);

                revenue_account.children_payments[j] = revenue_account.children_payments[j].add(royalty);
                uint256 parentPosition = assetManager.getParentPosition();
                asset_account.parents_receipts[j] = revenue_account.children_payments[j].add(royalty);
            }
        }
    }
}