use aiken/dict.{Dict}
use aiken/int
use aiken/list
use aiken/transaction.{
  Input, Output, ScriptContext, Spend, Transaction, placeholder,
}
use aiken/transaction/value.{AssetName, PolicyId, add, from_asset}
use aiken_content_ownership/common.{compare_output_reference}
use aiken_content_ownership/placeholder.{
  mock_content_registry_output, mock_oracle_datum, mock_oracle_output,
  mock_output, mock_ownership_registry_output, mock_policy_id, mock_policy_id_2,
  mock_policy_id_3, mock_policy_id_4, mock_policy_id_5, mock_utxo_ref,
}
use aiken_content_ownership/types.{
  ContentRegistryDatum, CreateContent, CreateOwnershipRecord,
  OwnershipRegistryDatum, StopContentRegistry, TransferOwnership,
}
use aiken_content_ownership/utils.{get_registry_token_name}
use aiken_content_ownership/validators/ownership_registry.{
  ownership_registry_logic,
}

type CreateTestCase {
  has_input_from_content_registry: Bool,
  is_content_registry_redeemer_correct: Bool,
}

fn make_mock_tx_body_for_create(
  record_count: Int,
  content_registry: Dict<Int, ByteArray>,
  ownership_registry: Dict<Int, (PolicyId, AssetName)>,
  content_hash: ByteArray,
  owner: (PolicyId, AssetName),
  test_case: CreateTestCase,
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
      |> if test_case.has_input_from_content_registry {
           dict.insert(
             _,
             Spend(mock_utxo_ref(1)),
             content_redeemer,
             compare_output_reference,
           )
         } else {
           fn(x) { x }
         }

  let content_input =
    if test_case.has_input_from_content_registry {
      [
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
      ]
    } else {
      []
    }

  let content_output =
    if test_case.has_input_from_content_registry {
      [
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
      ]
    } else {
      []
    }

  let inputs =
    list.push(
      content_input,
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
    )
  let outputs =
    list.push(
      content_output,
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
    )

  Transaction {
    ..placeholder(),
    reference_inputs: [
      Input {
        output_reference: mock_utxo_ref(0),
        output: mock_oracle_output(mock_oracle_datum()),
      },
    ],
    inputs: inputs,
    outputs: outputs,
    redeemers: redeemers,
  }
}

fn create_base_case(test_case: CreateTestCase) {
  let redeemer = CreateOwnershipRecord
  let dat = OwnershipRegistryDatum { count: 0, registry: dict.new() }
  let content_hash = "QmWBaeu6y1zEcKbsEqCuhuDHPL3W8pZouCPdafMCRCSUWk"
  let owner = (mock_policy_id_4(), "my_token_name")
  let tx =
    make_mock_tx_body_for_create(
      0,
      dict.new(),
      dict.new(),
      content_hash,
      owner,
      test_case,
    )
  let ctx = ScriptContext { purpose: Spend(mock_utxo_ref(2)), transaction: tx }
  ownership_registry_logic(mock_policy_id(), dat, redeemer, ctx)
}

test success_create_ownership_record() {
  create_base_case(
    CreateTestCase {
      has_input_from_content_registry: True,
      is_content_registry_redeemer_correct: True,
    },
  )
}

test fail_create_ownership_record_without_content_input() {
  !create_base_case(
    CreateTestCase {
      has_input_from_content_registry: False,
      is_content_registry_redeemer_correct: True,
    },
  )
}

test fail_create_ownership_record_with_incorrect_redeemer() {
  !create_base_case(
    CreateTestCase {
      has_input_from_content_registry: True,
      is_content_registry_redeemer_correct: False,
    },
  )
}

type UpdateTestCase {
  is_original_owner_authorized: Bool,
  is_registry_updated: Bool,
  is_registry_value_clean: Bool,
}

fn make_mock_tx_body_for_update(
  record_count: Int,
  ownership_registry: Dict<Int, (PolicyId, AssetName)>,
  original_owner: (PolicyId, AssetName),
  new_owner: (PolicyId, AssetName),
  test_case: UpdateTestCase,
) -> Transaction {
  let ownership_registry_value =
    from_asset(mock_policy_id_3(), get_registry_token_name(0), 1)
      |> add(#"", #"", 2_000_000)
  let auth_token =
    if test_case.is_original_owner_authorized {
      original_owner
    } else {
      new_owner
    }
  let original_owner_output =
    Output {
      ..mock_output(),
      value: mock_output().value
        |> add(auth_token.1st, auth_token.2nd, 1)
        |> if test_case.is_registry_value_clean {
             add(_, #"", #"", 2_000_000)
           } else {
             add(_, mock_policy_id_4(), "another_token", 1)
           },
    }
  let inputs =
    [
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
      Input {
        output_reference: mock_utxo_ref(3),
        output: original_owner_output,
      },
    ]

  let outputs =
    [
      Output {
        ..mock_ownership_registry_output(
          0,
          OwnershipRegistryDatum {
            count: record_count,
            registry: if test_case.is_registry_updated {
              dict.insert(
                ownership_registry,
                record_count,
                new_owner,
                int.compare,
              )
            } else {
              ownership_registry
            },
          },
        ),
        value: if test_case.is_registry_value_clean {
          ownership_registry_value
        } else {
          ownership_registry_value
            |> add(mock_policy_id_4(), "another_token", 1)
        },
      },
      original_owner_output,
    ]

  Transaction {
    ..placeholder(),
    reference_inputs: [
      Input {
        output_reference: mock_utxo_ref(0),
        output: mock_oracle_output(mock_oracle_datum()),
      },
    ],
    inputs: inputs,
    outputs: outputs,
  }
}

fn update_base_case(test_case: UpdateTestCase) {
  let current_registry =
    dict.new()
      |> dict.insert(0, (mock_policy_id(), "my_token_name"), int.compare)
      |> dict.insert(1, (mock_policy_id(), "my_token_name"), int.compare)
      |> dict.insert(2, (mock_policy_id(), "my_token_name"), int.compare)
      |> dict.insert(3, (mock_policy_id(), "my_token_name"), int.compare)
      |> dict.insert(4, (mock_policy_id_4(), "my_token_name"), int.compare)
      |> dict.insert(5, (mock_policy_id(), "my_token_name"), int.compare)
  let dat = OwnershipRegistryDatum { count: 0, registry: current_registry }
  let original_owner = (mock_policy_id_4(), "my_token_name")
  let new_owner = (mock_policy_id_5(), "my_another_token_name")
  let tx =
    make_mock_tx_body_for_update(
      4,
      current_registry,
      original_owner,
      new_owner,
      test_case,
    )
  let redeemer =
    TransferOwnership { new_owner_token: new_owner, content_number: 4 }
  let ctx = ScriptContext { purpose: Spend(mock_utxo_ref(2)), transaction: tx }
  ownership_registry_logic(mock_policy_id(), dat, redeemer, ctx)
}

test success_update_ownership_record() {
  update_base_case(
    UpdateTestCase {
      is_original_owner_authorized: True,
      is_registry_updated: True,
      is_registry_value_clean: True,
    },
  )
}

test fail_update_ownership_record_without_auth_token() {
  !update_base_case(
    UpdateTestCase {
      is_original_owner_authorized: False,
      is_registry_updated: True,
      is_registry_value_clean: True,
    },
  )
}

test fail_update_ownership_record_without_registry_update() {
  !update_base_case(
    UpdateTestCase {
      is_original_owner_authorized: True,
      is_registry_updated: False,
      is_registry_value_clean: True,
    },
  )
}

test fail_update_ownership_record_without_clean_registry_value() {
  !update_base_case(
    UpdateTestCase {
      is_original_owner_authorized: True,
      is_registry_updated: True,
      is_registry_value_clean: False,
    },
  )
}
