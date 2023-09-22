// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IOwnerManager {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           ERRORS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Thrown when trying to add a signer that is deemed as invalid.
     */
    error InvalidOwner();

    /**
     * Thrown when attempting to add a signer that already exists.
     */
    error DuplicateOwner();

    /**
     * Thrown when the newly proposed quorum value exceeds the number of signers.
     */
    error RemovalBreaksQuorum();

    /**
     * Thrown when the pointer signer does point to the expected signer.
     */
    error InvalidPointer();

    /**
     * Thrown when the pointer signer does not match the expected signer.
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
     * Function used to add a signer and update the quorum value.
     * @param newSigner Address of the new signer to be added.
     * @param quorumValue Number of signer approvals to reach quorum on a proposal.
     */
    function addOwner(address newSigner, uint256 quorumValue) external;

    /**
     * Function used to remove a signer and update the quorum value.
     * @param ptrSigner Signer address that points to `signer` in the linked list.
     * @param signer Address of the signer to be removed.
     * @param quorumValue Number of signer approvals to reach quorum on a proposal.
     */
    function removeOwner(address ptrSigner, address signer, uint256 quorumValue) external;

    /**
     * Function used to swap `oldSigner` with `newSigner` and update the quorum value.
     * @param ptrSigner Signer address that points to `signer` in the linked list.
     * @param oldSigner Address of the old signer to be removed.
     * @param newSigner Address of the new signer to be added.
     */
    function swapOwner(address ptrSigner, address oldSigner, address newSigner) external;

    /**
     * Function used to update the quorum value.
     * @param quorumValue New number of approvals required to reach quorum on a proposal.
     */
    function changeQuorum(uint256 quorumValue) external;

    /**
     * Function used to view all the approved signers of a Safe.
     */
    function getOwners() external view returns (address[] memory);

    /**
     * Function used to view if `account` is an approved signer.
     */
    function isOwner(address account) external view returns (bool);

    /**
     * Function used to view the current quorum value.
     */
    function getQuorum() external view returns (uint256);
}
