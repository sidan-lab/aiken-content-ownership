use aiken/transaction.{NoDatum, Output, OutputReference, TransactionId}
use aiken/transaction/credential.{
  Address, Credential, ScriptCredential, VerificationKeyCredential,
}
use aiken/transaction/value.{PolicyId, from_lovelace}

pub fn mock_policy_id() -> PolicyId {
  #"1c1b7afe8affbee1505cf3ec5a58bd2734d4ffdfcc9b9f059625bd76"
}

pub fn mock_policy_id_2() -> PolicyId {
  #"52e322a5dd87fe977c5ee5b91e3f42eedeccd6795a7ef4f158bd8892"
}

pub fn mock_policy_id_3() -> PolicyId {
  #"a15cd6051ea2fc92c034b0bb1d33f2b7ba7ac92277e6ee5c30ab19a4"
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

// Pub Key Addresses

pub fn mock_vkey_hex() -> ByteArray {
  #"a2c20c77887ace1cd986193e4e75babd8993cfd56995cd5cfce609c2"
}

pub fn mock_verfication_key_credential() -> Credential {
  VerificationKeyCredential(mock_vkey_hex())
}

pub fn mock_pub_key_address(stake_credential) -> Address {
  Address {
    payment_credential: mock_verfication_key_credential(),
    stake_credential,
  }
}

pub fn mock_vkey_hex_2() -> ByteArray {
  #"e2cfca46ecdf7feb8a3a7f957ead86b88c156f3fdd9607bcb44eb8f5"
}

pub fn mock_verfication_key_credential_2() -> Credential {
  VerificationKeyCredential(mock_vkey_hex_2())
}

pub fn mock_pub_key_address_2(stake_credential) -> Address {
  Address {
    payment_credential: mock_verfication_key_credential_2(),
    stake_credential,
  }
}

// Script Addresses

pub fn mock_script_hex() -> ByteArray {
  #"70ce90786897b6f7b6430a57ae005ecaf7c8cab817dd7510598403a9"
}

pub fn mock_script_credential() -> Credential {
  ScriptCredential(mock_script_hex())
}

pub fn mock_script_address(stake_credential) -> Address {
  Address {
    payment_credential: ScriptCredential(mock_script_hex()),
    stake_credential,
  }
}

pub fn mock_script_hex_2() -> ByteArray {
  #"efa5288b2b13cff1db555eed5debc54f3b25a62b7321db37f8af9213"
}

pub fn mock_script_credential_2() -> Credential {
  ScriptCredential(mock_script_hex_2())
}

pub fn mock_script_address_2(stake_credential) -> Address {
  Address {
    payment_credential: ScriptCredential(mock_script_hex_2()),
    stake_credential,
  }
}

pub fn mock_script_hex_3() -> ByteArray {
  #"a8ba4d8ab8d7f1f864a27a63dab1185cc47929dc3c3a34956d946286"
}

pub fn mock_script_credential_3() -> Credential {
  ScriptCredential(mock_script_hex_3())
}

pub fn mock_script_address_3(stake_credential) -> Address {
  Address {
    payment_credential: ScriptCredential(mock_script_hex_3()),
    stake_credential,
  }
}
