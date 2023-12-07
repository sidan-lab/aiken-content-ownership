use aiken/cbor.{serialise}
use aiken/transaction.{OutputReference, TransactionId}

// use aiken_content_ownership/placeholder.{mock_utxo_ref}
// use aiken_content_ownership/utils.{get_registry_token_name}

pub fn utxo_ref() -> OutputReference {
  OutputReference {
    transaction_id: TransactionId(
      #"3fbdf2b0b4213855dd9b87f7c94a50cf352ba6edfdded85ecb22cf9ceb75f814",
    ),
    output_index: 6,
  }
}

test diag() {
  serialise(utxo_ref()) == #"d8799fd8799f58203fbdf2b0b4213855dd9b87f7c94a50cf352ba6edfdded85ecb22cf9ceb75f814ff06ff"
  // serialise(mock_utxo_ref(1)) == #"d8799fd8799f58205a077cbcdffb88b104f292aacb9687ce93e2191e103a30a0cc5505c18b719f98ff01ff"
  // serialise(mock_verfication_key_credential()) == #"d8799f5820e822178d3ceaeef383a84cbd41a702b3837360bf889aaac714e6f380731d20d4ff"
  // "Registry (0)" == get_registry_token_name(0)
}
