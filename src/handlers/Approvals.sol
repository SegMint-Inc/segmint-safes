// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { IApprovals } from "../interfaces/IApprovals.sol";

/**
 * @title Approvals
 * @notice Handles transaction approvals.
 */
abstract contract Approvals is IApprovals {
    /// Mapping that keeps track of which accounts have approved which transactions.
    mapping(address account => mapping(bytes32 txnHash => bool approved)) internal _approvedTxns;

    /**
     * @inheritdoc IApprovals
     */
    function hasApprovedTxn(address account, bytes32 txnHash) external view returns (bool) {
        return _approvedTxns[account][txnHash];
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       INTERNAL LOGIC                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Function used to approve a transaction hash.
     */
    function _approveTxnHash(bytes32 txnHash) internal {
        _approvedTxns[msg.sender][txnHash] = true;
        emit TxnApproved({ account: msg.sender, txnHash: txnHash });
    }
}
