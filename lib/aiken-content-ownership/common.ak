use aiken/bytearray
use aiken/list
use aiken/transaction.{Input, Output}
use aiken/transaction/credential.{Address}
use aiken/transaction/value.{
  AssetName, MintedValue, PolicyId, Value, flatten, from_minted_value,
  quantity_of,
}

pub fn inputs_at(inputs: List<Input>, address: Address) -> List<Input> {
  list.filter(inputs, fn(input) { input.output.address == address })
}

pub fn inputs_with(
  inputs: List<Input>,
  policy: PolicyId,
  name: AssetName,
) -> List<Input> {
  list.filter(
    inputs,
    fn(input) { quantity_of(input.output.value, policy, name) == 1 },
  )
}

pub fn inputs_at_with(
  inputs: List<Input>,
  address: Address,
  policy: PolicyId,
  name: AssetName,
) -> List<Input> {
  list.filter(
    inputs,
    fn(input) {
      input.output.address == address && quantity_of(
        input.output.value,
        policy,
        name,
      ) == 1
    },
  )
}

pub fn inputs_at_with_policy(
  inputs: List<Input>,
  address: Address,
  policy: PolicyId,
) -> List<Input> {
  list.filter(
    inputs,
    fn(input) {
      input.output.address == address && list.any(
        flatten(input.output.value),
        fn(token) { token.1st == policy },
      )
    },
  )
}

pub fn outputs_at(outputs: List<Output>, address: Address) -> List<Output> {
  list.filter(outputs, fn(output) { output.address == address })
}

pub fn outputs_with(outputs: List<Output>, policy: PolicyId, name: AssetName) {
  list.filter(
    outputs,
    fn(output) { quantity_of(output.value, policy, name) == 1 },
  )
}

pub fn outputs_at_with(
  outputs: List<Output>,
  address: Address,
  policy: PolicyId,
  name: AssetName,
) -> List<Output> {
  list.filter(
    outputs,
    fn(output) {
      output.address == address && quantity_of(output.value, policy, name) == 1
    },
  )
}

pub fn outputs_at_with_policy(
  outputs: List<Output>,
  address: Address,
  policy: PolicyId,
) -> List<Output> {
  list.filter(
    outputs,
    fn(output) {
      output.address == address && list.any(
        flatten(output.value),
        fn(token) { token.1st == policy },
      )
    },
  )
}

pub fn check_policy_only_burn(mint: MintedValue, policy: PolicyId) -> Bool {
  let burn_value = flatten(from_minted_value(mint))
  list.all(
    burn_value,
    fn(x) {
      if x.1st == policy {
        x.3rd < 0
      } else {
        True
      }
    },
  )
}

pub fn only_minted_token(
  mint: MintedValue,
  policy: PolicyId,
  name: AssetName,
  quantity: Int,
) {
  expect [(mPolicy, mAssetName, mQuantity)] =
    from_minted_value(mint) |> flatten()
  mPolicy == policy && mAssetName == name && mQuantity == quantity
}

pub fn convert_int_to_bytes(i: Int) -> ByteArray {
  convert_int_to_bytes_go(i, get_number_digit(i))
}

fn convert_int_to_bytes_go(newInt: Int, digit: Int) -> ByteArray {
  if digit == 1 {
    bytearray.push("", newInt + 48)
  } else {
    bytearray.push(
      convert_int_to_bytes_go(newInt % digit, digit / 10),
      newInt / digit + 48,
    )
  }
}

pub fn get_number_digit(i: Int) -> Int {
  go_get_number_digit(i, 1)
}

fn go_get_number_digit(newInt: Int, digit: Int) -> Int {
  if newInt < 10 {
    digit
  } else {
    go_get_number_digit(newInt / 10, digit * 10)
  }
}

pub fn key_signed(witnesses: List<ByteArray>, key: ByteArray) {
  list.has(witnesses, key)
}

pub fn all_key_signed(witnesses: List<ByteArray>, keys: List<ByteArray>) {
  list.all(keys, fn(key) { key_signed(witnesses, key) })
}

pub fn value_length(value: Value) -> Int {
  list.length(flatten(value))
}

test byte_conversion() {
  convert_int_to_bytes(1) == "1" && convert_int_to_bytes(123) == "123" && convert_int_to_bytes(
    672912,
  ) == "672912"
}
