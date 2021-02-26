// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IRevenueManager {
    function initialize(address _axoneRegistry) external;

    function setAssetManager(address _assetManager) external;
}
