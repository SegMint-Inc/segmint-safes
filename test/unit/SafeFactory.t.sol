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

    function test_Initialize_Fuzzed(address randomAdmin, address randomSafe) public {
        /// Create dummy instance of {SafeFactory} to test initialize.
        SafeFactory factory = new SafeFactory();
        factory.initialize({ _admin: randomAdmin, _safe: randomSafe });

        assertEq(factory.owner(), address(this));
        assertEq(factory.safe(), randomSafe);

        uint256 adminRole = factory.ADMIN_ROLE();
        assertTrue(factory.hasAllRoles(randomAdmin, adminRole));
    }

    function testCannot_Initialize_AlreadyInitialized() public {
        vm.expectRevert("Initializable: contract is already initialized");
        safeFactory.initialize({ _admin: address(0), _safe: address(0) });
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
        emit UpgradeProposed({ admin: users.admin.account, implementation: address(mockUpgrade), deadline: expectedDeadline });
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