// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

struct User {
    address payable account;
    uint256 privateKey;
}

struct Users {
    /// Default administrator.
    User admin;
    /// Signator #1
    User alice;
    /// Signator #2
    User bob;
    /// Signator #3
    User charlie;
    /// Malicious user.
    User eve;
}
