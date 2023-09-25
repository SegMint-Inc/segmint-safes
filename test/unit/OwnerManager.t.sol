// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../BaseTest.sol";

contract OwnerManagerTest is BaseTest {
    Safe public userSafe;

    function setUp() public override {
        super.setUp();
        userSafe = createSafe();
    }

    /// @dev Whilst `Eve` is our assigned malicious user, we will use her
    /// address here to test adding and swapping owners.

    function test_AddOwner_NoQuorumChange() public {
        uint256 initQuorum = userSafe.getQuorum();

        bytes memory callData = abi.encodeWithSelector(IOwnerManager.addOwner.selector, users.eve.account, initQuorum);

        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: address(userSafe), value: 0, data: callData, nonce: 0 });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit OwnerAdded({ account: users.eve.account });

        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit TransactionSuccess({ txnHash: txnHash });

        hoax(users.alice.account);
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));

        assertEq(userSafe.nonce(), 1);
        assertEq(userSafe.getQuorum(), initQuorum);

        address[] memory owners = userSafe.getOwners();
        assertEq(userSafe.ownerCount(), owners.length);

        assertTrue(userSafe.isOwner(users.alice.account));
        assertTrue(userSafe.isOwner(users.bob.account));
        assertTrue(userSafe.isOwner(users.charlie.account));
        assertTrue(userSafe.isOwner(users.eve.account));
    }

    function test_AddOwner_QuorumChange() public {
        uint256 oldQuorum = userSafe.getQuorum();
        uint256 newQuorum = oldQuorum + 1;

        bytes memory callData = abi.encodeWithSelector(IOwnerManager.addOwner.selector, users.eve.account, newQuorum);

        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: address(userSafe), value: 0, data: callData, nonce: 0 });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit OwnerAdded({ account: users.eve.account });

        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit QuorumChanged({ oldQuorum: oldQuorum, newQuorum: newQuorum });

        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit TransactionSuccess({ txnHash: txnHash });

        hoax(users.alice.account);
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));

        assertEq(userSafe.nonce(), 1);
        assertEq(userSafe.getQuorum(), newQuorum);

        address[] memory owners = userSafe.getOwners();
        assertEq(userSafe.ownerCount(), owners.length);

        assertTrue(userSafe.isOwner(users.alice.account));
        assertTrue(userSafe.isOwner(users.bob.account));
        assertTrue(userSafe.isOwner(users.charlie.account));
        assertTrue(userSafe.isOwner(users.eve.account));
    }

    function testCannot_AddOwner_CallerNotSelf_Fuzzed(address notSafe) public {
        vm.assume(notSafe != address(userSafe));

        hoax(notSafe);
        vm.expectRevert(SelfAuthorized.CallerNotSelf.selector);
        userSafe.addOwner({ newOwner: notSafe, newQuorum: 0 });
    }

    function testCannot_AddOwner_InvalidOwner_ZeroAddress() public {
        bytes memory callData =
            abi.encodeWithSelector(IOwnerManager.addOwner.selector, address(0), userSafe.getQuorum());

        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: address(userSafe), value: 0, data: callData, nonce: 0 });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit TransactionFailed({ txnHash: txnHash });
        
        hoax(users.alice.account);
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));
    }

    function testCannot_AddOwner_InvalidAddress_Sentinel() public {
        bytes memory callData = abi.encodeWithSelector(
            IOwnerManager.addOwner.selector,
            address(0x01), // sentinel value.
            userSafe.getQuorum()
        );

        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: address(userSafe), value: 0, data: callData, nonce: 0 });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        hoax(users.alice.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit TransactionFailed({ txnHash: txnHash });
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));
    }

    function testCannot_AddOwner_InvalidAddress_Self() public {
        bytes memory callData = abi.encodeWithSelector(
            IOwnerManager.addOwner.selector,
            address(userSafe), // self value.
            userSafe.getQuorum()
        );

        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: address(userSafe), value: 0, data: callData, nonce: 0 });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        hoax(users.alice.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit TransactionFailed({ txnHash: txnHash });
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));
    }

    function testCannot_AddOwner_DuplicateOwner() public {
        bytes memory callData = abi.encodeWithSelector(
            IOwnerManager.addOwner.selector,
            users.alice.account, // default owner.
            userSafe.getQuorum()
        );

        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: address(userSafe), value: 0, data: callData, nonce: 0 });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        hoax(users.alice.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit TransactionFailed({ txnHash: txnHash });
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));
    }

    /// @dev Owners are ordered [alice, bob, charlie].
    function test_RemoveOwner_QuorumUpdate() public {
        uint256 newQuorum = userSafe.getQuorum() - 1;

        /// Remove Bob.
        bytes memory callData = abi.encodeWithSelector(
            IOwnerManager.removeOwner.selector,
            users.alice.account, // Alice points to Bob in linked list.
            users.bob.account,
            newQuorum
        );

        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: address(userSafe), value: 0, data: callData, nonce: 0 });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        hoax(users.alice.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit OwnerRemoved({ account: users.bob.account });
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));

        address[] memory owners = userSafe.getOwners();

        assertEq(owners.length, 2);
        assertEq(owners[0], users.alice.account);
        assertEq(owners[1], users.charlie.account);
        assertEq(owners.length, userSafe.ownerCount());

        assertEq(userSafe.getQuorum(), newQuorum);
        assertTrue(userSafe.isOwner(users.alice.account));
        assertTrue(userSafe.isOwner(users.charlie.account));
        assertFalse(userSafe.isOwner(users.bob.account));
    }

    function testCannot_RemoveOwner_CallerNotSelf(address notSafe) public {
        vm.assume(notSafe != address(userSafe));

        hoax(notSafe);
        vm.expectRevert(SelfAuthorized.CallerNotSelf.selector);
        userSafe.removeOwner({ prtOwner: users.alice.account, oldOwner: users.bob.account, newQuorum: 2 });
    }

    function testCannot_RemoveOwner_RemovalBreaksQuorum() public {
        /// Remove Bob.
        bytes memory callData = abi.encodeWithSelector(
            IOwnerManager.removeOwner.selector,
            users.alice.account, // Alice points to Bob in linked list.
            users.bob.account,
            userSafe.getQuorum()
        );

        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: address(userSafe), value: 0, data: callData, nonce: 0 });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        hoax(users.alice.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit TransactionFailed({ txnHash: txnHash });
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));
        /// Reverts with RemovalBreaksQuorum selector.
    }

    function testCannot_RemoveOwner_InvalidOwner_ZeroAddress() public {
        bytes memory callData = abi.encodeWithSelector(
            IOwnerManager.removeOwner.selector,
            users.alice.account,
            address(0), // zero address.
            userSafe.getQuorum() - 1
        );

        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: address(userSafe), value: 0, data: callData, nonce: 0 });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        hoax(users.alice.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit TransactionFailed({ txnHash: txnHash });
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));
        /// Reverts with InvalidOwner selector.
    }

    function testCannot_RemoveOwner_InvalidOwner_Sentinel() public {
        bytes memory callData = abi.encodeWithSelector(
            IOwnerManager.removeOwner.selector,
            users.alice.account,
            address(0x01), // sentinel address.
            userSafe.getQuorum() - 1
        );

        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: address(userSafe), value: 0, data: callData, nonce: 0 });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        hoax(users.alice.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit TransactionFailed({ txnHash: txnHash });
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));
        /// Reverts with InvalidOwner selector.
    }

    function testCannot_RemoveOwner_InvalidPointer() public {
        bytes memory callData = abi.encodeWithSelector(
            IOwnerManager.removeOwner.selector,
            users.charlie.account, // charlie doesn't point to Bob
            users.bob.account,
            userSafe.getQuorum() - 1
        );

        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: address(userSafe), value: 0, data: callData, nonce: 0 });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        hoax(users.alice.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit TransactionFailed({ txnHash: txnHash });
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));
        /// Reverts with InvalidPointer selector.
    }

    function test_SwapOwner() public {
        bytes memory callData = abi.encodeWithSelector(
            IOwnerManager.swapOwner.selector,
            users.alice.account,
            users.bob.account, // swap Bob with Eve,
            users.eve.account
        );

        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: address(userSafe), value: 0, data: callData, nonce: 0 });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        hoax(users.alice.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit OwnerSwapped({ oldOwner: users.bob.account, newOwner: users.eve.account });
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));
        /// Reverts with InvalidPointer selector.

        assertFalse(userSafe.isOwner(users.bob.account));
        assertTrue(userSafe.isOwner(users.eve.account));
    }

    function testCannot_SwapOwner_InvalidOwner_ZeroAddress() public {
        bytes memory callData = abi.encodeWithSelector(
            IOwnerManager.swapOwner.selector,
            users.alice.account,
            users.bob.account, // swap Bob with Eve,
            address(0)
        );

        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: address(userSafe), value: 0, data: callData, nonce: 0 });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        hoax(users.alice.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit TransactionFailed({ txnHash: txnHash });
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));
        /// Reverts with InvalidOwner selector.
    }

    function testCannot_SwapOwner_InvalidOwner_Sentinel() public {
        bytes memory callData = abi.encodeWithSelector(
            IOwnerManager.swapOwner.selector,
            users.alice.account,
            users.bob.account, // swap Bob with Eve,
            address(0x01)
        );

        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: address(userSafe), value: 0, data: callData, nonce: 0 });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        hoax(users.alice.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit TransactionFailed({ txnHash: txnHash });
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));
        /// Reverts with InvalidOwner selector.
    }

    function testCannot_SwapOwner_InvalidOwner_Self() public {
        bytes memory callData = abi.encodeWithSelector(
            IOwnerManager.swapOwner.selector,
            users.alice.account,
            users.bob.account, // swap Bob with Eve,
            address(userSafe)
        );

        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: address(userSafe), value: 0, data: callData, nonce: 0 });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        hoax(users.alice.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit TransactionFailed({ txnHash: txnHash });
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));
        /// Reverts with InvalidOwner selector.
    }

    function testCannot_SwapOwner_DuplicateOwner() public {
        bytes memory callData = abi.encodeWithSelector(
            IOwnerManager.swapOwner.selector, users.alice.account, users.bob.account, users.charlie.account
        );

        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: address(userSafe), value: 0, data: callData, nonce: 0 });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        hoax(users.alice.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit TransactionFailed({ txnHash: txnHash });
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));
        /// Reverts with DuplicateOwner selector.
    }

    function testCannot_SwapOwner_InvalidOwner_OldOwner_ZeroAddress() public {
        bytes memory callData =
            abi.encodeWithSelector(IOwnerManager.swapOwner.selector, users.alice.account, address(0), users.eve.account);

        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: address(userSafe), value: 0, data: callData, nonce: 0 });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        hoax(users.alice.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit TransactionFailed({ txnHash: txnHash });
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));
        /// Reverts with InvalidOwner selector.
    }

    function testCannot_SwapOwner_InvalidOwner_OldOwner_Sentinel() public {
        bytes memory callData = abi.encodeWithSelector(
            IOwnerManager.swapOwner.selector, users.alice.account, address(0x01), users.eve.account
        );

        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: address(userSafe), value: 0, data: callData, nonce: 0 });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        hoax(users.alice.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit TransactionFailed({ txnHash: txnHash });
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));
        /// Reverts with InvalidOwner selector.
    }

    function testCannot_SwapOwner_PointerMismatch() public {
        bytes memory callData = abi.encodeWithSelector(
            IOwnerManager.swapOwner.selector,
            users.charlie.account, // Alice doesn't point to Charlie.
            users.bob.account,
            users.eve.account
        );

        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: address(userSafe), value: 0, data: callData, nonce: 0 });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        hoax(users.alice.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit TransactionFailed({ txnHash: txnHash });
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));
        /// Reverts with InvalidOwner selector.
    }

    function test_ChangeQuorum() public {
        uint256 oldQuorum = userSafe.getQuorum();
        uint256 newQuorum = 2;

        bytes memory callData = abi.encodeWithSelector(IOwnerManager.changeQuorum.selector, newQuorum);

        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: address(userSafe), value: 0, data: callData, nonce: 0 });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        hoax(users.alice.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit QuorumChanged({ oldQuorum: oldQuorum, newQuorum: newQuorum });
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));
        /// Reverts with InvalidOwner selector.

        assertEq(userSafe.getQuorum(), newQuorum);
    }

    function testCannot_ChangeQuorum_CallerNotSelf(address notSafe) public {
        vm.assume(notSafe != address(userSafe));

        hoax(notSafe);
        vm.expectRevert(SelfAuthorized.CallerNotSelf.selector);
        userSafe.changeQuorum(1);
    }

    function testCannot_ChangeQuorum_InvalidQuorum_UnderMin() public {
        bytes memory callData = abi.encodeWithSelector(IOwnerManager.changeQuorum.selector, 0);

        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: address(userSafe), value: 0, data: callData, nonce: 0 });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        hoax(users.alice.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit TransactionFailed({ txnHash: txnHash });
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));
        /// Reverts with InvalidOwner selector.
    }

    function testCannot_ChangeQuorum_InvalidQuorum_OverMax() public {
        uint256 badQuorum = userSafe.ownerCount() + 1;
        bytes memory callData = abi.encodeWithSelector(IOwnerManager.changeQuorum.selector, badQuorum);

        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: address(userSafe), value: 0, data: callData, nonce: 0 });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        hoax(users.alice.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit TransactionFailed({ txnHash: txnHash });
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));
        /// Reverts with InvalidOwner selector.
    }
}
