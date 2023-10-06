// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.19;

/**
 * @title NativeTokenReceiver
 * @notice Enables the inheriting contract to receive the chain native token.
 */
abstract contract NativeTokenReceiver {
    /**
     * Emitted when native token is received.
     * @param sender Sender of the native token.
     * @param amount Amount of native token received.
     */
    event NativeTokenReceived(address sender, uint256 amount);

    receive() external payable {
        emit NativeTokenReceived(msg.sender, msg.value);
    }
}
