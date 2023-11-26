use aiken/dict
use aiken/transaction.{
  InlineDatum, ScriptContext, ScriptPurpose, Spend, Transaction,
}
use aiken/transaction/value.{PolicyId}
use aiken_content_ownership/common.{inputs_at, inputs_with}
use aiken_content_ownership/types.{
  ContentRegistryRedeemer, CreateContent, CreateOwnershipRecord, OracleDatum,
  OwnershipRegistryDatum, OwnershipRegistryRedeemer,
}

pub fn ownership_registry_logic(
  oracle_nft: PolicyId,
  _datum: OwnershipRegistryDatum,
  redeemer: OwnershipRegistryRedeemer,
  context: ScriptContext,
) {
  let ScriptContext { purpose, transaction } = context
  let Transaction { reference_inputs, redeemers, inputs, .. } = transaction
  expect Spend(_): ScriptPurpose = purpose
  when (redeemer, inputs_with(reference_inputs, oracle_nft, "")) is {
    (CreateOwnershipRecord, [oracle_ref_utxo]) -> {
      expect InlineDatum(inline_datum) = oracle_ref_utxo.output.datum
      expect OracleDatum { content_registry_address, .. }: OracleDatum =
        inline_datum
      expect [content_input] = inputs_at(inputs, content_registry_address)
      expect Some(raw_redeemer) =
        dict.get(redeemers, Spend(content_input.output_reference))
      expect parsed_redeemer: ContentRegistryRedeemer = raw_redeemer
      when parsed_redeemer is {
        CreateContent { content_hash: _, owner: _ } -> True
        _ -> False
      }
    }
    _ -> False
  }
}
