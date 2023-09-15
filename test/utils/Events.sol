// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

abstract contract Events {
    /// {ISafeFactory} Events.
    event SafeCreated(address indexed user, address indexed safe);

    /// {IUpgradeHandler} Events.
    event UpgradeProposed(address indexed admin, address implementation, uint40 deadline);
    event UpgradeCancelled(address indexed admin, address implementation);

    /// {IERC1967} Events.
    event Upgraded(address indexed implementation);

    /// {NativeTokenReceiver} Events.
    event NativeTokenReceived(address sender, uint256 amount);
}