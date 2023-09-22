// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { ERC721 } from "@openzeppelin/token/ERC721/ERC721.sol";

contract MockERC721 is ERC721 {
    error InvalidEtherAmount();

    uint256 public tokenPrice = 0.1 ether;

    constructor() ERC721("Mock ERC721", "MOCK") { }

    function mint(uint256 tokenId) external {
        _mint(msg.sender, tokenId);
    }

    function mintPaid(uint256 tokenId) external payable {
        if (msg.value != tokenPrice) revert InvalidEtherAmount();
        _mint(msg.sender, tokenId);
    }
}