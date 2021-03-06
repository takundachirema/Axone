// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

library SharedStructs {
    struct Asset {
        uint256 asset_id; // starts from 1. 0 means null asset
        string asset_uri; // IPFS blob address of the asset
        uint256[] parents; // uri's of direct assets used to create this one
        uint256[] children; // uri's of direct assets created from this one
        uint256 owner_id; // id of the owner
        uint256 sell_price; // for changing asset ownership
        uint256 revenue;
        uint256 total_revenue;
        uint8 pricing_strategy;
    }

    struct RevenueAccount {
        uint256 asset_id;
        uint256 usage_price; // the price that must be paid to use the asset
        uint256 revenue; // undistributed revenue
        uint256 net_revenue;
        uint256 gross_revenue;
    }

    struct RevenueAccountDetails {
        uint256 asset_id;
        uint256 usage_price; // the price that must be paid to use the asset
        uint256 revenue; // undistributed revenue
        uint256 net_revenue;
        uint256 gross_revenue;
        uint8[] parents_weights; 
        uint8[] children_weights;
        uint256[] parents_payments;
        uint256[] children_payments;
        uint256[] parents_receipts;
        uint256[] children_receipts;
    }
}