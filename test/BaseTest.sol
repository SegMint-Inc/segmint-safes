// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./Base.sol";

import { ISafe } from "../src/interfaces/ISafe.sol";
import { ISafeFactory } from "../src/interfaces/ISafeFactory.sol";
import { IOwnerManager } from "../src/interfaces/IOwnerManager.sol";
import { IUpgradeHandler } from "../src/interfaces/IUpgradeHandler.sol";

import { SelfAuthorized } from "../src/utils/SelfAuthorized.sol";
import { Operation, Transaction } from "../src/types/DataTypes.sol";

import { MockERC20 } from "./mocks/MockERC20.sol";
import { MockERC721 } from "./mocks/MockERC721.sol";
import { MockERC1155 } from "./mocks/MockERC1155.sol";
import { MockUpgrade } from "./mocks/MockUpgrade.sol";
import { MockEncoder } from "./mocks/MockEncoder.sol";

import { Events } from "./utils/Events.sol";
import { Errors } from "./utils/Errors.sol";
import { User, Users } from "./utils/Users.sol";

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
        coreSetup({ admin: users.admin.account });

        /// Interface proxy contract with implementation.
        safeFactory = SafeFactory(address(safeFactoryProxy));
    }

    /// Test Helpers

    function createUser(string memory name) internal returns (User memory) {
        (address user, uint256 privateKey) = makeAddrAndKey(name);
        vm.deal({ account: user, newBalance: 100 ether });
        return User({ account: payable(user), privateKey: privateKey });
    }

    /// @dev Creates a {Safe} instance for `address(this)` with 3 owners and 3 quorum.
    function createSafe() internal returns (Safe) {
        address[] memory owners = getDefaultOwners();
        safeFactory.createSafe({ owners: owners, quorum: owners.length });
        
        address[] memory userSafes = safeFactory.getSafes(address(this));
        Safe userSafe = Safe(payable(userSafes[0]));
        
        vm.label({ account: address(userSafe), newLabel: "Safe" });

        return userSafe;
    }

    function signTransactionHash(bytes32 txnHash, uint256 privateKey) internal pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, txnHash);
        return abi.encodePacked(r, s, v);
    }

    /// Returns the ordered signatures of a signed transaction hash.
    function getOrderedSignatures(bytes32 txnHash) internal view returns (bytes[] memory) {
        bytes[] memory signatures = new bytes[](3);
        signatures[0] = signTransactionHash(txnHash, users.bob.privateKey);
        signatures[1] = signTransactionHash(txnHash, users.charlie.privateKey);
        signatures[2] = signTransactionHash(txnHash, users.alice.privateKey);
        return signatures;
    }

    function getUnorderedSignatures(bytes32 txnHash) internal view returns (bytes[] memory) {
        bytes[] memory signatures = new bytes[](3);
        signatures[0] = signTransactionHash(txnHash, users.alice.privateKey);
        signatures[1] = signTransactionHash(txnHash, users.bob.privateKey);
        signatures[2] = signTransactionHash(txnHash, users.charlie.privateKey);
        return signatures;
    }

    function getDefaultOwners() internal view returns (address[] memory owners) {
        owners = new address[](3);
        owners[0] = users.alice.account;
        owners[1] = users.bob.account;
        owners[2] = users.charlie.account;
    }

    /// Token Handlers

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }

}