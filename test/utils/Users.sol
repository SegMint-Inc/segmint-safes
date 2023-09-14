// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

struct Users {
    /// Default administrator.
    address payable admin;
    /// Signator #1
    address payable alice;
    /// Signator #2
    address payable bob;
    /// Signator #3
    address payable charlie;
    /// Malicious user.
    address payable eve;
}