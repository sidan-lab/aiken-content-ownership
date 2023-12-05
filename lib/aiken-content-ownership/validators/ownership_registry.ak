use aiken/dict
use aiken/list
use aiken/transaction.{
  InlineDatum, ScriptContext, ScriptPurpose, Spend, Transaction,
}
use aiken/transaction/value.{
  PolicyId, flatten, from_minted_value, negate, without_lovelace,
}
use aiken_content_ownership/common.{
  inputs_at, inputs_at_with_policy, inputs_token_quantity, inputs_with,
  key_signed, outputs_at_with_policy,
}
use aiken_content_ownership/types.{
  ContentRegistryRedeemer, CreateContent, CreateOwnershipRecord, OracleDatum,
  OwnershipRegistryDatum, OwnershipRegistryRedeemer, StopOwnershipRegistry,
  TransferOwnership,
}

pub fn ownership_registry_logic(
  oracle_nft: PolicyId,
  _datum: OwnershipRegistryDatum,
  redeemer: OwnershipRegistryRedeemer,
  context: ScriptContext,
) {
  let ScriptContext { purpose, transaction } = context
  let Transaction {
    reference_inputs,
    redeemers,
    inputs,
    outputs,
    extra_signatories,
    mint,
    ..
  } = transaction
  expect Spend(_): ScriptPurpose = purpose
  when inputs_with(reference_inputs, oracle_nft, "") is {
    [oracle_ref_utxo] -> {
      expect InlineDatum(inline_datum) = oracle_ref_utxo.output.datum
      when redeemer is {
        CreateOwnershipRecord -> {
          expect OracleDatum { content_registry_address, .. }: OracleDatum =
            inline_datum
          when inputs_at(inputs, content_registry_address) is {
            [content_input] -> {
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
        TransferOwnership { new_owner_token, content_number } -> {
          expect OracleDatum {
            ownership_registry_address,
            ownership_registry_ref_token,
            ..
          }: OracleDatum = inline_datum
          when
            (
              inputs_at_with_policy(
                inputs,
                ownership_registry_address,
                ownership_registry_ref_token,
              ),
              outputs_at_with_policy(
                outputs,
                ownership_registry_address,
                ownership_registry_ref_token,
              ),
            )
          is {
            ([ownership_input], [ownership_output]) -> {
              expect InlineDatum(raw_input_datum) = ownership_input.output.datum
              expect input_datum: OwnershipRegistryDatum = raw_input_datum
              expect InlineDatum(raw_output_datum) = ownership_output.datum
              expect output_datum: OwnershipRegistryDatum = raw_output_datum
              expect Some(original_owner) =
                list.at(input_datum.registry, content_number)
              let is_original_owner_authorized =
                inputs_token_quantity(inputs, original_owner) > 0
              let is_registry_updated =
                output_datum == OwnershipRegistryDatum {
                  count: input_datum.count,
                  registry: list.concat(input_datum.registry, [new_owner_token]),
                }
              let is_registry_value_clean =
                list.length(flatten(ownership_output.value)) == 2
              is_original_owner_authorized && is_registry_updated && is_registry_value_clean
            }
            _ -> False
          }
        }
        StopOwnershipRegistry -> {
          expect OracleDatum {
            stop_key,
            ownership_registry_ref_token,
            ownership_registry_address,
            ..
          }: OracleDatum = inline_datum
          when
            inputs_at_with_policy(
              inputs,
              ownership_registry_address,
              ownership_registry_ref_token,
            )
          is {
            [ownership_input] -> {
              let is_stop_key_signed = key_signed(extra_signatories, stop_key)
              let ownership_ref_token =
                ownership_input.output.value |> without_lovelace
              let is_ref_token_burned =
                from_minted_value(mint) == negate(ownership_ref_token)
              is_stop_key_signed && is_ref_token_burned
            }
            _ -> False
          }
        }
      }
    }

    _ -> False
  }
}
