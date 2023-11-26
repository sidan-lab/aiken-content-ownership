use aiken/transaction.{Input, Mint, ScriptContext, Transaction, placeholder}
use aiken/transaction/value.{PolicyId, add, from_asset, to_minted_value}
use aiken_content_ownership/placeholder.{
  mock_output, mock_policy_id, mock_policy_id_2, mock_utxo_ref,
}
use aiken_content_ownership/types.{RBurn, RMint}
use aiken_content_ownership/validators/one_time_minting_policy.{
  one_time_minting_policy_logic,
}

test success_mint() {
  let redeemer = RMint
  let input_utxo = mock_utxo_ref(1)
  let policy_id: PolicyId =
    #"1c1b7afe8affbee1505cf3ec5a58bd2734d4ffdfcc9b9f059625bd76"

  let tx =
    Transaction {
      ..placeholder(),
      mint: to_minted_value(from_asset(policy_id, "", 1)),
      inputs: [Input { output_reference: input_utxo, output: mock_output() }],
    }
  let ctx = ScriptContext { purpose: Mint(policy_id), transaction: tx }

  one_time_minting_policy_logic(input_utxo, redeemer, ctx)
}

test fail_mint_no_utxo_ref_supply() {
  let redeemer = RMint
  let policy_id = mock_policy_id()

  let ctx =
    ScriptContext { purpose: Mint(policy_id), transaction: placeholder() }

  !one_time_minting_policy_logic(mock_utxo_ref(0), redeemer, ctx)
}

test success_burn() {
  let redeemer = RBurn
  let policy_id = mock_policy_id()

  let tx =
    Transaction {
      ..placeholder(),
      mint: to_minted_value(from_asset(policy_id, "", -1)),
    }
  let ctx = ScriptContext { purpose: Mint(policy_id), transaction: tx }
  one_time_minting_policy_logic(mock_utxo_ref(0), redeemer, ctx)
}

test success_burn_with_other_minting() {
  let redeemer = RBurn
  let policy_id = mock_policy_id()

  let tx =
    Transaction {
      ..placeholder(),
      mint: to_minted_value(
        from_asset(policy_id, "", -1) |> add(mock_policy_id_2(), "", 1),
      ),
    }
  let ctx = ScriptContext { purpose: Mint(policy_id), transaction: tx }
  one_time_minting_policy_logic(mock_utxo_ref(0), redeemer, ctx)
}

test fail_burn_with_mint() {
  let redeemer = RBurn
  let policy_id = mock_policy_id()

  let tx =
    Transaction {
      ..placeholder(),
      mint: to_minted_value(from_asset(policy_id, "", 1)),
    }
  let ctx = ScriptContext { purpose: Mint(policy_id), transaction: tx }
  !one_time_minting_policy_logic(mock_utxo_ref(0), redeemer, ctx)
}

test fail_burn_with_mix() {
  let redeemer = RBurn
  let policy_id = mock_policy_id()

  let tx =
    Transaction {
      ..placeholder(),
      mint: to_minted_value(
        from_asset(policy_id, "", -1) |> add(policy_id, "1", 1),
      ),
    }
  let ctx = ScriptContext { purpose: Mint(policy_id), transaction: tx }
  !one_time_minting_policy_logic(mock_utxo_ref(0), redeemer, ctx)
}
