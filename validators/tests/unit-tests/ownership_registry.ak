use aiken/dict.{Dict}
use aiken/int
use aiken/transaction.{
  Input, Output, ScriptContext, Spend, Transaction, placeholder,
}
use aiken/transaction/value.{AssetName, PolicyId, add, from_asset}
use aiken_content_ownership/common.{compare_output_reference}
use aiken_content_ownership/placeholder.{
  mock_content_registry_output, mock_oracle_datum, mock_oracle_output,
  mock_ownership_registry_output, mock_policy_id, mock_policy_id_2,
  mock_policy_id_3, mock_policy_id_4, mock_utxo_ref,
}
use aiken_content_ownership/types.{
  ContentRegistryDatum, CreateContent, CreateOwnershipRecord,
  OwnershipRegistryDatum, StopContentRegistry,
}
use aiken_content_ownership/utils.{get_registry_token_name}
use aiken_content_ownership/validators/ownership_registry.{
  ownership_registry_logic,
}

type TestCase {
  has_input_from_content_registry: Bool,
  is_content_registry_redeemer_correct: Bool,
}

fn make_mock_tx_body(
  record_count: Int,
  content_registry: Dict<Int, ByteArray>,
  ownership_registry: Dict<Int, (PolicyId, AssetName)>,
  content_hash: ByteArray,
  owner: (PolicyId, AssetName),
  test_case: TestCase,
) -> Transaction {
  let content_registry_value =
    from_asset(mock_policy_id_2(), get_registry_token_name(0), 1)
      |> add(#"", #"", 2_000_000)

  let ownership_registry_value =
    from_asset(mock_policy_id_3(), get_registry_token_name(0), 1)
      |> add(#"", #"", 2_000_000)
  let content_redeemer: Data =
    if test_case.is_content_registry_redeemer_correct {
      CreateContent { content_hash, owner }
    } else {
      StopContentRegistry
    }
  let ownership_redeemer: Data = CreateOwnershipRecord
  let redeemers =
    dict.new()
      |> dict.insert(
           Spend(mock_utxo_ref(2)),
           ownership_redeemer,
           compare_output_reference,
         )
      |> dict.insert(
           Spend(mock_utxo_ref(1)),
           content_redeemer,
           compare_output_reference,
         )

  Transaction {
    ..placeholder(),
    reference_inputs: [
      Input {
        output_reference: mock_utxo_ref(0),
        output: mock_oracle_output(mock_oracle_datum()),
      },
    ],
    inputs: [
      Input {
        output_reference: mock_utxo_ref(1),
        output: Output {
          ..mock_content_registry_output(
            0,
            ContentRegistryDatum {
              count: record_count,
              registry: content_registry,
            },
          ),
          value: content_registry_value,
        },
      },
      Input {
        output_reference: mock_utxo_ref(2),
        output: Output {
          ..mock_ownership_registry_output(
            0,
            OwnershipRegistryDatum {
              count: record_count,
              registry: ownership_registry,
            },
          ),
          value: ownership_registry_value,
        },
      },
    ],
    outputs: [
      Output {
        ..mock_content_registry_output(
          0,
          ContentRegistryDatum {
            count: record_count + 1,
            registry: dict.insert(
              content_registry,
              record_count,
              content_hash,
              int.compare,
            ),
          },
        ),
        value: content_registry_value,
      },
      Output {
        ..mock_ownership_registry_output(
          0,
          OwnershipRegistryDatum {
            count: record_count + 1,
            registry: dict.insert(
              ownership_registry,
              record_count,
              owner,
              int.compare,
            ),
          },
        ),
        value: ownership_registry_value,
      },
    ],
    redeemers: redeemers,
  }
}

test success_mint() {
  let redeemer = CreateOwnershipRecord
  let dat = OwnershipRegistryDatum { count: 0, registry: dict.new() }
  let content_hash = "QmWBaeu6y1zEcKbsEqCuhuDHPL3W8pZouCPdafMCRCSUWk"
  let owner = (mock_policy_id_4(), "my_token_name")
  let tx =
    make_mock_tx_body(
      0,
      dict.new(),
      dict.new(),
      content_hash,
      owner,
      TestCase {
        has_input_from_content_registry: True,
        is_content_registry_redeemer_correct: True,
      },
    )
  let ctx = ScriptContext { purpose: Spend(mock_utxo_ref(2)), transaction: tx }
  ownership_registry_logic(mock_policy_id(), dat, redeemer, ctx)
}
