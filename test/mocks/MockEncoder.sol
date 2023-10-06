// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { TransactionEncoder } from "../../src/utils/TransactionEncoder.sol";
import { Transaction } from "../../src/types/DataTypes.sol";

contract MockEncoder is TransactionEncoder {
    function mockDomainNameAndVersion() public pure returns (string memory name, string memory version) {
        return _domainNameAndVersion();
    }
}
