// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../BaseTest.sol";

contract MultiCallTest is BaseTest {
    Safe public userSafe;

    function setUp() public override {
        super.setUp();
        userSafe = createSafe();
    }

    function testCannot_MultiCall_CallerNotSelf() public {
        address[] memory targets = new address[](1);
        bytes[] memory payloads = new bytes[](1);

        vm.expectRevert(SelfAuthorized.CallerNotSelf.selector);
        userSafe.multicall(targets, payloads);
    }
}
