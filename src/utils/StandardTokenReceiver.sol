// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.19;

/**
 * @title StandardTokenReceiver
 * @notice Allows the receival of ERC721 and ERC1155 tokens.
 */
abstract contract StandardTokenReceiver {

    /**
     * Handles {ERC721.safeTransferFrom} callback.
     */
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * Handles {ERC155.safeTransferFrom} callback.
     */
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * Handles {ERC155.safeBatchTransferFrom} callback.
     */
    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }

}