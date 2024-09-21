### Deploy
ETH
```
forge script script/DeployValueRouter.s.sol --libraries src/lib/Bytes.sol/Bytes:Bytes:0x064B37a5E001E73020166c32B06Eb07372659029 src/lib/CCTPMessage.sol/CCTPMessage:0x6ec82CDE6a64B8752017C0160E272f77BbBeD089 src/lib/SwapMessage:SwapMessageCodec:0xdb38EB076d423557F24dE1634358aa750Fd9A0DB --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

Avalanche-C
```
forge script script/DeployValueRouter.s.sol --libraries src/lib/Bytes.sol/Bytes:Bytes:0xd1BD7F4aCD9490b13fa4401FDE5Ad9fdF478E30A src/lib/CCTPMessage.sol/CCTPMessage:0xa89B7b20bdbfD2D40AE78254f4Eb170e4d93D890 src/lib/SwapMessage:SwapMessageCodec:0x26BB84002D2256BBbD5C283B5c775376c892d2c6 --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

Optimism
```
forge script script/DeployValueRouter.s.sol --libraries src/lib/Bytes.sol/Bytes:Bytes:0x064B37a5E001E73020166c32B06Eb07372659029 src/lib/CCTPMessage.sol/CCTPMessage:0x6ec82CDE6a64B8752017C0160E272f77BbBeD089 src/lib/SwapMessage:SwapMessageCodec:0xdb38EB076d423557F24dE1634358aa750Fd9A0DB --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

Arbitrum
```
forge script script/DeployValueRouter.s.sol --libraries src/lib/Bytes.sol/Bytes:Bytes:0x064B37a5E001E73020166c32B06Eb07372659029 src/lib/CCTPMessage.sol/CCTPMessage:0x6ec82CDE6a64B8752017C0160E272f77BbBeD089 src/lib/SwapMessage:SwapMessageCodec:0xdb38EB076d423557F24dE1634358aa750Fd9A0DB --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

Base
```
forge script script/DeployValueRouter.s.sol --libraries src/lib/Bytes.sol/Bytes:Bytes:0x064B37a5E001E73020166c32B06Eb07372659029 src/lib/CCTPMessage.sol/CCTPMessage:0x6ec82CDE6a64B8752017C0160E272f77BbBeD089 src/lib/SwapMessage:SwapMessageCodec:0xdb38EB076d423557F24dE1634358aa750Fd9A0DB --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

Polygon
```
forge script script/DeployValueRouter.s.sol --libraries src/lib/Bytes.sol/Bytes:Bytes:0x064B37a5E001E73020166c32B06Eb07372659029 src/lib/CCTPMessage.sol/CCTPMessage:0x6ec82CDE6a64B8752017C0160E272f77BbBeD089 src/lib/SwapMessage:SwapMessageCodec:0x06bCcac1D96Ec89c1Dd62F715e0487b8c6B9FC92 --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

### Verification
Avanache-C
```
forge verify-contract 0xd4c567F1e08357F8923203350bc5aBE7834eb512 src/ValueRouter.sol:ValueRouter --verifier-url 'https://api.routescan.io/v2/network/mainnet/evm/43114/etherscan' --etherscan-api-key "verifyContract" --num-of-optimizations 200 --compiler-version 0.8.18 --constructor-args $(cast abi-encode "constructor(address usdc, address messageTransmitter, address tokenMessenger, address zeroEx, address admin)" 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E 0x8186359aF5F57FbB40c6b14A588d2A59C0C29880 0x6B25532e1060CE10cc3B0A99e5683b91BFDe6982 0xDef1C0ded9bec7F1a1670819833240f027b25EfF 0x7E6691451b82253C9e926Ba6e36F84074898CAA9)
```