// SPDX-License-Identifier: SegMint Code License 1.1
pragma solidity 0.8.19;

import { OwnableRoles } from "solady/src/auth/OwnableRoles.sol";
import { LibClone } from "solady/src/utils/LibClone.sol";
import { Initializable } from "@openzeppelin/proxy/utils/Initializable.sol";
import { AccessRoles } from "../access/AccessRoles.sol";
import { ISafeFactory } from "../interfaces/ISafeFactory.sol";
import { ISafe } from "../interfaces/ISafe.sol";
import { UpgradeHandler } from "../handlers/UpgradeHandler.sol";

/**
 * @title SafeFactory
 * @notice Creates new instances of {Safe}.
 */

contract SafeFactory is ISafeFactory, OwnableRoles, Initializable, UpgradeHandler {
    using LibClone for address;

    /// @dev Safe implementation address.
    address public safe;

    mapping(address account => uint256 nonce) private _nonce;

    constructor() {
        /// Prevent implementation contract from being initialized.
        _disableInitializers();
    }

    /**
     * @inheritdoc ISafeFactory
     */
    function initialize(address _admin, address _safe) external initializer {
        if (_admin == address(0) || _safe == address(0)) revert ZeroAddressInvalid();

        _initializeOwner(msg.sender);
        _grantRoles({ user: _admin, roles: AccessRoles.ADMIN_ROLE });
        safe = _safe;
    }

    /**
     * @inheritdoc ISafeFactory
     */
    function createSafe(address[] calldata owners, uint256 quorum) external {
        uint256 nonce = _nonce[msg.sender]++;

        /// Clone the safe.
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, nonce));
        address newSafe = safe.cloneDeterministic(salt);

        /// Initialize the Safe.
        ISafe(newSafe).initialize(owners, quorum);

        emit ISafeFactory.SafeCreated({ user: msg.sender, safe: newSafe, safeOwners: owners, safeQuorum: quorum });
    }

    /**
     * @inheritdoc ISafeFactory
     */
    function getSafes(address account) external view returns (address[] memory deployments) {
        uint256 safeNonce = _nonce[account];
        deployments = new address[](safeNonce);

        for (uint256 i = 0; i < safeNonce; i++) {
            bytes32 salt = keccak256(abi.encodePacked(account, i));
            deployments[i] = safe.predictDeterministicAddress(salt, address(this));
        }

        return deployments;
    }

    /**
     * @inheritdoc ISafeFactory
     */
    function getNonce(address account) external view returns (uint256) {
        return _nonce[account];
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     UPGRADE FUNCTIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @inheritdoc ISafeFactory
     */
    function proposeUpgrade(address newImplementation) external onlyRoles(AccessRoles.ADMIN_ROLE) onlyProxy {
        if (newImplementation == address(0)) revert ZeroAddressInvalid();
        _proposeUpgrade(newImplementation);
    }

    /**
     * @inheritdoc ISafeFactory
     */
    function cancelUpgrade() external onlyRoles(AccessRoles.ADMIN_ROLE) onlyProxy {
        _cancelUpgrade();
    }

    /**
     * @inheritdoc ISafeFactory
     */
    function executeUpgrade(bytes memory payload) external onlyRoles(AccessRoles.ADMIN_ROLE) onlyProxy {
        _executeUpgrade(payload);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      VERSION CONTROL                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function nameAndVersion() external pure virtual returns (string memory name, string memory version) {
        name = "Safe Factory";
        version = "1.0";
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       INTERNAL LOGIC                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Overriden to ensure that only callers with the correct role can upgrade the implementation.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRoles(AccessRoles.ADMIN_ROLE) { }
}
