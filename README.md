# Segmint Safes

Smart contract suite for SegMint Safes.

See `./SPECIFICATION.md` for further details.

## Protocol Overview

| File Name | Description |
| --- | --- |
| `Safe.sol` | Instance of a SegMint Safe. |

### Factories

| File Name | Description |
| --- | --- |
| `SafeFactory.sol` | Used to create a new instance of `Safe`. |

### Handlers

| File Name | Description |
| --- | --- |
| `Approvals.sol` | Handles transactions approvals. |
| `MultiCall.sol` | Used to execute multiple nonpayable actions within a single Safe transaction. |
| `UpgradeHandler.sol` | Used for managing upgrades to the Vault Factory contract using a timelock. |

### Managers

| File Name | Description |
| --- | --- |
| `OwnerManager.sol` | Managers ownership associated with a Safe. |

### Utils

| File Name | Description |
| --- | --- |
| `NativeTokenReceiver.sol` | Implements native token receival. |
| `SelfAuthorized.sol` | Restricts modified functions to only being callable by self. |
| `StandardTokenReceiver.sol` | Implements ERC721 and ERC1155 transfer callbacks. |
| `TransactionEncoder.sol` | Encodes a Safe transaction using EIP712. |
| `TransactionExecutor.sol` | Implements the logic to execute a Safe transaction. |

## Testing

This repository uses Foundry for testing and deployment.

```cmd
forge install
forge build
forge test
```

## Access Control

See `PERMISSIONS.md` for further details.

## Deplyoment

TBD.
