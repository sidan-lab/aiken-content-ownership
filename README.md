# aiken-content-ownership

This is the implementation of on-chain content ownership with below features:

1. User can create content and leverage Cardano blockchain to record ownership
2. The content owner can update the content anytime
3. The content owner can transfer content ownership to others
4. Forward compatible: Incentive mechanism expansion
5. Scalable: Up to 10,000 users, each with 10,000 piece of content
6. User can use any native asset on Cardano to represent ownership identity

# Script Actions

## Scripts

The specification of all scripts involved could be found at [scripts_specs.md](./specs/scripts_specs.md). Scripts are labelled with number 1 - 6. And we would use the label for referring to validation logic needed on below.

## Setup

The are 4 steps of setting up the applications:

1. Minting `oracle_nft`, one time minting policy with empty token name with quantity of 1.
   - Validation: 1.1
2. Sending the the `oracle_nft` to `oracle_validator` with initialized inline datum of specifying all compile scripts, addresses with owner keys. Setting both registry counts to `0`.
   - Validation: N/A
3. Creating `content_registry` by minting `content_registry_ref_token` to `content_registry` address.
   - Validation: 2.1, 3.1
4. Creating `ownership_registry` by minting `ownership_registry_ref_token` to `ownership_registry` address.
   - Validation: 2.2, 4.1

Step 3 and 4 would be repeated anytime, considering:

- Operating concurrency (1 UTxO = 1 concurrency)
- Registry size (desired size to be tested)

## User Actions

1. Create Content
   - Validation: 4.1, 6.1
2. Update Content
   - Validation: 4.2
3. Transfer Ownership
   - Validation: 6.2

## Admin Actions

1. Rotate keys
   - Validation: 2.3
2. Stop Oracle
   - Validation: 1.2, 2.4
3. Stop Content Registry
   - Validation: 3.2, 4.3
4. Stop Ownership Registry
   - Validation: 5.2, 6.3

# Testing

There is unit tests in this implementation. To run all tests, simply do:

```sh
aiken check
```
