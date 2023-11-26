use aiken/transaction.{ScriptContext}
use aiken/transaction/value.{PolicyId}
use aiken_content_ownership/types.{MintPolarity}
use aiken_content_ownership/validators/content_registry_ref_token.{
  content_registry_ref_token_logic,
}

validator(oracle_nft: PolicyId) {
  fn content_registry_ref_token(
    redeemer: MintPolarity,
    context: ScriptContext,
  ) -> Bool {
    content_registry_ref_token_logic(oracle_nft, redeemer, context)
  }
}
