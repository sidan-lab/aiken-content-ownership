use aiken/list
use aiken/transaction.{Input, Mint, ScriptContext, Transaction}

type Redeemer {
  RMint
  RBurn
}

validator(utxo_ref: ByteArray) {
  fn one_time_minting_policy(redeemer: Redeemer, context: ScriptContext) -> Bool {
    let ScriptContext { purpose, transaction } = context
    when purpose is {
      Mint(_) ->
        when redeemer is {
          RMint -> {
            let Transaction { inputs, .. } = transaction
            let hash_equal =
              fn(input: Input) {
                let hash = input.output_reference.transaction_id.hash
                utxo_ref == hash
              }
            let target_input_exist = list.find(inputs, hash_equal)
            when target_input_exist is {
              Some(_) -> True
              None -> False
            }
          }
          RBurn -> True
        }
      _ -> False
    }
  }
}
