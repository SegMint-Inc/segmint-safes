// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

/**
 * @title IOwnerManager
 * @notice Interface for {OwnerManager}.
 */
interface IOwnerManager {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           ERRORS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Thrown when trying to add a owner that is deemed as invalid.
     */
    error InvalidOwner();

    /**
     * Thrown when attempting to add a owner that already exists.
     */
    error DuplicateOwner();

    /**
     * Thrown when the newly proposed quorum value exceeds the number of owners.
     */
    error RemovalBreaksQuorum();

    /**
     * Thrown when the pointer owner does point to the expected owner.
     */
    error InvalidPointer();

    /**
     * Thrown when the pointer owner does not match the expected owner.
     */
    error PointerMismatch();

    /**
     * Thrown when an invalid quorum value is provided.
     */
    error InvalidQuorumValue();

    /**
     * Thrown when no owners have been provided during initialization.
     */
    error NoOwnersProvided();

    /**
     * Thrown when an invalid quorum value is proposed.
     */
    error InvalidQuorum();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Emitted when a new owner is added.
     * @param account Address of the newly added owner.
     */
    event OwnerAdded(address account);

    /**
     * Emitted when an owner is removed.
     * @param account Address of the removed owner.
     */
    event OwnerRemoved(address account);

    /**
     * Emitted when an owner is swapped.
     * @param oldOwner Address of the owner being swapped out.
     * @param newOwner Address of the owner being swapped in.
     */
    event OwnerSwapped(address oldOwner, address newOwner);

    /**
     * Emitted when the quorum value is modified.
     * @param oldQuorum Old quorum value.
     * @param newQuorum New quorum value.
     */
    event QuorumChanged(uint256 oldQuorum, uint256 newQuorum);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         FUNCTIONS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Function used to add a owner and update the quorum value.
     * @param newOwner Address of the new owner to be added.
     * @param quorumValue Number of owner approvals to reach quorum on a proposal.
     */
    function addOwner(address newOwner, uint256 quorumValue) external;

    /**
     * Function used to remove a owner and update the quorum value.
     * @param pointerOwner Signer address that points to `owner` in the linked list.
     * @param owner Address of the owner to be removed.
     * @param quorumValue Number of owner approvals to reach quorum on a proposal.
     */
    function removeOwner(address pointerOwner, address owner, uint256 quorumValue) external;

    /**
     * Function used to swap `oldOwner` with `newOwner` and update the quorum value.
     * @param pointerOwner Signer address that points to `owner` in the linked list.
     * @param oldOwner Address of the old owner to be removed.
     * @param newOwner Address of the new owner to be added.
     */
    function swapOwner(address pointerOwner, address oldOwner, address newOwner) external;

    /**
     * Function used to update the quorum value.
     * @param quorumValue New number of approvals required to reach quorum on a proposal.
     */
    function changeQuorum(uint256 quorumValue) external;

    /**
     * Function used to view all the approved owners of a Safe.
     */
    function getOwners() external view returns (address[] memory);

    /**
     * Function used to view if `account` is an approved owner.
     */
    function isOwner(address account) external view returns (bool);

    /**
     * Function used to view the current number of owners.
     */
    function ownerCount() external view returns (uint256);

    /**
     * Function used to view the current quorum value.
     */
    function getQuorum() external view returns (uint256);
}
