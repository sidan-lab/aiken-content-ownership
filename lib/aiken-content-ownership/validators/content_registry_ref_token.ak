use aiken/transaction.{
  InlineDatum, Input, Mint, Output, ScriptContext, Transaction,
}
use aiken/transaction/value.{PolicyId}
use aiken_content_ownership/common.{
  check_policy_only_burn, inputs_with, outputs_at_with, value_length,
}
use aiken_content_ownership/types.{
  ContentRegistryDatum, MintPolarity, OracleDatum, RBurn, RMint,
}
use aiken_content_ownership/utils.{get_registry_token_name}

pub fn content_registry_ref_token_logic(
  oracle_nft: PolicyId,
  redeemer: MintPolarity,
  context: ScriptContext,
) -> Bool {
  let ScriptContext { purpose, transaction } = context
  let Transaction { inputs, outputs, mint, .. } = transaction
  when purpose is {
    Mint(current_policy) ->
      when (redeemer, inputs_with(inputs, oracle_nft, "")) is {
        (RMint, [oracle_input]) -> {
          expect InlineDatum(inline_datum) = oracle_input.output.datum
          expect input_datum: OracleDatum = inline_datum
          let OracleDatum {
            oracle_address,
            content_registry_ref_token,
            content_registry_address,
            content_registry_count,
            ..
          } = input_datum
          when
            (
              outputs_at_with(outputs, oracle_address, oracle_nft, ""),
              outputs_at_with(
                outputs,
                content_registry_address,
                content_registry_ref_token,
                get_registry_token_name(content_registry_count),
              ),
            )
          is {
            ([oracle_output], [registry_output]) -> {
              expect InlineDatum(raw_oracle_datum) = oracle_output.datum
              expect InlineDatum(raw_registry_datum) = registry_output.datum
              expect oracle_datum: OracleDatum = raw_oracle_datum
              expect ContentRegistryDatum { count, registry }: ContentRegistryDatum =
                raw_registry_datum
              let oracle_datum_updated =
                oracle_datum == OracleDatum {
                  ..input_datum,
                  content_registry_count: content_registry_count + 1,
                }
              let registry_initial_datum_correct = count == 0 && registry == []
              let oracle_output_value_clean =
                value_length(oracle_output.value) == 2
              let registry_output_value_clean =
                value_length(registry_output.value) == 2
              oracle_datum_updated && registry_initial_datum_correct && oracle_output_value_clean && registry_output_value_clean
            }
            _ -> False
          }
        }
        (RBurn, _) -> check_policy_only_burn(mint, current_policy)
        _ -> False
      }
    _ -> False
  }
}
