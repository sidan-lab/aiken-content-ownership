use aiken/bytearray
use aiken/list
use aiken/transaction.{Output}
use aiken/transaction/credential.{Address}
use aiken/transaction/value.{
  AssetName, MintedValue, PolicyId, flatten, from_minted_value, quantity_of,
}

pub fn utxos_at(outputs: List<Output>, address: Address) {
  list.filter(outputs, fn(output) { output.address == address })
}

pub fn utxos_at_with(
  outputs: List<Output>,
  address: Address,
  policy: PolicyId,
  name: AssetName,
) {
  list.filter(
    outputs,
    fn(output) {
      output.address == address && quantity_of(output.value, policy, name) == 1
    },
  )
}

pub fn onlyMintedToken(
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

test byte_conversion() {
  convert_int_to_bytes(1) == "1" && convert_int_to_bytes(123) == "123" && convert_int_to_bytes(
    672912,
  ) == "672912"
}

pub fn key_signed(witnesses: List<ByteArray>, key: ByteArray) {
  list.has(witnesses, key)
}

pub fn all_key_signed(witnesses: List<ByteArray>, keys: List<ByteArray>) {
  list.all(keys, fn(key) { key_signed(witnesses, key) })
}
