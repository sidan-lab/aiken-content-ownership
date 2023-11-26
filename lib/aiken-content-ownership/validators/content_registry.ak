use aiken/dict
use aiken/int
use aiken/list
use aiken/transaction.{
  InlineDatum, ScriptContext, ScriptPurpose, Spend, Transaction,
}
use aiken/transaction/value.{PolicyId, flatten}
use aiken_content_ownership/common.{
  inputs_at_with_policy, inputs_with, outputs_at_with,
}
use aiken_content_ownership/types.{
  ContentRegistryDatum, ContentRegistryRedeemer, CreateContent, OracleDatum,
  OwnershipRegistryDatum,
}

pub fn content_registry_logic(
  oracle_nft: PolicyId,
  _datum: ContentRegistryDatum,
  redeemer: ContentRegistryRedeemer,
  context: ScriptContext,
) {
  let ScriptContext { purpose, transaction } = context
  let Transaction { reference_inputs, inputs, outputs, .. } = transaction
  expect Spend(_): ScriptPurpose = purpose
  when (redeemer, inputs_with(reference_inputs, oracle_nft, "")) is {
    (CreateContent { content_hash, owner }, [oracle_ref_utxo]) -> {
      expect InlineDatum(inline_datum) = oracle_ref_utxo.output.datum
      expect OracleDatum {
        content_registry_address,
        ownership_registry_address,
        content_registry_ref_token,
        ownership_registry_ref_token,
        ..
      }: OracleDatum = inline_datum
      when
        (
          inputs_at_with_policy(
            inputs,
            content_registry_address,
            content_registry_ref_token,
          ),
          inputs_at_with_policy(
            inputs,
            ownership_registry_address,
            ownership_registry_ref_token,
          ),
        )
      is {
        ([content_input], [ownership_input]) -> {
          expect Some((_, content_ref_token_name, _)) =
            list.find(
              flatten(content_input.output.value),
              fn(token) { token.1st == content_registry_ref_token },
            )
          expect Some((_, ownership_ref_token_name, _)) =
            list.find(
              flatten(ownership_input.output.value),
              fn(token) { token.1st == ownership_registry_ref_token },
            )
          expect ([content_output], [ownership_output]) =
            (
              outputs_at_with(
                outputs,
                content_registry_address,
                content_registry_ref_token,
                content_ref_token_name,
              ),
              outputs_at_with(
                outputs,
                ownership_registry_address,
                ownership_registry_ref_token,
                ownership_ref_token_name,
              ),
            )
          expect InlineDatum(content_input_raw_datum) =
            content_input.output.datum
          expect InlineDatum(ownership_input_raw_datum) =
            ownership_input.output.datum
          expect content_input_datum: ContentRegistryDatum =
            content_input_raw_datum
          expect ownership_input_datum: OwnershipRegistryDatum =
            ownership_input_raw_datum
          expect InlineDatum(content_output_raw_datum) = content_output.datum
          expect InlineDatum(ownership_output_raw_datum) =
            ownership_output.datum
          expect content_output_datum: ContentRegistryDatum =
            content_output_raw_datum
          expect ownership_output_datum: OwnershipRegistryDatum =
            ownership_output_raw_datum
          let ref_tokens_equal =
            content_ref_token_name == ownership_ref_token_name
          let current_count_equal =
            content_input_datum.count == content_output_datum.count
          let content_new_datum_correct =
            content_output_datum == ContentRegistryDatum {
              count: content_input_datum.count + 1,
              registry: dict.insert(
                content_input_datum.registry,
                content_input_datum.count,
                content_hash,
                int.compare,
              ),
            }
          let ownership_new_datum_correct =
            ownership_output_datum == OwnershipRegistryDatum {
              count: ownership_input_datum.count + 1,
              registry: dict.insert(
                ownership_input_datum.registry,
                ownership_input_datum.count,
                owner,
                int.compare,
              ),
            }
          ref_tokens_equal && current_count_equal && content_new_datum_correct && ownership_new_datum_correct
        }
        _ -> False
      }
    }

    _ -> False
  }
}