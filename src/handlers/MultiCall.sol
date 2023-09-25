// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { SelfAuthorized } from "../utils/SelfAuthorized.sol";

/**
 * @title MultiCall
 * @notice Used to batch nonpayable calls.
 */
abstract contract MultiCall is SelfAuthorized {
    /**
     * Thrown when the `targets` and `payloads` array are not equal in length.
     */
    error ArrayLengthMismatch();

    /**
     * Thrown when a call to an external address fails.
     */
    error CallFailed();

    /**
     * Function used to execute an array of payloads to an array of targets.
     * @param targets Array of addresses to call.
     * @param payloads Array of calldata to forward to each address.
     */
    function multicall(address[] calldata targets, bytes[] calldata payloads) public selfAuthorized {
        if (targets.length != payloads.length) revert ArrayLengthMismatch();

        for (uint256 i = 0; i < targets.length; i++) {
            (bool success,) = targets[i].call(payloads[i]);
            if (!success) revert CallFailed();
        }
    }
}
