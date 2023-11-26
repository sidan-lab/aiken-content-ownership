use aiken/transaction.{ScriptContext, ScriptPurpose, Spend, Transaction}
use aiken/transaction/value.{PolicyId}
use aiken_content_ownership/common.{inputs_with}
use aiken_content_ownership/types.{
  ContentRegistryDatum, ContentRegistryRedeemer, CreateContent,
}

validator(oracle_nft: PolicyId) {
  fn content_registry_validator(
    datum: ContentRegistryDatum,
    redeemer: ContentRegistryRedeemer,
    context: ScriptContext,
  ) {
    let ScriptContext { purpose, transaction } = context
    let Transaction { reference_inputs, inputs, outputs, mint, .. } =
      transaction
    expect Spend(_): ScriptPurpose = purpose
    when (redeemer, inputs_with(reference_inputs, oracle_nft, "")) is {
      (CreateContent { content_hash }, [oracle_ref_input]) -> True
      _ -> False
    }
  }
}
