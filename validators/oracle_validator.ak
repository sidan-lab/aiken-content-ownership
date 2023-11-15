use aiken/transaction.{ScriptContext, Spend}
use aiken/transaction/credential.{Address, Credential}
use aiken/transaction/value.{PolicyId}

type Datum {
  content_registry_address: Address,
  content_registry_ref_token: PolicyId,
  ownership_registry_address: Address,
  ownership_registry_ref_token: PolicyId,
  content_registry_count: Int,
  ownership_registry_count: Int,
  operation_key: Credential,
  stop_key: Credential,
}

type Redeemer {
  CreateContentRegistry
  CreateOwnershipRegistry
  RotateKey { new_operation_key: Credential, new_stop_key: Credential }
  StopApp
}

validator {
  fn oracle_validator(datum: Datum, redeemer: Redeemer, context: ScriptContext) {
    let ScriptContext { purpose, transaction } = context
    when purpose is {
      Spend(_) ->
        when redeemer is {
          CreateContentRegistry ->
            // Ref token is minted to address
            // count + 1
            True
          CreateOwnershipRegistry ->
            // Ref token is minted to address
            // count + 1
            True
          RotateKey { new_operation_key, new_stop_key } ->
            // Sign by both ops and stop key
            // datum update correctly (key rotated)
            True
          StopApp ->
            // signed by stop key
            True
        }
      _ -> False
    }
  }
}
