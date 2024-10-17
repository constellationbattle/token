contract;

abi Token {
    #[storage(read, write)]
    fn set_contract(_indentity: Identity);

    #[storage(read)]
    fn get_asset_id() -> AssetId;
}

use standards::{
    src20::{
        SetDecimalsEvent,
        SetNameEvent,
        SetSymbolEvent,
        SRC20,
        TotalSupplyEvent,
    },
    src3::SRC3,
};
use std::{
    asset::{
        burn,
        mint_to,
    },
    auth::msg_sender,
    call_frames::msg_asset_id,
    constants::DEFAULT_SUB_ID,
    context::msg_amount,
    string::String,
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

storage {
    /// The total supply of the asset minted by this contract.
    total_supply: u64 = 0,
    contract_owner: Identity = Identity::ContractId(ContractId::from(0x3b8726d7b9c9c659c3d51f29b636c40a70a039c9b0b2b2a376e93da0d334a93a)),
}

impl Token for Contract {

    #[storage(read, write)]
    fn set_contract(_indentity: Identity){
        require(
            msg_sender().unwrap() == ADMIN, 
            "Not admin",
        );
        storage.contract_owner.write(_indentity);
    }

    #[storage(read)]
    fn get_asset_id() -> AssetId{
        AssetId::default()
    }
}

impl SRC3 for Contract {
    
    #[storage(read, write)]
    fn mint(recipient: Identity, sub_id: Option<SubId>, amount: u64) {
        require(
            sub_id
                .is_some() && sub_id
                .unwrap() == DEFAULT_SUB_ID,
            "Incorrect Sub Id",
        );

        require(
            msg_sender().unwrap() == storage.contract_owner.read(), 
            "Sender Not Owner",
        );

        require(
            (amount + storage.total_supply.read()) <= TOTALMINT,
            "Amount Not Allow",
        );

        // Increment total supply of the asset and mint to the recipient.
        let new_supply = amount + storage.total_supply.read();
        storage.total_supply.write(new_supply);

        mint_to(recipient, DEFAULT_SUB_ID, amount);

        // TotalSupplyEvent::new(AssetId::default(), new_supply, msg_sender().unwrap())
        //     .log();
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
        let new_supply = storage.total_supply.read() - amount;
        storage.total_supply.write(new_supply);

        burn(DEFAULT_SUB_ID, amount);

        TotalSupplyEvent::new(AssetId::default(), new_supply, msg_sender().unwrap())
            .log();
    }
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

abi EmitSRC20Events {
    fn emit_src20_events();
}

impl EmitSRC20Events for Contract {
    fn emit_src20_events() {
        // Metadata that is stored as a configurable should only be emitted once.
        let asset = AssetId::default();
        let sender = msg_sender().unwrap();
        let name = Some(String::from_ascii_str(from_str_array(NAME)));
        let symbol = Some(String::from_ascii_str(from_str_array(SYMBOL)));

        SetNameEvent::new(asset, name, sender).log();
        SetSymbolEvent::new(asset, symbol, sender).log();
        SetDecimalsEvent::new(asset, DECIMALS, sender).log();
    }
}
