// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../BaseTest.sol";

contract MultiCallTest is BaseTest {
    Safe public userSafe;

    function setUp() public override {
        super.setUp();
        userSafe = createSafe();  /// Creates a safe for `address(this)`.
    }

    function test_ExecuteTransaction_AddMultipleOwners() public {

    }

    function testCannot_MultiCall_CallerNotSelf() public {
        address[] memory targets = new address[](1);
        bytes[] memory payloads = new bytes[](1);

        vm.expectRevert(SelfAuthorized.CallerNotSelf.selector);
        userSafe.multicall(targets, payloads);
    }

    /* Helper Functions */

    /// @dev Helper function to approve a transaction hash with all Safe owners.
    function approveWithOwners(bytes32 txnHash) internal {
        hoax(users.alice.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit TxnApproved({ account: users.alice.account, txnHash: txnHash });
        userSafe.approveTxnHash(txnHash);

        hoax(users.bob.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit TxnApproved({ account: users.bob.account, txnHash: txnHash });
        userSafe.approveTxnHash(txnHash);

        hoax(users.charlie.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit TxnApproved({ account: users.charlie.account, txnHash: txnHash });
        userSafe.approveTxnHash(txnHash);
    }

}