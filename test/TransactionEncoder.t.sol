// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./BaseTest.sol";

contract TransactionEncoder is BaseTest {
    MockEncoder public mockEncoder;

    function setUp() public override {
        mockEncoder = new MockEncoder();
    }

    function test_DomainNameAndVersion() public {
        (string memory name, string memory version) = mockEncoder.mockDomainNameAndVersion();
        assertEq(name, "SegMint Safe");
        assertEq(version, "1.0");
    }

}