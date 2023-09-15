// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./Base.sol";

import { ISafe } from "../src/interfaces/ISafe.sol";
import { ISafeFactory } from "../src/interfaces/ISafeFactory.sol";
import { IOwnerManager } from "../src/interfaces/IOwnerManager.sol";
import { IUpgradeHandler } from "../src/interfaces/IUpgradeHandler.sol";

import { MockERC20 } from "./mocks/MockERC20.sol";
import { MockERC721 } from "./mocks/MockERC721.sol";
import { MockERC1155 } from "./mocks/MockERC1155.sol";
import { MockUpgrade } from "./mocks/MockUpgrade.sol";

import { Events } from "./utils/Events.sol";
import { Errors } from "./utils/Errors.sol";
import { Users } from "./utils/Users.sol";

contract BaseTest is Base, Events, Errors {

    Users public users;

    MockERC20 public mockERC20;
    MockERC721 public mockERC721;
    MockERC1155 public mockERC1155;
    MockUpgrade public mockUpgrade;

    function setUp() public virtual {
        mockERC20 = new MockERC20();
        mockERC721 = new MockERC721();
        mockERC1155 = new MockERC1155();
        mockUpgrade = new MockUpgrade();

        users = Users({
            admin: createUser("Admin"),
            alice: createUser("Alice"),
            bob: createUser("Bob"),
            charlie: createUser("Charlie"),
            eve: createUser("Eve")
        });

        /// Deploy core contracts.
        coreSetup({ admin: users.admin });

        /// Interface proxy contract with implementation.
        safeFactory = SafeFactory(address(safeFactoryProxy));
    }

    function createUser(string memory name) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({ account: user, newBalance: 100 ether });
        return user;
    }

    function getDefaultOwners() internal view returns (address[] memory owners) {
        owners = new address[](3);
        owners[0] = users.alice;
        owners[1] = users.bob;
        owners[2] = users.charlie;
    }

}