// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { SelfAuthorized } from "../utils/SelfAuthorized.sol";

/**
 * @title MultiCall
 * @notice Used to batch multiple nonpayable calls in a single transaction.
 */
abstract contract MultiCall is SelfAuthorized {
    /**
     * Thrown when the `targets` and `payloads` array are not equal in length.
     */
    error ArrayLengthMismatch();

    /**
     * Thrown when a call fails.
     */
    error CallFailed();

    /**
     * Emitted when a call is successfully made to a target.
     */
    event CallSuccess(address indexed target, bytes payload);

    /**
     * Function used to execute an array of payloads to an array of targets.
     * @param targets Array of addresses to call.
     * @param payloads Array of calldata to forward to each target address.
     */
    function multicall(address[] calldata targets, bytes[] calldata payloads) public selfAuthorized {
        if (targets.length != payloads.length) revert ArrayLengthMismatch();

        for (uint256 i = 0; i < targets.length; i++) {
            address target = targets[i];
            bytes calldata payload = payloads[i];

            (bool success,) = target.call(payload);
            if (!success) revert CallFailed();

            emit CallSuccess(target, payload);
        }
    }
}
