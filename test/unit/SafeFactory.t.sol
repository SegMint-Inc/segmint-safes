// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../BaseTest.sol";

contract SafeFactoryTest is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_SafeFactory_Deployment() public {
        assertEq(safeFactory.owner(), address(this));
        assertEq(safeFactory.safe(), address(safe));

        uint256 adminRole = safeFactory.ADMIN_ROLE();
        assertTrue(safeFactory.hasAllRoles(users.admin.account, adminRole));

        (string memory name, string memory version) = safeFactory.nameAndVersion();
        assertEq(name, "Safe Factory");
        assertEq(version, "1.0");
    }

    /// Since `Base.sol` initializes the implementation on setup, we do a clean deploy within this test.
    function test_Initialize_Fuzzed(address randomAdmin, address randomImplementation) public {
        vm.assume(randomAdmin != address(0) && randomImplementation != address(0));
        SafeFactory testFactory = new SafeFactory();

        bytes4 funcSelector = SafeFactory.initialize.selector;
        bytes memory payload = abi.encodeWithSelector(funcSelector, randomAdmin, randomImplementation);
        SafeFactory factory = SafeFactory(address(new ERC1967Proxy({ _logic: address(testFactory), _data: payload })));

        assertTrue(factory.hasAllRoles(randomAdmin, factory.ADMIN_ROLE()));
        assertEq(factory.owner(), address(this));
        assertEq(factory.safe(), randomImplementation);
    }

    function testCannot_Initialize_SafeFactory_Implementation() public {
        /// @dev Since we cast the original implementation in `Base.sol` to the proxy, we need to
        /// load the EIP-1967 slot to get the true implementation address.
        bytes32 implementationSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        bytes32 safeFactoryImplementation = vm.load(address(safeFactory), implementationSlot);
        address implementation = address(uint160(uint256(safeFactoryImplementation)));

        vm.expectRevert("Initializable: contract is already initialized");
        SafeFactory(implementation).initialize({ _admin: users.admin.account, _safe: address(safe) });
    }

    function testCannot_Initialize_ContractIsAlreadyInitialized() public {
        vm.expectRevert("Initializable: contract is already initialized");
        safeFactory.initialize({ _admin: address(1), _safe: address(1) });
    }

    function test_CreateSafe() public {
        address[] memory owners = getDefaultOwners();

        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit SafeCreated({ user: address(this), safe: address(0) });
        safeFactory.createSafe({ owners: owners, quorum: owners.length });
        assertEq(safeFactory.getNonce(address(this)), 1);

        address[] memory safes = safeFactory.getSafes(address(this));
        assertEq(safes.length, 1);

        Safe newSafe = Safe(payable(safes[0]));
        assertEq(newSafe.ownerCount(), owners.length);
        assertEq(newSafe.getQuorum(), owners.length);
        assertEq(newSafe.nonce(), 0);

        for (uint256 i = 0; i < owners.length; i++) {
            assertTrue(newSafe.isOwner(owners[i]));
        }
    }

    /* `UpgradeHandler` Tests */

    function test_ProposeUpgrade() public {
        uint40 expectedDeadline = uint40(block.timestamp + safeFactory.UPGRADE_TIMELOCK());

        hoax(users.admin.account);
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit UpgradeProposed({
            admin: users.admin.account,
            implementation: address(mockUpgrade),
            deadline: expectedDeadline
        });
        safeFactory.proposeUpgrade({ newImplementation: address(mockUpgrade) });

        (address newImplementation, uint40 deadline) = safeFactory.upgradeProposal();
        assertEq(newImplementation, address(mockUpgrade));
        assertEq(deadline, expectedDeadline);
    }

    function testCannot_ProposeUpgrade_Unauthorized_Fuzzed(address nonAdmin) public {
        vm.assume(nonAdmin != users.admin.account);

        hoax(nonAdmin);
        vm.expectRevert(Unauthorized.selector);
        safeFactory.proposeUpgrade(address(0));
    }

    function testCannot_ProposeUpgrade_ProposalInProgress() public {
        startHoax(users.admin.account);
        safeFactory.proposeUpgrade({ newImplementation: address(mockUpgrade) });
        vm.expectRevert(IUpgradeHandler.ProposalInProgress.selector);
        safeFactory.proposeUpgrade({ newImplementation: address(mockUpgrade) });
    }

    function test_CancelUpgrade() public {
        startHoax(users.admin.account);
        safeFactory.proposeUpgrade({ newImplementation: address(mockUpgrade) });

        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit UpgradeCancelled({ admin: users.admin.account, implementation: address(mockUpgrade) });
        safeFactory.cancelUpgrade();

        (address newImplementation, uint40 deadline) = safeFactory.upgradeProposal();
        assertEq(newImplementation, address(0));
        assertEq(deadline, 0);
    }

    function testCannot_CancelUpgrade_Unauthorized_Fuzzed(address nonAdmin) public {
        vm.assume(nonAdmin != users.admin.account);

        hoax(nonAdmin);
        vm.expectRevert(Unauthorized.selector);
        safeFactory.cancelUpgrade();
    }

    function testCannot_CancelUpgrade_NoProposalExists() public {
        hoax(users.admin.account);
        vm.expectRevert(IUpgradeHandler.NoProposalExists.selector);
        safeFactory.cancelUpgrade();
    }

    function test_ExecuteUpgrade() public {
        startHoax(users.admin.account);
        safeFactory.proposeUpgrade({ newImplementation: address(mockUpgrade) });

        uint256 deadline = block.timestamp + safeFactory.UPGRADE_TIMELOCK();
        vm.warp(deadline);

        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit Upgraded({ implementation: address(mockUpgrade) });
        safeFactory.executeUpgrade("");

        (address newImplementation, uint40 proposalDeadline) = safeFactory.upgradeProposal();
        assertEq(newImplementation, address(0));
        assertEq(proposalDeadline, 0);

        (string memory name, string memory version) = safeFactory.nameAndVersion();
        assertEq(name, "Upgraded Safe Factory");
        assertEq(version, "2.0");
    }

    function testCannot_ExecuteUpgrade_Unauthorized_Fuzzed(address nonAdmin) public {
        vm.assume(nonAdmin != users.admin.account);

        hoax(users.admin.account);
        safeFactory.proposeUpgrade({ newImplementation: address(mockUpgrade) });

        uint256 deadline = block.timestamp + safeFactory.UPGRADE_TIMELOCK();
        vm.warp(deadline);

        hoax(nonAdmin);
        vm.expectRevert(Unauthorized.selector);
        safeFactory.executeUpgrade("");
    }

    function testCannot_ExecuteUpgrade_NoProposalExists() public {
        hoax(users.admin.account);
        vm.expectRevert(IUpgradeHandler.NoProposalExists.selector);
        safeFactory.executeUpgrade("");
    }

    function testCannot_ExecuteUpgrade_UpgradeTimeLocked_Fuzzed(uint256 badTime) public {
        uint256 maxBadTime = safeFactory.UPGRADE_TIMELOCK() - 1 seconds;
        badTime = bound(badTime, block.timestamp, maxBadTime);

        startHoax(users.admin.account);
        safeFactory.proposeUpgrade({ newImplementation: address(mockUpgrade) });

        vm.warp(badTime);

        vm.expectRevert(IUpgradeHandler.UpgradeTimeLocked.selector);
        safeFactory.executeUpgrade("");
    }
}
