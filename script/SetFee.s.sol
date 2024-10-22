// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/ValueRouter.sol";

contract ConfigValueRouter is Script {
    function run() external {
        uint256 chainId = block.chainid;

        Fee[] memory price = new Fee[](8);

        address contractAddress;
        if (chainId == 1) {
            // Ethereum
            contractAddress = 0x66F011F9F4ab937b47f51a8da5542c897D12E3Cb;
            // [[0,0],[111111111111111,148148148148148],[111111111111111,148148148148148],[111111111111111,148148148148148],[111111111111111,148148148148148],[111111111111111,148148148148148],[111111111111111,148148148148148],[111111111111111,148148148148148]]
            price[0] = Fee({bridgeFee: 0, swapFee: 0});
            price[1] = Fee({bridgeFee: 111111111111111, swapFee: 148148148148148});
            price[2] = Fee({bridgeFee: 111111111111111, swapFee: 148148148148148});
            price[3] = Fee({bridgeFee: 111111111111111, swapFee: 148148148148148});
            price[4] = Fee({bridgeFee: 111111111111111, swapFee: 148148148148148});
            price[5] = Fee({bridgeFee: 111111111111111, swapFee: 148148148148148});
            price[6] = Fee({bridgeFee: 111111111111111, swapFee: 148148148148148});
            price[7] = Fee({bridgeFee: 111111111111111, swapFee: 148148148148148});
        } else if (chainId == 43114) {
            // Avalanche-C
            contractAddress = 0x43Dc3A0abc0148b2Cc9E76699Aa9e8f5edf69B36;
            // [[178571428571429000,357142857142857000],[0,0],[10714285714285700,14285714285714300],[10714285714285700,14285714285714300],[10714285714285700,14285714285714300],[10714285714285700,14285714285714300],[10714285714285700,14285714285714300],[10714285714285700,14285714285714300]]
            price[0] = Fee({bridgeFee: 178571428571429000, swapFee: 357142857142857000});
            price[1] = Fee({bridgeFee: 0, swapFee: 0});
            price[2] = Fee({bridgeFee: 10714285714285700, swapFee: 14285714285714300});
            price[3] = Fee({bridgeFee: 10714285714285700, swapFee: 14285714285714300});
            price[4] = Fee({bridgeFee: 10714285714285700, swapFee: 14285714285714300});
            price[5] = Fee({bridgeFee: 10714285714285700, swapFee: 14285714285714300});
            price[6] = Fee({bridgeFee: 10714285714285700, swapFee: 14285714285714300});
            price[7] = Fee({bridgeFee: 10714285714285700, swapFee: 14285714285714300});
        } else if (chainId == 10) {
            // Optimism
            contractAddress = 0xc17cffDaA599A759d06EE2Eae88866055622d937;
            // [[1851851851851850,3703703703703700],[111111111111111,148148148148148],[0,0],[111111111111111,148148148148148],[111111111111111,148148148148148],[111111111111111,148148148148148],[111111111111111,148148148148148],[111111111111111,148148148148148]]
            price[0] = Fee({bridgeFee: 1851851851851850, swapFee: 3703703703703700});
            price[1] = Fee({bridgeFee: 111111111111111, swapFee: 148148148148148});
            price[2] = Fee({bridgeFee: 0, swapFee: 0});
            price[3] = Fee({bridgeFee: 111111111111111, swapFee: 148148148148148});
            price[4] = Fee({bridgeFee: 111111111111111, swapFee: 148148148148148});
            price[5] = Fee({bridgeFee: 111111111111111, swapFee: 148148148148148});
            price[6] = Fee({bridgeFee: 111111111111111, swapFee: 148148148148148});
            price[7] = Fee({bridgeFee: 111111111111111, swapFee: 148148148148148});
        } else if (chainId == 42161) {
            // Arbitrum
            contractAddress = 0xE438AADd3C34e444FF775F7d376ffE54d197673A;
            // [[1851851851851850,3703703703703700],[111111111111111,148148148148148],[111111111111111,148148148148148],[0,0],[111111111111111,148148148148148],[111111111111111,148148148148148],[111111111111111,148148148148148],[111111111111111,148148148148148]]
            price[0] = Fee({bridgeFee: 1851851851851850, swapFee: 3703703703703700});
            price[1] = Fee({bridgeFee: 111111111111111, swapFee: 148148148148148});
            price[2] = Fee({bridgeFee: 111111111111111, swapFee: 148148148148148});
            price[3] = Fee({bridgeFee: 0, swapFee: 0});
            price[4] = Fee({bridgeFee: 111111111111111, swapFee: 148148148148148});
            price[5] = Fee({bridgeFee: 111111111111111, swapFee: 148148148148148});
            price[6] = Fee({bridgeFee: 111111111111111, swapFee: 148148148148148});
            price[7] = Fee({bridgeFee: 111111111111111, swapFee: 148148148148148});
        } else if (chainId == 8453) {
            // Base
            contractAddress = 0x7C5d3CF79f213F691637AB28b414eBCB41F4FfbB;
            // [[1851851851851850,3703703703703700],[111111111111111,148148148148148],[111111111111111,148148148148148],[111111111111111,148148148148148],[111111111111111,148148148148148],[111111111111111,148148148148148],[0,0],[111111111111111,148148148148148]]
            price[0] = Fee({bridgeFee: 1851851851851850, swapFee: 3703703703703700});
            price[1] = Fee({bridgeFee: 111111111111111, swapFee: 148148148148148});
            price[2] = Fee({bridgeFee: 111111111111111, swapFee: 148148148148148});
            price[3] = Fee({bridgeFee: 111111111111111, swapFee: 148148148148148});
            price[4] = Fee({bridgeFee: 111111111111111, swapFee: 148148148148148});
            price[5] = Fee({bridgeFee: 111111111111111, swapFee: 148148148148148});
            price[6] = Fee({bridgeFee: 0, swapFee: 0});
            price[7] = Fee({bridgeFee: 111111111111111, swapFee: 148148148148148});
        } else if (chainId == 137) {
            // Polygon
            contractAddress = 0x7C5d3CF79f213F691637AB28b414eBCB41F4FfbB;
            // [[13513513513513500000,27027027027027000000],[810810810810811000,1081081081081080000],[810810810810811000,1081081081081080000],[810810810810811000,1081081081081080000],[810810810810811000,1081081081081080000],[810810810810811000,1081081081081080000],[810810810810811000,1081081081081080000],[0,0]]
            price[0] = Fee({bridgeFee: 13513513513513500000, swapFee: 27027027027027000000});
            price[1] = Fee({bridgeFee: 810810810810811000, swapFee: 1081081081081080000});
            price[2] = Fee({bridgeFee: 810810810810811000, swapFee: 1081081081081080000});
            price[3] = Fee({bridgeFee: 810810810810811000, swapFee: 1081081081081080000});
            price[4] = Fee({bridgeFee: 810810810810811000, swapFee: 1081081081081080000});
            price[5] = Fee({bridgeFee: 810810810810811000, swapFee: 1081081081081080000});
            price[6] = Fee({bridgeFee: 810810810810811000, swapFee: 1081081081081080000});
            price[7] = Fee({bridgeFee: 0, swapFee: 0});
        } else {
            revert("Unsupported chain");
        }

        uint32[] memory domains = new uint32[](8);
        domains[0] = 0;
        domains[1] = 1;
        domains[2] = 2;
        domains[3] = 3;
        domains[4] = 4;
        domains[5] = 5;
        domains[6] = 6;
        domains[7] = 7;

        vm.startBroadcast();

        ValueRouter valueRouter = ValueRouter(payable(contractAddress));

        valueRouter.setFee(domains, price);

        // 停止广播
        vm.stopBroadcast();
    }
}
