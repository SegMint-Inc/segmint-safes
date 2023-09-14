// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Initializable } from "@openzeppelin/proxy/utils/Initializable.sol";
import { ISafe } from "./interfaces/ISafe.sol";

import { OwnerManager } from "./managers/OwnerManager.sol";

import { SelfAuthorized } from "./utils/SelfAuthorized.sol";
import { NativeTokenReceiver } from "./utils/NativeTokenReceiver.sol";
import { StandardTokenReceiver } from "./utils/StandardTokenReceiver.sol";

contract Safe is ISafe, SelfAuthorized, OwnerManager, Initializable, NativeTokenReceiver, StandardTokenReceiver {
    /// Mapping to keep track of all message hashes that have been approved by ALL REQUIRED owners
    mapping(bytes32 => uint256) public signedMessages;

    // Mapping to keep track of all hashes (message or transaction) that have been approved by ANY owners
    mapping(address signer => mapping(bytes32 dataHash => bool approved)) public approvedHashes;
    
    /// Current Safe nonce.
    uint256 public nonce;

    function initialize(address[] calldata owners, uint256 quorum) external initializer {
        _initOwners(owners, quorum);
    }

}
