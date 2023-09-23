import 'solana';

// https://github.com/metaplex-foundation/metaplex-program-library/blob/3a9c68ab8c48318f96379a136feaa9b66c322752/token-metadata/program/src/instruction.rs#L347
// Reference: https://github.com/metaplex-foundation/metaplex-program-library/blob/master/token-metadata/program/src/instruction/metadata.rs#L449
// Solidity does not support Rust Option<> type, so we need to handle it manually
// Requires creating a struct for each combination of Option<> types
// If bool for Option<> type is false, comment out the corresponding struct field otherwise instruction fails with "invalid account data"
// https://github.com/samuelvanderwaal/wtf-is/blob/main/src/errors.rs#L49
library MplMetadata {
	address constant metadataProgramId = address"metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s";
	address constant systemAddress = address"11111111111111111111111111111111";
    address constant rentAddress = address"SysvarRent111111111111111111111111111111111";
    address constant tokenProgramId = address"TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA";

	// Reference: https://github.com/metaplex-foundation/mpl-token-metadata/blob/main/programs/token-metadata/program/src/instruction/metadata.rs#L31
	struct CreateMetadataAccountArgsV3Collection {
        DataV2Collection data;
        bool isMutable;
        bool collectionDetailsPresent;
        CollectionDetails collectionDetails;
    }
    struct CreateMetadataAccountArgsV3Normal {
        DataV2Normal data;
        bool isMutable;
        bool collectionDetailsPresent;
    }

    // Reference: https://github.com/metaplex-foundation/mpl-token-metadata/blob/main/programs/token-metadata/program/src/instruction/edition.rs#L39C12-L39C35
    struct CreateMasterEditionArgsCollection {
        bool maxSupplyOption;
        uint64 maxSupply;
    }
    struct CreateMasterEditionArgsNft {
        bool maxSupplyOption;
    }

	// Reference: https://github.com/metaplex-foundation/mpl-token-metadata/blob/main/clients/rust/src/generated/types/data_v2.rs#L16
    struct DataV2Collection {
        string name;
        string symbol;
        string uri;
        uint16 sellerFeeBasisPoints;
        // https://borsh.io/
        bool creatorsPresent;
        uint32 size;
        Creator creators; 
        bool collectionPresent;
        bool usesPresent;
        // Uses uses;
    }
    struct DataV2Normal {
        string name;
        string symbol;
        string uri;
        uint16 sellerFeeBasisPoints;
        // https://borsh.io/
        bool creatorsPresent;
        uint32 size;
        Creator creators;
        bool collectionPresent;
        Collection collection;
        bool usesPresent;
        // Uses uses;
    }

	// Reference: https://github.com/metaplex-foundation/mpl-token-metadata/blob/main/clients/rust/src/generated/types/creator.rs#L14
    struct Creator {
        address creatorAddress;
        bool verified;
        uint8 share;
    }

	// Reference: https://github.com/metaplex-foundation/metaplex-program-library/blob/master/bubblegum/program/src/state/metaplex_adapter.rs#L66
    struct Collection {
        bool verified;
        address key;
    }

    // Reference: https://github.com/metaplex-foundation/mpl-token-metadata/blob/main/clients/rust/src/generated/types/collection_details.rs#L13
    struct CollectionDetails {
        CollectionDetailsType detailType;
        uint64 size;
    }
    enum CollectionDetailsType {
        V1
    }

	// Reference: https://github.com/metaplex-foundation/metaplex-program-library/blob/master/bubblegum/program/src/state/metaplex_adapter.rs#L43
    struct Uses {
        UseMethod useMethod;
        uint64 remaining;
        uint64 total;
    }

	// Reference: https://github.com/metaplex-foundation/metaplex-program-library/blob/master/bubblegum/program/src/state/metaplex_adapter.rs#L35
    enum UseMethod {
        Burn,
        Multiple,
        Single
    }

    function verify_collection(
        address metadata,
        address collection_authority,
        address payer,
        address collection_mint,
        address collection_metadata,
        address collection_edition
    ) internal {
        AccountMeta[6] metas = [
            AccountMeta({pubkey: metadata, is_writable: true, is_signer: false}),
            AccountMeta({pubkey: collection_authority, is_writable: true, is_signer: true}),
            AccountMeta({pubkey: payer, is_writable: true, is_signer: true}),
            AccountMeta({pubkey: collection_mint, is_writable: false, is_signer: false}),
            AccountMeta({pubkey: collection_metadata, is_writable: false, is_signer: false}),
            AccountMeta({pubkey: collection_edition, is_writable: false, is_signer: false})
        ];

        // https://docs.metaplex.com/programs/token-metadata/instructions#verify-a-collection-item
        bytes1 discriminator = 18;

        metadataProgramId.call{accounts: metas}(discriminator);
    }

    function create_master_edition_v3_collection(
        address edition,
        address mint,
        address payer,
        address metadata
    ) internal {
        CreateMasterEditionArgsCollection args = CreateMasterEditionArgsCollection({
            maxSupplyOption: true,
            maxSupply: 0
        });
        
        AccountMeta[9] metas = [
            AccountMeta({pubkey: edition, is_writable: true, is_signer: false}), // edition
            AccountMeta({pubkey: mint, is_writable: true, is_signer: false}), // mint
            AccountMeta({pubkey: payer, is_writable: false, is_signer: true}), // update authority
            AccountMeta({pubkey: payer, is_writable: false, is_signer: true}), // mint authority
            AccountMeta({pubkey: payer, is_writable: true, is_signer: true}), // payer
            AccountMeta({pubkey: metadata, is_writable: true, is_signer: false}), // metadata
            AccountMeta({pubkey: tokenProgramId, is_writable: false, is_signer: false}), // token 
            AccountMeta({pubkey: systemAddress, is_writable: false, is_signer: false}), // system
            AccountMeta({pubkey: rentAddress, is_writable: false, is_signer: false}) // rent
        ];

        // https://docs.metaplex.com/programs/token-metadata/instructions#create-a-master-edition-account
        bytes1 discriminator = 17;
        bytes instructionData = abi.encode(discriminator, args);

        metadataProgramId.call{accounts: metas}(instructionData);
    }

    function create_master_edition_v3_nft(
        address edition,
        address mint,
        address payer,
        address metadata
    ) internal {
        CreateMasterEditionArgsNft args = CreateMasterEditionArgsNft({
            maxSupplyOption: false
        });
        
        AccountMeta[9] metas = [
            AccountMeta({pubkey: edition, is_writable: true, is_signer: false}), // edition
            AccountMeta({pubkey: mint, is_writable: true, is_signer: false}), // mint
            AccountMeta({pubkey: payer, is_writable: false, is_signer: true}), // update authority
            AccountMeta({pubkey: payer, is_writable: false, is_signer: true}), // mint authority
            AccountMeta({pubkey: payer, is_writable: true, is_signer: true}), // payer
            AccountMeta({pubkey: metadata, is_writable: true, is_signer: false}), // metadata
            AccountMeta({pubkey: tokenProgramId, is_writable: false, is_signer: false}), // token 
            AccountMeta({pubkey: systemAddress, is_writable: false, is_signer: false}), // system
            AccountMeta({pubkey: rentAddress, is_writable: false, is_signer: false}) // rent
        ];

        // https://docs.metaplex.com/programs/token-metadata/instructions#create-a-master-edition-account
        bytes1 discriminator = 17;
        bytes instructionData = abi.encode(discriminator, args);

        metadataProgramId.call{accounts: metas}(instructionData);
    }

    /// Collection NFT
    //  collection = None => collectionMetadata = 0x0
    //  collectionDetails = Some(size = 0) => for initialization
	function create_metadata_account_collection(
		address metadata,
		address mint,
		address payer,
		string name,
		string symbol,
		string uri
	) internal {
        DataV2Collection data = DataV2Collection({
            name: name,
            symbol: symbol,
            uri: uri,
            sellerFeeBasisPoints: 500,
            creatorsPresent: true,
            size: 1,
            creators: Creator({
                creatorAddress: payer,
                verified: true,
                share: 100
            }),
            collectionPresent: false,
            usesPresent: false
        });

        CreateMetadataAccountArgsV3Collection args = CreateMetadataAccountArgsV3Collection({
            data: data,
            isMutable: true,
            collectionDetailsPresent: true,
            collectionDetails: CollectionDetails({
                detailType: CollectionDetailsType.V1,
                size: 0
            })
        });

        AccountMeta[7] metas = [
            AccountMeta({pubkey: metadata, is_writable: true, is_signer: false}),
            AccountMeta({pubkey: mint, is_writable: false, is_signer: false}),
            AccountMeta({pubkey: payer, is_writable: false, is_signer: true}),
            AccountMeta({pubkey: payer, is_writable: true, is_signer: true}),
            AccountMeta({pubkey: payer, is_writable: false, is_signer: false}),
            AccountMeta({pubkey: systemAddress, is_writable: false, is_signer: false}),
            AccountMeta({pubkey: rentAddress, is_writable: false, is_signer: false})
        ];

        // https://docs.metaplex.com/programs/token-metadata/instructions#create-a-metadata-account
        bytes1 discriminator = 33;
        bytes instructionData = abi.encode(discriminator, args);

        metadataProgramId.call{accounts: metas}(instructionData);
    }

    ///  Normal NFT
    //  collection = Some(mintAccount)
    //  collectionDetails = None
	function create_metadata_account_normal(
		address metadata,
		address mint,
		address payer,
        address nftMint,
		string name,
		string symbol,
		string uri
	) internal {
        DataV2Normal data = DataV2Normal({
            name: name,
            symbol: symbol,
            uri: uri,
            sellerFeeBasisPoints: 500,
            creatorsPresent: true,
            size: 1,
            creators: Creator({
                creatorAddress: payer,
                verified: true,
                share: 100
            }),
            collectionPresent: true,
            collection: Collection({ verified: false, key: nftMint}),
            usesPresent: false
        });

        CreateMetadataAccountArgsV3Normal args = CreateMetadataAccountArgsV3Normal({
            data: data,
            isMutable: true,
            collectionDetailsPresent: false
        });

        AccountMeta[7] metas = [
            AccountMeta({pubkey: metadata, is_writable: true, is_signer: false}),
            AccountMeta({pubkey: mint, is_writable: false, is_signer: false}),
            AccountMeta({pubkey: payer, is_writable: false, is_signer: true}),
            AccountMeta({pubkey: payer, is_writable: true, is_signer: true}),
            AccountMeta({pubkey: payer, is_writable: false, is_signer: false}),
            AccountMeta({pubkey: systemAddress, is_writable: false, is_signer: false}),
            AccountMeta({pubkey: rentAddress, is_writable: false, is_signer: false})
        ];

        // https://docs.metaplex.com/programs/token-metadata/instructions#create-a-metadata-account
        bytes1 discriminator = 33;
        bytes instructionData = abi.encode(discriminator, args);

        metadataProgramId.call{accounts: metas}(instructionData);
    }
}
