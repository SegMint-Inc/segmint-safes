// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Initializable } from "@openzeppelin/proxy/utils/Initializable.sol";
import { ECDSA } from "solady/src/utils/ECDSA.sol";
import { ISafe } from "./interfaces/ISafe.sol";

import { OwnerManager } from "./managers/OwnerManager.sol";
import { Approvals } from "./handlers/Approvals.sol";

import { SelfAuthorized } from "./utils/SelfAuthorized.sol";
import { NativeTokenReceiver } from "./utils/NativeTokenReceiver.sol";
import { StandardTokenReceiver } from "./utils/StandardTokenReceiver.sol";
import { TransactionExecutor } from "./utils/TransactionExecutor.sol";
import { TransactionEncoder } from "./utils/TransactionEncoder.sol";

import { Transaction } from "./types/DataTypes.sol";

contract Safe is
    ISafe,
    SelfAuthorized,
    Initializable,
    OwnerManager,
    Approvals,
    NativeTokenReceiver,
    StandardTokenReceiver,
    TransactionExecutor,
    TransactionEncoder
{
    using ECDSA for bytes32;

    /// Transaction nonce.
    uint256 public nonce;

    /**
     * @inheritdoc ISafe
     */
    function initialize(address[] calldata owners, uint256 quorum) external initializer {
        _initOwners(owners, quorum);
    }

    /**
     * @inheritdoc ISafe
     * @dev `signatures` must be provided in ascending order from the 'lowest' signer address to the 'highest'.
     */
    function executeTransaction(Transaction memory transaction, bytes32 txnHash, bytes[] memory signatures) external {
        /// Checks: Ensure `msg.sender` is a known owner.
        if (!_isOwner(msg.sender)) revert CallerNotOwner();

        /// Checks: Ensure a valid number of signatures have been provided.
        if (signatures.length < _quroum) revert QuorumNotReached();

        /// Checks: Ensure a valid nonce has been provided.

        /// Get the EIP712 digest of the transaction.
        bytes32 txnHash = _encodeTransaction(transaction);

        /// Validate the provided signatures and approvals.
        _validateSignatures(txnHash, signatures);

        /// Execute the transaction.
        bool success = _executeTransaction(transaction);
        if (success) {
            emit TransactionSuccess(txnHash);
        } else {
            emit TransactionFailed(txnHash);
        }
    }

    /**
     * @inheritdoc ISafe
     */
    function approveTxnHash(bytes32 txnHash) external {
        /// Checks: Ensure the caller is a known owner.
        if (!_isOwner(msg.sender)) revert CallerNotOwner();

        /// Acknowledge the transaction hash as being approved by `msg.sender`.
        _approveTxnHash(txnHash);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       INTERNAL LOGIC                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _validateSignatures(bytes32 txnHash, bytes[] memory signatures) internal {
        /// Push `_quorum` value to the stack.
        uint256 quorum = _quroum;

        address lastSigner = address(0);

        for (uint256 i = 0; i < signatures.length; i++) {
            /// Cache the signature.
            bytes memory signature = signatures[i];

            /// Recover the signer. EIP-2098 signatures should not be accepted.
            address recoveredSigner = txnHash.recover(signature);

            /// Checks: Ensure the recovered signer is an owner.
            if (!_isOwner(recoveredSigner)) revert SignerNotOwner();

            /// Checks: Ensure the recovered signer is greater than the last.
            if (recoveredSigner <= lastSigner) revert InvalidSignatureOrder();

            /// Checks: Ensure the signer has approved the txn.
            if (!_hasApprovedTxn[recoveredSigner][txnHash]) revert SignerHasNotApproved();

            /// Update the `lastSigner` and continue iterating.
            lastSigner = recoveredSigner;
        }
    }

}
