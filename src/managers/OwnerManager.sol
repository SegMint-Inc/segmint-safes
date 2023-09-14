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
        address currentOwner = _SENTINEL_VALUE;

        for (uint256 i = 0; i < owners.length; i++) {
            address signer = owners[i];

            /// forgefmt: disable-next-item
            /// Checks: Ensure `signer` is a valid address.
            if (
                signer == address(0) ||         // not zero address.
                signer == _SENTINEL_VALUE ||    // not sentinel value.
                signer == address(this) ||      // not self.
                currentOwner == signer         // not concurrent index duplicate.
            ) revert InvalidSigner();

            /// Checks: Ensure `signer` is not already an authorized signer.
            if (_owners[currentOwner] != address(0)) revert DuplicateSigner();

            _owners[currentOwner] = signer;
            currentOwner = signer;
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
        if (signer == address(0) || signer == _SENTINEL_VALUE) revert InvalidSigner();
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
        ) revert InvalidSigner();

        /// Checks: Ensure `signer` is not already an authorized signer.
        if (_owners[newOwner] != address(0)) revert DuplicateSigner();

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
        ) revert InvalidSigner();

        // No duplicate owners allowed.
        if (_owners[newOwner] != address(0)) revert DuplicateSigner();

        // Validate oldOwner address and check that it corresponds to owner index.
        // TODO: Rename this error.
        if (oldOwner == address(0) || oldOwner == _SENTINEL_VALUE) revert InvalidSigner();
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

    /**
     * @inheritdoc IOwnerManager
     */
    function getOwners() public view returns (address[] memory) {
        address[] memory _signers = new address[](_ownerCount);

        uint256 idx = 0;
        address currentOwner = _owners[_SENTINEL_VALUE];

        while (currentOwner != _SENTINEL_VALUE) {
            _signers[idx] = currentOwner;
            currentOwner = _owners[currentOwner];
            idx++;
        }

        return _signers;
    }

    /**
     * @inheritdoc IOwnerManager
     */
    function isOwner(address account) public view returns (bool) {
        return account != _SENTINEL_VALUE && _owners[account] != address(0);
    }

    /**
     * @inheritdoc IOwnerManager
     */
    function getQuorum() public view returns (uint256) {
        return _quroum;
    }
}