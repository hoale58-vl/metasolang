import 'solana';

library SplAssociatedToken {
	address constant associatedTokenProgramId = address"ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL";
    address constant tokenProgramId = address"TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA";
    address constant systemAddress = address"11111111111111111111111111111111";

	function create_associated_token_account(
		address payer,
        address tokenAccount,
		address owner,
		address mintAccount
	) internal {
        bytes1 discriminator = 1; // Create

        // https://github.com/solana-labs/solana-program-library/blob/master/associated-token-account/program/src/instruction.rs#L19
		AccountMeta[6] metas = [
			AccountMeta({pubkey: payer, is_writable: true, is_signer: true}),
            AccountMeta({pubkey: tokenAccount, is_writable: true, is_signer: false}),
            AccountMeta({pubkey: owner, is_writable: false, is_signer: false}),
            AccountMeta({pubkey: mintAccount, is_writable: false, is_signer: false}),
            AccountMeta({pubkey: systemAddress, is_writable: false, is_signer: false}),
            AccountMeta({pubkey: tokenProgramId, is_writable: false, is_signer: false})
		];

		associatedTokenProgramId.call{accounts: metas}(discriminator);
	}
}