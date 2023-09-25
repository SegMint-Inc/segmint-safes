// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../BaseTest.sol";

/**
 * @dev Tests that require a fork of mainnet to pass.
 */
contract SafeForkTest is BaseTest {
    Safe public userSafe;

    /// Respective mainnet addresses.
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    constructor() {
        deployment = Deployment.FORK;
    }

    function setUp() public override {
        super.setUp();
        userSafe = createSafe();
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
        approveWithOwners(userSafe, txnHash);

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

        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: USDT, value: 0, data: callData, nonce: userSafe.nonce() });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

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

        Transaction memory txn =
            Transaction({ operation: Operation.CALL, to: USDC, value: 0, data: callData, nonce: userSafe.nonce() });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        bytes[] memory signatures = getOrderedSignatures(txnHash);

        hoax(users.alice.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit TransactionSuccess({ txnHash: txnHash });
        userSafe.executeTransaction(txn, signatures);

        assertEq(IERC20(USDC).balanceOf(address(userSafe)), 0);
        assertEq(IERC20(USDC).balanceOf(users.bob.account), depositAmount);
    }

    function test_ExecuteTransaction_MultiCall_SendTokens() public {
        /// Populate Safe with WETH, USDC and USDT.
        uint256 ethAmount = 100 ether;
        uint256 usdAmount = 1_000_000e6; // $1m.

        deal({ token: WETH, to: address(userSafe), give: ethAmount });
        deal({ token: USDC, to: address(userSafe), give: usdAmount });
        deal({ token: USDT, to: address(userSafe), give: usdAmount });

        assertEq(IERC20(WETH).balanceOf(address(userSafe)), ethAmount);
        assertEq(IERC20(USDC).balanceOf(address(userSafe)), usdAmount);
        assertEq(IERC20(USDT).balanceOf(address(userSafe)), usdAmount);

        /// Assign targets for multicall transaction.
        address[] memory targets = new address[](3);
        targets[0] = WETH;
        targets[1] = USDC;
        targets[2] = USDT;

        /// Assign targets for multicall transaction.
        bytes[] memory payloads = new bytes[](3);
        payloads[0] = abi.encodeWithSelector(IERC20.transfer.selector, users.bob.account, ethAmount);
        payloads[1] = abi.encodeWithSelector(IERC20.transfer.selector, users.bob.account, usdAmount);
        payloads[2] = abi.encodeWithSelector(IERC20.transfer.selector, users.bob.account, usdAmount);

        /// Craft multicall calldata.
        bytes memory callData = abi.encodeWithSelector(userSafe.multicall.selector, targets, payloads);

        Transaction memory txn = Transaction({
            operation: Operation.CALL,
            to: address(userSafe),
            value: 0,
            data: callData,
            nonce: userSafe.nonce()
        });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        bytes[] memory signatures = getOrderedSignatures(txnHash);

        hoax(users.alice.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit TransactionSuccess({ txnHash: txnHash });
        userSafe.executeTransaction(txn, signatures);

        assertEq(IERC20(WETH).balanceOf(address(userSafe)), 0 ether);
        assertEq(IERC20(USDC).balanceOf(address(userSafe)), 0);
        assertEq(IERC20(USDT).balanceOf(address(userSafe)), 0);

        assertEq(IERC20(WETH).balanceOf(users.bob.account), ethAmount);
        assertEq(IERC20(USDC).balanceOf(users.bob.account), usdAmount);
        assertEq(IERC20(USDT).balanceOf(users.bob.account), usdAmount);
    }

    function testCannot_ExecuteTransaction_MultiCall_ArrayLengthMismatch() public {
        /// Populate Safe with WETH, USDC and USDT.
        uint256 ethAmount = 100 ether;
        uint256 usdAmount = 1_000_000e6; // $1m.

        deal({ token: WETH, to: address(userSafe), give: ethAmount });
        deal({ token: USDC, to: address(userSafe), give: usdAmount });
        deal({ token: USDT, to: address(userSafe), give: usdAmount });

        assertEq(IERC20(WETH).balanceOf(address(userSafe)), ethAmount);
        assertEq(IERC20(USDC).balanceOf(address(userSafe)), usdAmount);
        assertEq(IERC20(USDT).balanceOf(address(userSafe)), usdAmount);

        /// Assign targets for multicall transaction.
        address[] memory targets = new address[](3);
        targets[0] = WETH;
        targets[1] = USDC;
        targets[2] = USDT;

        /// Assign targets for multicall transaction.
        bytes[] memory payloads = new bytes[](2);
        payloads[0] = abi.encodeWithSelector(IERC20.transfer.selector, users.bob.account, ethAmount);
        payloads[1] = abi.encodeWithSelector(IERC20.transfer.selector, users.bob.account, usdAmount);

        /// Craft multicall calldata.
        bytes memory callData = abi.encodeWithSelector(userSafe.multicall.selector, targets, payloads);

        Transaction memory txn = Transaction({
            operation: Operation.CALL,
            to: address(userSafe),
            value: 0,
            data: callData,
            nonce: userSafe.nonce()
        });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        bytes[] memory signatures = getOrderedSignatures(txnHash);

        hoax(users.alice.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit TransactionFailed({ txnHash: txnHash });
        userSafe.executeTransaction(txn, signatures); // Reverts with `ArrayLengthMismatch` selector.
    }

    function testCannot_ExecuteTransaction_MultiCall_CallFailed() public {
        uint256 usdAmount = 1_000_000e6; // $1m.
        deal({ token: USDC, to: address(userSafe), give: usdAmount });
        deal({ token: USDT, to: address(userSafe), give: usdAmount });
        assertEq(IERC20(USDC).balanceOf(address(userSafe)), usdAmount);
        assertEq(IERC20(USDT).balanceOf(address(userSafe)), usdAmount);

        /// Assign targets for multicall transaction.
        address[] memory targets = new address[](2);
        targets[0] = USDC;
        targets[1] = USDT;

        /// Assign targets for multicall transaction.
        bytes[] memory payloads = new bytes[](2);
        payloads[0] = abi.encodeWithSelector(IERC20.transfer.selector, users.bob.account, usdAmount);
        payloads[1] = abi.encodeWithSelector(IERC20.transfer.selector, users.bob.account, usdAmount);

        /// Craft multicall calldata.
        bytes memory callData = abi.encodeWithSelector(userSafe.multicall.selector, targets, payloads);

        Transaction memory txn = Transaction({
            operation: Operation.CALL,
            to: address(userSafe),
            value: 0,
            data: callData,
            nonce: userSafe.nonce()
        });

        bytes32 txnHash = userSafe.encodeTransaction(txn);
        approveWithOwners(userSafe, txnHash);

        bytes[] memory signatures = getOrderedSignatures(txnHash);

        /// Ensure the transfer call reverts.
        vm.mockCallRevert({ callee: USDT, data: "", revertData: "" });

        hoax(users.alice.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit TransactionFailed({ txnHash: txnHash });
        userSafe.executeTransaction(txn, signatures); // Reverts with `CallFailed` selector.

        /// Clear the mocked revert.
        vm.clearMockedCalls();

        assertEq(IERC20(USDC).balanceOf(address(userSafe)), usdAmount);
        assertEq(IERC20(USDT).balanceOf(address(userSafe)), usdAmount);

        assertEq(IERC20(USDC).balanceOf(users.bob.account), 0);
        assertEq(IERC20(USDT).balanceOf(users.bob.account), 0);
    }
}
