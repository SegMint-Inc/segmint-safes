// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { TransactionEncoder } from "../../src/utils/TransactionEncoder.sol";
import { Transaction } from "../../src/types/DataTypes.sol";

contract MockEncoder is TransactionEncoder {

    function mockEncodeTransaction(Transaction memory transaction) public returns (bytes32) {
        return _encodeTransaction(transaction);
    }

    function mockDomainNameAndVersion() public returns (string memory name, string memory version) {
        return _domainNameAndVersion();
    }

}