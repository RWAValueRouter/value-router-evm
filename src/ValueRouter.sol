// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./interfaces/IERC20.sol";
import "./interfaces/IMessageTransmitter.sol";
import "./interfaces/ITokenMessenger.sol";
import "./lib/CCTPMessage.sol";
import "./lib/SwapMessage.sol";

abstract contract AdminControl {
    address public admin;
    address public pendingAdmin;

    event ChangeAdmin(address indexed _old, address indexed _new);
    event ApplyAdmin(address indexed _old, address indexed _new);

    constructor(address _admin) {
        require(_admin != address(0), "AdminControl: address(0)");
        admin = _admin;
        emit ChangeAdmin(address(0), _admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "AdminControl: not admin");
        _;
    }

    function changeAdmin(address _admin) external onlyAdmin {
        require(_admin != address(0), "AdminControl: address(0)");
        pendingAdmin = _admin;
        emit ChangeAdmin(admin, _admin);
    }

    function applyAdmin() external {
        require(msg.sender == pendingAdmin, "AdminControl: Forbidden");
        emit ApplyAdmin(admin, pendingAdmin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }
}

abstract contract AdminPausable is AdminControl {
    mapping(string => bool) private _pausedFunctions;

    event Paused(string functionName);
    event Unpaused(string functionName);

    constructor(address _admin) AdminControl(_admin) {}

    modifier whenNotPaused(string memory functionName) {
        require(
            !_pausedFunctions[functionName],
            "Pausable: function is paused"
        );
        _;
    }

    function pauseFunction(string memory functionName) public onlyAdmin {
        _pausedFunctions[functionName] = true;
        emit Paused(functionName);
    }

    function unpauseFunction(string memory functionName) public onlyAdmin {
        _pausedFunctions[functionName] = false;
        emit Unpaused(functionName);
    }
}

struct MessageWithAttestation {
    bytes message;
    bytes attestation;
}

struct SellArgs {
    address sellToken;
    uint256 sellAmount;
    uint256 guaranteedBuyAmount;
    uint256 sellcallgas;
    bytes sellcalldata;
}

struct BuyArgs {
    bytes32 buyToken;
    uint256 guaranteedBuyAmount;
    bytes memo;
}

struct Fee {
    uint256 bridgeFee;
    uint256 swapFee;
}

interface IValueRouter {
    event TakeFee(address to, uint256 amount);

    event SwapAndBridge2(
        address sellToken,
        bytes32 buyToken,
        uint256 bridgeUSDCAmount,
        uint32 destDomain,
        bytes32 recipient,
        bytes memo
    );

    event ReplaceSwapMessage(
        address buyToken,
        uint32 destDomain,
        address recipient,
        uint64 swapMessageNonce
    );

    event LocalSwap(
        address msgsender,
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 boughtAmount
    );

    event BridgeArrive(bytes32 bridgeNonceHash, uint256 amount);

    event DestSwapFailed(bytes32 bridgeNonceHash);

    event DestSwapSuccess(bytes32 bridgeNonceHash);

    function version() external view returns (uint16);

    function fee(uint32 domain) external view returns (uint256, uint256);

    function swap(
        bytes calldata swapcalldata,
        uint256 callgas,
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 guaranteedBuyAmount,
        address recipient
    ) external payable;

    function swapAndBridge(
        SellArgs calldata sellArgs,
        BuyArgs calldata buyArgs,
        uint32 destDomain,
        bytes32 recipient
    ) external payable returns (uint64, uint64);

    function relay(
        MessageWithAttestation calldata bridgeMessage,
        MessageWithAttestation calldata swapMessage,
        bytes calldata swapdata,
        uint256 callgas
    ) external;
}

contract ValueRouter is IValueRouter, AdminPausable {
    using Bytes for *;
    using TypedMemView for bytes;
    using TypedMemView for bytes29;
    using CCTPMessage for *;
    using SwapMessageCodec for *;

    mapping(uint32 => Fee) public fee;

    function setFee(
        uint32[] calldata domain,
        Fee[] calldata price
    ) public onlyAdmin {
        for (uint256 i = 0; i < domain.length; i++) {
            fee[domain[i]] = price[i];
        }
    }

    address public immutable usdc;
    IMessageTransmitter public immutable messageTransmitter;
    ITokenMessenger public immutable tokenMessenger;
    address public immutable zeroEx;
    uint16 public immutable version = 1;

    bytes32 public nobleCaller;
    bytes32 public solanaCaller;
    bytes32 public solanaProgramUsdcAccount;
    bytes32 public solanaReceiver;

    mapping(uint32 => bytes32) public remoteRouter;
    mapping(bytes32 => address) swapHashSender;

    constructor(
        address _usdc,
        address _messageTransmitter,
        address _tokenMessenger,
        address _zeroEx,
        address admin
    ) AdminPausable(admin) {
        usdc = _usdc;
        messageTransmitter = IMessageTransmitter(_messageTransmitter);
        tokenMessenger = ITokenMessenger(_tokenMessenger);
        zeroEx = _zeroEx;
    }

    receive() external payable {}

    function setNobleCaller(bytes32 caller) public onlyAdmin {
        nobleCaller = caller;
    }

    function setSolanaCaller(bytes32 caller) public onlyAdmin {
        solanaCaller = caller;
    }

    function setSolanaProgramUsdcAccount(bytes32 account) public onlyAdmin {
        solanaProgramUsdcAccount = account;
    }

    function setSolanaReceiver(bytes32 account) public onlyAdmin {
        solanaReceiver = account;
    }

    function setupSolana(
        bytes32 valueRouter,
        bytes32 caller,
        bytes32 programUsdcAccount,
        bytes32 cctpReceiver
    ) public onlyAdmin {
        remoteRouter[5] = valueRouter;
        solanaCaller = caller;
        solanaProgramUsdcAccount = programUsdcAccount;
        solanaReceiver = cctpReceiver;
    }

    function setRemoteRouter(
        uint32 remoteDomain,
        address router
    ) public onlyAdmin {
        remoteRouter[remoteDomain] = router.addressToBytes32();
    }

    function setRemoteRouter(
        uint32 remoteDomain,
        bytes32 router
    ) public onlyAdmin {
        remoteRouter[remoteDomain] = router;
    }

    function setRemoteRouters(
        uint32[] memory remoteDomains,
        bytes32[] memory routers
    ) public onlyAdmin {
        for (uint256 i = 0; i < remoteDomains.length; i++) {
            remoteRouter[remoteDomains[i]] = routers[i];
        }
    }

    function takeFee(address to, uint256 amount) public onlyAdmin {
        (bool succ, ) = to.call{value: amount}("");
        require(succ);
        emit TakeFee(to, amount);
    }

    /// @param recipient set recipient to address(0) to save token in the router contract.
    function zeroExSwap(
        bytes memory swapcalldata,
        uint256 callgas,
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 guaranteedBuyAmount,
        address recipient,
        uint256 value
    ) public payable returns (uint256 boughtAmount) {
        require(value <= msg.value, "msg value not enough");
        // before swap
        // approve
        if (sellToken != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            require(
                IERC20(sellToken).approve(zeroEx, sellAmount),
                "erc20 approve failed"
            );
        }
        // check balance 0
        uint256 buyToken_bal_0;
        if (buyToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            buyToken_bal_0 = address(this).balance;
        } else {
            buyToken_bal_0 = IERC20(buyToken).balanceOf(address(this));
        }

        _zeroExSwap(swapcalldata, callgas, value);

        // after swap
        // cancel approval
        if (sellToken != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            // cancel approval
            require(
                IERC20(sellToken).approve(zeroEx, 0),
                "erc20 cancel approval failed"
            );
        }
        // check balance 1
        uint256 buyToken_bal_1;
        if (buyToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            buyToken_bal_1 = address(this).balance;
        } else {
            buyToken_bal_1 = IERC20(buyToken).balanceOf(address(this));
        }
        boughtAmount = buyToken_bal_1 - buyToken_bal_0;
        require(boughtAmount >= guaranteedBuyAmount, "swap output not enough");
        // send token to recipient
        if (recipient == address(0)) {
            return boughtAmount;
        }
        if (buyToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            (bool succ, ) = recipient.call{value: boughtAmount}("");
            require(succ, "send eth failed");
        } else {
            bool succ = IERC20(buyToken).transfer(recipient, boughtAmount);
            require(succ, "erc20 transfer failed");
        }

        return boughtAmount;
    }

    function _zeroExSwap(
        bytes memory swapcalldata,
        uint256 callgas,
        uint256 value
    ) internal {
        (bool succ, ) = zeroEx.call{value: value, gas: callgas}(swapcalldata);
        require(succ, "call swap failed");
    }

    function swap(
        bytes calldata swapcalldata,
        uint256 callgas,
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 guaranteedBuyAmount,
        address recipient
    ) public payable whenNotPaused("swap") {
        if (sellToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            require(msg.value >= sellAmount, "tx value is not enough");
        } else {
            require(
                IERC20(sellToken).transferFrom(
                    msg.sender,
                    address(this),
                    sellAmount
                ),
                "erc20 transfer failed"
            );
        }
        uint256 boughtAmount = zeroExSwap(
            swapcalldata,
            callgas,
            sellToken,
            sellAmount,
            buyToken,
            guaranteedBuyAmount,
            recipient,
            msg.value
        );
        emit LocalSwap(
            msg.sender,
            sellToken,
            sellAmount,
            buyToken,
            boughtAmount
        );
    }

    function isNoble(uint32 domain) public pure returns (bool) {
        return (domain == 4);
    }

    function isSolana(uint32 domain) public pure returns (bool) {
        return (domain == 5);
    }

    /// User entrance
    /// @param sellArgs : sell-token arguments
    /// @param buyArgs : buy-token arguments
    /// @param destDomain : destination domain
    /// @param recipient : token receiver on dest domain
    function swapAndBridge(
        SellArgs calldata sellArgs,
        BuyArgs calldata buyArgs,
        uint32 destDomain,
        bytes32 recipient
    ) public payable whenNotPaused("swapAndBridge") returns (uint64, uint64) {
        // to receive usdc on dest -> _fee = bridgeFee
        // to receive other token on dest (require swap) -> _fee = swapFee

        uint256 fee = (
            (buyArgs.buyToken == bytes32(0) ||
                (isSolana(destDomain) &&
                    buyArgs.buyToken ==
                    bytes32(
                        0xc6fa7af3bedbad3a3d65f36aabc97431b1bbe4c2d2f6e0e47ca60203452f5d61
                    )))
                ? fee[destDomain].bridgeFee
                : fee[destDomain].swapFee
        );
        require(msg.value >= fee, "Insufficient fee");

        if (recipient == bytes32(0)) {
            recipient = msg.sender.addressToBytes32();
        }

        // swap sellToken to usdc
        if (sellArgs.sellToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            require(
                msg.value >= sellArgs.sellAmount + fee,
                "tx value is not enough"
            );
        } else {
            require(
                IERC20(sellArgs.sellToken).transferFrom(
                    msg.sender,
                    address(this),
                    sellArgs.sellAmount
                ),
                "erc20 transfer failed"
            );
        }
        uint256 bridgeUSDCAmount;
        if (sellArgs.sellToken == usdc) {
            bridgeUSDCAmount = sellArgs.sellAmount;
        } else {
            bridgeUSDCAmount = zeroExSwap(
                sellArgs.sellcalldata,
                sellArgs.sellcallgas,
                sellArgs.sellToken,
                sellArgs.sellAmount,
                usdc,
                sellArgs.guaranteedBuyAmount,
                address(0),
                msg.value - fee
            );
        }

        // bridge usdc
        require(
            IERC20(usdc).approve(address(tokenMessenger), bridgeUSDCAmount),
            "erc20 approve failed"
        );

        uint64 bridgeNonce;
        if (isNoble(destDomain)) {
            return
                _swapAndBridgeNoble(
                    sellArgs.sellToken,
                    buyArgs.buyToken,
                    bridgeUSDCAmount,
                    destDomain,
                    recipient,
                    buyArgs.memo
                );
        } else {
            return
                _swapAndBridgeOther(
                    sellArgs.sellToken,
                    buyArgs.buyToken,
                    bridgeUSDCAmount,
                    destDomain,
                    recipient,
                    buyArgs.guaranteedBuyAmount,
                    buyArgs.memo
                );
        }
    }

    function _swapAndBridgeNoble(
        address sellToken,
        bytes32 buyToken,
        uint256 bridgeUSDCAmount,
        uint32 destDomain,
        bytes32 recipient,
        bytes calldata memo
    ) internal returns (uint64, uint64) {
        uint64 bridgeNonce = tokenMessenger.depositForBurnWithCaller(
            bridgeUSDCAmount,
            destDomain,
            recipient,
            usdc,
            nobleCaller
        );

        emit SwapAndBridge2(
            sellToken,
            buyToken,
            bridgeUSDCAmount,
            destDomain,
            recipient,
            memo
        );

        return (bridgeNonce, 0);
    }

    function _swapAndBridgeOther(
        address sellToken,
        bytes32 buyToken,
        uint256 bridgeUSDCAmount,
        uint32 destDomain,
        bytes32 recipient,
        uint256 guaranteedBuyAmount,
        bytes calldata memo
    ) internal returns (uint64, uint64) {
        uint64 bridgeNonce;
        bytes32 destRouter = remoteRouter[destDomain];

        if (isSolana(destDomain)) {
            bridgeNonce = tokenMessenger.depositForBurnWithCaller(
                bridgeUSDCAmount,
                destDomain,
                solanaProgramUsdcAccount,
                usdc,
                solanaCaller
            );
        } else {
            bridgeNonce = tokenMessenger.depositForBurnWithCaller(
                bridgeUSDCAmount,
                destDomain,
                destRouter,
                usdc,
                destRouter
            );
        }

        bytes32 bridgeNonceHash = keccak256(
            abi.encodePacked(messageTransmitter.localDomain(), bridgeNonce)
        );

        // Send swap message
        SwapMessage memory swapMessage = SwapMessage(
            version,
            bridgeNonceHash,
            bridgeUSDCAmount,
            buyToken,
            guaranteedBuyAmount,
            recipient
        );

        uint64 swapMessageNonce = isSolana(destDomain)
            ? messageTransmitter.sendMessageWithCaller(
                destDomain,
                solanaReceiver,
                solanaCaller,
                swapMessage.encode()
            )
            : messageTransmitter.sendMessageWithCaller(
                destDomain,
                destRouter,
                destRouter,
                swapMessage.encode()
            );

        emit SwapAndBridge2(
            sellToken,
            buyToken,
            bridgeUSDCAmount,
            destDomain,
            recipient,
            memo
        );

        swapHashSender[
            keccak256(abi.encode(destDomain, swapMessageNonce))
        ] = msg.sender;

        return (bridgeNonce, swapMessageNonce);
    }

    /// Relayer entrance
    function relay(
        MessageWithAttestation calldata bridgeMessage,
        MessageWithAttestation calldata swapMessage,
        bytes calldata swapdata,
        uint256 callgas
    ) public whenNotPaused("relay") {
        uint32 sourceDomain = bridgeMessage.message.sourceDomain();
        require(
            swapMessage.message.sourceDomain() == sourceDomain,
            "inconsistent source domain"
        );
        require(
            bridgeMessage.message.nonce() + 1 == swapMessage.message.nonce(),
            "nonce not match"
        );
        // 1. decode swap message, get binding bridge message nonce.
        SwapMessage memory swapArgs = swapMessage.message.body().decode();

        // 2. check bridge message nonce is unused.
        // ignore noble messages
        if (!isNoble(sourceDomain)) {
            require(
                messageTransmitter.usedNonces(swapArgs.bridgeNonceHash) == 0,
                "bridge message nonce is already used"
            );
        }

        // 3. verifys bridge message attestation and mint usdc to this contract.
        // reverts when atestation is invalid.
        uint256 usdc_bal_0 = IERC20(usdc).balanceOf(address(this));
        messageTransmitter.receiveMessage(
            bridgeMessage.message,
            bridgeMessage.attestation
        );
        uint256 usdc_bal_1 = IERC20(usdc).balanceOf(address(this));
        require(usdc_bal_1 >= usdc_bal_0, "usdc bridge error");

        // 4. check bridge message nonce is used.
        // ignore noble messages
        if (!isNoble(sourceDomain)) {
            require(
                messageTransmitter.usedNonces(swapArgs.bridgeNonceHash) == 1,
                "bridge message nonce is incorrect"
            );
        }

        // 5. verifys swap message attestation.
        // reverts when atestation is invalid.
        messageTransmitter.receiveMessage(
            swapMessage.message,
            swapMessage.attestation
        );

        address recipient = swapArgs.recipient.bytes32ToAddress();

        emit BridgeArrive(swapArgs.bridgeNonceHash, usdc_bal_1 - usdc_bal_0);

        uint256 bridgeUSDCAmount;
        if (swapArgs.sellAmount == 0) {
            bridgeUSDCAmount = usdc_bal_1 - usdc_bal_0;
        } else {
            bridgeUSDCAmount = swapArgs.sellAmount;
            if (bridgeUSDCAmount < (usdc_bal_1 - usdc_bal_0)) {
                // router did not receive enough usdc
                IERC20(usdc).transfer(recipient, bridgeUSDCAmount);
                return;
            }
        }

        uint256 swapAmount = bridgeUSDCAmount;

        require(swapArgs.version == version, "wrong swap message version");

        if (
            swapArgs.buyToken == bytes32(0) ||
            swapArgs.buyToken == usdc.addressToBytes32()
        ) {
            // receive usdc
            bool succ = IERC20(usdc).transfer(recipient, bridgeUSDCAmount);
            require(succ, "erc20 transfer failed");
        } else {
            try
                this.zeroExSwap(
                    swapdata,
                    callgas,
                    usdc,
                    swapAmount,
                    swapArgs.buyToken.bytes32ToAddress(),
                    swapArgs.guaranteedBuyAmount,
                    recipient,
                    0
                )
            {} catch {
                IERC20(usdc).transfer(recipient, swapAmount);
                emit DestSwapFailed(swapArgs.bridgeNonceHash);
                return;
            }
            // transfer rem to recipient
            emit DestSwapSuccess(swapArgs.bridgeNonceHash);
        }
    }

    /// @dev Does not handle message.
    /// Returns a boolean to make message transmitter accept or refuse a message.
    function handleReceiveMessage(
        uint32 sourceDomain,
        bytes32 sender,
        bytes calldata messageBody
    ) external returns (bool) {
        require(
            msg.sender == address(messageTransmitter),
            "caller not allowed"
        );
        if (remoteRouter[sourceDomain] == sender || isNoble(sourceDomain)) {
            return true;
        }
        return false;
    }

    function usedNonces(bytes32 nonce) external view returns (uint256) {
        return messageTransmitter.usedNonces(nonce);
    }

    function localDomain() external view returns (uint32) {
        return messageTransmitter.localDomain();
    }
}
