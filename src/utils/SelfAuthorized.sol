// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.19;

/**
 * @title SelfAuthorized
 * @notice From Gnosis Safe's `SelfAuthorized`.
 * https://github.com/safe-global/safe-contracts/blob/main/contracts/common/SelfAuthorized.sol
 */
abstract contract SelfAuthorized {
    /**
     * Thrown when the caller is not the address itself.
     */
    error CallerNotSelf();

    function _sanityCheck() private view {
        /// Checks: Ensure the caller is the address itself.
        if (msg.sender != address(this)) revert CallerNotSelf();
    }

    modifier selfAuthorized() {
        _sanityCheck();
        _;
    }
}
