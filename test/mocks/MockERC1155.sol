// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { ERC1155 } from "@openzeppelin/token/ERC1155/ERC1155.sol";

contract MockERC1155 is ERC1155 {
    constructor() ERC1155("") { }
}