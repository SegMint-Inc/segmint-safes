// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

/**
 * @title ISafeFactory
 * @notice N/A
 */

interface ISafeFactory {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           ERRORS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Thrown when the predicted deployment address does not match the actual deployment address.
     */
    error AddressMismatch();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Emitted when a new safe is created.
     * @param user Address of the account that created the safe.
     * @param safe Address of the newly created safe.
     */
    event SafeCreated(address indexed user, address indexed safe);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         FUNCTIONS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Function used to initialize {VaultFactory}.
     * @param admin_ Address to asign the admin role.
     * @param safeImplementation_ Address of the Safe implementation.
     */
    function initialize(address admin_, address safeImplementation_) external;

    /**
     * Function used to create a safe.
     * @param owners List of signer addresses to initialize the safe with.
     * @param quorum Initial quorum value that all proposals must reach.
     */
    function createSafe(address[] calldata owners, uint256 quorum) external;

    /**
     * Function used to get all the safes created by a given account.
     * @param account Address of the account to check.
     */
    function getSafes(address account) external view returns (address[] memory);

    /**
     * Function used to propose an upgrade to the implementation address of {VaultFactory}.
     * @param newImplementation Newly proposed {VaultFactory} address.
     */
    function proposeUpgrade(address newImplementation) external;

    /**
     * Function used to cancel a pending upgrade proposal.
     */
    function cancelUpgrade() external;

    /**
     * Function used to execute an upgrade to the implementation address of {VaultFactory}.
     * @param payload Encoded calldata that will be used to initialize the new implementation.
     */
    function executeUpgrade(bytes memory payload) external;
}
