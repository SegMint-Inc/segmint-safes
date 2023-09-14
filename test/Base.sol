// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "forge-std/Test.sol";

import { ERC1967Proxy } from "@openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";

import { SafeFactory } from "../src/factories/SafeFactory.sol";
import { Safe } from "../src/Safe.sol";

abstract contract Base is Script, Test {
    enum Deployment {
        DEFAULT,
        FORK
    }

    /// Core contracts.
    ERC1967Proxy public safeFactoryProxy;
    SafeFactory public safeFactory;
    Safe public safe;

    function coreSetup(address admin) public {
        /// Deploy implementation contracts.
        safe = new Safe();
        safeFactory = new SafeFactory();

        /// Deploy proxy and initialize.
        bytes memory initPayload = abi.encodeWithSelector(SafeFactory.initialize.selector, admin, address(safe));
        safeFactoryProxy = new ERC1967Proxy({ _logic: address(safeFactory), _data: initPayload });
    }
}
