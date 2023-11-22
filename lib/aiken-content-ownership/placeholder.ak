use aiken/transaction.{NoDatum, Output, OutputReference, TransactionId}
use aiken/transaction/credential.{Address,
  Credential, VerificationKeyCredential}
use aiken/transaction/value.{PolicyId, from_lovelace}

pub fn mock_policy_id() -> PolicyId {
  #"1c1b7afe8affbee1505cf3ec5a58bd2734d4ffdfcc9b9f059625bd76"
}

pub fn mock_policy_id_2() -> PolicyId {
  #"1c1b7afe8affbee1505cf3ec5a58bd2734d4ffdfcc9b9f059625bd77"
}

pub fn mock_utxo_ref(output_index: Int) -> OutputReference {
  OutputReference {
    transaction_id: TransactionId(
      #"5a077cbcdffb88b104f292aacb9687ce93e2191e103a30a0cc5505c18b719f98",
    ),
    output_index,
  }
}

pub fn mock_output() -> Output {
  Output {
    address: Address {
      payment_credential: VerificationKeyCredential(""),
      stake_credential: None,
    },
    value: from_lovelace(1000000),
    datum: NoDatum,
    reference_script: None,
  }
}

pub fn mock_verfication_key_credential() -> Credential {
  VerificationKeyCredential(
    #"e822178d3ceaeef383a84cbd41a702b3837360bf889aaac714e6f380731d20d4",
  )
}
