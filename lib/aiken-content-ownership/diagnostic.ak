// use aiken/cbor.{serialise}
// use aiken_content_ownership/placeholder.{mock_utxo_ref}
use aiken_content_ownership/utils.{get_registry_token_name}

test diag() {
  // serialise(mock_utxo_ref(0)) == #"d8799fd8799f58205a077cbcdffb88b104f292aacb9687ce93e2191e103a30a0cc5505c18b719f98ff00ff"
  // serialise(mock_utxo_ref(1)) == #"d8799fd8799f58205a077cbcdffb88b104f292aacb9687ce93e2191e103a30a0cc5505c18b719f98ff01ff"
  // serialise(mock_verfication_key_credential()) == #"d8799f5820e822178d3ceaeef383a84cbd41a702b3837360bf889aaac714e6f380731d20d4ff"
  "Registry (0)" == get_registry_token_name(0)
}
