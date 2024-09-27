## 1. Functional Requirements
### 1.1 Roles:
Admin: Manages fees, cross-chain setups, and can pause/unpause the contract.
User: Can initiate token swaps and bridge assets across chains.
Relayer: Executes cross-chain relaying operations, ensuring messages are forwarded between chains.

### 1.2 Features:
- Token swaps via 0x protocol.
- Cross-chain USDC bridging with relayer support.
- Configurable fees for swaps and bridges.
- Relaying and cross-chain message verification.

### 1.3 Use Cases:
- A user swaps tokens on the local chain.
- A user bridges USDC to the remote chain.
- A user sells tokens on the local chain and requests to receive token on the remote chain.
- Relayer forwards messages to ensure cross-chain transfers.
- Admin adjusts fees or pauses the system.

## 2. Technical Requirements
### 2.1 Architecture Overview:
Cross-chain interaction between EVM and non-EVM chains like Solana, Noble.
Relayer system supports message delivery between chains.
0x for token swaps, and token messengers for bridging.
```
/src
  ├── interfaces
    ├── IERC20.sol
    ├── IMessageTransmitter.sol
    ├── ITokenMessenger.sol
  ├── lib
    ├── Bytes.sol
    ├── CCTPMessage.sol             # CCTP encode and decode functions
    ├── SwapMessage.sol             # ValueRouter message body encoding and decoding functions
    ├── TypedMemView.sol            # from summa-tx/memview-sol, low-cost way to index bytes
  ├── ValueRouter.sol               # Main contract for value routing
/lib
/script
/tests
```

### 2.2 Contract Information:
#### Assets
```
struct MessageWithAttestation {
    bytes message;
    bytes attestation;
}
```
```
struct SellArgs {
    address sellToken;
    uint256 sellAmount;
    uint256 guaranteedBuyAmount;
    uint256 sellcallgas;
    bytes sellcalldata;
}
```
```
struct BuyArgs {
    bytes32 buyToken;
    uint256 guaranteedBuyAmount;
    bytes memo;
}
```
```
struct Fee {
    uint256 bridgeFee;
    uint256 swapFee;
}
ValueRouter CCTP meessage body struct
```
struct SwapMessage {
    uint32 version;
    bytes32 bridgeNonceHash;
    uint256 sellAmount;
    bytes32 buyToken;
    uint256 guaranteedBuyAmount;
    bytes32 recipient;
}
#### Events
```
event ChangeAdmin(address indexed _old, address indexed _new);
```
```
event ApplyAdmin(address indexed _old, address indexed _new);
```
```
event Paused(string functionName);
```
```
event Unpaused(string functionName);```
```
```
event TakeFee(address to, uint256 amount);
```
```
event SwapAndBridge2(
  address sellToken,
  bytes32 buyToken,
  uint256 bridgeUSDCAmount,
  uint32 destDomain,
  bytes32 recipient,
  bytes memo
);
```
```
event ReplaceSwapMessage(
  address buyToken,
  uint32 destDomain,
  address recipient,
  uint64 swapMessageNonce
);
```
```
event LocalSwap(
  address msgsender,
  address sellToken,
  uint256 sellAmount,
  address buyToken,
  uint256 boughtAmount
);
```
```
    event BridgeArrive(bytes32 bridgeNonceHash, uint256 amount);
```
```
    event DestSwapFailed(bytes32 bridgeNonceHash);
```
```
    event DestSwapSuccess(bytes32 bridgeNonceHash);
```
#### Functions
##### changeAdmin
sets pending admin
```
function changeAdmin(address _admin)
```

##### applyAdmin
applies the pending admin, only called by the pending admin
```
function applyAdmin()
```

##### pauseFunction
pauses a function
```
function pauseFunction(string memory functionName)
```

##### unpauseFunction
unpauses a function
```
function unpauseFunction(string memory functionName)
```

##### fee
returns bridge fee and swap fee to the destination domain
```
function fee(uint32 domain) external view returns (uint256, uint256)
```

##### swapAndBridge
handles swap from source token to usdc
burns usdc
emits two CCTP messages: bridge message and swap message
```
function swapAndBridge(
        SellArgs calldata sellArgs,
        BuyArgs calldata buyArgs,
        uint32 destDomain,
        bytes32 recipient
    ) external payable returns (uint64, uint64)
```

##### relay
is called by the backend relayer program
validates bridge and swap message from source chain
mints usdc and swaps to target token
sends target token to recipient
```
function relay(
        MessageWithAttestation calldata bridgeMessage,
        MessageWithAttestation calldata swapMessage,
        bytes calldata swapdata,
        uint256 callgas
    ) external
```

##### takeFee
is used to take fee only by admin
```
function takeFee(address to, uint256 amount)
```

##### zeroExSwap
handles local swap
is used internally in `swap`, `swapAndBridge` and `relay`
is marked as public because it is used in the “try” statement in `relay`
is safe to public.
```
function zeroExSwap(
  bytes memory swapcalldata,
  uint256 callgas,
  address sellToken,
  uint256 sellAmount,
  address buyToken,
  uint256 guaranteedBuyAmount,
  address recipient,
  uint256 value
) public payable returns (uint256 boughtAmount)
```

##### swap
Wrapper function of zeroExSwap
```
function swap(
  bytes calldata swapcalldata,
  uint256 callgas,
  address sellToken,
  uint256 sellAmount,
  address buyToken,
  uint256 guaranteedBuyAmount,
  address recipient
)
```
##### Modifiers
```
modifier onlyAdmin()
```
```
modifier whenNotPaused(string memory functionName)
```

### 2.3 Explain
#### Admin functions
ValueRouter contract has a single admin
Admin can change admin, and the new admin is pending first
The new admin address must send a transaction and confirms the address before
When there is an address pending, the old admin still plays the role of admin
Administrators can pause and unpause functions
Admin can set fees
Admin can take fees

Users can initiate 4 types of transactions
#### Local swap
Get swap calldata from 0x API through front-end program and pass it to valueRouter contract
valueRouter contract executes 0x swap calldata
#### USDC cross-chain
Users indirectly call CCTP tokenMessenger through valueRouter contract, burn USDC and generate a CCTP message (called bridge message)
ValueRouter contract also generates a swap message, which includes the target token address, the user's receiving address, and the minimum receiving quantity
#### Any token cross-chain
Users build the swap calldata of source chain through front-end, which is executed by valueRouter, converts any token into USDC through 0x
ValueRouter contract then destroy USDC through CCTP contract, and emits bridgeMessage and swapMessage.

If targeting chain is a cosmos chain connected to Noble, it only allow output token is usdc.
Front-end must set destDomain to 4, and buyArgs.memo must include destination chain name and user's recipient address.
Relayer will register "forwarding" according for user according to the recipient account.

#### Fee
When users want to receive USDC on the target chain, fee = bridgeFee (regardless of whether the original chain has swap)
Users need to receive tokens other than USDC on the target chain, fee = swapFee

#### relay
The backend relay will relay after scanning the valueRouter message pair generated by other chains
The nonce of the bridge message and the swap message must be adjacent
Attestations must be verified by the CCTP messageTransmitter
If it requires receiving any token other than usdc, the relay program must get swap calldata through 0x api and pass it to valueRouter contract.
After the swap is successful, the contract checks whether the token received by the user has reached the minimum amount of tokens received
If not, the user's address will receive all the USDC from the cross-chain

#### Messages
Both bridgeMessage and swapMessage have a specified caller
The target chain is EVM or Solana, and the caller is the EVM contract or caller pda
When the target chain is Noble, the caller is a specific relayer, and other relayers cannot relay on its behalf
bridgeMessage is sent through tokenMessenger, and the sender is tokenMessenger
The token receiving address of the bridge message is:
- EVM - target chain contract address
- Noble - target chain user address
- Solana - valueRouter program usdc pda
swapMessage is sent by valueRouter, and the sender is valueRouter
Contains bridgeNonceHash, which is used to check whether bridgeMessage and swapMessage are from the same transaction
- buyToken = 0 means usdc
- The target chain is EVM, buyToken - 0xEeeeeEeeeEeeEeEeEeEeeEeeeeEeeeeeeeeEe means the target chain token is a native gas token

If the target chain is Noble
The recipient of bridgeMessage is the user's address
