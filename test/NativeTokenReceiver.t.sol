// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./BaseTest.sol";

contract NativeTokenReceiverTest is BaseTest {
    Safe public userSafe;

    function setUp() public override {
        super.setUp();
        userSafe = createSafe();  /// Creates a safe for `address(this)`.
    }

    function test_Receive_Fuzzed(uint256 msgValue) public {
        msgValue = bound(msgValue, 0 wei, address(this).balance);

        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit NativeTokenReceived({ sender: address(this), amount: msgValue });
        (bool success,) = address(userSafe).call{ value: msgValue }("");
        assertTrue(success);

        assertEq(address(userSafe).balance, msgValue);
    }

}