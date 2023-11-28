use aiken/dict
use aiken/int
use aiken/list
use aiken/transaction.{
  InlineDatum, ScriptContext, ScriptPurpose, Spend, Transaction,
}
use aiken/transaction/value.{
  PolicyId, flatten, from_minted_value, negate, without_lovelace,
}
use aiken_content_ownership/common.{
  inputs_at_with_policy, inputs_with, key_signed, outputs_at_with,
}
use aiken_content_ownership/types.{
  ContentRegistryDatum, ContentRegistryRedeemer, CreateContent, OracleDatum,
  OwnershipRegistryDatum, StopContentRegistry,
}

pub fn content_registry_logic(
  oracle_nft: PolicyId,
  _datum: ContentRegistryDatum,
  redeemer: ContentRegistryRedeemer,
  context: ScriptContext,
) {
  let ScriptContext { purpose, transaction } = context
  let Transaction {
    reference_inputs,
    inputs,
    outputs,
    extra_signatories,
    mint,
    ..
  } = transaction
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
            content_input_datum.count == ownership_input_datum.count
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
          let content_registry_value_clean =
            list.length(flatten(content_output.value)) == 2
          let ownership_registry_value_clean =
            list.length(flatten(ownership_output.value)) == 2
          ref_tokens_equal && current_count_equal && content_new_datum_correct && ownership_new_datum_correct && content_registry_value_clean && ownership_registry_value_clean
        }
        _ -> False
      }
    }
    (StopContentRegistry, [oracle_ref_utxo]) -> {
      expect InlineDatum(inline_datum) = oracle_ref_utxo.output.datum
      expect OracleDatum {
        stop_key,
        content_registry_ref_token,
        content_registry_address,
        ..
      }: OracleDatum = inline_datum
      when
        inputs_at_with_policy(
          inputs,
          content_registry_address,
          content_registry_ref_token,
        )
      is {
        [content_input] -> {
          let is_stop_key_signed = key_signed(extra_signatories, stop_key)
          let content_ref_token = content_input.output.value |> without_lovelace
          let is_ref_token_burned =
            from_minted_value(mint) == negate(content_ref_token)
          is_stop_key_signed && is_ref_token_burned
        }
        _ -> False
      }
    }
    _ -> False
  }
}
