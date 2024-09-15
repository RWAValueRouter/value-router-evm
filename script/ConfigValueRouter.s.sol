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
            contractAddress = 0x0000000000000000000000000000000000000000;
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

        bytes32 nobleCaller = 0x000000000000000000000000bbc905eb987498003c94d64bba25ee5efe84b51e;

        bytes32 solanaValueRouter = 0x2e12357ca301f806dc09b9aae1a6dabc86954c1fd0593b6df8708b1bee83e888;
        bytes32 solanaValueRouterCaller = 0x95472250619365db8d7f3d4a655da9383d3f66d0615442c55edfe4679cda4a0d;
        bytes32 programUsdcAccount = 0x4ce9ba6d8ed6265fe5d9262abe2522c4970bbe42a00ad7e78a36422c932e5544;
        bytes32 solanaCctpReceiver = 0x4352e98d0dfef2a95d0a81a56c960dec102111ac0ba732ab8858a5891dfb5df0;

        uint32[] memory remoteDomains;
        remoteDomains[0] = 0;
        remoteDomains[1] = 1;
        remoteDomains[2] = 2;
        remoteDomains[3] = 3;
        remoteDomains[4] = 4;
        remoteDomains[5] = 5;
        remoteDomains[6] = 6;
        remoteDomains[7] = 7;

        bytes32[] memory routers;
        routers[
            0
        ] = 0x000000000000000000000000000000000000000000000000000000000000abcd;
        routers[
            1
        ] = 0x000000000000000000000000000000000000000000000000000000000000abcd;
        routers[
            2
        ] = 0x000000000000000000000000000000000000000000000000000000000000abcd;
        routers[
            3
        ] = 0x000000000000000000000000000000000000000000000000000000000000abcd;
        routers[
            4
        ] = 0x000000000000000000000000000000000000000000000000000000000000abcd;
        routers[
            5
        ] = 0x2e12357ca301f806dc09b9aae1a6dabc86954c1fd0593b6df8708b1bee83e888;
        routers[
            6
        ] = 0x000000000000000000000000000000000000000000000000000000000000abcd;
        routers[
            7
        ] = 0x000000000000000000000000000000000000000000000000000000000000abcd;

        vm.startBroadcast();

        ValueRouter valueRouter = ValueRouter(payable(contractAddress));

        valueRouter.setRemoteRouters(remoteDomains, routers);

        valueRouter.setNobleCaller(nobleCaller);

        valueRouter.setupSolana(
            solanaValueRouter,
            solanaValueRouterCaller,
            programUsdcAccount,
            solanaCctpReceiver
        );

        valueRouter.changeAdmin(admin);

        // 停止广播
        vm.stopBroadcast();
    }
}
