# SegMint Safes

Safes offer versatility and can accommodate both short-term and long-term storage. Using Safes, users can store EVM-compatible assets such as ERC20, ERC721, ERC1155 and chain-native tokens. They have the flexibility to add, remove and swap multiple signatories and establish threshold requirements for approving transaction proposals. In essence, Safes can be likened to real-life safety deposit boxes, where the keys required to open the safe are equivalent to the proposed signatories authorized to approve transactions.

## Protocol Upgradability

All contracts within the Safe ecosystem are immutable besides the `SafeFactory.sol` smart contract which allows an administrator to propose an upgrade. Upgrades to the implementation can then be executed assuming the hardcoded timelock of 5 days has lapsed. This contract has been defined as upgradable so that future versions of Safes may be added at a later point in time.

## Factories

### Safe Factory

The `SafeFactory.sol` contract is responsible for creating new instances of `Safe.sol`. The factory achieves this using clones and creates these new instances using `CREATE2`. After a Safe has been created, it is then initialised. Through the Safe Factory, a user is able to query this contract to view all Safes associated with their address.

## Handlers

### Approvals

The `Approvals.sol` contract contains all the relevant logic for approving transactions as a Safe owner. Whilst the `_approveTxnHash` function is internal, the Safe contract itself implements a `approveTxnHash` function which allows Safe owners to call this function. Owners are also able to query which transactions that have approved.

### MultiCall

The `MultiCall.sol` contract allows Safe owners to batch nonpayable actions into a single Safe transaction. This may include transferring multiple ERC-20 tokens to a variety of addresses, swapping tokens via UniSwap, and etc. Whilst this function is nonpayable, existing services such as [disperse.app](https://disperse.app/) can be utilised for Ether distribution to multiple different addresses. This contract ensures that all calls must succeed and the failure of a single call results in a revert of the entire transaction.

## Managers

### Owner Manager

The `OwnerManager.sol` contract is responsible for managing the users associated with a vault and forks [Gnosis Safe's Owner Mangager](https://github.com/safe-global/safe-contracts/blob/main/contracts/base/OwnerManager.sol) but uses custom errors instead require statements for consistency within the surrounding codebase.

All exposed non-view functions within this contract should only be callable through a Safe transaction, meaning that a proposal must pass before these functions can be called. Safe owners are able to add, remove, and swap owners, but also propose a change to the current quorum value that is required to achieve transaction execution.

## Utils

### Native Token Receiver

The `NativeTokenReceiver.sol` contract enables the Safe to receive the native token and emits an event upon doing so.

### Self Authorized

The `SelfAuthorized.sol` contract implements a modifier that can be inherited by certain functions to ensure that no address other than the Safe itself can call these functions. This modifier is used in both the `OwnerManager.sol` and `MultiCall.sol` contracts.

### Standard Token Receiver

The `StandardTokenReceiver.sol` contract allows the Safe to receive ERC-721 and ERC-1155 tokens that are transferred using "safe" transfer methods, namely `safeTransferFrom` and `safeBatchTransferFrom`.

### Transaction Encoder

The `TransactionEncoder.sol` contract allows the front-end to encode proposed transactions using EIP712 and returns the hash of the encoded transaction. These hashes will be used to provide Safe owners with the ability to approve said transactions in a gas-efficient manner rather than approving the unecoded transaction data.

### Transaction Executor

The `TransactionExecutor.sol` contract provides the basic functionality to execute transactions. Allowing for either `CALL` or `DELEGATECALL` functionality.
