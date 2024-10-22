### Deploy
```
source ./.env
forge script script/DeployValueRouter.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

### Config
```
source ./.env
forge script script/ConfigValueRouter.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

### Set fee
```
source ./.env
forge script script/SetFee.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```