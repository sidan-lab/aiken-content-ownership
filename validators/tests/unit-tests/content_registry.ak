use aiken/dict.{Dict}
use aiken/int
use aiken/transaction.{
  Input, Output, ScriptContext, Spend, Transaction, placeholder,
}
use aiken/transaction/value.{
  AssetName, PolicyId, add, from_asset, negate, to_minted_value, zero,
}
use aiken_content_ownership/placeholder.{
  mock_content_registry_datum, mock_content_registry_output, mock_oracle_datum,
  mock_oracle_output, mock_output, mock_ownership_registry_output,
  mock_policy_id, mock_policy_id_2, mock_policy_id_3, mock_policy_id_4,
  mock_utxo_ref,
}
use aiken_content_ownership/types.{
  ContentRegistryDatum, CreateContent, OwnershipRegistryDatum,
  StopContentRegistry,
}
use aiken_content_ownership/utils.{get_registry_token_name}
use aiken_content_ownership/validators/content_registry.{content_registry_logic}

type TestCase {
  is_content_count_updated: Bool,
  is_ownership_count_updated: Bool,
  is_content_registry_updated: Bool,
  is_ownership_registry_updated: Bool,
  is_content_ref_respent: Bool,
  is_ownership_ref_respent: Bool,
  is_content_registry_value_clean: Bool,
  is_ownership_registry_value_clean: Bool,
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
  }
}

fn make_mock_tx_body(
  record_count: Int,
  content_registry: Dict<Int, ByteArray>,
  ownership_registry: Dict<Int, (PolicyId, AssetName)>,
  content_hash: ByteArray,
  owner: (PolicyId, AssetName),
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
      dict.insert(content_registry, record_count, content_hash, int.compare)
    } else {
      content_registry
    }
  let new_ownership_registry =
    if is_ownership_registry_updated {
      dict.insert(ownership_registry, record_count, owner, int.compare)
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
  }
}

fn run_content_registry_test(test_case: TestCase) -> Bool {
  let content_hash = "QmWBaeu6y1zEcKbsEqCuhuDHPL3W8pZouCPdafMCRCSUWk"
  let owner = (mock_policy_id_4(), "my_token_name")
  let transaction =
    make_mock_tx_body(0, dict.new(), dict.new(), content_hash, owner, test_case)
  let dat = mock_content_registry_datum(0, dict.new())
  let ctx = ScriptContext { purpose: Spend(mock_utxo_ref(1)), transaction }
  content_registry_logic(
    mock_policy_id(),
    dat,
    CreateContent { content_hash, owner },
    ctx,
  )
}

test success_create_content() {
  run_content_registry_test(default_test_case())
}

test fail_create_content_content_count_not_updated() {
  let test_case =
    TestCase { ..default_test_case(), is_content_count_updated: False }
  !run_content_registry_test(test_case)
}

test fail_create_content_ownership_count_not_updated() {
  let test_case =
    TestCase { ..default_test_case(), is_ownership_count_updated: False }
  !run_content_registry_test(test_case)
}

test fail_create_content_content_registry_not_updated() {
  let test_case =
    TestCase { ..default_test_case(), is_content_registry_updated: False }
  !run_content_registry_test(test_case)
}

test fail_create_content_ownership_registry_not_updated() {
  let test_case =
    TestCase { ..default_test_case(), is_ownership_registry_updated: False }
  !run_content_registry_test(test_case)
}

test fail_create_content_content_ref_not_respent() {
  let test_case =
    TestCase { ..default_test_case(), is_content_ref_respent: False }
  !run_content_registry_test(test_case)
}

test fail_create_content_ownership_ref_not_respent() {
  let test_case =
    TestCase { ..default_test_case(), is_ownership_ref_respent: False }
  !run_content_registry_test(test_case)
}

test fail_create_content_content_registry_value_unclean() {
  let test_case =
    TestCase { ..default_test_case(), is_content_registry_value_clean: False }
  !run_content_registry_test(test_case)
}

test fail_create_content_ownership_registry_value_unclean() {
  let test_case =
    TestCase { ..default_test_case(), is_ownership_registry_value_clean: False }
  !run_content_registry_test(test_case)
}

type StopTestCase {
  is_stop_key_signed: Bool,
  is_ref_token_burned: Bool,
}

fn make_mock_tx_body_for_stop(test_case: StopTestCase) {
  let registry_token_value =
    from_asset(mock_policy_id_2(), get_registry_token_name(0), 1)
  let mint =
    if test_case.is_ref_token_burned {
      to_minted_value(negate(registry_token_value))
    } else {
      to_minted_value(zero())
    }

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
            ContentRegistryDatum { count: 0, registry: dict.new() },
          ),
          value: registry_token_value |> add(#"", #"", 2_000_000),
        },
      },
    ],
    outputs: [
      Output {
        ..mock_output(),
        value: if test_case.is_ref_token_burned {
          zero()
        } else {
          registry_token_value
        }
          |> add(#"", #"", 2_000_000),
      },
    ],
    extra_signatories: [
      if test_case.is_stop_key_signed {
        mock_oracle_datum().stop_key
      } else {
        mock_oracle_datum().operation_key
      },
    ],
    mint: mint,
  }
}

fn stop_base_case(test_case: StopTestCase) {
  let current_registry = dict.new()
  let dat = ContentRegistryDatum { count: 0, registry: current_registry }
  let tx = make_mock_tx_body_for_stop(test_case)
  let redeemer = StopContentRegistry
  let ctx = ScriptContext { purpose: Spend(mock_utxo_ref(1)), transaction: tx }
  content_registry_logic(mock_policy_id(), dat, redeemer, ctx)
}

test success_stop_registry() {
  stop_base_case(
    StopTestCase { is_stop_key_signed: True, is_ref_token_burned: True },
  )
}

test fail_stop_registry_without_stop_key() {
  !stop_base_case(
    StopTestCase { is_stop_key_signed: False, is_ref_token_burned: True },
  )
}

test fail_stop_registry_without_ref_token_burned() {
  !stop_base_case(
    StopTestCase { is_stop_key_signed: True, is_ref_token_burned: False },
  )
}
