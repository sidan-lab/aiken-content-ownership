use aiken/transaction.{Input, ScriptContext, Spend, Transaction, placeholder}
use aiken/transaction/value.{PolicyId, from_asset, to_minted_value}
use aiken_content_ownership/placeholder.{
  mock_oracle_datum, mock_oracle_output, mock_policy_id, mock_policy_id_2,
  mock_policy_id_3, mock_utxo_ref, mock_vkey_hex, mock_vkey_hex_2,
}
use aiken_content_ownership/types.{
  CreateContentRegistry, CreateOwnershipRegistry, OracleDatum, RotateKey,
  StopApp,
}
use aiken_content_ownership/validators/oracle_validator.{oracle_validator_logic}

test success_create_content_registry() {
  let redeemer = CreateContentRegistry
  let policy_id: PolicyId = mock_policy_id_2()

  let tx =
    Transaction {
      ..placeholder(),
      mint: to_minted_value(from_asset(policy_id, "Registry (0)", 1)),
    }
  let ctx = ScriptContext { purpose: Spend(mock_utxo_ref(0)), transaction: tx }

  oracle_validator_logic(mock_oracle_datum(), redeemer, ctx)
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

  oracle_validator_logic(mock_oracle_datum(), redeemer, ctx)
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

  oracle_validator_logic(mock_oracle_datum(), redeemer, ctx)
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

  oracle_validator_logic(mock_oracle_datum(), redeemer, ctx)
}
