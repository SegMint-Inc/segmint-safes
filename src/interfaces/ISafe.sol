// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Transaction } from "../types/DataTypes.sol";

/**
 * @title ISafe
 * @notice Interface for {Safe}.
 */
interface ISafe {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           ERRORS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Thrown when the caller is not a known owner.
     */
    error CallerNotOwner();

    /**
     * Thrown when the amount of signatures provided subceeds the quorum value.
     */
    error QuorumNotReached();

    /**
     * Thrown when the recovered signer of a signature does not exceed the previously recovered signer.
     */
    error InvalidSignatureOrder();

    /**
     * Thrown when the recovered signer of a signature is not a known owner.
     */
    error SignerNotOwner();

    /**
     * Thrown when the recovered signer has not approved the txn.
     */
    error SignerHasNotApproved();

    /**
     * Thrown when the transaction nonce doesn't match the transaction nonce.
     */
    error NonceMismatch();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Emitted when a transaction has successfully executed.
     * @param txnHash EIP712 digest of the transaction.
     */
    event TransactionSuccess(bytes32 txnHash);

    /**
     * Emitted when a transaction has failed to execute.
     * @param txnHash EIP712 digest of the transaction.
     */
    event TransactionFailed(bytes32 txnHash);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         FUNCTIONS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Function used to initialize a newly created Safe.
     * @param owners Array of desired owners.
     * @param quorum Number of approvals required to reach quorum.
     */
    function initialize(address[] calldata owners, uint256 quorum) external;

    /**
     * Function used to execute a Safe transaction.
     * @param transaction Struct containing the transaction parameters.
     * @param signatures Signed message digests of the owner approvals.
     */
    function executeTransaction(Transaction calldata transaction, bytes[] calldata signatures) external;

    /**
     * Function used to approve a Safe transaction.
     * @param txnHash EIP712 digest of the transaction.
     */
    function approveTxnHash(bytes32 txnHash) external;
}
