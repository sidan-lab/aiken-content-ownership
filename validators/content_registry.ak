use aiken/transaction.{ScriptContext}
use aiken/transaction/value.{PolicyId}
use aiken_content_ownership/types.{ContentRegistryDatum,
  ContentRegistryRedeemer}
use aiken_content_ownership/validators/content_registry.{content_registry_logic}

validator(oracle_nft: PolicyId) {
  fn content_registry(
    datum: ContentRegistryDatum,
    redeemer: ContentRegistryRedeemer,
    context: ScriptContext,
  ) {
    content_registry_logic(oracle_nft, datum, redeemer, context)
  }
}
