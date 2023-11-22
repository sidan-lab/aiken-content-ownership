use aiken/transaction.{InlineDatum, ScriptContext, Spend, Transaction}
use aiken/transaction/credential.{Address}
use aiken/transaction/value.{PolicyId}
use aiken_content_ownership/common.{
  all_key_signed, key_signed, onlyMintedToken, utxos_at_with,
}
use aiken_content_ownership/utils.{get_registry_token_name}

type Datum {
  oracle_nft: PolicyId,
  oracle_address: Address,
  content_registry_address: Address,
  content_registry_ref_token: PolicyId,
  ownership_registry_address: Address,
  ownership_registry_ref_token: PolicyId,
  content_registry_count: Int,
  ownership_registry_count: Int,
  operation_key: ByteArray,
  stop_key: ByteArray,
}

type Redeemer {
  CreateContentRegistry
  CreateOwnershipRegistry
  RotateKey { new_operation_key: ByteArray, new_stop_key: ByteArray }
  StopApp
}

validator {
  fn oracle_validator(datum: Datum, redeemer: Redeemer, context: ScriptContext) {
    let ScriptContext { purpose, transaction } = context
    when purpose is {
      Spend(_) -> {
        let Transaction { outputs, mint, extra_signatories, .. } = transaction
        let Datum {
          oracle_nft,
          oracle_address,
          content_registry_ref_token,
          content_registry_count,
          ownership_registry_ref_token,
          ownership_registry_count,
          operation_key,
          stop_key,
          ..
        } = datum

        when redeemer is {
          CreateContentRegistry ->
            // Ref token is minted
            onlyMintedToken(
              mint,
              content_registry_ref_token,
              get_registry_token_name(content_registry_count),
              1,
            )

          CreateOwnershipRegistry ->
            // Ref token is minted
            onlyMintedToken(
              mint,
              ownership_registry_ref_token,
              get_registry_token_name(ownership_registry_count),
              1,
            )
          RotateKey { new_operation_key, new_stop_key } -> {
            // Sign by both ops and stop key
            expect [own_output] =
              utxos_at_with(outputs, oracle_address, oracle_nft, "")
            expect InlineDatum(dat) = own_output.datum
            expect own_datum: Datum = dat
            let datum_correct =
              own_datum == Datum {
                ..datum,
                operation_key: new_operation_key,
                stop_key: new_stop_key,
              }
            all_key_signed(extra_signatories, [operation_key, stop_key]) && datum_correct
          }

          // datum update correctly (key rotated)
          StopApp ->
            // signed by stop key
            // oracle nft is burned
            key_signed(extra_signatories, stop_key) && onlyMintedToken(
              mint,
              oracle_nft,
              "",
              -1,
            )
        }
      }
      _ -> False
    }
  }
}
