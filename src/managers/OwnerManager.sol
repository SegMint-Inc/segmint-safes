// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.19;

import { IOwnerManager } from "../interfaces/IOwnerManager.sol";
import { SelfAuthorized } from "../utils/SelfAuthorized.sol";

/**
 * @title OwnerManager
 * @custom:note Modification of Gnosis Safe's `OwnerManager` to use custom errors.
 * https://github.com/safe-global/safe-contracts/blob/main/contracts/base/OwnerManager.sol
 */

abstract contract OwnerManager is IOwnerManager, SelfAuthorized {
    address internal constant _SENTINEL_VALUE = address(0x01);

    /// Linked list of approved signers.
    mapping(address prevOwner => address owner) internal _owners;

    /// Number of signers associated with the Safe.
    uint256 internal _ownerCount;

    /// Proposal quorum value.
    uint256 internal _quroum;

    /**
     * Function used to initialize the signers associated with a safe.
     * @param owners List of intended signers to initialize the safe with.
     * @param quorum Number of approvals required to reach quorum.
     */
    function _initOwners(address[] calldata owners, uint256 quorum) internal {
        /// Checks: Ensure owners is non-zero in length.
        if (owners.length == 0) revert NoOwnersProvided();

        /// Checks: Ensure a valid quorum value has been provided.
        if (quorum == 0 || quorum > owners.length) revert InvalidQuorum();

        address currentOwner = _SENTINEL_VALUE;

        for (uint256 i = 0; i < owners.length; i++) {
            address owner = owners[i];

            /// forgefmt: disable-next-item
            /// Checks: Ensure `signer` is a valid address.
            if (
                owner == address(0) ||         // not zero address.
                owner == _SENTINEL_VALUE ||    // not sentinel value.
                owner == address(this) ||      // not self.
                currentOwner == owner         // not concurrent index duplicate.
            ) revert InvalidOwner();

            /// Checks: Ensure `signer` is not already an authorized signer.
            if (_owners[owner] != address(0)) revert DuplicateOwner();

            _owners[currentOwner] = owner;
            currentOwner = owner;
        }

        _owners[currentOwner] = _SENTINEL_VALUE;
        _ownerCount = owners.length;
        _quroum = quorum;
    }

    /**
     * @inheritdoc IOwnerManager
     */
    function removeOwner(address prtOwner, address signer, uint256 newQuorum) public selfAuthorized {
        if (newQuorum > _ownerCount - 1) revert RemovalBreaksQuorum();
        if (signer == address(0) || signer == _SENTINEL_VALUE) revert InvalidOwner();
        if (_owners[prtOwner] != signer) revert InvalidPointer();

        _owners[prtOwner] = _owners[signer];
        _owners[signer] = address(0);
        _ownerCount--;

        if (_quroum != newQuorum) {
            changeQuorum(newQuorum);
        }
    }

    /**
     * @inheritdoc IOwnerManager
     */
    function addOwner(address newOwner, uint256 newQuorum) public selfAuthorized {
        /// forgefmt: disable-next-item
        /// Checks: Ensure `signer` is a valid address.
        if (
            newOwner == address(0) ||      // not zero address.
            newOwner == _SENTINEL_VALUE || // not sentinel value.
            newOwner == address(this)      // not self.
        ) revert InvalidOwner();

        /// Checks: Ensure `signer` is not already an authorized signer.
        if (_owners[newOwner] != address(0)) revert DuplicateOwner();

        _owners[newOwner] = _owners[_SENTINEL_VALUE];
        _owners[_SENTINEL_VALUE] = newOwner;

        _ownerCount++;

        if (_quroum != newQuorum) {
            changeQuorum(newQuorum);
        }
    }

    /**
     * @inheritdoc IOwnerManager
     */
    function swapOwner(address prtOwner, address oldOwner, address newOwner) public selfAuthorized {
        /// forgefmt: disable-next-item
        // Owner address cannot be null, the sentinel or the Safe itself.
        if (
            newOwner == address(0) ||      // not zero address.
            newOwner == _SENTINEL_VALUE || // not sentinel value.
            newOwner == address(this)      // not self.
        ) revert InvalidOwner();

        // No duplicate owners allowed.
        if (_owners[newOwner] != address(0)) revert DuplicateOwner();

        // Validate oldOwner address and check that it corresponds to owner index.
        // TODO: Rename this error.
        if (oldOwner == address(0) || oldOwner == _SENTINEL_VALUE) revert InvalidOwner();
        if (_owners[prtOwner] != oldOwner) revert PointerMismatch();

        _owners[newOwner] = _owners[oldOwner];
        _owners[prtOwner] = newOwner;
        _owners[oldOwner] = address(0);
    }

    /**
     * @inheritdoc IOwnerManager
     */
    function changeQuorum(uint256 newQuorum) public selfAuthorized {
        // if (newQuorum == 0 || newQuorum > _ownerCount) revert InvalidQuorum();
        _quroum = newQuorum;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       VIEW FUNCTIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @inheritdoc IOwnerManager
     */
    function getOwners() public view returns (address[] memory) {
        address[] memory safeOwners = new address[](_ownerCount);

        uint256 idx = 0;
        address currentOwner = _owners[_SENTINEL_VALUE];

        while (currentOwner != _SENTINEL_VALUE) {
            safeOwners[idx] = currentOwner;
            currentOwner = _owners[currentOwner];
            idx++;
        }

        return safeOwners;
    }

    /**
     * @inheritdoc IOwnerManager
     */
    function isOwner(address account) public view returns (bool) {
        return account != _SENTINEL_VALUE && _owners[account] != address(0);
    }

    function ownerCount() public view returns (uint256) {
        return _ownerCount;
    }

    /**
     * @inheritdoc IOwnerManager
     */
    function getQuorum() public view returns (uint256) {
        return _quroum;
    }
}
