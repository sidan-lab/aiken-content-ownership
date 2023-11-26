use aiken/transaction.{
  InlineDatum, Input, Output, ScriptContext, Spend, Transaction, placeholder,
}
use aiken/transaction/value.{PolicyId, from_asset, to_minted_value}
use aiken_content_ownership/common.{
  all_key_signed, key_signed, onlyMintedToken, outputs_at_with,
}
use aiken_content_ownership/placeholder.{
  mock_oracle_datum, mock_oracle_output, mock_policy_id, mock_policy_id_2,
  mock_policy_id_3, mock_utxo_ref, mock_vkey_hex, mock_vkey_hex_2,
}
use aiken_content_ownership/types.{
  CreateContentRegistry, CreateOwnershipRegistry, OracleDatum, OracleRedeemer,
  RotateKey, StopApp,
}
use aiken_content_ownership/utils.{get_registry_token_name}

validator {
  fn oracle_validator(
    datum: OracleDatum,
    redeemer: OracleRedeemer,
    context: ScriptContext,
  ) {
    let ScriptContext { purpose, transaction } = context
    when purpose is {
      Spend(_) -> {
        let Transaction { outputs, mint, extra_signatories, .. } = transaction
        let OracleDatum {
          oracle_nft,
          oracle_address,
          content_registry_ref_token,
          content_registry_count,
          ownership_registry_ref_token,
          ownership_registry_count,
          operation_key,
          stop_key,
          ..
        } = datum

        when redeemer is {
          CreateContentRegistry ->
            // Ref token is minted
            onlyMintedToken(
              mint,
              content_registry_ref_token,
              get_registry_token_name(content_registry_count),
              1,
            )

          CreateOwnershipRegistry ->
            // Ref token is minted
            onlyMintedToken(
              mint,
              ownership_registry_ref_token,
              get_registry_token_name(ownership_registry_count),
              1,
            )
          RotateKey { new_operation_key, new_stop_key } -> {
            // Sign by both ops and stop key
            expect [own_output] =
              outputs_at_with(outputs, oracle_address, oracle_nft, "")
            expect InlineDatum(dat) = own_output.datum
            expect own_datum: OracleDatum = dat
            let datum_correct =
              own_datum == OracleDatum {
                ..datum,
                operation_key: new_operation_key,
                stop_key: new_stop_key,
              }
            all_key_signed(extra_signatories, [operation_key, stop_key]) && datum_correct
          }

          // datum update correctly (key rotated)
          StopApp ->
            // signed by stop key
            // oracle nft is burned
            key_signed(extra_signatories, stop_key) && onlyMintedToken(
              mint,
              oracle_nft,
              "",
              -1,
            )
        }
      }
      _ -> False
    }
  }
}

test success_create_content_registry() {
  let redeemer = CreateContentRegistry
  let policy_id: PolicyId = mock_policy_id_2()

  let tx =
    Transaction {
      ..placeholder(),
      mint: to_minted_value(from_asset(policy_id, "Registry (0)", 1)),
    }
  let ctx = ScriptContext { purpose: Spend(mock_utxo_ref(0)), transaction: tx }

  oracle_validator(mock_oracle_datum(), redeemer, ctx)
}

test success_create_ownership_registry() {
  let redeemer = CreateOwnershipRegistry
  let policy_id: PolicyId = mock_policy_id_3()

  let tx =
    Transaction {
      ..placeholder(),
      mint: to_minted_value(from_asset(policy_id, "Registry (0)", 1)),
    }
  let ctx = ScriptContext { purpose: Spend(mock_utxo_ref(0)), transaction: tx }

  oracle_validator(mock_oracle_datum(), redeemer, ctx)
}

test success_rotate_key() {
  let redeemer =
    RotateKey {
      new_operation_key: mock_vkey_hex_2(),
      new_stop_key: mock_vkey_hex(),
    }

  let input_utxo = mock_utxo_ref(0)
  let input =
    Input {
      output_reference: input_utxo,
      output: mock_oracle_output(mock_oracle_datum()),
    }
  let output =
    mock_oracle_output(
      OracleDatum {
        ..mock_oracle_datum(),
        operation_key: mock_vkey_hex_2(),
        stop_key: mock_vkey_hex(),
      },
    )

  let tx =
    Transaction {
      ..placeholder(),
      inputs: [input],
      outputs: [output],
      extra_signatories: [mock_vkey_hex(), mock_vkey_hex_2()],
    }
  let ctx = ScriptContext { purpose: Spend(input_utxo), transaction: tx }

  oracle_validator(mock_oracle_datum(), redeemer, ctx)
}

test success_stop_app() {
  let redeemer = StopApp
  let tx =
    Transaction {
      ..placeholder(),
      mint: to_minted_value(from_asset(mock_policy_id(), "", -1)),
      extra_signatories: [mock_vkey_hex_2()],
    }
  let ctx = ScriptContext { purpose: Spend(mock_utxo_ref(0)), transaction: tx }

  oracle_validator(mock_oracle_datum(), redeemer, ctx)
}
