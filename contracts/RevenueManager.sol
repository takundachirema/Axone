// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/IAssetManager.sol";
import "./libraries/SharedStructs.sol";

contract RevenueManager is Initializable {

    address registry;

    IAssetManager private assetManager;

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

    function distributeRevenue() public onlyRegistry {

        SharedStructs.Asset[] memory assets = assetManager.getAssets();
        
        for (uint256 i =0; i < assets.length; i++){
            SharedStructs.Asset memory asset = assets[i];
            if (asset.revenue > 0) {
                uint256[] memory childrenIds = asset.children;
                for (uint256 j =0; j< childrenIds.length; j ++){
                    // Distribute revenue to adjacent nodes created before asset
                    // i.e. to adjacent nodes with id < asset_id
                    if (childrenIds[j] < asset.asset_id){
                        
                    }
                }
            }
        }
    }
}