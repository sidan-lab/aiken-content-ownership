use aiken/transaction.{InlineDatum, Output, ScriptContext, Spend, Transaction}
use aiken_content_ownership/common.{
  all_key_signed, key_signed, only_minted_token, outputs_at_with,
}
use aiken_content_ownership/types.{
  CreateContentRegistry, CreateOwnershipRegistry, OracleDatum, RotateKey,
  StopApp,
}
use aiken_content_ownership/utils.{get_registry_token_name}

pub fn oracle_validator_logic(datum, redeemer, context) {
  let ScriptContext { purpose, transaction } = context
  when purpose is {
    Spend(_) -> {
      let Transaction { outputs, mint, extra_signatories, .. } = transaction
      let OracleDatum {
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
          only_minted_token(
            mint,
            content_registry_ref_token,
            get_registry_token_name(content_registry_count),
            1,
          )

        CreateOwnershipRegistry ->
          // Ref token is minted
          only_minted_token(
            mint,
            ownership_registry_ref_token,
            get_registry_token_name(ownership_registry_count),
            1,
          )
        RotateKey { new_operation_key, new_stop_key } -> {
          // Sign by both ops and stop key
          expect [own_output] =
            outputs_at_with(outputs, oracle_address, oracle_nft, "")
          expect InlineDatum(dat) = own_output.datum
          expect own_datum: OracleDatum = dat
          let datum_correct =
            own_datum == OracleDatum {
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
          key_signed(extra_signatories, stop_key) && only_minted_token(
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
