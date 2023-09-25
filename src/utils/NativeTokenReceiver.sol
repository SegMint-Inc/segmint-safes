// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.19;

/**
 * @title NativeTokenReceiver
 */
abstract contract NativeTokenReceiver {
    /**
     * Emitted when native token is received.
     */
    event NativeTokenReceived(address sender, uint256 amount);

    receive() external payable {
        emit NativeTokenReceived(msg.sender, msg.value);
    }
}
