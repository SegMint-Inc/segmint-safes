// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { ERC721 } from "@openzeppelin/token/ERC721/ERC721.sol";

contract MockERC721 is ERC721 {
    constructor() ERC721("Mock ERC721", "MOCK") { }
}