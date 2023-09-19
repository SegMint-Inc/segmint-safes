// SPDX-License-Identifier: UNLICENSED
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
     * @dev `transaction.value` will be ignored in the case of a `delegatecall` operation.
     */
    function _executeTransaction(Transaction memory transaction) internal returns (bool success) {
        if (transaction.operation == Operation.CALL) {
            (success,) = transaction.to.call{ value: transaction.value }(transaction.data);
        } else {
            (success,) = transaction.to.delegatecall(transaction.data);
        }
    }

}