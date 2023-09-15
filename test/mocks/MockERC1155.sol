// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { ERC1155 } from "@openzeppelin/token/ERC1155/ERC1155.sol";

contract MockERC1155 is ERC1155 {
    constructor() ERC1155("") { }

    function mint(uint256 tokenId, uint256 amount) external {
        _mint(msg.sender, tokenId, amount, "");
    }

    function mintBatch(uint256[] calldata tokenIds, uint256[] calldata amounts) external {
        _mintBatch(msg.sender, tokenIds, amounts, "");
    }
}