import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { ExampleNft } from "../target/types/example_nft";
import { PublicKey, SYSVAR_RENT_PUBKEY } from "@solana/web3.js";
import { Metaplex, walletAdapterIdentity } from "@metaplex-foundation/js";
import { BN } from "bn.js";

const TOKEN_METADATA_PROGRAM_ID = new PublicKey(
  "metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s"
);

describe("spl-token-minter", () => {
  // Configure the client to use the local cluster.
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  // Generate a new keypair for the data account for the program
  const dataAccount = anchor.web3.Keypair.generate();

  const wallet = provider.wallet as anchor.Wallet;
  const connection = provider.connection;

  const program = anchor.workspace.ExampleNft as Program<ExampleNft>;

  // Metadata for the Token
  const tokenTitle = "Example NFT";
  const tokenSymbol = "AVATOS";
  const collectionURI = "https://assets.example.xyz/metadata.json";
  const baseURI = "https://assets.example.xyz/";
  const mintFee = "10000000"; // 0.01 SOL
  const beneficary = wallet.publicKey;

  /// Keypairs
  const metaplex = Metaplex.make(connection);
  // Collection NFT
  const collectionMintKeypair = anchor.web3.Keypair.generate();
  const collectionMetadata = metaplex
    .nfts()
    .pdas()
    .metadata({ mint: collectionMintKeypair.publicKey });
  const collectionMasterEdition = metaplex
    .nfts()
    .pdas()
    .masterEdition({ mint: collectionMintKeypair.publicKey });
  const collectionAta = metaplex.tokens().pdas().associatedTokenAccount({
    mint: collectionMintKeypair.publicKey,
    owner: wallet.publicKey,
  });
  // Normal NFT
  const nftMintKeypair = anchor.web3.Keypair.generate();
  const nftMetadata = metaplex
    .nfts()
    .pdas()
    .metadata({ mint: nftMintKeypair.publicKey });
  const nftMasterEdition = metaplex
    .nfts()
    .pdas()
    .masterEdition({ mint: nftMintKeypair.publicKey });
  const nftAta = metaplex.tokens().pdas().associatedTokenAccount({
    mint: nftMintKeypair.publicKey, // mint
    owner: wallet.publicKey, // owner
  });

  it("Is initialized!", async () => {
    //// Initialize data account for the program, which is required by Solang
    const tx = await program.methods
      .new()
      .accounts({ dataAccount: dataAccount.publicKey })
      .signers([dataAccount])
      .rpc();
    console.log("Your transaction constructor signature", tx);
  });

  it("Mint Collection NFT - OnlyOwner", async () => {
    const init_tx = await program.methods
      .initialize(
        wallet.publicKey, // payer
        collectionMintKeypair.publicKey, // mint
        collectionMetadata, // metadata
        collectionMasterEdition, // edition
        collectionAta, // associated token account
        collectionURI, // collection uri
        tokenTitle, // token name
        tokenSymbol, // token symbol
        baseURI, // base uri
        new BN(mintFee) // mint fee
      )
      .accounts({ dataAccount: dataAccount.publicKey })
      .remainingAccounts([
        { pubkey: wallet.publicKey, isWritable: true, isSigner: true },
        {
          pubkey: collectionMintKeypair.publicKey,
          isWritable: true,
          isSigner: true,
        },
        { pubkey: collectionMetadata, isWritable: true, isSigner: false },
        { pubkey: collectionMasterEdition, isWritable: true, isSigner: false },
        { pubkey: collectionAta, isWritable: true, isSigner: false },
        { pubkey: SYSVAR_RENT_PUBKEY, isWritable: false, isSigner: false },
        {
          pubkey: TOKEN_METADATA_PROGRAM_ID,
          isWritable: false,
          isSigner: false,
        },
      ])
      .signers([collectionMintKeypair])
      .rpc();
    console.log("Your mint collection nft transaction signature", init_tx);
  });

  it("Mint Normal token!", async () => {
    // Associated token account PDA
    const tx = await program.methods
      .mintToken(
        wallet.publicKey, // payer
        nftMintKeypair.publicKey, // mint
        nftMetadata, // metadata
        nftMasterEdition, // edition
        nftAta, // associated token account
        "https://assets.example.xyz/metadata.json"
      )
      .accounts({ dataAccount: dataAccount.publicKey })
      .remainingAccounts([
        { pubkey: wallet.publicKey, isWritable: true, isSigner: true },
        {
          pubkey: nftMintKeypair.publicKey,
          isWritable: true,
          isSigner: true,
        },
        { pubkey: nftMetadata, isWritable: true, isSigner: false },
        { pubkey: nftMasterEdition, isWritable: true, isSigner: false },
        { pubkey: nftAta, isWritable: true, isSigner: false },
        { pubkey: SYSVAR_RENT_PUBKEY, isWritable: false, isSigner: false },
        {
          pubkey: TOKEN_METADATA_PROGRAM_ID,
          isWritable: false,
          isSigner: false,
        },
      ])
      .signers([nftMintKeypair])
      .rpc();
    console.log("Your mint normal nft transaction signature", tx);
  });

  it("Verify NFT as collection item", async () => {
    metaplex.use(walletAdapterIdentity(wallet));
    const verify = await metaplex.nfts().verifyCollection(
      {
        mintAddress: nftMintKeypair.publicKey,
        collectionMintAddress: collectionMintKeypair.publicKey,
        isSizedCollection: true,
      },
      { commitment: "finalized" }
    );
    console.log("Your verify transaction signature", verify);
  });
});
