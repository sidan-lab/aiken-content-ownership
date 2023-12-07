use aiken/dict
use aiken/list
use aiken/transaction.{
  Input, Output, ScriptContext, Spend, Transaction, placeholder,
}
use aiken/transaction/value.{add, from_asset, zero}
use aiken_content_ownership/common.{compare_output_reference}
use aiken_content_ownership/placeholder.{
  mock_content_registry_datum, mock_content_registry_output, mock_oracle_datum,
  mock_oracle_output, mock_ownership_registry_datum,
  mock_ownership_registry_output, mock_policy_id, mock_policy_id_2,
  mock_policy_id_3, mock_policy_id_4, mock_utxo_ref,
}
use aiken_content_ownership/types.{
  ContentRegistryDatum, CreateContent, CreateOwnershipRecord,
  OwnershipRegistryDatum, StopContentRegistry,
}
use aiken_content_ownership/utils.{get_registry_token_name}
use aiken_content_ownership/validators/content_registry.{content_registry_logic}
use aiken_content_ownership/validators/ownership_registry.{
  ownership_registry_logic,
}

type TestCase {
  is_content_count_updated: Bool,
  is_ownership_count_updated: Bool,
  is_content_registry_updated: Bool,
  is_ownership_registry_updated: Bool,
  is_content_ref_respent: Bool,
  is_ownership_ref_respent: Bool,
  is_content_registry_value_clean: Bool,
  is_ownership_registry_value_clean: Bool,
  is_content_registry_redeemer_correct: Bool,
}

fn default_test_case() -> TestCase {
  TestCase {
    is_content_count_updated: True,
    is_ownership_count_updated: True,
    is_content_registry_updated: True,
    is_ownership_registry_updated: True,
    is_content_ref_respent: True,
    is_ownership_ref_respent: True,
    is_content_registry_value_clean: True,
    is_ownership_registry_value_clean: True,
    is_content_registry_redeemer_correct: True,
  }
}

fn make_mock_tx_body(
  record_count: Int,
  content_registry: List<ByteArray>,
  ownership_registry: List<List<ByteArray>>,
  content_hash: ByteArray,
  owner: List<ByteArray>,
  test_case: TestCase,
) -> Transaction {
  let TestCase {
    is_content_count_updated,
    is_ownership_count_updated,
    is_content_registry_updated,
    is_ownership_registry_updated,
    is_content_ref_respent,
    is_ownership_ref_respent,
    is_content_registry_value_clean,
    is_ownership_registry_value_clean,
    is_content_registry_redeemer_correct,
  } = test_case
  let new_content_count =
    if is_content_count_updated {
      record_count + 1
    } else {
      record_count
    }
  let new_ownership_count =
    if is_ownership_count_updated {
      record_count + 1
    } else {
      record_count
    }
  let new_content_registry =
    if is_content_registry_updated {
      list.concat(content_registry, [content_hash])
    } else {
      content_registry
    }
  let new_ownership_registry =
    if is_ownership_registry_updated {
      list.concat(ownership_registry, [owner])
    } else {
      ownership_registry
    }
  let content_registry_value =
    when (is_content_ref_respent, is_content_registry_value_clean) is {
      (True, True) ->
        from_asset(mock_policy_id_2(), get_registry_token_name(0), 1)
      (True, False) ->
        from_asset(mock_policy_id_2(), get_registry_token_name(0), 1)
          |> add(mock_policy_id_3(), "123", 1)
      (False, True) -> zero()
      (False, False) -> from_asset(mock_policy_id_3(), "123", 1)
    }
      |> add(#"", #"", 2_000_000)

  let ownership_registry_value =
    when (is_ownership_ref_respent, is_ownership_registry_value_clean) is {
      (True, True) ->
        from_asset(mock_policy_id_3(), get_registry_token_name(0), 1)
      (True, False) ->
        from_asset(mock_policy_id_3(), get_registry_token_name(0), 1)
          |> add(mock_policy_id_2(), "123", 1)
      (False, True) -> zero()
      (False, False) -> from_asset(mock_policy_id_2(), "123", 1)
    }
      |> add(#"", #"", 2_000_000)

  let content_redeemer: Data =
    if is_content_registry_redeemer_correct {
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
            count: new_content_count,
            registry: new_content_registry,
          },
        ),
        value: content_registry_value,
      },
      Output {
        ..mock_ownership_registry_output(
          0,
          OwnershipRegistryDatum {
            count: new_ownership_count,
            registry: new_ownership_registry,
          },
        ),
        value: ownership_registry_value,
      },
    ],
    redeemers: redeemers,
  }
}

fn run_create_content_test(test_case: TestCase) -> Bool {
  let content_hash =
    #"5260e5bd0791d38438b891514d6158b5306884e9b7f4ef4b6433c6943285776c"
  let owner =
    [mock_policy_id_4(), "my_token_name"]
  let transaction = make_mock_tx_body(0, [], [], content_hash, owner, test_case)
  let content_dat = mock_content_registry_datum(0, [])
  let ownership_dat = mock_ownership_registry_datum(0, [])
  let ctx = ScriptContext { purpose: Spend(mock_utxo_ref(1)), transaction }
  ownership_registry_logic(
    mock_policy_id(),
    ownership_dat,
    CreateOwnershipRecord,
    ctx,
  ) && content_registry_logic(
    mock_policy_id(),
    content_dat,
    CreateContent { content_hash, owner },
    ctx,
  )
}

test success_create_content() {
  run_create_content_test(default_test_case())
}

test fail_create_content_content_count_not_updated() {
  let test_case =
    TestCase { ..default_test_case(), is_content_count_updated: False }
  !run_create_content_test(test_case)
}

test fail_create_content_ownership_count_not_updated() {
  let test_case =
    TestCase { ..default_test_case(), is_ownership_count_updated: False }
  !run_create_content_test(test_case)
}

test fail_create_content_content_registry_not_updated() {
  let test_case =
    TestCase { ..default_test_case(), is_content_registry_updated: False }
  !run_create_content_test(test_case)
}

test fail_create_content_ownership_registry_not_updated() {
  let test_case =
    TestCase { ..default_test_case(), is_ownership_registry_updated: False }
  !run_create_content_test(test_case)
}

test fail_create_content_content_ref_not_respent() {
  let test_case =
    TestCase { ..default_test_case(), is_content_ref_respent: False }
  !run_create_content_test(test_case)
}

test fail_create_content_ownership_ref_not_respent() {
  let test_case =
    TestCase { ..default_test_case(), is_ownership_ref_respent: False }
  !run_create_content_test(test_case)
}

test fail_create_content_content_registry_value_unclean() {
  let test_case =
    TestCase { ..default_test_case(), is_content_registry_value_clean: False }
  !run_create_content_test(test_case)
}

test fail_create_content_ownership_registry_value_unclean() {
  let test_case =
    TestCase { ..default_test_case(), is_ownership_registry_value_clean: False }
  !run_create_content_test(test_case)
}

test fail_create_content_record_with_incorrect_redeemer() {
  let test_case =
    TestCase {
      ..default_test_case(),
      is_content_registry_redeemer_correct: False,
    }
  !run_create_content_test(test_case)
}

fn create_preloaded_content_registry(
  registry: List<ByteArray>,
  curr: Int,
  size: Int,
) -> List<ByteArray> {
  let content_hash =
    #"5260e5bd0791d38438b891514d6158b5306884e9b7f4ef4b6433c6943285776c"
  let new_registry = list.concat(registry, [content_hash])
  if curr == size {
    new_registry
  } else {
    create_preloaded_content_registry(new_registry, curr + 1, size)
  }
}

fn mock_content_registry_datum_at_scale(size: Int) -> ContentRegistryDatum {
  let registry = create_preloaded_content_registry([], 0, size)
  ContentRegistryDatum { count: size, registry }
}

fn create_preloaded_ownership_registry(
  registry: List<List<ByteArray>>,
  curr: Int,
  size: Int,
) -> List<List<ByteArray>> {
  let owner =
    [mock_policy_id_4(), "my_token_name"]
  let new_registry = list.concat(registry, [owner])
  if curr == size {
    new_registry
  } else {
    create_preloaded_ownership_registry(new_registry, curr + 1, size)
  }
}

fn mock_ownership_registry_datum_at_scale(size: Int) -> OwnershipRegistryDatum {
  let registry = create_preloaded_ownership_registry([], 0, size)
  OwnershipRegistryDatum { count: size, registry }
}

fn run_create_content_at_scale_test(test_case: TestCase) -> Bool {
  let content_hash =
    #"5260e5bd0791d38438b891514d6158b5306884e9b7f4ef4b6433c6943285776c"
  let owner =
    [mock_policy_id_4(), "my_token_name"]
  let content_registry = create_preloaded_content_registry([], 0, 50)
  let ownership_registry = create_preloaded_ownership_registry([], 0, 50)
  let transaction =
    make_mock_tx_body(
      0,
      content_registry,
      ownership_registry,
      content_hash,
      owner,
      test_case,
    )
  let content_dat = mock_content_registry_datum(0, [])
  let ownership_dat = mock_ownership_registry_datum(0, [])
  let ctx = ScriptContext { purpose: Spend(mock_utxo_ref(1)), transaction }
  ownership_registry_logic(
    mock_policy_id(),
    ownership_dat,
    CreateOwnershipRecord,
    ctx,
  ) && content_registry_logic(
    mock_policy_id(),
    content_dat,
    CreateContent { content_hash, owner },
    ctx,
  )
}

test success_create_content_at_scale() {
  run_create_content_at_scale_test(default_test_case())
}
