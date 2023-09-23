import "../libraries/spl_token.sol";
import "../libraries/spl_associated_token.sol";
import "../libraries/mpl_metadata.sol";

@program_id("6CjY9JxNbd1o16Q53cu67TeD7xwwcGiLYSUdgDJ9jHpi")
contract example_nft {
    string private _name;
    string private _symbol;
    address private _collectionMint;
    address private _beneficary;
    uint64 private _totalSupply;
    uint64 private _mintFee;

    @space(256)
    @payer(payer)
    constructor() {}

    function initialize(
        address payer, // payer account
        address mint, // mint account to be created
        address metadata, // metadata account to be created
        address edition, // edition account to be created
        address tokenAccount, // Associated Token Account
        string collectionUri, // uri for the metadata account
        string name_,
        string symbol_,
        string baseURI_,
        uint64 mintFee_
    ) public {
        require(_name == "", "initialized");

        _name = name_;
        _symbol = symbol_;
        _beneficary = payer;
        _mintFee = mintFee_;

        _createCollectionToken(
            payer,
            mint,
            metadata,
            edition,
            tokenAccount,
            collectionUri
        );
        _collectionMint = mint;
    }

    // Call only once
    // Create new Collection Token. The following account will be initialize
    // MintAccount + Metadata + Edition + Token Account
    function _createCollectionToken(
        address payer, // payer account
        address mint, // mint account to be created
        address metadata, // metadata account PDA to be created
        address edition, // edition account PDA to be created
        address tokenAccount, // Associated Token Account
        string collectionUri // uri for the metadata account
    ) internal {
        // Collection NFT
        // Create Mint Account
        SplToken.create_mint_account(
            payer,           // payer account
            mint,            // mint account
            0                // decimals
        );

        // Create Metadata Account
        MplMetadata.create_metadata_account_collection(
            metadata, // metadata account
            mint,  // mint account
            payer, // mint authority
            _name, // name
            _symbol, // symbol
            collectionUri // uri (off-chain metadata json)
        );

        // Create Token Account to store token
        SplAssociatedToken.create_associated_token_account(
            payer,
            tokenAccount,
            payer,
		    mint
        );

        // Mint token to
        SplToken.mint_to(
            mint, // mint account
            tokenAccount, // token account
            payer, // mint authority
            1 // amount
        );

        // Create Master Edition Account
        MplMetadata.create_master_edition_v3_collection(
            edition, // edition
            mint,  // mint account
            payer, // payer
            metadata // metadata
        );
    }

    function mintToken(
        address payer, // payer account
        address mint, // mint account to be created
        address metadata, // metadata account to be created
        address edition,  // edition account to be created
        address tokenAccount, // token account PDA to be created,
        string tokenUri
    ) public {
        SystemInstruction.transfer(
            payer,
            _beneficary,
            _mintFee
        );

        // Normal NFT
        // Create Mint Account
        SplToken.create_mint_account(
            payer,           // payer account
            mint,            // mint account
            0                // decimals
        );

        // Create Metadata Account
        _totalSupply = _totalSupply + 1;
        string tokenName = "{} #{}".format(_name, _totalSupply);
        MplMetadata.create_metadata_account_normal(
            metadata, // metadata account
            mint,  // mint account
            payer, // mint authority
            _collectionMint, // collection nft mint account
            tokenName, // name
            _symbol, // symbol
            tokenUri // uri (off-chain metadata json)
        );

        // Create Token Account to store token
        SplAssociatedToken.create_associated_token_account(
            payer,
            tokenAccount,
            payer,
		    mint
        );

        // Mint token to
        SplToken.mint_to(
            mint, // mint account
            tokenAccount, // token account
            payer, // mint authority
            1 // amount
        );

        // Create Master Edition Account
        MplMetadata.create_master_edition_v3_nft(
            edition, // edition
            mint,  // mint account
            payer, // payer
            metadata // metadata
        );
    }
}
