use aiken/dict
// use aiken/list
use aiken/transaction.{
  InlineDatum, Input, Mint, ScriptContext, Transaction, placeholder,
}
use aiken/transaction/value.{PolicyId, from_asset, to_minted_value}
use aiken_content_ownership/common.{inputs_with, outputs_at_with, value_length}
use aiken_content_ownership/placeholder.{
  mock_content_registry_datum, mock_content_registry_output, mock_oracle_datum,
  mock_oracle_output, mock_policy_id, mock_policy_id_2, mock_utxo_ref,
}
use aiken_content_ownership/types.{
  ContentRegistryDatum, MintPolarity, OracleDatum, RBurn, RMint,
}
use aiken_content_ownership/utils.{get_registry_token_name}

validator(oracle_nft: PolicyId) {
  fn content_registry_ref_token(
    redeemer: MintPolarity,
    context: ScriptContext,
  ) -> Bool {
    let ScriptContext { purpose, transaction } = context
    let Transaction { inputs, outputs, .. } = transaction
    when purpose is {
      Mint(_) ->
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
                let registry_initial_datum_correct =
                  count == 0 && registry == dict.new()
                let oracle_output_value_clean =
                  value_length(oracle_output.value) == 2
                let registry_output_value_clean =
                  value_length(registry_output.value) == 2
                oracle_datum_updated && registry_initial_datum_correct && oracle_output_value_clean && registry_output_value_clean
              }
              _ -> False
            }
          }
          (RBurn, _) -> True
          _ -> False
        }
      _ -> False
    }
  }
}

fn make_mock_tx_body(record_count: Int) -> Transaction {
  Transaction {
    ..placeholder(),
    mint: to_minted_value(
      from_asset(mock_policy_id_2(), get_registry_token_name(record_count), 1),
    ),
    inputs: [
      Input {
        output_reference: mock_utxo_ref(1),
        output: mock_oracle_output(mock_oracle_datum()),
      },
    ],
    outputs: [
      mock_oracle_output(
        OracleDatum {
          ..mock_oracle_datum(),
          content_registry_count: record_count + 1,
        },
      ),
      mock_content_registry_output(
        record_count,
        mock_content_registry_datum(0, dict.new()),
      ),
    ],
  }
}

test success_mint() {
  let redeemer = RMint
  let tx = make_mock_tx_body(0)
  let ctx = ScriptContext { purpose: Mint(mock_policy_id_2()), transaction: tx }
  content_registry_ref_token(mock_policy_id(), redeemer, ctx)
}

test fail_mint_without_update_oracle() {
  let redeemer = RMint
  let tx = make_mock_tx_body(0)
  let ctx = ScriptContext { purpose: Mint(mock_policy_id()), transaction: tx }
  !content_registry_ref_token(mock_policy_id(), redeemer, ctx)
}
