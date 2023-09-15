// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./BaseTest.sol";

contract SafeTest is BaseTest {
    Safe public userSafe;

    function setUp() public override {
        super.setUp();
        userSafe = createSafe();  /// Creates a safe for `address(this)`.
    }

    /// @dev Ensures that `userSafe` has been correctly initialized.
    function test_Safe_Deployment() public {
        address[] memory owners = getDefaultOwners();
        address[] memory safeOwners = userSafe.getOwners();
        
        assertEq(owners.length, safeOwners.length);
        assertEq(userSafe.nonce(), 0);
        assertEq(userSafe.ownerCount(), safeOwners.length);
        assertEq(userSafe.getQuorum(), safeOwners.length);

        for (uint256 i = 0; i < owners.length; i++) {
            address expectedOwner = owners[i];
            address actualOwner = safeOwners[i];

            assertEq(expectedOwner, actualOwner);
            assertTrue(userSafe.isOwner(expectedOwner));
        }
    }

    /// @dev `initialize()` tests create a dummy safe that is only used
    /// for testing as `setUp()` defines an already initalized safe.

    function test_Initialize() public {
        Safe _safe = new Safe();
        address[] memory owners = getDefaultOwners();

        _safe.initialize({ owners: owners, quorum: owners.length });
        address[] memory safeOwners = _safe.getOwners();

        assertEq(_safe.nonce(), 0);
        assertEq(_safe.ownerCount(), safeOwners.length);
        assertEq(_safe.getQuorum(), safeOwners.length);

        for (uint256 i = 0; i < owners.length; i++) {
            address expectedOwner = owners[i];
            address actualOwner = safeOwners[i];

            assertEq(expectedOwner, actualOwner);
            assertTrue(_safe.isOwner(expectedOwner));
        }
    }

    function testCannot_Initialize_NoOwnersProvided() public {
        Safe _safe = new Safe();
        address[] memory owners = new address[](0);

        vm.expectRevert(IOwnerManager.NoOwnersProvided.selector);
        _safe.initialize({ owners: owners, quorum: 0 });
    }

    function testCannot_Initialize_InvalidQuorum_ZeroValue() public {
        Safe _safe = new Safe();
        address[] memory owners = getDefaultOwners();
        
        vm.expectRevert(IOwnerManager.InvalidQuorum.selector);
        _safe.initialize({ owners: owners, quorum: 0 });
    }

    function testCannot_Initialize_InvalidQuorum_OverOwners() public {
        Safe _safe = new Safe();
        address[] memory owners = getDefaultOwners();

        vm.expectRevert(IOwnerManager.InvalidQuorum.selector);
        _safe.initialize({ owners: owners, quorum: owners.length + 1 });  /// Test max case.
    }

    function testCannot_Initialize_InvalidOwner_ZeroAddress() public {
        Safe _safe = new Safe();
        address[] memory owners = getDefaultOwners();
        owners[0] = address(0);  // Zero address case. [0, bob, charlie]
        
        vm.expectRevert(IOwnerManager.InvalidOwner.selector);
        _safe.initialize({ owners: owners, quorum: owners.length });
    }
    
    function testCannot_Initialize_InvalidOwner_SentinelValue() public {
        Safe _safe = new Safe();
        address[] memory owners = getDefaultOwners();
        owners[0] = address(0x01);  // Sentinel address case. [sentinel, bob, charlie]
        
        vm.expectRevert(IOwnerManager.InvalidOwner.selector);
        _safe.initialize({ owners: owners, quorum: owners.length });
    }

    function testCannot_Initialize_InvalidOwner_Self() public {
        Safe _safe = new Safe();
        address[] memory owners = getDefaultOwners();
        owners[0] = address(_safe);  // Safe address case. [safe, bob, charlie]
        
        vm.expectRevert(IOwnerManager.InvalidOwner.selector);
        _safe.initialize({ owners: owners, quorum: owners.length });
    }

    function testCannot_Initialize_InvalidOwner_SequentialDuplicate() public {
        Safe _safe = new Safe();
        address[] memory owners = getDefaultOwners();
        owners[1] = owners[0];  // Sequential duplicate case. [alice, alice, charlie]
        
        vm.expectRevert(IOwnerManager.InvalidOwner.selector);
        _safe.initialize({ owners: owners, quorum: owners.length });
    }

    function testCannot_Initialize_DuplicateOwner() public {
        Safe _safe = new Safe();
        address[] memory owners = getDefaultOwners();
        owners[2] = owners[0];  // Non-sequential duplicate case. [alice, bob, alice]
        
        vm.expectRevert(IOwnerManager.DuplicateOwner.selector);
        _safe.initialize({ owners: owners, quorum: owners.length });
    }

    /* `OwnerManager` Tests */

    /* `NativeTokenReceiver` Tests */

    function test_Receive_Fuzzed(uint256 msgValue) public {
        msgValue = bound(msgValue, 0 wei, address(this).balance);

        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit NativeTokenReceived({ sender: address(this), amount: msgValue });
        (bool success,) = address(userSafe).call{ value: msgValue }("");
        assertTrue(success);

        assertEq(address(userSafe).balance, msgValue);
    }

    /* `StandardTokenReceiver` Tests */

    function test_OnERC721Received() public {
        uint256 tokenId = 1;
        mockERC721.mint(tokenId);
        assertEq(mockERC721.ownerOf(tokenId), address(this));

        mockERC721.safeTransferFrom(address(this), address(userSafe), tokenId);
        assertEq(mockERC721.ownerOf(tokenId), address(userSafe));
    }

    function test_OnERC1155Received() public {
        uint256 tokenId = 1;
        uint256 amount = 5;
        mockERC1155.mint(tokenId, amount);
        assertEq(mockERC1155.balanceOf(address(this), tokenId), amount);

        mockERC1155.safeTransferFrom(address(this), address(userSafe), tokenId, amount, "");
        assertEq(mockERC1155.balanceOf(address(userSafe), tokenId), amount);
    }

    function test_OnERC1155BatchReceived() public {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 5;
        amounts[1] = 10;

        mockERC1155.mintBatch(tokenIds, amounts);
        assertEq(mockERC1155.balanceOf(address(this), tokenIds[0]), amounts[0]);
        assertEq(mockERC1155.balanceOf(address(this), tokenIds[1]), amounts[1]);

        mockERC1155.safeBatchTransferFrom(address(this), address(userSafe), tokenIds, amounts, "");
        assertEq(mockERC1155.balanceOf(address(userSafe), tokenIds[0]), amounts[0]);
        assertEq(mockERC1155.balanceOf(address(userSafe), tokenIds[1]), amounts[1]);
    }

}
