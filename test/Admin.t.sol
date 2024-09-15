// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/ValueRouter.sol";

contract AdminPausableTest is Test {
    ValueRouter public adminPausable;
    address public admin = address(1);
    address public newAdmin = address(2);
    address public nonAdmin = address(3);
    address public user = address(4);

    bytes public revertReason_paused =
        hex"08c379a00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000001c5061757361626c653a2066756e6374696f6e2069732070617573656400000000";

    function setUp() public {
        adminPausable = new ValueRouter(
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            admin
        );
    }

    function testChangeAdmin() public {
        vm.prank(admin);

        adminPausable.changeAdmin(newAdmin);

        assertEq(adminPausable.pendingAdmin(), newAdmin);
    }

    function testApplyAdmin() public {
        vm.prank(admin);
        adminPausable.changeAdmin(newAdmin);

        vm.prank(newAdmin);
        adminPausable.applyAdmin();

        address currentAdmin = adminPausable.admin();
        console.log("Current admin after applyAdmin:", currentAdmin);

        assertEq(currentAdmin, newAdmin, "Invalid admin address after applyAdmin");
    }

    function testFailNonAdminCannotChangeAdmin() public {
        vm.prank(nonAdmin);
        adminPausable.changeAdmin(newAdmin);
    }

    function testPauseAndUnpauseFunction() public {
        string memory functionName = "someFunction";

        vm.prank(admin);
        adminPausable.pauseFunction(functionName);

        vm.prank(admin);
        adminPausable.unpauseFunction(functionName);
    }

    function testFailNonAdminCannotPauseFunction() public {
        vm.prank(nonAdmin);
        adminPausable.pauseFunction("someFunction");
    }

    function testSwapAndBridgeNotPaused() public {
        SellArgs memory sellArgs = SellArgs({
            sellToken: 0x0000000000000000000000000000000000000001,
            sellAmount: 1000,
            guaranteedBuyAmount: 950,
            sellcallgas: 50000,
            sellcalldata: hex"abcdef"
        });

        BuyArgs memory buyArgs = BuyArgs({
            buyToken: bytes32(0x0000000000000000000000000000000000000000000000000000000000000001), // 假设的 buyToken
            guaranteedBuyAmount: 1000,
            memo: bytes(hex"")
        });

        bytes32 recipient = bytes32(0x0000000000000000000000000000000000000000000000000000000000000001);

        vm.prank(user);
        // Expect not paused
        // Expect revert
        try adminPausable.swapAndBridge(sellArgs, buyArgs, 2, recipient) {}
        catch (bytes memory revertReason) {
            string memory revertMessage = string(revertReason);

            assertTrue(
                keccak256(bytes(revertMessage)) != keccak256(revertReason_paused),
                "Unexpected revert: Pausable: function is paused"
            );
        }
    }

    function testSwapAndBridgePaused() public {
        vm.prank(admin);
        adminPausable.pauseFunction("swapAndBridge");

        SellArgs memory sellArgs = SellArgs({
            sellToken: 0x0000000000000000000000000000000000000001,
            sellAmount: 1000,
            guaranteedBuyAmount: 950,
            sellcallgas: 50000,
            sellcalldata: hex"abcdef"
        });

        BuyArgs memory buyArgs = BuyArgs({
            buyToken: bytes32(0x0000000000000000000000000000000000000000000000000000000000000001),
            guaranteedBuyAmount: 1000,
            memo: bytes(hex"")
        });

        bytes32 recipient = bytes32(0x0000000000000000000000000000000000000000000000000000000000000001);

        vm.prank(user);
        vm.expectRevert("Pausable: function is paused");
        adminPausable.swapAndBridge(sellArgs, buyArgs, 2, recipient);
    }

    function testUnpauseAndSwapAndBridge() public {
        vm.prank(admin);
        adminPausable.pauseFunction("swapAndBridge");

        vm.prank(admin);
        adminPausable.unpauseFunction("swapAndBridge");

        SellArgs memory sellArgs = SellArgs({
            sellToken: 0x0000000000000000000000000000000000000001,
            sellAmount: 1000,
            guaranteedBuyAmount: 950,
            sellcallgas: 50000,
            sellcalldata: hex"abcdef"
        });

        BuyArgs memory buyArgs = BuyArgs({
            buyToken: bytes32(0x0000000000000000000000000000000000000000000000000000000000000001),
            guaranteedBuyAmount: 1000,
            memo: bytes(hex"")
        });

        bytes32 recipient = bytes32(0x0000000000000000000000000000000000000000000000000000000000000001);

        vm.prank(user);
        // Expect not paused
        // Expect revert
        try adminPausable.swapAndBridge(sellArgs, buyArgs, 2, recipient) {}
        catch (bytes memory revertReason) {
            string memory revertMessage = string(revertReason);

            assertTrue(
                keccak256(bytes(revertMessage)) != keccak256(revertReason_paused),
                "Unexpected revert: Pausable: function is paused"
            );
        }
    }

    function testAdminCanTakeFee() public {
        address feeReceiver = address(8);
        vm.deal(address(adminPausable), 10 ether);

        uint256 initialBalance = feeReceiver.balance;

        vm.prank(admin);

        adminPausable.takeFee(feeReceiver, 1 ether);

        assertEq(feeReceiver.balance, initialBalance + 1 ether);
    }

    function testNonAdminCannotTakeFee() public {
        address feeReceiver = address(8);
        vm.deal(address(adminPausable), 10 ether);

        vm.prank(user);

        vm.expectRevert("AdminControl: not admin");
        adminPausable.takeFee(feeReceiver, 1 ether);
    }
}
