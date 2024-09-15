// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/ValueRouter.sol";

contract DeployValueRouter is Script {
    function run() external {
        uint256 chainId = block.chainid;
        address deployer = vm.addr(uint256(vm.envUint("PRIVATE_KEY")));

        address usdc;
        address messageTransmitter;
        address tokenMessenger;
        address zeroEx;

        address bytesLib;
        address cctpMessageLib;
        address swapMessageCodecLib;

        if (chainId == 1) {
            // Ethereum
            usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
            messageTransmitter = 0x0a992d191DEeC32aFe36203Ad87D7d289a738F81;
            tokenMessenger = 0xBd3fa81B58Ba92a82136038B25aDec7066af3155;
            zeroEx = 0xDef1C0ded9bec7F1a1670819833240f027b25EfF;

            bytesLib = 0x064B37a5E001E73020166c32B06Eb07372659029;
            cctpMessageLib = 0x6ec82CDE6a64B8752017C0160E272f77BbBeD089;
            swapMessageCodecLib = 0xdb38EB076d423557F24dE1634358aa750Fd9A0DB;
        } else if (chainId == 43114) {
            // Avalanche-C
            usdc = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
            messageTransmitter = 0x8186359aF5F57FbB40c6b14A588d2A59C0C29880;
            tokenMessenger = 0x6B25532e1060CE10cc3B0A99e5683b91BFDe6982;
            zeroEx = 0xDef1C0ded9bec7F1a1670819833240f027b25EfF;

            bytesLib = 0xd1BD7F4aCD9490b13fa4401FDE5Ad9fdF478E30A;
            cctpMessageLib = 0xa89B7b20bdbfD2D40AE78254f4Eb170e4d93D890;
            swapMessageCodecLib = 0x26BB84002D2256BBbD5C283B5c775376c892d2c6;
        } else if (chainId == 10) {
            // Optimism
            usdc = 0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85;
            messageTransmitter = 0x4D41f22c5a0e5c74090899E5a8Fb597a8842b3e8;
            tokenMessenger = 0x2B4069517957735bE00ceE0fadAE88a26365528f;
            zeroEx = 0xDEF1ABE32c034e558Cdd535791643C58a13aCC10;

            bytesLib = 0x064B37a5E001E73020166c32B06Eb07372659029;
            cctpMessageLib = 0x6ec82CDE6a64B8752017C0160E272f77BbBeD089;
            swapMessageCodecLib = 0xdb38EB076d423557F24dE1634358aa750Fd9A0DB;
        } else if (chainId == 42161) {
            // Arbitrum
            usdc = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
            messageTransmitter = 0xC30362313FBBA5cf9163F0bb16a0e01f01A896ca;
            tokenMessenger = 0x19330d10D9Cc8751218eaf51E8885D058642E08A;
            zeroEx = 0xDef1C0ded9bec7F1a1670819833240f027b25EfF;

            bytesLib = 0x064B37a5E001E73020166c32B06Eb07372659029;
            cctpMessageLib = 0x6ec82CDE6a64B8752017C0160E272f77BbBeD089;
            swapMessageCodecLib = 0xdb38EB076d423557F24dE1634358aa750Fd9A0DB;
        } else if (chainId == 8453) {
            // Base
            usdc = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
            messageTransmitter = 0xAD09780d193884d503182aD4588450C416D6F9D4;
            tokenMessenger = 0x1682Ae6375C4E4A97e4B583BC394c861A46D8962;
            zeroEx = 0xDef1C0ded9bec7F1a1670819833240f027b25EfF;

            bytesLib = 0x064B37a5E001E73020166c32B06Eb07372659029;
            cctpMessageLib = 0x6ec82CDE6a64B8752017C0160E272f77BbBeD089;
            swapMessageCodecLib = 0xdb38EB076d423557F24dE1634358aa750Fd9A0DB;
        } else if (chainId == 137) {
            // Polygon
            usdc = 0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359;
            messageTransmitter = 0xF3be9355363857F3e001be68856A2f96b4C39Ba9;
            tokenMessenger = 0x9daF8c91AEFAE50b9c0E69629D3F6Ca40cA3B3FE;
            zeroEx = 0xDef1C0ded9bec7F1a1670819833240f027b25EfF;

            bytesLib = 0x064B37a5E001E73020166c32B06Eb07372659029;
            cctpMessageLib = 0x6ec82CDE6a64B8752017C0160E272f77BbBeD089;
            swapMessageCodecLib = 0x06bCcac1D96Ec89c1Dd62F715e0487b8c6B9FC92;
        } else {
            revert("Unsupported chain");
        }

        string[] memory args;
        args[0] = "Bytes";
        args[1] = vm.toString(bytesLib);
        args[2] = "CCTPMessage";
        args[3] = vm.toString(cctpMessageLib);
        args[4] = "SwapMessageCodec";
        args[5] = vm.toString(swapMessageCodecLib);

        vm.startBroadcast();

        // 部署合约
        ValueRouter valueRouter = new ValueRouter(usdc, messageTransmitter, tokenMessenger, zeroEx, deployer);

        vm.stopBroadcast();
    }
}
