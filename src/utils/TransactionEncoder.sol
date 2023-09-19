// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { EIP712 } from "solady/src/utils/EIP712.sol";
import { ITransactionEncoder } from "../interfaces/ITransactionEncoder.sol";
import { Transaction } from "../types/DataTypes.sol";

/**
 * @title TransactionEncoder
 * @notice Used to encode a `Transaction` struct in accordance with EIP712.
 */
abstract contract TransactionEncoder is ITransactionEncoder, EIP712 {

    /// @dev keccak256("Transaction(uint8 operation,address to,uint256 value,bytes data,uint256 nonce)");
    bytes32 private constant _TRANSACTION_TYPEHASH = 0x50b485665d49aaf8f3dd2ff8d505569748e3466ae4f543247e673b667008bd66;

    /**
     * @inheritdoc ITransactionEncoder
     */
    function encodeTransaction(Transaction memory transaction) public view returns (bytes32) {
        _encodeTransaction(transaction);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       INTERNAL LOGIC                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _encodeTransaction(Transaction memory transaction) internal view returns (bytes32) {
        return _hashTypedData(keccak256(abi.encodePacked(
            _TRANSACTION_TYPEHASH,
            transaction.operation,
            transaction.to,
            transaction.value,
            keccak256(transaction.data),
            transaction.nonce
        )));
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