// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../BaseTest.sol";

contract SafeForkTest is BaseTest {
    Safe public userSafe;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    constructor() {
        deployment = Deployment.FORK;
    }

    function setUp() public override {
        super.setUp();
        userSafe = createSafe();  /// Creates a safe for `address(this)`.
    }

    function test_ExecuteTransaction_WETHDeposit() public {
        uint256 depositAmount = 5 ether;
        vm.deal(address(userSafe), depositAmount);
        assertEq(address(userSafe).balance, depositAmount);

        Transaction memory txn = Transaction({
            operation: Operation.CALL,
            to: WETH,
            value: depositAmount,
            data: "",
            nonce: userSafe.nonce()
        });

        bytes32 txnHash = userSafe.encodeTransaction(txn);

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

        bytes[] memory signatures = getOrderedSignatures(txnHash);

        hoax(users.alice.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit TransactionSuccess({ txnHash: txnHash });
        userSafe.executeTransaction(txn, signatures);

        uint256 wethBalance = IERC20(WETH).balanceOf(address(userSafe));
        assertEq(wethBalance, depositAmount);
    }

    function test_ExecuteTransaction_USDTTransfer() public {
        uint256 depositAmount = 1_000_000e6;
        deal({ token: USDT, to: address(userSafe), give: depositAmount });
        
        assertEq(IERC20(USDT).balanceOf(address(userSafe)), depositAmount);
        assertEq(IERC20(USDT).balanceOf(users.bob.account), 0);

        /// `transfer(address,uint256)`
        /// Transfer 1m USDT from Safe to Bob.
        bytes memory callData = abi.encodeWithSelector(IERC20.transfer.selector, users.bob.account, depositAmount);

        Transaction memory txn = Transaction({
            operation: Operation.CALL,
            to: USDT,
            value: 0,
            data: callData,
            nonce: userSafe.nonce()
        });

        bytes32 txnHash = userSafe.encodeTransaction(txn);

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

        bytes[] memory signatures = getOrderedSignatures(txnHash);

        hoax(users.alice.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit TransactionSuccess({ txnHash: txnHash });
        userSafe.executeTransaction(txn, signatures);

        assertEq(IERC20(USDT).balanceOf(address(userSafe)), 0);
        assertEq(IERC20(USDT).balanceOf(users.bob.account), depositAmount);
    }

    function test_ExecuteTransaction_USDCTransfer() public {
        uint256 depositAmount = 1_000_000e6;
        deal({ token: USDC, to: address(userSafe), give: depositAmount });
        
        assertEq(IERC20(USDC).balanceOf(address(userSafe)), depositAmount);
        assertEq(IERC20(USDC).balanceOf(users.bob.account), 0);

        /// `transfer(address,uint256)`
        /// Transfer 1m USDC from Safe to Bob.
        bytes memory callData = abi.encodeWithSelector(IERC20.transfer.selector, users.bob.account, depositAmount);

        Transaction memory txn = Transaction({
            operation: Operation.CALL,
            to: USDC,
            value: 0,
            data: callData,
            nonce: userSafe.nonce()
        });

        bytes32 txnHash = userSafe.encodeTransaction(txn);

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

        bytes[] memory signatures = getOrderedSignatures(txnHash);

        hoax(users.alice.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit TransactionSuccess({ txnHash: txnHash });
        userSafe.executeTransaction(txn, signatures);

        assertEq(IERC20(USDC).balanceOf(address(userSafe)), 0);
        assertEq(IERC20(USDC).balanceOf(users.bob.account), depositAmount);
    }

}