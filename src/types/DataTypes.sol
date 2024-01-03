// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.19;

/**
 * Enum encapsulating the types of calls that can be made with a safe.
 */
enum Operation {
    CALL,
    DELEGATECALL
}

/**
 * Struct encapsulating the types associated with a transaction call.
 * @param operation {Operation} Enum value.
 * @param to Address that the call will be made too.
 * @param value Amount of native token to provide with the call.
 * @param data Calldata to associate with the call.
 * @param nonce Safe nonce to associate with the call.
 * @param deadline Timestamp by which the transaction is valid until.
 */
struct Transaction {
    Operation operation;
    address to;
    uint256 value;
    bytes data;
    uint256 nonce;
    uint256 deadline;
}
