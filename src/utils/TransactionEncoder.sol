// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { EIP712 } from "solady/src/utils/EIP712.sol";
import { ITransactionEncoder } from "../interfaces/ITransactionEncoder.sol";
import { Transaction } from "../types/DataTypes.sol";

/**
 * @title TransactionEncoder
 * @notice Encodes a `Transaction` struct in accordance with EIP712.
 */
abstract contract TransactionEncoder is ITransactionEncoder, EIP712 {
    /// @dev keccak256("Transaction(uint8 operation,address to,uint256 value,bytes data,uint256 nonce,uint256 deadline)");
    bytes32 private constant _TRANSACTION_TYPEHASH = 0x33b543d6d88a9ae409adf21994caa4f1fb2caa001d13be022d6bf4a3a5afc01d;

    /**
     * @inheritdoc ITransactionEncoder
     */
    function encodeTransaction(Transaction memory transaction) public view returns (bytes32) {
        return _encodeTransaction(transaction);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       INTERNAL LOGIC                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Function used to return the EIP712 digest of a `Transaction` struct.
     */
    function _encodeTransaction(Transaction memory transaction) internal view returns (bytes32) {
        return _hashTypedData(
            keccak256(
                abi.encodePacked(
                    _TRANSACTION_TYPEHASH,
                    transaction.operation,
                    transaction.to,
                    transaction.value,
                    keccak256(transaction.data),
                    transaction.nonce,
                    transaction.deadline
                )
            )
        );
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EIP712                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Overriden as required in Solady EIP712 documentation.
     */
    function _domainNameAndVersion() internal pure override returns (string memory name, string memory version) {
        name = "SegMint Safe";
        version = "1.0";
    }
}
