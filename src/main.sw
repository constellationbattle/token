contract;

abi Token {
    #[storage(read, write)]
    fn setContract(_indentity: Identity);

    #[storage(read)]
    fn getAssetId() -> AssetId;
}

use standards::{src20::SRC20, src3::SRC3};
use std::{
    asset::{
        burn,
        mint_to,
    },
    call_frames::msg_asset_id,
    constants::DEFAULT_SUB_ID,
    context::msg_amount,
    string::String,
    auth::msg_sender,
};

configurable {
    /// The decimals of the asset minted by this contract.
    DECIMALS: u8 = 9u8,
    /// The name of the asset minted by this contract.
    NAME: str[13] = __to_str_array("Constellation"),
    /// The symbol of the asset minted by this contract.
    SYMBOL: str[3] = __to_str_array("CON"),

    ADMIN: Identity = Identity::Address(Address::from(0x3b8726d7b9c9c659c3d51f29b636c40a70a039c9b0b2b2a376e93da0d334a93a)),
    TOTALMINT: u64 = 10000000000000000000,
}

enum AuthorizationError {
    SenderNotOwner: (),
    AmountNotAllow: (),
}


storage {
    /// The total supply of the asset minted by this contract.
    total_supply: u64 = 0,
    contract_owner: Identity = Identity::ContractId(ContractId::from(0x3b8726d7b9c9c659c3d51f29b636c40a70a039c9b0b2b2a376e93da0d334a93a)),
}

// DEFAULT_SUB_ID = 0x0000000000000000000000000000000000000000000000000000000000000000

impl Token for Contract {

    #[storage(read, write)]
    fn setContract(_indentity: Identity){
        require(
            msg_sender().unwrap() == ADMIN, 
            AuthorizationError::SenderNotOwner,
        );
        storage.contract_owner.write(_indentity);
    }

    #[storage(read)]
    fn getAssetId() -> AssetId{
        AssetId::default()
    }
}

impl SRC3 for Contract {
    
    #[storage(read, write)]
    fn mint(recipient: Identity, sub_id: SubId, amount: u64) {
        require(
            msg_sender().unwrap() == storage.contract_owner.read(), 
            AuthorizationError::SenderNotOwner,
        );
        require(sub_id == DEFAULT_SUB_ID, "Incorrect Sub Id");
        require(
            (amount + storage.total_supply.read()) <= TOTALMINT,
            AuthorizationError::AmountNotAllow,
        );
        // Increment total supply of the asset and mint to the recipient.
        storage
            .total_supply
            .write(amount + storage.total_supply.read());
        mint_to(recipient, DEFAULT_SUB_ID, amount);
    }

   
    #[payable]
    #[storage(read, write)]
    fn burn(sub_id: SubId, amount: u64) {
        require(sub_id == DEFAULT_SUB_ID, "Incorrect Sub Id");
        require(msg_amount() >= amount, "Incorrect amount provided");
        require(
            msg_asset_id() == AssetId::default(),
            "Incorrect asset provided",
        );

        // Decrement total supply of the asset and burn.
        storage
            .total_supply
            .write(storage.total_supply.read() - amount);
        burn(DEFAULT_SUB_ID, amount);
    }
    //need to check the function 
    //already check
}

// SRC3 extends SRC20, so this must be included
impl SRC20 for Contract {
    #[storage(read)]
    fn total_assets() -> u64 {
        1
    }

    #[storage(read)]
    fn total_supply(asset: AssetId) -> Option<u64> {
        if asset == AssetId::default() {
            Some(storage.total_supply.read())
        } else {
            None
        }
    }

    #[storage(read)]
    fn name(asset: AssetId) -> Option<String> {
        if asset == AssetId::default() {
            Some(String::from_ascii_str(from_str_array(NAME)))
        } else {
            None
        }
    }

    #[storage(read)]
    fn symbol(asset: AssetId) -> Option<String> {
        if asset == AssetId::default() {
            Some(String::from_ascii_str(from_str_array(SYMBOL)))
        } else {
            None
        }
    }

    #[storage(read)]
    fn decimals(asset: AssetId) -> Option<u8> {
        if asset == AssetId::default() {
            Some(DECIMALS)
        } else {
            None
        }
    }
}
