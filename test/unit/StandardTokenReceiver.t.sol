// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../BaseTest.sol";

contract StandardTokenReceiverTest is BaseTest {
    Safe public userSafe;

    function setUp() public override {
        super.setUp();
        userSafe = createSafe();
    }

    function test_OnERC721Received_Fuzzed(uint256 tokenId) public {
        mockERC721.mint(tokenId);
        assertEq(mockERC721.ownerOf(tokenId), address(this));

        mockERC721.safeTransferFrom(address(this), address(userSafe), tokenId);
        assertEq(mockERC721.ownerOf(tokenId), address(userSafe));
    }

    function test_OnERC1155Received_Fuzzed(uint256 tokenId, uint256 amount) public {
        mockERC1155.mint(tokenId, amount);
        assertEq(mockERC1155.balanceOf(address(this), tokenId), amount);

        mockERC1155.safeTransferFrom(address(this), address(userSafe), tokenId, amount, "");
        assertEq(mockERC1155.balanceOf(address(userSafe), tokenId), amount);
    }

    function test_OnERC1155BatchReceived_Fuzzed(uint256 amount0, uint256 amount1) public {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount0;
        amounts[1] = amount1;

        mockERC1155.mintBatch(tokenIds, amounts);
        assertEq(mockERC1155.balanceOf(address(this), tokenIds[0]), amount0);
        assertEq(mockERC1155.balanceOf(address(this), tokenIds[1]), amount1);

        mockERC1155.safeBatchTransferFrom(address(this), address(userSafe), tokenIds, amounts, "");
        assertEq(mockERC1155.balanceOf(address(userSafe), tokenIds[0]), amount0);
        assertEq(mockERC1155.balanceOf(address(userSafe), tokenIds[1]), amount1);
    }
}
