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

    /// {IApprovals} Events.
    event TxnApproved(address indexed account, bytes32 txnHash);

    /// {ISafe} Events.
    event TransactionFailed(bytes32 txnHash);
    event TransactionSuccess(bytes32 txnHash);

    /// {IOwnerManager} Events.
    event OwnerAdded(address account);
    event OwnerRemoved(address account);
    event OwnerSwapped(address oldOwner, address newOwner);
    event QuorumChanged(uint256 oldQuorum, uint256 newQuorum);

    /// {MultiCall} Events.
    event CallSuccess(address indexed target, bytes payload);
}
