# SegMint Safes Access Control

## Roles & Abilities

The SegMint Safe ecosystem is very limited in scope when it comes to access control. Essentially there is only 4 roles that exist, these are:

- Contract Owner: The owner of the contract, in the context of the ecosystem this will namely be the deployer of the contracts.
- Administrator: Any account that has been granted the `ADMIN_ROLE`, this particular role will only exist within the `SafeFactory.sol` contract.
- Safe Owners: Any owner that has been acknowledged as an owner of a Safe instance. Safes will be initialized with an array of owners, but owners can change over time depending on the requirements of the Safe creator.
- Anyone: Any EOA.

## Safe Factory

| Role | Permissions |
| --- | --- |
| Contract Owner | Can grant the `ADMIN_ROLE` to an account. |
| Administrator | Can propose, cancel and execute upgrades to the implementation. |
| Safe Owners | N/A |
| Anyone | Can create an instance of a SegMint Safe. |

## Safe

| Role | Permissions |
| --- | --- |
| Contract Owner | N/A |
| Administrator | N/A |
| Safe Owners | Can approve and execute SegMint safe related transactions. |
| Anyone | Can view existing state variables associated with the Safe. |
