// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../BaseTest.sol";

contract SafeTest is BaseTest {
    Safe public userSafe;

    function setUp() public override {
        super.setUp();
        userSafe = createSafe();
    }

    /// @dev Ensures that `userSafe` has been correctly initialized.
    function test_Safe_Deployment() public {
        address[] memory owners = getDefaultOwners();
        address[] memory safeOwners = userSafe.getOwners();

        assertEq(owners.length, safeOwners.length);
        assertEq(userSafe.nonce(), 0);
        assertEq(userSafe.ownerCount(), safeOwners.length);
        assertEq(userSafe.getQuorum(), safeOwners.length);

        for (uint256 i = 0; i < owners.length; i++) {
            address expectedOwner = owners[i];
            address actualOwner = safeOwners[i];

            assertEq(expectedOwner, actualOwner);
            assertTrue(userSafe.isOwner(expectedOwner));
        }
    }

    function test_Initialize() public {
        address[] memory defaultOwners = getDefaultOwners();

        safeFactory.createSafe({ owners: defaultOwners, quorum: defaultOwners.length });
        Safe createdSafe = Safe(payable(safeFactory.getSafes({ account: address(this) })[0]));

        address[] memory safeOwners = createdSafe.getOwners();

        assertEq(createdSafe.nonce(), 0);
        assertEq(createdSafe.ownerCount(), safeOwners.length);
        assertEq(createdSafe.getQuorum(), safeOwners.length);

        for (uint256 i = 0; i < safeOwners.length; i++) {
            address expectedOwner = defaultOwners[i];
            address actualOwner = safeOwners[i];

            assertEq(expectedOwner, actualOwner);
            assertTrue(createdSafe.isOwner(expectedOwner));
        }
    }

    function testCannot_Initialize_Safe_Implementation() public {
        vm.expectRevert("Initializable: contract is already initialized");
        safe.initialize({ owners: new address[](1), quorum: 1 });
    }

    function testCannot_Initialize_NoOwnersProvided() public {
        vm.expectRevert(IOwnerManager.NoOwnersProvided.selector);
        safeFactory.createSafe({ owners: new address[](0), quorum: 1 });
    }

    function testCannot_Initialize_InvalidQuorum_ZeroValue() public {
        vm.expectRevert(IOwnerManager.InvalidQuorum.selector);
        safeFactory.createSafe({ owners: getDefaultOwners(), quorum: 0 });
    }

    function testCannot_Initialize_InvalidQuorum_OverOwners() public {
        address[] memory defaultOwners = getDefaultOwners();
        vm.expectRevert(IOwnerManager.InvalidQuorum.selector);
        safeFactory.createSafe({ owners: defaultOwners, quorum: defaultOwners.length + 1 });
    }

    /// @dev Case where an owner is the zero address. defaultOwners: [0, bob, charlie]
    function testCannot_Initialize_InvalidOwner_ZeroAddress() public {
        address[] memory defaultOwners = getDefaultOwners();
        defaultOwners[0] = address(0);

        vm.expectRevert(IOwnerManager.InvalidOwner.selector);
        safeFactory.createSafe({ owners: defaultOwners, quorum: defaultOwners.length });
    }

    /// @dev Case where an owner is the sentinel address. defaultOwners: [sentinel, bob, charlie]
    function testCannot_Initialize_InvalidOwner_SentinelValue() public {
        address[] memory defaultOwners = getDefaultOwners();
        defaultOwners[0] = address(0x01);

        vm.expectRevert(IOwnerManager.InvalidOwner.selector);
        safeFactory.createSafe({ owners: defaultOwners, quorum: defaultOwners.length });
    }

    /// @dev Case where an owner is the Safe address. defaultOwners: [safe, bob, charlie]
    function testCannot_Initialize_InvalidOwner_Self() public {
        address[] memory defaultOwners = getDefaultOwners();
        defaultOwners[0] = 0xd77C0C290eB6eF0d1f0e9fa2917D7C487B3567D8; // First Safe address.

        vm.expectRevert(IOwnerManager.InvalidOwner.selector);
        safeFactory.createSafe({ owners: defaultOwners, quorum: defaultOwners.length });
    }

    /// @dev Case where an owner is a sequential duplicate entry. defaultOwners: [alice, alice, charlie]
    function testCannot_Initialize_InvalidOwner_SequentialDuplicate() public {
        address[] memory defaultOwners = getDefaultOwners();
        defaultOwners[1] = defaultOwners[0];

        vm.expectRevert(IOwnerManager.InvalidOwner.selector);
        safeFactory.createSafe({ owners: defaultOwners, quorum: defaultOwners.length });
    }

    /// @dev Case where an owner is a duplicate entry. defaultOwners: [alice, bob, alice]
    function testCannot_Initialize_DuplicateOwner() public {
        address[] memory defaultOwners = getDefaultOwners();
        defaultOwners[2] = defaultOwners[0];

        vm.expectRevert(IOwnerManager.DuplicateOwner.selector);
        safeFactory.createSafe({ owners: defaultOwners, quorum: defaultOwners.length });
    }

    /* `executeTransaction` Tests */

    function test_ExecuteTransaction_MintERC721_Free() public {
        uint256 safeNonce = userSafe.nonce();
        assertEq(safeNonce, 0);

        uint256 tokenId = 1;

        Transaction memory txn = Transaction({
            operation: Operation.CALL,
            to: address(mockERC721),
            value: 0,
            data: abi.encodeWithSelector(MockERC721.mint.selector, tokenId),
            nonce: safeNonce
        });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        /// Signatures must be provided in ascending order.
        bytes[] memory signatures = getOrderedSignatures(txnHash);

        hoax(users.alice.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit TransactionSuccess({ txnHash: txnHash });
        userSafe.executeTransaction(txn, signatures);

        assertEq(userSafe.nonce(), safeNonce + 1);
        assertEq(mockERC721.ownerOf(tokenId), address(userSafe));
    }

    function test_ExecuteTransaction_MintERC721_Paid() public {
        uint256 tokenId = 1;
        uint256 price = mockERC721.tokenPrice();
        vm.deal(address(userSafe), price);
        assertEq(address(userSafe).balance, price);

        Transaction memory txn = Transaction({
            operation: Operation.CALL,
            to: address(mockERC721),
            value: price,
            data: abi.encodeWithSelector(mockERC721.mintPaid.selector, tokenId),
            nonce: 0
        });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        startHoax(users.alice.account);
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));

        assertEq(mockERC721.ownerOf(tokenId), address(userSafe));
        assertEq(mockERC721.balanceOf(address(userSafe)), 1);
    }

    function test_ExecuteTransaction_ERC721Transfer() public {
        uint256 tokenId = 1;

        startHoax(users.alice.account);
        mockERC721.mint(tokenId);
        mockERC721.safeTransferFrom(users.alice.account, address(userSafe), tokenId);
        vm.stopPrank();

        assertEq(mockERC721.ownerOf(tokenId), address(userSafe));

        /// `transferFrom(address,address,uint256)`
        bytes memory callData =
            abi.encodeWithSelector(mockERC721.transferFrom.selector, address(userSafe), users.bob.account, tokenId);

        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: address(mockERC721), value: 0, data: callData, nonce: 0 });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        startHoax(users.alice.account);
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));

        assertEq(mockERC721.ownerOf(tokenId), users.bob.account);
    }

    function test_ExecuteTransaction_MintERC1155_Free() public {
        uint256 tokenId = 1;
        uint256 amount = 5;

        Transaction memory txn = Transaction({
            operation: Operation.CALL,
            to: address(mockERC1155),
            value: 0,
            data: abi.encodeWithSelector(MockERC1155.mint.selector, tokenId, amount),
            nonce: 0
        });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        startHoax(users.alice.account);
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));

        assertEq(mockERC1155.balanceOf(address(userSafe), tokenId), amount);
    }

    function test_ExecuteTransaction_MintERC1155_Paid() public {
        uint256 tokenId = 1;
        uint256 amount = 5;

        uint256 price = mockERC721.tokenPrice();
        vm.deal(address(userSafe), price);
        assertEq(address(userSafe).balance, price);

        Transaction memory txn = Transaction({
            operation: Operation.CALL,
            to: address(mockERC1155),
            value: price,
            data: abi.encodeWithSelector(MockERC1155.mintPaid.selector, tokenId, amount),
            nonce: 0
        });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        startHoax(users.alice.account);
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));

        assertEq(mockERC1155.balanceOf(address(userSafe), tokenId), amount);
    }

    function test_ExecuteTransaction_ERC1155Transfer() public {
        uint256 tokenId = 1;
        uint256 amount = 5;

        startHoax(users.alice.account);
        mockERC1155.mint(tokenId, amount);
        mockERC1155.safeTransferFrom(users.alice.account, address(userSafe), tokenId, amount, "");
        vm.stopPrank();

        assertEq(mockERC1155.balanceOf(address(userSafe), tokenId), amount);

        /// `safeTransferFrom(address,address,uint256,uint256,bytes)`
        bytes memory callData = abi.encodeWithSelector(
            mockERC1155.safeTransferFrom.selector, address(userSafe), users.bob.account, tokenId, amount, ""
        );

        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: address(mockERC1155), value: 0, data: callData, nonce: 0 });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        startHoax(users.alice.account);
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));

        assertEq(mockERC1155.balanceOf(address(userSafe), tokenId), 0);
        assertEq(mockERC1155.balanceOf(users.bob.account, tokenId), amount);
    }

    function test_ExecuteTransaction_ERC20Transfer() public {
        uint256 amount = 100_000_000e18 ether;
        deal({ token: address(mockERC20), to: address(userSafe), give: amount });
        assertEq(mockERC20.balanceOf(address(userSafe)), amount);

        bytes memory callData = abi.encodeWithSelector(mockERC20.transfer.selector, users.bob.account, amount);

        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: address(mockERC20), value: 0, data: callData, nonce: 0 });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        hoax(users.alice.account);
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));

        assertEq(mockERC20.balanceOf(address(userSafe)), 0);
        assertEq(mockERC20.balanceOf(users.bob.account), amount);
    }

    function test_ExecuteTransaction_NativeTokenTransfer_Fuzzed(uint256 msgValue) public {
        msgValue = bound(msgValue, 1 wei, 100 ether);

        vm.deal(address(userSafe), msgValue);
        assertEq(address(userSafe).balance, msgValue);

        address receiver = address(0xbabe);

        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: receiver, value: msgValue, data: "", nonce: 0 });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        hoax(users.alice.account);
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));

        assertEq(address(userSafe).balance, 0 ether);
        assertEq(receiver.balance, msgValue);
    }

    function testCannot_ExecuteTransaction_CallerNotOwner() public {
        Transaction memory txn = Transaction({
            operation: Operation.CALL,
            to: address(mockERC721),
            value: 0,
            data: abi.encodeWithSelector(MockERC721.mint.selector, 2),
            nonce: 0
        });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        vm.expectRevert(ISafe.CallerNotOwner.selector);
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));
    }

    function testCannot_ExecuteTransaction_QuorumNotReached() public {
        bytes[] memory signatures = new bytes[](1);
        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: users.alice.account, value: 0 ether, data: "", nonce: 0 });

        hoax(users.alice.account);
        vm.expectRevert(ISafe.QuorumNotReached.selector);
        userSafe.executeTransaction(txn, signatures);
    }

    function testCannot_ExecuteTransaction_NonceMismatch_Fuzzed(uint256 randNonce) public {
        vm.assume(randNonce != 0);

        Transaction memory txn = Transaction({
            operation: Operation.CALL,
            to: users.alice.account,
            value: 0 ether,
            data: "",
            nonce: randNonce
        });

        bytes32 txnHash = userSafe.encodeTransaction(txn);

        hoax(users.alice.account);
        vm.expectRevert(ISafe.NonceMismatch.selector);
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));
    }

    function testCannot_ExecuteTransaction_SignerNotOwner() public {
        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: users.alice.account, value: 0 ether, data: "", nonce: 0 });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        /// Replace Charlie's valid signature with Eve's.
        bytes[] memory signatures = getOrderedSignatures(txnHash);
        signatures[2] = signTransactionHash(txnHash, users.eve.privateKey);

        hoax(users.alice.account);
        vm.expectRevert(ISafe.SignerNotOwner.selector);
        userSafe.executeTransaction(txn, signatures);
    }

    function testCannot_ExecuteTransaction_InvalidSignatureOrder() public {
        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: users.alice.account, value: 0 ether, data: "", nonce: 0 });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        hoax(users.alice.account);
        vm.expectRevert(ISafe.InvalidSignatureOrder.selector);
        userSafe.executeTransaction(txn, getUnorderedSignatures(txnHash));
    }

    function testCannot_ExecuteTransaction_SignerHasNotApproved() public {
        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: users.alice.account, value: 0 ether, data: "", nonce: 0 });

        bytes32 txnHash = userSafe.encodeTransaction(txn);

        hoax(users.alice.account);
        vm.expectRevert(ISafe.SignerHasNotApproved.selector);
        userSafe.executeTransaction(txn, getOrderedSignatures(txnHash));
    }

    /* `approveTxnHash` Tests */

    function test_ApproveTxnHash_Fuzzed(bytes32 randomHash) public {
        hoax(users.alice.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit TxnApproved({ account: users.alice.account, txnHash: randomHash });
        userSafe.approveTxnHash(randomHash);

        bool hasApproved = userSafe.hasApprovedTxn(users.alice.account, randomHash);
        assertTrue(hasApproved);
    }

    function testCannot_ApproveTxnHash_CallerNotOwner_Fuzzed(address nonOwner) public {
        vm.assume(nonOwner != users.alice.account && nonOwner != users.bob.account && nonOwner != users.charlie.account);

        hoax(nonOwner);
        vm.expectRevert(ISafe.CallerNotOwner.selector);
        userSafe.approveTxnHash(bytes32(0));
    }
}
