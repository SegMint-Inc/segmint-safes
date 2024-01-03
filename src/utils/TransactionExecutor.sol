// SPDX-License-Identifier: SegMint Code License 1.1
pragma solidity 0.8.19;

import { Operation, Transaction } from "../types/DataTypes.sol";

/**
 * @title TransactionExecutor
 * @notice Used to execute transactions.
 */
abstract contract TransactionExecutor {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       INTERNAL LOGIC                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Function used to execute a Safe transaction.
     */
    function _executeTransaction(Transaction memory transaction) internal returns (bool success) {
        if (transaction.operation == Operation.CALL) {
            (success,) = transaction.to.call{ value: transaction.value }(transaction.data);
        } else {
            (success,) = transaction.to.delegatecall(transaction.data);
        }
    }
}
