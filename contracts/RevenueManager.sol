// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/IAssetManager.sol";
import "./libraries/SharedStructs.sol";

contract RevenueManager is Initializable {

    using SafeMath for uint256;

    address registry;

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
        uint8[] memory parents_weights
    ) public {

        uint8[] memory children_weights;
        uint256[] memory parents_payments;
        uint256[] memory children_payments;
        uint256[] memory parents_receipts;
        uint256[] memory children_receipts;

        SharedStructs.RevenueAccount memory account = SharedStructs.RevenueAccount(
            asset_id,
            parents_weights,
            children_weights,
            parents_payments,
            children_payments,
            parents_receipts,
            children_receipts,
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

    function useAsset(uint256 asset_id, uint256 payment) public onlyRegistry {
        require(accounts.length > asset_id, "Asset does not exist");
        SharedStructs.RevenueAccount storage account = accounts[asset_id-1];
        account.revenue = account.revenue.add(payment);
        account.total_revenue = account.total_revenue.add(payment);
    }

    function distributeRevenue() public onlyRegistry {
        
        for (uint256 i =0; i < accounts.length; i++){
            SharedStructs.RevenueAccount memory account = accounts[i];
            if (account.revenue > 0) {
                uint256[] memory childrenIds = assetManager.getChildrenIds(account.asset_id);
                for (uint256 j =0; j< childrenIds.length; j ++){
                    // Distribute revenue to adjacent nodes created before asset
                    // i.e. to adjacent nodes with id < asset_id
                    if (childrenIds[j] < account.asset_id){
                        
                    }
                }
            }
        }
    }
}