// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./Base.sol";

import { ISafe } from "../src/interfaces/ISafe.sol";
import { ISafeFactory } from "../src/interfaces/ISafeFactory.sol";
import { IOwnerManager } from "../src/interfaces/IOwnerManager.sol";

import { MockERC20 } from "./mocks/MockERC20.sol";
import { MockERC721 } from "./mocks/MockERC721.sol";
import { MockERC1155 } from "./mocks/MockERC1155.sol";

import { Users } from "./utils/Users.sol";

contract BaseTest is Base {

    Users public users;

    MockERC20 public mockERC20;
    MockERC721 public mockERC721;
    MockERC1155 public mockERC1155;

    function setUp() public virtual {
        mockERC20 = new MockERC20();
        mockERC721 = new MockERC721();
        mockERC1155 = new MockERC1155();

        users = Users({
            admin: createUser("Admin"),
            alice: createUser("Alice"),
            bob: createUser("Bob"),
            charlie: createUser("Charlie"),
            eve: createUser("Eve")
        });
    }

    function createUser(string memory name) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({ account: user, newBalance: 100 ether });
        return user;
    }

}