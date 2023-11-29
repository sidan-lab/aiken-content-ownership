use aiken/dict.{Dict}
use aiken/transaction/credential.{Address}
use aiken/transaction/value.{AssetName, PolicyId}

pub type MintPolarity {
  RMint
  RBurn
}

pub type OracleDatum {
  oracle_nft: PolicyId,
  oracle_address: Address,
  content_registry_ref_token: PolicyId,
  content_registry_address: Address,
  content_registry_count: Int,
  ownership_registry_ref_token: PolicyId,
  ownership_registry_address: Address,
  ownership_registry_count: Int,
  operation_key: ByteArray,
  stop_key: ByteArray,
}

pub type OracleRedeemer {
  CreateContentRegistry
  CreateOwnershipRegistry
  RotateKey { new_operation_key: ByteArray, new_stop_key: ByteArray }
  StopApp
}

pub type ContentRegistryDatum {
  count: Int,
  registry: Dict<Int, ByteArray>,
}

pub type ContentRegistryRedeemer {
  CreateContent { content_hash: ByteArray, owner: (PolicyId, AssetName) }
  UpdateContent { new_content_hash: ByteArray, content_number: Int }
  StopContentRegistry
}

pub type OwnershipRegistryDatum {
  count: Int,
  registry: Dict<Int, (PolicyId, AssetName)>,
}

pub type OwnershipRegistryRedeemer {
  CreateOwnershipRecord
  TransferOwnership {
    new_owner_token: (PolicyId, AssetName),
    content_number: Int,
  }
  StopOwnershipRegistry
}
