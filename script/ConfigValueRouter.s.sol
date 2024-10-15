// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/ValueRouter.sol";

contract ConfigValueRouter is Script {
    function run() external {
        uint256 chainId = block.chainid;

        address contractAddress;
        if (chainId == 1) {
            // Ethereum
            contractAddress = 0x0000000000000000000000000000000000000000;
        } else if (chainId == 43114) {
            // Avalanche-C
            contractAddress = 0x43Dc3A0abc0148b2Cc9E76699Aa9e8f5edf69B36;
        } else if (chainId == 10) {
            // Optimism
            contractAddress = 0x0000000000000000000000000000000000000000;
        } else if (chainId == 42161) {
            // Arbitrum
            contractAddress = 0x0000000000000000000000000000000000000000;
        } else if (chainId == 8453) {
            // Base
            contractAddress = 0x0000000000000000000000000000000000000000;
        } else if (chainId == 137) {
            // Polygon
            contractAddress = 0x0000000000000000000000000000000000000000;
        } else {
            revert("Unsupported chain");
        }
        address admin = 0x840fC5Cf55019904f85F91DE5aD211248FfC5F4d;

        bytes32 nobleCaller = bytes32(0x000000000000000000000000bbc905eb987498003c94d64bba25ee5efe84b51e);

        bytes32 solanaValueRouter = bytes32(0x003084f9571ca2a55253e5d3c3194bbb240de72173b0adff5a88c36255f85b25);
        bytes32 solanaValueRouterCaller = bytes32(0xbc30db1770ae6f9957e4d41baec0a767b98869e74f2d9dd82dde5b71c4a45dda);
        bytes32 programUsdcAccount = bytes32(0x29aade440d65cd315ab6b5cccdd5545e1a720db6e7b7d94dc56ded8d5c1ee9f3);
        bytes32 solanaCctpReceiver = bytes32(0x4352e98d0dfef2a95d0a81a56c960dec102111ac0ba732ab8858a5891dfb5df0);

        uint32[] memory remoteDomains = new uint32[](8);
        remoteDomains[0] = 0;
        remoteDomains[1] = 1;
        remoteDomains[2] = 2;
        remoteDomains[3] = 3;
        remoteDomains[4] = 4;
        remoteDomains[5] = 5;
        remoteDomains[6] = 6;
        remoteDomains[7] = 7;

        bytes32[] memory routers = new bytes32[](8);
        routers[0] = bytes32(0x000000000000000000000000000000000000000000000000000000000000abcd);
        routers[1] = bytes32(0x000000000000000000000000000000000000000000000000000000000000abcd);
        routers[2] = bytes32(0x000000000000000000000000000000000000000000000000000000000000abcd);
        routers[3] = bytes32(0x000000000000000000000000000000000000000000000000000000000000abcd);
        routers[4] = bytes32(0x000000000000000000000000000000000000000000000000000000000000abcd);
        routers[5] = solanaValueRouter;
        routers[6] = bytes32(0x000000000000000000000000000000000000000000000000000000000000abcd);
        routers[7] = bytes32(0x000000000000000000000000000000000000000000000000000000000000abcd);

        vm.startBroadcast();

        ValueRouter valueRouter = ValueRouter(payable(contractAddress));

        valueRouter.setRemoteRouters(remoteDomains, routers);

        valueRouter.setNobleCaller(nobleCaller);

        valueRouter.setupSolana(solanaValueRouter, solanaValueRouterCaller, programUsdcAccount, solanaCctpReceiver);

        valueRouter.changeAdmin(admin);

        // 停止广播
        vm.stopBroadcast();
    }
}
