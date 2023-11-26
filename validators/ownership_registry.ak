use aiken/transaction.{ScriptContext}
use aiken/transaction/value.{PolicyId}
use aiken_content_ownership/types.{
  OwnershipRegistryDatum, OwnershipRegistryRedeemer,
}
use aiken_content_ownership/validators/ownership_registry.{
  ownership_registry_logic,
}

validator(oracle_nft: PolicyId) {
  fn ownership_registry(
    datum: OwnershipRegistryDatum,
    redeemer: OwnershipRegistryRedeemer,
    context: ScriptContext,
  ) {
    ownership_registry_logic(oracle_nft, datum, redeemer, context)
  }
}
