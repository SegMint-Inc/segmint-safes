// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Initializable } from "@openzeppelin/proxy/utils/Initializable.sol";
import { ECDSA } from "solady/src/utils/ECDSA.sol";
import { ISafe } from "./interfaces/ISafe.sol";

import { OwnerManager } from "./managers/OwnerManager.sol";
import { Approvals } from "./handlers/Approvals.sol";
import { MultiCall } from "./handlers/MultiCall.sol";

import { SelfAuthorized } from "./utils/SelfAuthorized.sol";
import { NativeTokenReceiver } from "./utils/NativeTokenReceiver.sol";
import { StandardTokenReceiver } from "./utils/StandardTokenReceiver.sol";
import { TransactionExecutor } from "./utils/TransactionExecutor.sol";
import { TransactionEncoder } from "./utils/TransactionEncoder.sol";

import { Transaction } from "./types/DataTypes.sol";

/**
 * @title Safe
 * @notice Implements the logic associated with a SegMint Safe.
 */
contract Safe is
    ISafe,
    SelfAuthorized,
    Initializable,
    OwnerManager,
    Approvals,
    MultiCall,
    NativeTokenReceiver,
    StandardTokenReceiver,
    TransactionExecutor,
    TransactionEncoder
{
    using ECDSA for bytes32;

    /// Transaction nonce.
    uint256 public nonce;

    constructor() {
        /// Prevent implementation contract from being initialized.
        _disableInitializers();
    }

    modifier onlyOwners() {
        _onlyOwners();
        _;
    }

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
    function executeTransaction(Transaction calldata transaction, bytes[] calldata signatures) external onlyOwners {
        /// Checks: Ensure a valid number of signatures have been provided.
        if (signatures.length < _quorum) revert QuorumNotReached();

        /// Checks: Ensure a valid nonce has been provided and update the current nonce.
        if (transaction.nonce != nonce++) revert NonceMismatch();

        /// Checks: Ensure the transaction is still valid.
        if (block.timestamp > transaction.deadline) revert TransactionDeadlinePassed();

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
    function approveTxnHash(bytes32 txnHash) external onlyOwners {
        _approveTxnHash(txnHash);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       INTERNAL LOGIC                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Function used to validate the provided signatures and check that each of the recovered
     * signers has approved the given transaction hash. By successful execution of this
     * function, it should be guaranteed that the quorum value has been met and that all of
     * the recovered signers are unique.
     */
    function _validateSignatures(bytes32 txnHash, bytes[] calldata signatures) internal view {
        address lastSigner;
        for (uint256 i = 0; i < signatures.length; i++) {
            /// Cache the signature.
            bytes calldata signature = signatures[i];

            /// Recover the signer.
            /// @dev It should be noted that Solady's {ECDSA.recover} does not allow for failed recovery resulting
            /// in the zero address. Short form signatures (EIP-2098) signatures are also not deemed as valid.
            address recoveredSigner = txnHash.recover(signature);

            /// Checks: Ensure the recovered signer is an owner.
            if (!_isOwner(recoveredSigner)) revert SignerNotOwner();

            /// Checks: Ensure the recovered signer is greater than the last.
            if (recoveredSigner <= lastSigner) revert InvalidSignatureOrder();

            /// Checks: Ensure the signer has approved the txn.
            if (!_approvedTxns[recoveredSigner][txnHash]) revert SignerHasNotApproved();

            /// Update the `lastSigner` and continue iterating.
            lastSigner = recoveredSigner;
        }
    }

    /**
     * Function used to ensure that the caller is a known owner.
     */
    function _onlyOwners() internal view {
        /// Checks: Ensure `msg.sender` is a known owner.
        if (!_isOwner(msg.sender)) revert CallerNotOwner();
    }
}
