// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { OwnableRoles } from "solady/src/auth/OwnableRoles.sol";
import { LibClone } from "solady/src/utils/LibClone.sol";
import { Initializable } from "@openzeppelin/proxy/utils/Initializable.sol";
import { ISafeFactory } from "../interfaces/ISafeFactory.sol";
import { ISafe } from "../interfaces/ISafe.sol";
import { UpgradeHandler } from "../handlers/UpgradeHandler.sol";

/**
 * @title SafeFactory
 * @notice See documentation for {ISafeFactory}.
 */

contract SafeFactory is ISafeFactory, OwnableRoles, Initializable, UpgradeHandler {
    using LibClone for address;

    /// `keccak256("ADMIN_ROLE");`
    uint256 public constant ADMIN_ROLE = 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775;
    
    /// @dev Safe implementation address.
    address public safe;

    mapping(address account => uint256 nonce) private _nonce;

    /**
     * @inheritdoc ISafeFactory
     */
    function initialize(address _admin, address _safe) external initializer {
        _initializeOwner(msg.sender);
        _grantRoles(_admin, ADMIN_ROLE);
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

        emit ISafeFactory.SafeCreated({ user: msg.sender, safe: newSafe });
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
    function proposeUpgrade(address newImplementation) external onlyRoles(ADMIN_ROLE) {
        _proposeUpgrade(newImplementation);
    }

    /**
     * @inheritdoc ISafeFactory
     */
    function cancelUpgrade() external onlyRoles(ADMIN_ROLE) {
        _cancelUpgrade();
    }

    /**
     * @inheritdoc ISafeFactory
     */
    function executeUpgrade(bytes memory payload) external onlyRoles(ADMIN_ROLE) {
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
    function _authorizeUpgrade(address newImplementation) internal override onlyRoles(ADMIN_ROLE) { }
}
