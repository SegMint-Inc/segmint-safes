// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IApprovals {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Emitted when a transaction is approved.
     * @param account Address which made the approval.
     * @param txnHash EIP712 digest of the transaction.
     */
    event TxnApproved(address indexed account, bytes32 txnHash);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         FUNCTIONS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Function used to check if account has approved a transaction hash.
     * @param account Address to check transaction approval of.
     * @param txnHash EIP712 digest of the transaction.
     */
    function hasApprovedTxn(address account, bytes32 txnHash) external view returns (bool);
}
