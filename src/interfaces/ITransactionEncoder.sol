// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Transaction } from "../types/DataTypes.sol";

/**
 * @title ITransactionEncoder
 * @notice Interface for {TransactionEncoder}.
 */
interface ITransactionEncoder {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         FUNCTIONS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Function used to encode a `Transaction` struct and return the EIP712 digest.
     * @param transaction `Transaction` struct.
     */
    function encodeTransaction(Transaction memory transaction) external view returns (bytes32);
}
