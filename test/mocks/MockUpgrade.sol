// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../../src/factories/SafeFactory.sol";

contract MockUpgrade is SafeFactory {
    function nameAndVersion() external pure override returns (string memory name, string memory version) {
        name = "Upgraded Safe Factory";
        version = "2.0";
    }
}
