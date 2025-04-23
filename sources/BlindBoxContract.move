module projectOwnerAdr::BlindBoxContract_Crystara_TestV17 {
    
    //
    // Module Upgrade Notes:
    //
    // - Change the fun init_module resource seed to "LOOTBOX_RESOURCE_V(NEW VERSION)"
    // - Change the callback module name in purchase_lootbox to "BlindBoxContract_Crystara_TestV(NEW VERSION)"
    // - Update the BlindBoxAdmin Contract to use the new version seed
    //

    use std::signer;
    use std::vector;
    use std::string::{Self, String};
    use std::error;
    use std::option::{Self, Option};
    use std::table;
    use std::type_info;
    use supra_framework::account::{Self};
    use supra_framework::supra_account;
    use aptos_token::token::{Self};
    use supra_framework::coin::{Self};
    use supra_framework::event;
    use supra_framework::timestamp;
    //DVRF
    use supra_addr::supra_vrf;
    use supra_addr::deposit;
    use std::bcs;
    use std::string_utils::{Self};

    // Constants
    const RESOURCE_ACCOUNT_SEED: vector<u8> = b"LOOTBOX_RESOURCE_V17";
    const USER_CLAIM_RESOURCE_SEED: vector<u8> = b"USER_CLAIM_RESOURCEV2_V17";
    const CALLBACK_MODULE_NAME: vector<u8> = b"BlindBoxContract_Crystara_TestV17";

    const SUPRA_COIN_TYPE: vector<u8> = b"0x1::supra_coin::SupraCoin";

    const EXTENSION_MAX_MINTS_KEY: vector<u8> = b"max_mints_per_wallet";
    const EXTENSION_STEP_DOWN_RARITY_KEY: vector<u8> = b"step_down_rarity_distribution";
    const EXTENSION_STEP_UP_RARITY_KEY: vector<u8> = b"step_up_rarity_distribution";
    const EXTENSION_MAX_MINTS_IN_WHITELIST_PHASE_KEY: vector<u8> = b"max_mints_in_whitelist_phase";
    const EXTENSION_CURRENT_MINTS_IN_WHITELIST_PHASE_KEY: vector<u8> = b"current_mints_in_whitelist_phase";

    /// Error Codes
    const ENOT_AUTHORIZED: u64 = 1;
    const ECOLLECTION_EXISTS: u64 = 2;
    const EINSUFFICIENT_BALANCE: u64 = 3;
    const ELOOTBOX_NOT_FOUND: u64 = 4;
    const ENOT_ENOUGH_STOCK: u64 = 5;
    const ELOOTBOX_EXISTS: u64 = 6;
    const EMAX_ROLLS_REACHED: u64 = 7;
    const ERESOURCE_FORFIXEDPRICE_EXISTS: u64 = 8;
    const EINVALID_INPUT_LENGTHS: u64 = 9;
    const EINVALID_RARITY: u64 = 10;
    const ETOKEN_NAME_ALREADY_EXISTS: u64 = 11;
    const EALREADY_INITIALIZED: u64 = 12;
    const EYOU_ARE_NOT_PROJECT_OWNER: u64 = 13;
    const EINVALID_VECTOR_LENGTH: u64 = 14;
    const EUNSAFE_NUMBER_CONVERSION: u64 = 15;
    const ELOOTBOX_NOTEXISTS: u64 = 16;
    const EPRICE_NOT_SET_OR_INVALID_COIN_TYPE: u64 = 17;
    const EPENDING_REWARDS_NOT_INITIALIZED: u64 = 18;
    const EPENDING_REWARD_NOT_FOUND: u64 = 19;
    const EMETADATA_NOT_FOUND: u64 = 20;
    const ETOKEN_DATA_NOT_FOUND: u64 = 21;
    const ENO_TOKENS_TO_CLAIM: u64 = 22;
    const ENO_TOKENS_FOUND: u64 = 23;
    const ENO_TOKENS_CLAIMED: u64 = 24;
    const ENO_TOKENS_CLAIMED_SUCCESSFULLY: u64 = 25;
    const ENO_TOKENS_CLAIMED_FAILED: u64 = 26;
    const ERESOURCE_ACCOUNT_NOT_EXISTS: u64 = 27;
    const ENO_NONCE_NOT_FOUND: u64 = 28;
    const ERESOURCE_ESCROW_CLAIM_ACCOUNT_NOT_EXISTS: u64 = 29;
    const ELOOTBOX_NOT_ACTIVE: u64 = 30;
    const ENOT_WHITELISTED: u64 = 31;
    const EINSUFFICIENT_WHITELIST_AMOUNT: u64 = 32;
    const EINVALID_MODULE_RESOURCE_SIGNER: u64 = 33;
    const EINVALID_EXTENSION_KEY: u64 = 34;
    const EINVALID_EXTENSION_TYPE: u64 = 35;
    const EINVALID_EXTENSION_VALUE: u64 = 36;
    const EINVALID_EXTENSION_TABLE: u64 = 37;
    const EINVALID_TYPE: u64 = 38;
    const EINVALID_COIN_TYPE: u64 = 39;
    const EDEPRECATED: u64 = 40;
    const ENO_TOKENS_AVAILABLE: u64 = 41;
    const ENO_RARITY_SELECTED: u64 = 42;
    const EINVALID_AMOUNT: u64 = 43;
    const EFUNCTION_DISABLED: u64 = 44;
    const ELOOTBOX_EMPTY: u64 = 45;
    const EBULK_PURCHASE_OVERFLOW: u64 = 46;
    const EINVALID_VRF_CALLER: u64 = 47;
    const ENO_TOKENS_AVAILABLE_TO_MINT: u64 = 48;
    const EDEBUG_POINT: u64 = 49;
    const EINVALID_TOKEN_INDEX: u64 = 50;
    const ERARITY_NOTEXISTS: u64 = 51;
    const ECANNOT_DELETE_EXISTING_RARITY: u64 = 52;
    const ENO_PERMISSION: u64 = 53;
    const EMAX_MINTS_PER_WALLET_NOT_SET: u64 = 54;
    const EMAX_MINTS_PER_WALLET_AMOUNT_ZERO: u64 = 55;
    const EMAX_MINTS_PER_WALLET_AMOUNT_REACHED: u64 = 56;
    const EMAX_MINTS_IN_WHITELIST_PHASE_REACHED: u64 = 57;

    #[event]
    struct LootboxCreatedEvent has copy, drop, store {
        creator: address,
        collection_management_resource_address: address,
        collection_name: vector<u8>,
        collection_description: vector<u8>,
        collection_uri: vector<u8>,  // Metadata URI
        price: u64,
        price_coinType: String,
        max_stock: u64,
        initial_stock: u64,
        is_active: bool,
        is_whitelist_mode: bool,
        auto_trigger_whitelist_time: u64,
        auto_trigger_active_time: u64,
        timestamp: u64,
    }

    #[event]
    struct LootboxPurchaseInitiatedEvent has drop, store {
        buyer: address,
        creator: address,
        collection_name: String,
        quantity: u64,
        nonce: u64,
        timestamp: u64,
        price: u64,
        price_coinType: String,
    }

    #[event]
    struct LootboxRewardDistributedEvent has drop, store {
        nonce: u64,
        buyer: address,
        creator: address,
        collection_name: String,
        selected_token: String,
        selected_rarity: String,
        random_number: u256,
        timestamp: u64
    }

    #[event]
    struct RaritiesSetEvent has drop, store {
      creator: address,
      collection_name: String,
      rarity_names: vector<String>,
      weights: vector<u64>,
      show_items_on_roll: vector<bool>,
      timestamp: u64
    }

    #[event]
    struct VRFCallbackReceivedEvent has drop, store {
        nonce: u64,
        caller_address: address,
        random_numbers: vector<u256>,
        timestamp: u64
    }

    #[event]
    struct TokenAddedEvent has drop, store {
        creator: address,
        collection_name: String,
        token_name: String,
        token_uri: String,
        rarity: String,
        max_supply: u64,
        timestamp: u64
    }

    // Add this event struct with your other events
    #[event]
    struct PriceUpdatedEvent has drop, store {
        creator: address,
        collection_name: String,
        price: u64,
        price_coinType: String,
        timestamp: u64
    }

    //DEPRECATED
    #[event]
    struct TokensClaimedEvent has drop, store {claimer: address,claim_resource_address: address,tokens_claimed: vector<TokenIdentifier>,total_tokens: u64,timestamp: u64}

    #[event]
    struct TokensClaimedEventV2 has drop, store {
        claimer: address,
        claim_resource_address: address,
        tokens_claimed: vector<TokenIdentifierV2>,
        total_tokens: u64,
        timestamp: u64
    }

    #[event]
    struct LootboxStatusUpdatedEvent has drop, store {
        creator: address,
        collection_name: String,
        is_active: bool,
        is_whitelist_mode: bool,
        auto_trigger_whitelist_time: u64,  // 0 if not auto-triggered
        auto_trigger_active_time: u64,  // 0 if not auto-triggered
        timestamp: u64
    }

    #[event]
    struct RequiresKeyUpdateEvent has drop, store {
        creator: address,
        collection_name: String,
        requires_key: bool,
        timestamp: u64
    }

    #[event]
    struct SetKeyCollectionNameEvent has drop, store {
        creator: address,
        collection_name: String,
        key_collection_name: String,
        timestamp: u64
    }

    #[event]
    struct PriceModifierUpdateEvent has drop, store {
        creator: address,
        collection_name: String,
        price_modifies_when_lack_of_certain_rarity: bool,
        rarities_price_modifier_if_sold_out_keys: vector<String>,
        rarities_price_modifier_if_sold_out_values: vector<u64>,
        timestamp: u64
    }

    #[event]
    struct EscrowAccountCreatedEvent has drop, store {
        owner_address: address,
        escrow_address: address,
        timestamp: u64
    }

    #[event]
    struct WhitelistUpdatedEvent has drop, store {
        creator: address,
        collection_name: String,
        addresses: vector<address>,
        amounts: vector<u64>,
        replace_existing: bool,
        timestamp: u64
    }

    #[event]
    struct WhitelistRemovedEvent has drop, store {
        creator: address,
        collection_name: String,
        removed_addresses: vector<address>,
        timestamp: u64
    }


    // Add event handle to PendingRewards struct
    struct PendingRewards has key {
        rewards: table::Table<u64, PendingReward>,
        next_nonce: u64,
    }

    //Structs
    //#[resource_group_member(group = supra_framework::object::ObjectGroup)]
    struct Lootbox has store {
      creator: address,
      collectionName: String, // Used to access collection by Creator + CollName in aptos_token::token

      collection_resource_address: address,
      collection_resource_signer_cap: account::SignerCapability,

      // ^ As good as storing the "Collection" Object because thats all we need to access it
      rarities: table::Table<String, u64>, // Map rarity name to weight
      rarities_showItemWhenRoll: table::Table<String, bool>,
      rarity_keys: vector<String>,         // Store rarity keys for iteration
      
      stock: u64, //Available stock
      maxRolls: u64, //Maximum Rolls ever
      rolled: u64, //Amount of this lootbox that has been rolled
      
      whitelistMode: bool,
      allow_mintList: table::Table<address, u64>,

      //FixedPriceListing with CoinType
      priceResourceAddress: address,
      
      tokensInLootbox: vector<String>, //Token names
      token_rarity_mapping: table::Table<String, String>, // Map token_name to rarity

      automatically_whitelist_mode_at_time: u64,
      automatically_active_at_time: u64,

      //Not Yet Implemented
      is_active: bool,
      mutable_if_active: bool, //If true, the lootbox can be modified while active

      requiresKey: bool, //Require Key to Roll and purchase lootbox
      keysCollectionName: String, //Collection Name of the keys by creator

      price_modifies_when_lack_of_certain_rarity: bool, //If true, the price will increase if the certain rarity is sold out
      rarities_price_modifier_if_sold_out: table::Table<String, u64>, //Map rarity to price modifier
    }

    //DEPRECATED
    #[event]
    struct LootboxExtensionUpdatedEvent has drop, store {creator: address,collection_name: String,updated_strings: vector<String>,updated_bools: vector<String>,updated_u64s: vector<String>,updated_u256s: vector<String>,timestamp: u64,}
    
    #[event]
    struct LootboxExtensionUpdatedEventV2 has drop, store {
        creator: address,
        collection_name: String,
        // Changed values
        updated_key_type: String,
        updated_key: String,
        updated_value: String,

        timestamp: u64,
    }

    struct LootboxExtension has store {
        creator: address,
        collectionName: String,
        extended_strings: table::Table<String, String>,
        extended_bools: table::Table<String, bool>,
        extended_u64: table::Table<String, u64>,
        extended_u256: table::Table<String, u256>,
    }

    // Add new resource to store extensions
    struct LootboxExtensions has key {
        extensions: table::Table<String, LootboxExtension>, // key is collection_name
    }

    struct LootboxDistributionHandler has store {
        creator: address,
        collection_name: String,
        avail_tokens_in_rarity: table::Table<String, vector<String>>, // rarity -> available token names
    }

    struct LootboxDistributionHandlers has key {
        distribution_handlers: table::Table<String, LootboxDistributionHandler>, // collection_name -> handler
    }

    /// Table to store all lootboxes by creator and collection name
    struct Lootboxes has key {
        lootbox_table: table::Table<String, Lootbox>, // Key: collection_name
    }

    #[resource_group_member(group = supra_framework::object::ObjectGroup)]
    struct FixedPriceListing<phantom CoinType> has key, store {
        /// The price to purchase the item up for listing.
        price: u64,
    }

    //DVRF SIgner Resource
    struct ResourceInfo has key {
      signer_cap: account::SignerCapability,
      signer_address: address
    }

    //Reward Structs
    struct PendingReward has store,drop {
      buyer: address,
      creator: address,
      collection_name: String,
      quantity: u64,
      nonce: u64,  // Link to the VRF request
    }

    // Escrow Resource for User Claim from Purchases
    struct UserClaimResourceInfoV2 has key {
        resource_signer_cap: account::SignerCapability,
        resource_signer_address: address,
        claimable_tokens: vector<TokenIdentifierV2>
    }

    struct TokenIdentifierV2 has store, drop {
        creator: address,
        collection: String,
        name: String,
        property_version: u64,
    }

    //DEPRECATED
    struct UserClaimResourceInfo has key { resource_signer_cap: account::SignerCapability, resource_signer_address: address, claimable_tokens: vector<TokenIdentifier> }
    //DEPRECATED
    struct TokenIdentifier has store, drop { creator: address, collection: String, name: String }

    //Entry Functions
    // Initialize the pending rewards storage
    fun init_module(publisher: &signer) {
        assert!(signer::address_of(publisher) == @projectOwnerAdr, error::unauthenticated(EYOU_ARE_NOT_PROJECT_OWNER));
        let resource_account_seed = RESOURCE_ACCOUNT_SEED;

        let resource_address = account::create_resource_address(&signer::address_of(publisher), resource_account_seed);
        assert!(!account::exists_at(resource_address), error::already_exists(EALREADY_INITIALIZED));

        // Create resource account with a seed
        let (resource_signer, signer_cap) = account::create_resource_account(publisher, resource_account_seed);
        
        // Store signer capability
        move_to(publisher, ResourceInfo {
            signer_cap: signer_cap,
            signer_address: signer::address_of(&resource_signer)
        });
        
        //initialize pending rewards
        move_to(publisher, PendingRewards {
            rewards: table::new(),
            next_nonce: 0,
        });
    }

    //DEPRECATED
    public entry fun deposit_supra_to_vrf<CoinType>(
    user: &signer,
    amount: u64
    ) acquires ResourceInfo {
        assert!(signer::address_of(user) == @projectOwnerAdr, error::permission_denied(ENOT_AUTHORIZED));
        
        let buyer_balance = coin::balance<CoinType>(signer::address_of(user));
        assert!(buyer_balance >= amount, error::invalid_argument(EINSUFFICIENT_BALANCE));

        // Distribute payment
        let coins = coin::withdraw<CoinType>(user, amount);
        let module_resource_info = borrow_global<ResourceInfo>(@projectOwnerAdr);
        let module_resource_signer = account::create_signer_with_capability(&module_resource_info.signer_cap);

        coin::deposit(signer::address_of(&module_resource_signer), coins);
        deposit::deposit_fund(&module_resource_signer, amount);
    }

    public entry fun deposit_supra_to_vrf_v2(
    user: &signer,
    amount: u64
    ) acquires ResourceInfo {
        assert!((signer::address_of(user) == @projectOwnerAdr || signer::address_of(user) == @v17_resource_addr) , error::permission_denied(ENOT_AUTHORIZED));
        let module_resource_info = borrow_global<ResourceInfo>(@projectOwnerAdr);
        let module_resource_signer = account::create_signer_with_capability(&module_resource_info.signer_cap);

        supra_account::transfer(user, module_resource_info.signer_address, amount);
        deposit::deposit_fund(&module_resource_signer, amount);
    }

    public entry fun add_contract_to_vrf_whitelist(
        user: &signer,
        contract_address: address
    ) acquires ResourceInfo {
        
        //Unused params reduce warnings in a no-op way
        let _ = contract_address;

        assert!(signer::address_of(user) == @projectOwnerAdr, error::permission_denied(ENOT_AUTHORIZED));

        let module_resource_info = borrow_global<ResourceInfo>(@projectOwnerAdr);
        let module_resource_signer = account::create_signer_with_capability(&module_resource_info.signer_cap);
        //deposit::remove_contract_from_whitelist(&module_resource_signer, @projectOwnerAdr);
        deposit::add_contract_to_whitelist(&module_resource_signer, @projectOwnerAdr);
    }


    public entry fun create_lootbox<CoinType>(
      source_account: &signer,
      collection_name: vector<u8>,
      description: vector<u8>,
      collection_uri: vector<u8>,
      maximum_supply: u64, 
      initial_stock: u64, //Deprecated
      max_stock: u64, //Deprecated
      price: u64,

      requiresKey: bool,
      keys_collection_name: vector<u8>,
      keys_collection_description: vector<u8>,
      keys_collection_url: vector<u8>,
    ) acquires Lootboxes {

    // Unused params reduce warnings in a no-op way
    let _ = initial_stock;
    let _ = max_stock;
    let _ = keys_collection_description;
    let _ = keys_collection_url;

    if(type_info::type_name<CoinType>() != string::utf8(SUPRA_COIN_TYPE)) {
        assert!(false, error::invalid_argument(EINVALID_COIN_TYPE));
    };

      let account_addr = signer::address_of(source_account);
      let fresh_account = false;

      //Check if Lootboxes Table Exists for Creator, If No, Init Table.
      if (!exists<Lootboxes>(account_addr)) {
        move_to(source_account, Lootboxes {
            lootbox_table: table::new<String, Lootbox>(),
        });
        fresh_account = true;
      };

      //Unused params reduce warnings in a no-op way
      let _ = fresh_account;

      // Convert the vectors to strings
      let collection_name_str = string::utf8(collection_name);
      let description_str = string::utf8(description);
      let collection_uri_str = string::utf8(collection_uri);

      let lootboxes = borrow_global_mut<Lootboxes>(account_addr);
      assert!(
        !table::contains(&lootboxes.lootbox_table, collection_name_str),
        error::already_exists(ELOOTBOX_EXISTS)
      );


      let lootbox_resource_account_seed = vector::empty<u8>(); 
      vector::append(&mut lootbox_resource_account_seed, b"Lootbox");
      vector::append(&mut lootbox_resource_account_seed, collection_name);
      vector::append(&mut lootbox_resource_account_seed, CALLBACK_MODULE_NAME);

      // Check exist in global record. If it exist, it will throw an error.
      let resource_address = account::create_resource_address(&account_addr, lootbox_resource_account_seed);
      assert!(!account::exists_at(resource_address), error::already_exists(ERESOURCE_FORFIXEDPRICE_EXISTS));
      
      let (lootbox_resource_account_signer, lootbox_resource_account_signCapability) = account::create_resource_account(source_account, lootbox_resource_account_seed);
      let lootbox_resource_account_addr = signer::address_of(&lootbox_resource_account_signer);

      //Removed Need to Check underlying collection exists because we are creating a new seed and already checked that the new seed dosent exist prior.

      // Check exist in global record. If it exist, it will throw an error.
      assert!(!exists<FixedPriceListing<CoinType>>(lootbox_resource_account_addr), error::already_exists(ERESOURCE_FORFIXEDPRICE_EXISTS));
      
      let fixed_price_listing = FixedPriceListing<CoinType> {
            price,
        };

      move_to(&lootbox_resource_account_signer, fixed_price_listing);

      let new_lootbox = Lootbox {
        creator: account_addr,
        collectionName: collection_name_str,

        collection_resource_address: lootbox_resource_account_addr,
        collection_resource_signer_cap: lootbox_resource_account_signCapability,

        rarities: table::new<String, u64>(),
        rarities_showItemWhenRoll: table::new<String, bool>(),
        rarity_keys: vector::empty<String>(),

        stock: maximum_supply, //Set to max. Then just use whitelisting to control the stock dsitributions
        maxRolls: maximum_supply,
        rolled: 0,

        whitelistMode: false,
        allow_mintList: table::new<address, u64>(),

        //price: fixed_price_listing,
        priceResourceAddress: lootbox_resource_account_addr,

        tokensInLootbox: vector::empty<String>(),
        token_rarity_mapping: table::new<String, String>(),

        //Not Yet Implemented
        is_active: false,
        mutable_if_active: false,

        automatically_whitelist_mode_at_time: 0,
        automatically_active_at_time: 0,

        //Not Yet Implemented
        price_modifies_when_lack_of_certain_rarity: false,
        rarities_price_modifier_if_sold_out: table::new<String, u64>(),

        //Not Yet Implemented
        requiresKey: requiresKey,
        keysCollectionName: string::utf8(keys_collection_name),
      };

      // Borrow a mutable reference to the `Lootboxes` resource
      let lootboxes = borrow_global_mut<Lootboxes>(account_addr);

      // Check if the lootbox already exists
      assert!(!table::contains(&lootboxes.lootbox_table, collection_name_str), error::already_exists(ELOOTBOX_EXISTS));
      // Insert the new lootbox into the `lootbox_table`
      table::add(&mut lootboxes.lootbox_table, collection_name_str, new_lootbox);

      // Create the collection with mutability settings
      let mutability_settings = vector::empty<bool>();
      vector::push_back(&mut mutability_settings , true); //Description
      vector::push_back(&mut mutability_settings , true); //URI
      vector::push_back(&mut mutability_settings , true); //Maximum
  
      // Create the collection using the new standard
      token::create_collection(
          &lootbox_resource_account_signer,
          collection_name_str,
          description_str,
          collection_uri_str,
          maximum_supply, //Follows the max stock of the lootbox
          mutability_settings
      );

      //TODO if need key, create key collection

      // Get the type name of CoinType
      let coin_type_name = type_info::type_name<CoinType>();
      
      let lootbox_event = LootboxCreatedEvent {
        creator: account_addr,
        collection_name: collection_name,
        collection_description: description,
        collection_uri: collection_uri,
        collection_management_resource_address: lootbox_resource_account_addr,
        price: price,
        price_coinType: coin_type_name,
        max_stock: maximum_supply,
        initial_stock: maximum_supply,
        is_active: false,
        is_whitelist_mode: false,
        auto_trigger_whitelist_time: 0,
        auto_trigger_active_time: 0,
        timestamp: timestamp::now_microseconds(), 
      };
      event::emit(lootbox_event);
    }




    public entry fun set_rarities(
      collection_owner: &signer,
      lootbox_name: vector<u8>,
      rarity_names: vector<vector<u8>>,
      rarity_weights: vector<u64>,
      show_items_on_roll: vector<bool>
    ) acquires Lootboxes {
        let owner_addr = signer::address_of(collection_owner);
        let lootbox_name_str = string::utf8(lootbox_name);

        // Get the lootbox
        let lootboxes = borrow_global_mut<Lootboxes>(owner_addr);
        let lootbox = table::borrow_mut(&mut lootboxes.lootbox_table, lootbox_name_str);
        
        // Verify the signer is the creator
        assert!(lootbox.creator == owner_addr, error::permission_denied(ENOT_AUTHORIZED));
        
        // Verify input vectors have same length
        let len = vector::length(&rarity_names);
        assert!(
            len == vector::length(&rarity_weights) && 
            len == vector::length(&show_items_on_roll),
            error::invalid_argument(EINVALID_INPUT_LENGTHS)
        );

        let existing_rarities_are_present_count = 0; 

        // Check if all existing rarities are present
        let i = 0;
        while (i < len) {
            let new_rarity_name = string::utf8(*vector::borrow(&rarity_names, i));
            if(table::contains(&lootbox.rarities, new_rarity_name)) {
                existing_rarities_are_present_count = existing_rarities_are_present_count + 1;
            };
            
            i = i + 1;
        };

        // If all existing rarities are not present, throw an error
        assert!(existing_rarities_are_present_count == vector::length(&lootbox.rarity_keys), error::invalid_argument(ECANNOT_DELETE_EXISTING_RARITY));

        lootbox.rarity_keys = vector::empty<String>();

        // Add new entries
        let i = 0;
        while (i < len) {
            let rarity_name = string::utf8(*vector::borrow(&rarity_names, i));
            let weight = *vector::borrow(&rarity_weights, i);
            let show_item = *vector::borrow(&show_items_on_roll, i);

            //Check if rarity name already exists
            if(!table::contains(&lootbox.rarities, rarity_name)) 
            {
                table::add(&mut lootbox.rarities, rarity_name, weight);
            }
            else {
                //Borrow existing record and override weight
                let existing_rarity = table::borrow_mut(&mut lootbox.rarities, rarity_name);
                *existing_rarity = weight;
            };

            //Check if show item already exists
            if(!table::contains(&lootbox.rarities_showItemWhenRoll, rarity_name)) 
            {
                table::add(&mut lootbox.rarities_showItemWhenRoll, rarity_name, show_item);
            }
            else {
                //Borrow existing record and override show item
                let existing_show_item = table::borrow_mut(&mut lootbox.rarities_showItemWhenRoll, rarity_name);
                *existing_show_item = show_item;
            };

            vector::push_back(&mut lootbox.rarity_keys, rarity_name);
            
            i = i + 1;
        };

        // Emit event
        event::emit(
            RaritiesSetEvent {
                creator: owner_addr,
                collection_name: lootbox_name_str,
                rarity_names: lootbox.rarity_keys,
                weights: rarity_weights,
                show_items_on_roll: show_items_on_roll,
                timestamp: timestamp::now_microseconds()
            }
        );
    }

    public entry fun set_rarities_with_colors(
    collection_owner: &signer,
    lootbox_name: vector<u8>,
    rarity_names: vector<vector<u8>>,
    rarity_weights: vector<u64>,
    show_items_on_roll: vector<bool>,
    rarity_colors: vector<u8>  // New parameter for colors
    ) acquires Lootboxes, LootboxExtensions {
        let owner_addr = signer::address_of(collection_owner);
        let lootbox_name_str = string::utf8(lootbox_name);
        
        // First call the original set_rarities function
        set_rarities(
            collection_owner,
            lootbox_name,
            rarity_names,
            rarity_weights,
            show_items_on_roll
        );
        
        // Get the lootbox to access its resource account
        let lootboxes = borrow_global<Lootboxes>(owner_addr);
        let lootbox = table::borrow(&lootboxes.lootbox_table, lootbox_name_str);

        assert!(lootbox.creator == owner_addr, error::permission_denied(ENOT_AUTHORIZED));
        
        // Create resource signer to set extension
        let resource_signer = account::create_signer_with_capability(&lootbox.collection_resource_signer_cap);
        
        // Set the rarity colors in extensions
        internal_set_lootbox_extension_string(
            &resource_signer,
            lootbox_name_str,
            string::utf8(b"rarity_colors"),
            string::utf8(rarity_colors)
        );
        
    }

    public entry fun set_max_mints_per_wallet(
        creator: &signer,
        collection_name: vector<u8>,
        max_mints_per_wallet_toggle: bool,
        max_mints_per_wallet_amount: u64
    ) acquires Lootboxes, LootboxExtensions {
        let owner_addr = signer::address_of(creator);
        let lootbox_name_str = string::utf8(collection_name);

        let lootboxes = borrow_global_mut<Lootboxes>(owner_addr);
        let lootbox = table::borrow_mut(&mut lootboxes.lootbox_table, lootbox_name_str);

        assert!(lootbox.creator == owner_addr, error::permission_denied(ENOT_AUTHORIZED));

        let resource_signer = account::create_signer_with_capability(&lootbox.collection_resource_signer_cap);

        internal_set_lootbox_extension_bool(
            &resource_signer,
            lootbox_name_str,
            string::utf8(EXTENSION_MAX_MINTS_KEY),
            max_mints_per_wallet_toggle
        );

        if(max_mints_per_wallet_toggle) {
            internal_set_lootbox_extension_u64(
                &resource_signer,
                lootbox_name_str,
                string::utf8(EXTENSION_MAX_MINTS_KEY),
                max_mints_per_wallet_amount
            );
        };
    }

    public entry fun set_max_mints_in_whitelist_phase(
        creator: &signer,
        collection_name: vector<u8>,
        max_mints_in_whitelist_phase: u64
    ) acquires Lootboxes, LootboxExtensions {
        let owner_addr = signer::address_of(creator);
        let lootbox_name_str = string::utf8(collection_name);

        let lootboxes = borrow_global_mut<Lootboxes>(owner_addr);
        let lootbox = table::borrow_mut(&mut lootboxes.lootbox_table, lootbox_name_str);

        assert!(lootbox.creator == owner_addr, error::permission_denied(ENOT_AUTHORIZED));

        let resource_signer = account::create_signer_with_capability(&lootbox.collection_resource_signer_cap);

        internal_set_lootbox_extension_u64(
            &resource_signer,
            lootbox_name_str,
            string::utf8(EXTENSION_MAX_MINTS_IN_WHITELIST_PHASE_KEY),
            max_mints_in_whitelist_phase
        );
    }

    public entry fun set_extension_rarity_distributions_toggle(
        creator: &signer,
        collection_name: vector<u8>,
        step_up_rarity_toggle: bool,
        step_down_rarity_toggle: bool
    ) acquires Lootboxes, LootboxExtensions {
        let owner_addr = signer::address_of(creator);
        let lootbox_name_str = string::utf8(collection_name);

        let lootboxes = borrow_global_mut<Lootboxes>(owner_addr);
        let lootbox = table::borrow_mut(&mut lootboxes.lootbox_table, lootbox_name_str);

        assert!(lootbox.creator == owner_addr, error::permission_denied(ENOT_AUTHORIZED));

        let resource_signer = account::create_signer_with_capability(&lootbox.collection_resource_signer_cap);

        internal_set_lootbox_extension_bool(
            &resource_signer,
            lootbox_name_str,
            string::utf8(EXTENSION_STEP_UP_RARITY_KEY),
            step_up_rarity_toggle
        );

        internal_set_lootbox_extension_bool(
            &resource_signer,
            lootbox_name_str,
            string::utf8(EXTENSION_STEP_DOWN_RARITY_KEY),
            step_down_rarity_toggle
        );
        
    }



  //Add Token To Lootbox
    public entry fun add_token_to_lootbox(
      creator: &signer,
      collection_name: vector<u8>,
      token_uri: vector<u8>,
      rarity: vector<u8>,
      max_supply: u64
    ) /*acquires Lootboxes*/ {
        /*let creator_addr = signer::address_of(creator);
        let collection_name_str = string::utf8(collection_name);

        // Get the lootbox
        let lootboxes = borrow_global_mut<Lootboxes>(creator_addr);
        let lootbox = table::borrow_mut(&mut lootboxes.lootbox_table, collection_name_str);
        // Verify the signer is the creator
        assert!(lootbox.creator == creator_addr, error::permission_denied(ENOT_AUTHORIZED));

        let collection_resource_address = lootbox.collection_resource_address;
        let collection_resource_signer = account::create_signer_with_capability(&lootbox.collection_resource_signer_cap);

        // Generate a new token name
        let token_count = vector::length(&lootbox.tokensInLootbox);
        let token_name_str = generate_token_name(token_count + 1);

        // Check if token with this name already exists
        assert!(
            !token::check_tokendata_exists(collection_resource_address, collection_name_str, token_name_str),
            error::already_exists(ETOKEN_NAME_ALREADY_EXISTS)
        );
        
        // Verify rarity exists in lootbox configuration
        let rarity_str = string::utf8(rarity);
        assert!(
            table::contains(&lootbox.rarities, rarity_str),
            error::invalid_argument(EINVALID_RARITY)
        );

        // Set up token properties including rarity
        let property_keys = vector[string::utf8(b"rarity")];
        let property_values = vector[rarity];
        let property_types = vector[string::utf8(b"String")];

        //Token Mutability Configuration
         //Max Supply, URI, Royalty, Description, Properties
        let mutability_settings = vector[false, true, true, true, true];
        let token_mutability_settings = token::create_token_mutability_config(&mutability_settings);

        // Create token metadata in the collection
        token::create_tokendata(
            &collection_resource_signer,
            collection_name_str,
            token_name_str,
            string::utf8(b""),
            max_supply,
            string::utf8(token_uri),
            creator_addr,
            100,
            5, //Royalty Percent
            token_mutability_settings,
            property_keys, 
            property_values,
            property_types,
        );


        // Store token data id only
        vector::push_back(&mut lootbox.tokensInLootbox, token_name_str);
        table::add(&mut lootbox.token_rarity_mapping, token_name_str, rarity_str);

        // Preparing Event Data
        let token_uri_str = string::utf8(token_uri);

        // Emit event
        event::emit(
            TokenAddedEvent {
                creator: creator_addr,
                collection_name: collection_name_str,
                token_name: token_name_str,
                token_uri: token_uri_str,
                rarity: rarity_str,
                max_supply,
                timestamp: timestamp::now_microseconds()
            }
        );
        */

        let _ = creator;
        let _ = collection_name;
        let _ = token_uri;
        let _ = rarity;
        let _ = max_supply;

        assert!(false, error::invalid_argument(EDEPRECATED));
    }

  fun generate_token_name(id: u64): String {
      let prefix = b"TOKEN_";
      let name_bytes = vector::empty<u8>();
      vector::append(&mut name_bytes, prefix);
      
      // Convert id to string and append
      let id_str = number_to_string(id);  // You'll need to implement this
      vector::append(&mut name_bytes, *string::bytes(&id_str));
      
      string::utf8(name_bytes)
  }

  fun number_to_string(num: u64): String {
    if (num == 0) {
        return string::utf8(b"0")
    };
    
    let digits = vector::empty<u8>();
    let temp_num = num;
    
    while (temp_num > 0) {
        let digit = ((48 + (temp_num % 10)) as u8);  // Convert to ASCII
        vector::push_back(&mut digits, digit);
        temp_num = temp_num / 10;
    };
    
    // Reverse the digits since we added them in reverse order
    let len = vector::length(&digits);
    let i = 0;
    while (i < len / 2) {
        let j = len - i - 1;
        let temp = *vector::borrow(&digits, i);
        *vector::borrow_mut(&mut digits, i) = *vector::borrow(&digits, j);
        *vector::borrow_mut(&mut digits, j) = temp;
        i = i + 1;
    };
    
    string::utf8(digits)
  }

  #[view]
  public fun view_get_lootbox_tokens_by_rarity(
    creator: address,
    collection_name: String,
    rarity: String
  ): vector<String> acquires Lootboxes {
    let lootboxes = borrow_global<Lootboxes>(creator);
    let lootbox = table::borrow(&lootboxes.lootbox_table, collection_name);

    let tokens_in_rarity = get_tokens_by_rarity(lootbox, rarity);
    tokens_in_rarity
  }

  //DEPRECATED
  #[view]
  public fun get_tokens_in_lootbox_by_rarity(
    collection_name: vector<u8>,
    creator: address,
    rarity: vector<u8>
  ): vector<String> acquires Lootboxes {
    let lootboxes = borrow_global<Lootboxes>(creator);
    let lootbox = table::borrow(&lootboxes.lootbox_table, string::utf8(collection_name));

    //Unused params reduce warnings in a no-op way
    let _ = lootbox;
    let _ = rarity;

    let deprecated_vector = vector::empty<String>();
    vector::push_back(&mut deprecated_vector, string::utf8(b"DEPRECATED"));
    deprecated_vector
  }

  // Helper function to get all tokens of a specific rarity
  fun get_tokens_by_rarity(
      lootbox: &Lootbox,
      rarity: String
    ): vector<String> {
      let tokens_of_rarity = vector::empty<String>();
      let i = 0;
      let len = vector::length(&lootbox.tokensInLootbox);
      
      while (i < len) {
          let token_name = *vector::borrow(&lootbox.tokensInLootbox, i);
          let token_rarity = *table::borrow(&lootbox.token_rarity_mapping, token_name);
          
          // If token has matching rarity, add its name to our result vector
          if (token_rarity == rarity) {
              let token_data_id = token::create_token_data_id(
                lootbox.collection_resource_address,
                lootbox.collectionName,
                token_name
            );
            let maxSupplyReached = false;
            let curSupply = token::get_token_supply(lootbox.collection_resource_address, token_data_id);
            if(curSupply != option::none()) {
                let maxSupply = token::get_tokendata_maximum(token_data_id);
                if (maxSupply != 0) {
                    //curSupply is std::option::some(u64) so how to access the value?
                    let curSupplyValue = *option::borrow(&curSupply);
                    if(curSupplyValue >= maxSupply) {
                        maxSupplyReached = true;
                    };
                };
            };
            if(!maxSupplyReached) {
                vector::push_back(&mut tokens_of_rarity, token_name);
            };
          };
          

          i = i + 1;
      };
    
    tokens_of_rarity
    }

    //TODO Modify Token Metadata by ID
    public entry fun modify_token_metadata(
      creator: &signer,
      collection_name: vector<u8>,
      token_name: vector<u8>,
      new_uri: vector<u8>,
      new_description: vector<u8>,
      new_rarity: vector<u8>,
      // For other properties
      property_keys: vector<String>,
      property_types: vector<String>,
      property_values: vector<vector<u8>>
    ) /*acquires Lootboxes*/ {
        
        /*
        let creator_addr = signer::address_of(creator);
        let collection_name_str = string::utf8(collection_name);
        let token_name_str = string::utf8(token_name);
        
        // Get the lootbox to verify ownership
        let lootboxes = borrow_global_mut<Lootboxes>(creator_addr);
        let lootbox = table::borrow_mut(&mut lootboxes.lootbox_table, collection_name_str);
        
        // Verify the signer is the creator
        assert!(lootbox.creator == creator_addr, error::permission_denied(ENOT_AUTHORIZED));

        let collection_resource_address = lootbox.collection_resource_address;
        let collection_resource_signer = account::create_signer_with_capability(&lootbox.collection_resource_signer_cap);

        // Get token data id
        let token_data_id = token::create_token_data_id(
            collection_resource_address,
            collection_name_str,
            token_name_str
        );

        // If changing rarity, verify the new rarity exists in lootbox configuration
        if (vector::length(&new_rarity) > 0) {
            let new_rarity_str = string::utf8(new_rarity);
            assert!(
                table::contains(&lootbox.rarities, new_rarity_str),
                error::invalid_argument(EINVALID_RARITY)
            );

            // Update rarity property
            let rarity_keys = vector[string::utf8(b"rarity")];
            let rarity_values = vector[new_rarity];
            let rarity_types = vector[string::utf8(b"String")];

            token::mutate_tokendata_property(
                &collection_resource_signer,
                token_data_id,
                rarity_keys,
                rarity_values,
                rarity_types,
            );
        };

        // Modify URI if provided
        if (vector::length(&new_uri) > 0) {
            token::mutate_tokendata_uri(
                &collection_resource_signer,
                token_data_id,
                string::utf8(new_uri)
            );
        };

        // Modify description if provided
        if (vector::length(&new_description) > 0) {
            token::mutate_tokendata_description(
                &collection_resource_signer,
                token_data_id,
                string::utf8(new_description)
            );
        };

        // Modify other properties if provided
        if (vector::length(&property_keys) > 0) {
            token::mutate_tokendata_property(
                &collection_resource_signer,
                token_data_id,
                property_keys,
                property_values,
                property_types,
            );
        };

        */

        let _ = creator;
        let _ = collection_name;
        let _ = token_name;
        let _ = new_uri;
        let _ = new_description;
        let _ = new_rarity;
        let _ = property_keys;
        let _ = property_types;
        let _ = property_values;
        assert!(false, error::invalid_argument(EFUNCTION_DISABLED));
    }

    public entry fun purchase_multiple_lootboxes<CoinType>(
      buyer: &signer,
      creator_addr: address,
      collection_name: vector<u8>,
      quantity: u64
    ) acquires FixedPriceListing, Lootboxes, PendingRewards, ResourceInfo, LootboxExtensions, LootboxDistributionHandlers {

        assert!(signer::address_of(buyer) == @projectOwnerAdr, error::invalid_argument(ENO_PERMISSION));
        
        let overflow = 200;
        let iter = 0;

        let price_per_box = get_lootbox_price<CoinType>(creator_addr, string::utf8(collection_name));
        let total_cost = price_per_box * quantity;
        assert!(coin::balance<CoinType>(signer::address_of(buyer)) >= total_cost, error::invalid_argument(EINSUFFICIENT_BALANCE));

        while(quantity > 0) {
            purchase_lootbox<CoinType>(buyer, creator_addr, collection_name);
            quantity = quantity - 1;
            iter = iter + 1;
            assert!(iter < overflow, error::invalid_state(EBULK_PURCHASE_OVERFLOW));
        };
    }

    /// Purchase a lootbox
    public entry fun purchase_lootbox<CoinType>(
        buyer: &signer,
        creator_addr: address,
        collection_name: vector<u8>,
      ) acquires FixedPriceListing, Lootboxes, PendingRewards, ResourceInfo, LootboxExtensions, LootboxDistributionHandlers {

        // Check if coin type is SupraCoin
        if(type_info::type_name<CoinType>() != string::utf8(SUPRA_COIN_TYPE)) {
            assert!(false, error::invalid_argument(EINVALID_COIN_TYPE));
        };


        let buyer_addr = signer::address_of(buyer);
        let collection_name_str = string::utf8(collection_name);

        // Check if user has initialized their claim escrow account
        let user_claim_resource_address = account::create_resource_address(&buyer_addr, USER_CLAIM_RESOURCE_SEED);        
        if(!account::exists_at(user_claim_resource_address)){
            initialize_claim_account(buyer);
        };

        // Fetch the lootbox
        let lootboxes = borrow_global_mut<Lootboxes>(creator_addr);
        // Abort if the lootbox dosent exist
        assert!(table::contains(&lootboxes.lootbox_table, collection_name_str), error::not_found(ELOOTBOX_NOTEXISTS));
        // Fetch the lootbox
        let lootbox = table::borrow_mut(&mut lootboxes.lootbox_table, collection_name_str);

        assert!(vector::length(&lootbox.tokensInLootbox) > 0, error::invalid_state(ELOOTBOX_EMPTY));

        // Check auto-activation time
        let current_time = timestamp::now_microseconds();
        if (lootbox.automatically_active_at_time != 0 && current_time >= lootbox.automatically_active_at_time) {
            lootbox.is_active = true;
            event::emit(
                LootboxStatusUpdatedEvent {
                    creator: creator_addr,
                    collection_name: collection_name_str,
                    is_active: lootbox.is_active,
                    is_whitelist_mode: lootbox.whitelistMode,
                    auto_trigger_whitelist_time: lootbox.automatically_whitelist_mode_at_time,
                    auto_trigger_active_time: lootbox.automatically_active_at_time,
                    timestamp: timestamp::now_microseconds()
                }
            );
        };

        // Check auto-whitelist time
        if (lootbox.automatically_whitelist_mode_at_time != 0 && current_time >= lootbox.automatically_whitelist_mode_at_time) {
            lootbox.whitelistMode = true;
            event::emit(
                LootboxStatusUpdatedEvent {
                    creator: creator_addr,
                    collection_name: collection_name_str,
                    is_active: lootbox.is_active,
                    is_whitelist_mode: lootbox.whitelistMode,
                    auto_trigger_whitelist_time: lootbox.automatically_whitelist_mode_at_time,
                    auto_trigger_active_time: lootbox.automatically_active_at_time,
                    timestamp: timestamp::now_microseconds()
                }
            );
        };

        // Check whitelist if enabled
        let buyer_addr = signer::address_of(buyer);
        if (lootbox.whitelistMode && !lootbox.is_active) {
            assert!(table::contains(&lootbox.allow_mintList, buyer_addr), error::permission_denied(ENOT_WHITELISTED));
            let allowed_amount = *table::borrow(&lootbox.allow_mintList, buyer_addr);
            assert!(allowed_amount >= 1, error::invalid_state(EINSUFFICIENT_WHITELIST_AMOUNT));

            let max_mints_in_whitelist_phase = get_lootbox_extension_u64(lootbox.collection_resource_address, collection_name_str, string::utf8(EXTENSION_MAX_MINTS_IN_WHITELIST_PHASE_KEY));
            if(max_mints_in_whitelist_phase != option::none()) {
                let max_mints_in_whitelist_phase = *option::borrow(&max_mints_in_whitelist_phase);
                let current_mints_in_whitelist_phase_extension = get_lootbox_extension_u64(lootbox.collection_resource_address, collection_name_str, string::utf8(EXTENSION_CURRENT_MINTS_IN_WHITELIST_PHASE_KEY));
                let current_mints_in_whitelist_phase = 0;
                
                if(current_mints_in_whitelist_phase_extension != option::none()) {
                    current_mints_in_whitelist_phase = *option::borrow(&current_mints_in_whitelist_phase_extension);
                };

                current_mints_in_whitelist_phase = current_mints_in_whitelist_phase + 1;
                assert!(current_mints_in_whitelist_phase < max_mints_in_whitelist_phase, error::invalid_state(EMAX_MINTS_IN_WHITELIST_PHASE_REACHED));

                internal_set_lootbox_extension_u64(
                    &collection_signer,
                    collection_name_str,
                    string::utf8(EXTENSION_CURRENT_MINTS_IN_WHITELIST_PHASE_KEY),
                    current_mints_in_whitelist_phase);
            };
            

        }else {
            assert!(lootbox.is_active, error::invalid_state(ELOOTBOX_NOT_ACTIVE));
        };

        // Check if there is stock and rolls are not maxed out
        assert!(lootbox.stock > 0, error::not_found(ENOT_ENOUGH_STOCK));
        assert!(lootbox.rolled < lootbox.maxRolls, error::not_found(EMAX_ROLLS_REACHED) );

        // Check if dynamic seed is enabled
        let dynamic_seed = get_lootbox_extension_bool(lootbox.collection_resource_address, collection_name_str, string::utf8(b"dynamic_seed_enabled"));
        if (dynamic_seed == option::none()) {
            let collection_signer = account::create_signer_with_capability(&lootbox.collection_resource_signer_cap);
            // Store seed in extension
            internal_set_lootbox_extension_bool(&collection_signer, collection_name_str, string::utf8(b"dynamic_seed_enabled"), true);
        };

        // Max Mint per wallet check
        let max_mints_per_wallet_toggle = get_lootbox_extension_bool(lootbox.collection_resource_address, collection_name_str, string::utf8(EXTENSION_MAX_MINTS_KEY));
        if(max_mints_per_wallet_toggle == option::some(true)) {
            
            let max_mints_per_wallet_amount = get_lootbox_extension_u64(lootbox.collection_resource_address, collection_name_str, string::utf8(EXTENSION_MAX_MINTS_KEY));
            if(max_mints_per_wallet_amount == option::none()) {
                assert!(false, error::invalid_state(EMAX_MINTS_PER_WALLET_NOT_SET));
            };

            let max_mints_per_wallet_amount = *option::borrow(&max_mints_per_wallet_amount);

            if(max_mints_per_wallet_amount == 0) {
                assert!(false, error::invalid_state(EMAX_MINTS_PER_WALLET_AMOUNT_ZERO));
            };

            let collection_signer = account::create_signer_with_capability(&lootbox.collection_resource_signer_cap);
            let max_mints_per_current_wallet_key = string::utf8(EXTENSION_MAX_MINTS_KEY); 
            string::append(&mut max_mints_per_current_wallet_key, string_utils::to_string_with_canonical_addresses(&buyer_addr));

            let current_wallet_mint_count = get_lootbox_extension_u64(lootbox.collection_resource_address, collection_name_str, max_mints_per_current_wallet_key);
            if(current_wallet_mint_count == option::none()) {
                internal_set_lootbox_extension_u64(&collection_signer, collection_name_str, max_mints_per_current_wallet_key, 1);
            }else {
                let current_wallet_mint_count = *option::borrow(&current_wallet_mint_count);
                if(current_wallet_mint_count >= max_mints_per_wallet_amount) {
                    assert!(false, error::invalid_state(EMAX_MINTS_PER_WALLET_AMOUNT_REACHED));
                };
                internal_set_lootbox_extension_u64(&collection_signer, collection_name_str, max_mints_per_current_wallet_key, current_wallet_mint_count + 1);
            }
        };


        let token_count = vector::length(&lootbox.tokensInLootbox);
        let at_least_one_available = false;
        let i = 0;
        
        // Check if distribution is upgraded, if yes, use for loop to check if at least one token is available
        if(is_distribution_upgraded(lootbox)) {
            let handlers = borrow_global<LootboxDistributionHandlers>(creator_addr);
            let handler = table::borrow(&handlers.distribution_handlers, collection_name_str);
            at_least_one_available = has_at_least_one_available_token(lootbox, handler);
        }
        else {
            // Distribution not upgraded, use while loop to check if at least one token is available
            while (i < token_count) {
                let token_name = *vector::borrow(&lootbox.tokensInLootbox, i);
            
                // Get token supply from the collection
                let token_data_id = token::create_token_data_id(
                    lootbox.collection_resource_address,
                    collection_name_str,
                    token_name
                );
                
                // Check if this token has supply available
                let curSupply = token::get_token_supply(lootbox.collection_resource_address, token_data_id);

                // If the token has a current supply, check against max supply.
                if (curSupply != option::none()) {
                    let maxSupply = token::get_tokendata_maximum(token_data_id);
                    if (maxSupply != 0) {
                        let curSupplyValue = *option::borrow(&curSupply);
                        if(curSupplyValue < maxSupply) {
                            at_least_one_available = true;
                            break
                        };
                    // Max supply == 0 means infinite supply.
                    }else {
                        at_least_one_available = true;
                        break
                    };
                // If the token has no current supply, it is available to mint / has no max supply.
                }else {
                    at_least_one_available = true;
                    break
                };
                
                i = i + 1;
                };
        };
        
        // Assert that at least one token is available for minting
        assert!(at_least_one_available, error::invalid_state(ENO_TOKENS_AVAILABLE_TO_MINT));

        // Check if price is set
        assert!(exists<FixedPriceListing<CoinType>>(lootbox.priceResourceAddress), error::not_found(EPRICE_NOT_SET_OR_INVALID_COIN_TYPE));
        // Fetch the price
        let price = borrow_global<FixedPriceListing<CoinType>>(lootbox.priceResourceAddress).price;

        // Check buyer's balance
        let buyer_balance = coin::balance<CoinType>(buyer_addr);
        assert!(buyer_balance >= price, error::invalid_argument(EINSUFFICIENT_BALANCE));

        // Distribute payment
        let marketplace_cut = price / 10; // 10%
        let creator_cut = price - marketplace_cut; // 90%

        let dvrf_amount = 1000000; 
        let dvrf_cut = 0;

        //Unused params reduce warnings in a no-op way
        let _ = dvrf_cut;

        //Check if marketplace cut is > than dvrf amount else use marketplace cut for dvrf deduction
        if(marketplace_cut < dvrf_amount) {
            dvrf_cut = marketplace_cut;
        }
        else {
            dvrf_cut = dvrf_amount;
        };
        marketplace_cut = marketplace_cut - dvrf_cut;

        // Deduct payment from the buyer
        let marketplace_cut_coins = coin::withdraw<CoinType>(buyer, marketplace_cut);
        let dvrf_cut_coins = coin::withdraw<CoinType>(buyer, dvrf_cut);
        let creator_cut_coins = coin::withdraw<CoinType>(buyer, creator_cut);

        // Deposit the coins to the creator and marketplace
        supra_account::deposit_coins(lootbox.creator, creator_cut_coins);
        supra_account::deposit_coins(@projectOwnerAdr, marketplace_cut_coins);

        // Deposit the coins to the dvrf
        let module_resource_info = borrow_global<ResourceInfo>(@projectOwnerAdr);
        let module_resource_signer = account::create_signer_with_capability(&module_resource_info.signer_cap);
        supra_account::deposit_coins(signer::address_of(&module_resource_signer), dvrf_cut_coins);
        deposit::deposit_fund(&module_resource_signer, dvrf_cut);

        // Update lootbox state
        lootbox.stock = lootbox.stock - 1;
        lootbox.rolled = lootbox.rolled + 1;

        // Request VRF
        let callback_address = @projectOwnerAdr;
        let callback_module = string::utf8(CALLBACK_MODULE_NAME);
        let callback_function = string::utf8(b"receive_dvrf");

        // Get this module's own resource signer
        let module_resource_info = borrow_global<ResourceInfo>(@projectOwnerAdr);
        let module_resource_signer = account::create_signer_with_capability(&module_resource_info.signer_cap);
        
        //debug::print(&b"module resource signer: ");
        assert!(signer::address_of(&module_resource_signer) == @v17_resource_addr, error::invalid_state(EINVALID_MODULE_RESOURCE_SIGNER));

        //Auto Opt In To Direct Transfer for Testnet Purposes
        token::opt_in_direct_transfer(buyer, true);

        let client_seed = timestamp::now_microseconds();  // Use timestamp as seed
        let nonce = supra_vrf::rng_request(
            //buyer, //Only works with the blindbox account
            &module_resource_signer, //awaiting response from VRF team, seems like been approved to use
            callback_address, 
            callback_module, 
            callback_function, 
            1,  // rng_count 
            client_seed,
            1   // num_confirmations
        );

        // Store pending reward
        let pending_rewards = borrow_global_mut<PendingRewards>(@projectOwnerAdr);
        let pending_reward = PendingReward {
            buyer: buyer_addr,
            creator: creator_addr,
            collection_name: collection_name_str,
            quantity: 1, //quantity
            nonce,
        };

        // Add to pending rewards
        table::add(&mut pending_rewards.rewards, nonce, pending_reward);

        // Update whitelist amount at the end of successful purchase
        if (lootbox.whitelistMode) {
            let remaining_amount = *table::borrow(&lootbox.allow_mintList, buyer_addr) - 1;
            *table::borrow_mut(&mut lootbox.allow_mintList, buyer_addr) = remaining_amount;
        };

        // Emit purchase event
        event::emit(
            LootboxPurchaseInitiatedEvent {
                buyer: buyer_addr,
                creator: creator_addr,
                collection_name: collection_name_str,
                quantity:1,
                nonce: nonce,
                timestamp: timestamp::now_microseconds(),
                price: price,
                price_coinType: type_info::type_name<CoinType>(),
            }
        );
    }

    #[view]
    public fun view_current_time(): u64 {
        timestamp::now_microseconds()
    }

    #[view]
    public fun simulate_dvrf_resultV2(
        creator_addr: address,
        collection_name: String,
        random_num: u256,
    ): (String, String, u256) acquires Lootboxes, LootboxDistributionHandlers, LootboxExtensions {
        let lootboxes = borrow_global<Lootboxes>(creator_addr);
        let lootbox = table::borrow(&lootboxes.lootbox_table, collection_name);
        
        if(is_distribution_upgraded(lootbox)) {
            let handlers = borrow_global_mut<LootboxDistributionHandlers>(creator_addr);
            let handler = table::borrow_mut(&mut handlers.distribution_handlers, collection_name);
            let (selected_rarity, selected_token, _) = select_rarity_and_token_distribution_upgraded(lootbox, random_num, handler);
            return (selected_rarity, selected_token, random_num)
        }
        else {
            // Select rarity based on weights
            let selected_rarity = select_rarity(lootbox, random_num);
                
            // If no valid rarity found, return empty strings
            if (selected_rarity == string::utf8(b"")) {
                return (string::utf8(b""), string::utf8(b"CRYSTARA_NO_TOKEN_FOUND"), random_num)
            };

            // Get tokens of that rarity
            let tokens_of_rarity = get_tokens_by_rarity(lootbox, selected_rarity);
            
            // If no tokens in that rarity, return empty token name
            let len = vector::length(&tokens_of_rarity);
            if (len == 0) {
                return (selected_rarity, string::utf8(b"CRYSTARA_NO_TOKEN_FOUND"), random_num)
            };
            
            // Calculate token index using same logic as receive_dvrf
            let len_u256 = (len as u256);
            let token_index = random_num % len_u256;
            let token_index_u64 = (token_index as u64);
            
            // Get selected token
            let selected_token = *vector::borrow(&tokens_of_rarity, token_index_u64);
            
            // Return tuple of (selected_rarity, selected_token, random_number)
            return (selected_rarity, selected_token, random_num)
        }
    }

    //DEPRECATED
    #[view]
    public fun simulate_dvrf_result(
        random_num: u256,
        creator_addr: address,
        collection_name: vector<u8>
    ): (String, String, u256) acquires Lootboxes {
        // Get lootbox
        let lootboxes = borrow_global<Lootboxes>(creator_addr);
        let lootbox = table::borrow(&lootboxes.lootbox_table, string::utf8(collection_name));

        let _ = random_num;
        let _ = lootbox;
        // Return tuple of (selected_rarity, selected_token, random_number)
        (string::utf8(b"DEPRECATED"), string::utf8(b"DEPRECATED"), 0)
    }

    //DO NOT RELEASE TO MAINNET
    public entry fun module_owner_force_dvrf_distribution(
        signer: &signer,
        creator_addr: address,
        collection_name: vector<u8>,
        random_num: u256,
        buyer: address
    ) acquires  Lootboxes, UserClaimResourceInfoV2, LootboxExtensions, LootboxDistributionHandlers {

            assert!(signer::address_of(signer) == @projectOwnerAdr, error::permission_denied(EINVALID_VRF_CALLER));

            let random_numbers = vector[];
            vector::push_back(&mut random_numbers, random_num);

            // Emit VRF callback event
            event::emit(
                VRFCallbackReceivedEvent {
                    nonce: 0,
                    caller_address: signer::address_of(signer),
                    random_numbers: random_numbers,
                    timestamp: timestamp::now_microseconds()
                }
            );

            // Get lootbox
            let lootboxes = borrow_global_mut<Lootboxes>(creator_addr);
            let collection_name_str = string::utf8(collection_name);
            let lootbox = table::borrow_mut(&mut lootboxes.lootbox_table, collection_name_str);
            
            let selected_rarity = string::utf8(b"");    
            let selected_token = string::utf8(b"");
            let token_index = 0;

            let _ = selected_rarity;
            let _ = selected_token;

            //New distribution logic
            if(is_distribution_upgraded(lootbox)) {
                let handlers = borrow_global_mut<LootboxDistributionHandlers>(creator_addr);
                let handler = table::borrow_mut(&mut handlers.distribution_handlers, collection_name_str);
                (selected_rarity, selected_token, token_index) = select_rarity_and_token_distribution_upgraded(lootbox, random_num, handler);
            }
            //Old distribution logic
            else {
                selected_rarity = select_rarity(lootbox, random_num);

                // Get tokens of that rarity
                let token_count = get_rarity_token_count(lootbox, selected_rarity);
                if (token_count == 0) {
                    emit_no_token_event(0, buyer, creator_addr, collection_name_str, selected_rarity, random_num);
                    return
                };

                // Get tokens of that rarity
                let tokens_of_rarity = get_tokens_by_rarity(lootbox, selected_rarity);

                // Unused params reduce warnings in a no-op way
                let _ = tokens_of_rarity;
            
                // Verify we have tokens to select from
                let len = vector::length(&tokens_of_rarity);
                if (len == 0) {
                    emit_no_token_event(0, buyer, creator_addr, collection_name_str, selected_rarity, random_num);
                    return
                };
                
                // Safe conversion: len is guaranteed to fit in u256
                let len_u256 = (len as u256);
                
                // Calculate token index using full u256 randomness
                let token_index = random_num % len_u256;
                
                // Safe conversion back to u64: guaranteed to be less than len
                let token_index_u64 = (token_index as u64);
                assert!(token_index_u64 < len, error::invalid_state(EUNSAFE_NUMBER_CONVERSION));
                
                selected_token = *vector::borrow(&tokens_of_rarity, token_index_u64);
            };

            if (selected_rarity == string::utf8(b"") || selected_token == string::utf8(b"")) {
                // Emit event that no token was found
                emit_no_token_event(0, buyer, creator_addr, collection_name_str, selected_rarity, random_num);
                return
            };

            // Get collection signer
            let collection_signer = account::create_signer_with_capability(&lootbox.collection_resource_signer_cap);

            // Create token data id
            let token_data_id = token::create_token_data_id(
                lootbox.collection_resource_address,
                string::utf8(collection_name),
                selected_token
            );

            let user_claim_seed = USER_CLAIM_RESOURCE_SEED;
            let user_claim_resource_address = account::create_resource_address(&buyer, user_claim_seed);
            // If user claim resource account doesn't exist, create it
            assert!(account::exists_at(user_claim_resource_address), error::not_found(ERESOURCE_ESCROW_CLAIM_ACCOUNT_NOT_EXISTS)); 
            // Get the resource account signer using stored capability
            let claim_info = borrow_global_mut<UserClaimResourceInfoV2>(user_claim_resource_address);
            let user_claim_escrow_signer = account::create_signer_with_capability(&claim_info.resource_signer_cap);


            // Mint token into collection owner resource account
            let token_minted_id = token::mint_token(
                &collection_signer,
                token_data_id,
                1  // amount
            );

            if(is_distribution_upgraded(lootbox)) {
                let handlers = borrow_global_mut<LootboxDistributionHandlers>(creator_addr);
                let handler = table::borrow_mut(&mut handlers.distribution_handlers, collection_name_str);
                update_distribution_handler_post_mint(handler, selected_rarity, token_index, lootbox);
            };

            // Upgrading SFT/NFT to NFT based on Random Seed
            let dynamic_seed = get_lootbox_extension_bool(lootbox.collection_resource_address, string::utf8(collection_name), string::utf8(b"dynamic_seed_enabled"));

            
            if (dynamic_seed == option::some(true)) {
                let property_keys = vector[
                    string::utf8(b"rarity"),
                    string::utf8(b"seed"),
                    ];
                let property_values = vector[
                    bcs::to_bytes(&selected_rarity), 
                    bcs::to_bytes(&random_num),
                    ];
                let property_types = vector[
                    string::utf8(b"String"),
                    string::utf8(b"u256")
                    ];
                token_minted_id = token::mutate_one_token(
                    &collection_signer,
                    signer::address_of(&collection_signer),
                    token_minted_id,
                    property_keys,
                    property_values,
                    property_types,
                );
            };

            //return values are public fun get_token_id_fields(token_id: &TokenId): (address, String, String, u64) {
            let (_, _, _, minted_property_version) = token::get_token_id_fields(&token_minted_id);
            
            //Transfer to buyer if OPT IN is true
            if(token::get_direct_transfer(buyer)) {
                token::transfer(
                    &collection_signer, 
                    token_minted_id,
                    buyer,
                    1 //amount
                );
            }
            //Add to escrow
            else { 
                vector::push_back(&mut claim_info.claimable_tokens, TokenIdentifierV2 {
                    creator: lootbox.collection_resource_address,
                    collection: string::utf8(collection_name),
                    name: selected_token,
                    property_version: minted_property_version
                });

                // Transfer token to buyer escrow resource account
                token::direct_transfer(
                    &collection_signer,
                    &user_claim_escrow_signer,
                    token_minted_id,
                    1 //amount
                );
            };


            // Emit distribution event
            event::emit(
                LootboxRewardDistributedEvent {
                    nonce: 0,
                    buyer: buyer,
                    creator: creator_addr,
                    collection_name: string::utf8(collection_name),
                    selected_token: selected_token,
                    selected_rarity: selected_rarity,
                    random_number: random_num,
                    timestamp: timestamp::now_microseconds()
                }
            );
        }

    // Helper function to get token count for a rarity without loading all tokens
    fun get_rarity_token_count(lootbox: &Lootbox, rarity: String): u64 {
        let count = 0u64;
        let i = 0;
        let len = vector::length(&lootbox.tokensInLootbox);
        
        while (i < len) {
            let token_name = *vector::borrow(&lootbox.tokensInLootbox, i);
            if (*table::borrow(&lootbox.token_rarity_mapping, token_name) == rarity) {
                count = count + 1;
            };
            i = i + 1;
        };
        count
    }

    // Helper function to get specific token at index for a rarity
    fun get_token_at_index(lootbox: &Lootbox, rarity: String, target_index: u64): String {
        let current_index = 0u64;
        let i = 0;
        let len = vector::length(&lootbox.tokensInLootbox);
        
        while (i < len) {
            let token_name = *vector::borrow(&lootbox.tokensInLootbox, i);
            if (*table::borrow(&lootbox.token_rarity_mapping, token_name) == rarity) {
                if (current_index == target_index) {
                    return token_name
                };
                current_index = current_index + 1;
            };
            i = i + 1;
        };
        abort error::invalid_state(EINVALID_TOKEN_INDEX)
    }

    // Helper function to emit no token found event
    fun emit_no_token_event(
        nonce: u64,
        buyer: address,
        creator: address,
        collection_name: String,
        selected_rarity: String,
        random_number: u256
    ) {
        event::emit(
            LootboxRewardDistributedEvent {
                nonce,
                buyer,
                creator,
                collection_name,
                selected_token: string::utf8(b"CRYSTARA_NO_TOKEN_FOUND"),
                selected_rarity,
                random_number,
                timestamp: timestamp::now_microseconds()
            }
        );
    }

        // Initialize the distribution handlers resource
    fun init_distribution_handlers(source_account: &signer) {
        if (!exists<LootboxDistributionHandlers>(signer::address_of(source_account))) {
            move_to(source_account, LootboxDistributionHandlers {
                distribution_handlers: table::new<String, LootboxDistributionHandler>(),
            });
        };
    }

        // Initialize distribution handler for a collection if it doesn't exist
    fun init_distribution_handler_for_collection(
        creator: &signer,
        collection_name: String
    ) acquires LootboxDistributionHandlers {
        let creator_addr = signer::address_of(creator);
        
        // Initialize handlers resource if it doesn't exist
        if (!exists<LootboxDistributionHandlers>(creator_addr)) {
            move_to(creator, LootboxDistributionHandlers {
                distribution_handlers: table::new<String, LootboxDistributionHandler>(),
            });
        };
        
        let handlers = borrow_global_mut<LootboxDistributionHandlers>(creator_addr);
        
        // Initialize handler for collection if it doesn't exist
        if (!table::contains(&handlers.distribution_handlers, collection_name)) {
            table::add(&mut handlers.distribution_handlers, collection_name, LootboxDistributionHandler {
                creator: creator_addr,
                collection_name,
                avail_tokens_in_rarity: table::new<String, vector<String>>(),
            });
        };
    }

    // Upgrade a specific rarity for a lootbox to use the new distribution system
    public entry fun upgrade_lootbox_rarity_distribution(
        creator: &signer,
        collection_name: vector<u8>,
        rarity: vector<u8>
    ) acquires Lootboxes, LootboxDistributionHandlers {
        let collection_name_str = string::utf8(collection_name);
        let rarity_str = string::utf8(rarity);
        
        // Get lootbox
        let lootboxes = borrow_global<Lootboxes>(signer::address_of(creator));
        let lootbox = table::borrow(&lootboxes.lootbox_table, collection_name_str);
        
        // Verify creator
        assert!(lootbox.creator == signer::address_of(creator), error::permission_denied(ENOT_AUTHORIZED));
        
        // Verify rarity exists
        assert!(table::contains(&lootbox.rarities, rarity_str), error::not_found(ERARITY_NOTEXISTS));
        
        // Initialize distribution handler if needed
        init_distribution_handler_for_collection(creator, collection_name_str);
        
        // Get distribution handler
        let handlers = borrow_global_mut<LootboxDistributionHandlers>(signer::address_of(creator));
        let handler = table::borrow_mut(&mut handlers.distribution_handlers, collection_name_str);
        
        // Create new vector for available tokens
        let avail_tokens = vector::empty<String>();
        
        // Add all available tokens for this rarity
        let i = 0;
        let len = vector::length(&lootbox.tokensInLootbox);
        while (i < len) {
            let token_name = *vector::borrow(&lootbox.tokensInLootbox, i);
            if (*table::borrow(&lootbox.token_rarity_mapping, token_name) == rarity_str) {
                let (cur_supply, max_supply) = get_token_supply_and_maximum(lootbox, token_name);
                if (max_supply == 0 || cur_supply < max_supply) {
                    vector::push_back(&mut avail_tokens, token_name);
                };
            };
            i = i + 1;
        };

        // Add or update the rarity's available tokens
        if (table::contains(&handler.avail_tokens_in_rarity, rarity_str)) {
            table::remove(&mut handler.avail_tokens_in_rarity, rarity_str);
        };

        table::add(&mut handler.avail_tokens_in_rarity, rarity_str, avail_tokens);
    }

    // Helper function to check if a specific rarity is upgraded
    #[view]
    public fun is_rarity_distribution_upgraded(
        creator: address,
        collection_name: String,
        rarity: String
    ): bool acquires LootboxDistributionHandlers {
        if (!exists<LootboxDistributionHandlers>(creator)) {
            return false
        };

        let handlers = borrow_global<LootboxDistributionHandlers>(creator);
        if (!table::contains(&handlers.distribution_handlers, collection_name)) {
            return false
        };

        let handler = table::borrow(&handlers.distribution_handlers, collection_name);
        table::contains(&handler.avail_tokens_in_rarity, rarity)
    }

    fun get_token_supply_and_maximum(lootbox: &Lootbox, token_name: String): (u64, u64) {
        let token_data_id = token::create_token_data_id(
            lootbox.collection_resource_address,
            lootbox.collectionName,
            token_name
        );
        
        let current_supply = token::get_token_supply(lootbox.collection_resource_address, token_data_id);
        let maximum_supply = token::get_tokendata_maximum(token_data_id);
        
        let current = if (option::is_none(&current_supply)) {
            0
        } else {
            *option::borrow(&current_supply)
        };
        
        (current, maximum_supply)
    }

    // Check if distribution is upgraded for a lootbox
    public fun is_distribution_upgraded(
        lootbox: &Lootbox
    ): bool acquires LootboxDistributionHandlers, LootboxExtensions {
        if (!exists<LootboxDistributionHandlers>(lootbox.creator)) {
            return false
        };

        let handlers = borrow_global<LootboxDistributionHandlers>(lootbox.creator);
        if (!table::contains(&handlers.distribution_handlers, lootbox.collectionName)) {
            return false
        };

        let handler = table::borrow(&handlers.distribution_handlers, lootbox.collectionName);
        
        let distribution_upgraded_option = get_lootbox_extension_bool(lootbox.collection_resource_address, lootbox.collectionName, string::utf8(b"is_distribution_upgraded_by_default"));
        if(option::is_some(&distribution_upgraded_option) && *option::borrow(&distribution_upgraded_option) == true) {
            return true
        };

        // Check if all rarities are present in the handler
        let i = 0;
        let len = vector::length(&lootbox.rarity_keys);
        while (i < len) {
            let rarity = vector::borrow(&lootbox.rarity_keys, i);
            if (!table::contains(&handler.avail_tokens_in_rarity, *rarity)) {
                return false
            };
            i = i + 1;
        };
        true
    }

    // Select rarity, token, and index in one function
    fun select_rarity_and_token_distribution_upgraded(
        lootbox: &Lootbox,
        random_num: u256,
        handler: &mut LootboxDistributionHandler
    ): (String, String, u64) acquires LootboxExtensions {
        let total_weight = (0 as u256);
        let rarities = &lootbox.rarities;
        
        let len = vector::length(&lootbox.rarity_keys);
        if (len == 0) {
            return (string::utf8(b""), string::utf8(b"CRYSTARA_NO_TOKEN_FOUND"), 0)
        };
        
        // Calculate total weight and store sorted rarities by weight (descending)
        let i = 0;
        let sorted_rarities = vector::empty<String>();
        let sorted_weights = vector::empty<u64>();
        
        while (i < len) {
            let rarity = vector::borrow(&lootbox.rarity_keys, i);
            let weight = *table::borrow(rarities, *rarity);
            total_weight = total_weight + (weight as u256);
            
            // Insert into sorted vectors
            let j = 0;
            let inserted = false;
            while (j < vector::length(&sorted_weights)) {
                if (weight >= *vector::borrow(&sorted_weights, j)) {
                    vector::insert(&mut sorted_weights, j, weight);
                    vector::insert(&mut sorted_rarities, j, *rarity);
                    inserted = true;
                    break
                };
                j = j + 1;
            };
            if (!inserted) {
                vector::push_back(&mut sorted_weights, weight);
                vector::push_back(&mut sorted_rarities, *rarity);
            };
            
            i = i + 1;
        };
        
        // Use random number to select initial rarity
        let roll = random_num % total_weight;
        let current_weight = (0 as u256);
        
        // Find initially selected rarity
        i = 0;
        let selected_rarity = string::utf8(b"");
        while (i < len) {
            let rarity = vector::borrow(&lootbox.rarity_keys, i);
            let weight = *table::borrow(rarities, *rarity);
            current_weight = current_weight + (weight as u256);
            
            if (roll < current_weight) {
                selected_rarity = *rarity;
                break
            };
            i = i + 1;
        };
        
        if (string::length(&selected_rarity) == 0) {
            return (string::utf8(b""), string::utf8(b"CRYSTARA_NO_TOKEN_FOUND"), 0)
        };
        
        // Check if selected rarity has available tokens and select one if available
        let avail_tokens = table::borrow(&handler.avail_tokens_in_rarity, selected_rarity);
        let avail_len = vector::length(avail_tokens);
        if (avail_len > 0) {
            // Safe conversion: avail_len is guaranteed to fit in u256
            let avail_len_u256 = (avail_len as u256);
            
            // Calculate token index using full u256 randomness
            let token_index = random_num % avail_len_u256;
            
            // Safe conversion back to u64: guaranteed to be less than avail_len
            let token_index_u64 = (token_index as u64);
            let selected_token = *vector::borrow(avail_tokens, token_index_u64);
            return (selected_rarity, selected_token, token_index_u64)
        };
        
        let step_down_rarity_toggle = get_lootbox_extension_bool(lootbox.collection_resource_address, lootbox.collectionName, string::utf8(EXTENSION_STEP_DOWN_RARITY_KEY));
        if (step_down_rarity_toggle == option::some(true) || step_down_rarity_toggle == option::none()) {
            // If no tokens in selected rarity, look for tokens in more common rarities
            i = vector::length(&sorted_rarities) - 1;
            while (i >= 0) {
                let rarity = *vector::borrow(&sorted_rarities, i);
                let weight = *vector::borrow(&sorted_weights, i);
                if (weight >= *table::borrow(rarities, selected_rarity)) {
                    let avail_tokens = table::borrow(&handler.avail_tokens_in_rarity, rarity);
                    let avail_len = vector::length(avail_tokens);
                    if (avail_len > 0) {
                        // Safe conversion: avail_len is guaranteed to fit in u256
                        let avail_len_u256 = (avail_len as u256);
                        
                        // Calculate token index using full u256 randomness
                        let token_index = random_num % avail_len_u256;
                        
                        // Safe conversion back to u64: guaranteed to be less than avail_len
                        let token_index_u64 = (token_index as u64);
                        let selected_token = *vector::borrow(avail_tokens, token_index_u64);
                        return (rarity, selected_token, token_index_u64)
                    };
                };
                if (i > 0) {
                    i = i - 1;
                } else {
                    break
                };
            };
        };

        // If Option for rarer tokens is true, look for tokens in rarer rarities
        let step_up_rarity_toggle = get_lootbox_extension_bool(lootbox.collection_resource_address, lootbox.collectionName, string::utf8(EXTENSION_STEP_UP_RARITY_KEY));
        if (step_up_rarity_toggle == option::some(true) || step_up_rarity_toggle == option::none()) {
            // If no tokens in selected commoner rarities, look for tokens in rarer rarities
            i = 0;
            let len = vector::length(&sorted_rarities);
            while (i < len) {
                let rarity = *vector::borrow(&sorted_rarities, i);
                let weight = *vector::borrow(&sorted_weights, i);
                if (weight <= *table::borrow(rarities, selected_rarity)) {
                    let avail_tokens = table::borrow(&handler.avail_tokens_in_rarity, rarity);
                    let avail_len = vector::length(avail_tokens);
                    if (avail_len > 0) {
                        let avail_len_u256 = (avail_len as u256);
                        let token_index = random_num % avail_len_u256;
                        let token_index_u64 = (token_index as u64);
                        let selected_token = *vector::borrow(avail_tokens, token_index_u64);
                        return (rarity, selected_token, token_index_u64)
                    };
                };
                i = i + 1;
            };
        };
        
        // If no tokens found in any rarity
        (string::utf8(b""), string::utf8(b"CRYSTARA_NO_TOKEN_FOUND"), 0)
    }
    
    fun has_at_least_one_available_token(
        lootbox: &Lootbox,
        handler: &LootboxDistributionHandler
    ): bool {
        let len = vector::length(&lootbox.rarity_keys);
        if (len == 0) {
            return false
        };
        
        let i = 0;
        while (i < len) {
            let rarity = vector::borrow(&lootbox.rarity_keys, i);
            let avail_tokens = table::borrow(&handler.avail_tokens_in_rarity, *rarity);
            if (vector::length(avail_tokens) > 0) {
                return true
            };
            i = i + 1;
        };
        
        false
    }

    // Update distribution handler after minting - now using the exact index
    fun update_distribution_handler_post_mint(
        handler: &mut LootboxDistributionHandler,
        rarity: String,
        token_index: u64,
        lootbox: &Lootbox
    ) {
        let avail_tokens = table::borrow_mut(&mut handler.avail_tokens_in_rarity, rarity);
        let token_name = *vector::borrow(avail_tokens, token_index);
        let (cur_supply, max_supply) = get_token_supply_and_maximum(lootbox, token_name);
        
        if ( max_supply != 0 && cur_supply >= max_supply ) {
            // Remove token at exact index - O(1) operation
            vector::remove(avail_tokens, token_index);
        };
    }
        
    

    // Callback function for VRF
    public entry fun receive_dvrf(
      nonce: u64,
      message: vector<u8>,
      signature: vector<u8>,
      caller_address: address,
      rng_count: u8,
      client_seed: u64,
    ) acquires PendingRewards, Lootboxes, UserClaimResourceInfoV2, LootboxExtensions, LootboxDistributionHandlers {
        // Verify VRF result
        let random_numbers = supra_vrf::verify_callback(
            nonce, 
            message, 
            signature, 
            caller_address, 
            rng_count, 
            client_seed
        );

        assert!(caller_address == @v17_resource_addr, error::permission_denied(EINVALID_VRF_CALLER));

        // Verify we got at least one random number
        assert!(vector::length(&random_numbers) > 0, error::invalid_argument(EINVALID_VECTOR_LENGTH));

        // Emit VRF callback event
        event::emit(
            VRFCallbackReceivedEvent {
                nonce,
                caller_address,
                random_numbers: random_numbers,
                timestamp: timestamp::now_microseconds()
            }
        );

        // Use random number by DVRF CALLBACK
        let random_num = *vector::borrow(&random_numbers, 0);
        
        // Get pending reward
        let pending_rewards = borrow_global_mut<PendingRewards>(@projectOwnerAdr);
        assert!(table::contains(&pending_rewards.rewards, nonce), error::not_found(ENO_NONCE_NOT_FOUND));
        let pending_reward = table::remove(&mut pending_rewards.rewards, nonce);

         // Get lootbox
        let lootboxes = borrow_global_mut<Lootboxes>(pending_reward.creator);
        let collection_name_str = pending_reward.collection_name;
        let lootbox = table::borrow_mut(&mut lootboxes.lootbox_table, collection_name_str);
        
        let selected_rarity = string::utf8(b"");    
        let selected_token = string::utf8(b"");
        let token_index = 0;

        let _ = selected_rarity;
        let _ = selected_token;

        //New distribution logic
        if(is_distribution_upgraded(lootbox)) {
            let handlers = borrow_global_mut<LootboxDistributionHandlers>(pending_reward.creator);
            let handler = table::borrow_mut(&mut handlers.distribution_handlers, collection_name_str);
            (selected_rarity, selected_token, token_index) = select_rarity_and_token_distribution_upgraded(lootbox, random_num, handler);
        }
        //Old distribution logic
        else {
            selected_rarity = select_rarity(lootbox, random_num);

            // Get tokens of that rarity
            let token_count = get_rarity_token_count(lootbox, selected_rarity);
            if (token_count == 0) {
                emit_no_token_event(nonce, pending_reward.buyer, pending_reward.creator, collection_name_str, selected_rarity, random_num);
                return
            };

            // Get tokens of that rarity
            let tokens_of_rarity = get_tokens_by_rarity(lootbox, selected_rarity);

            // Unused params reduce warnings in a no-op way
            let _ = tokens_of_rarity;
        
            // Verify we have tokens to select from
            let len = vector::length(&tokens_of_rarity);
            if (len == 0) {
                emit_no_token_event(nonce, pending_reward.buyer, pending_reward.creator, collection_name_str, selected_rarity, random_num);
                return
            };
            
            // Safe conversion: len is guaranteed to fit in u256
            let len_u256 = (len as u256);
            
            // Calculate token index using full u256 randomness
            let token_index = random_num % len_u256;
            
            // Safe conversion back to u64: guaranteed to be less than len
            let token_index_u64 = (token_index as u64);
            assert!(token_index_u64 < len, error::invalid_state(EUNSAFE_NUMBER_CONVERSION));
            
            selected_token = *vector::borrow(&tokens_of_rarity, token_index_u64);
        };

        if (selected_rarity == string::utf8(b"") || selected_token == string::utf8(b"")) {
            // Emit event that no token was found
            emit_no_token_event(nonce, pending_reward.buyer, pending_reward.creator, collection_name_str, selected_rarity, random_num);
            return
        };

        // Get collection signer
        let collection_signer = account::create_signer_with_capability(&lootbox.collection_resource_signer_cap);

        // Create token data id
        let token_data_id = token::create_token_data_id(
            lootbox.collection_resource_address,
            pending_reward.collection_name,
            selected_token
        );

        let user_claim_seed = USER_CLAIM_RESOURCE_SEED;
        let user_claim_resource_address = account::create_resource_address(&pending_reward.buyer, user_claim_seed);
        // If user claim resource account doesn't exist, create it
        assert!(account::exists_at(user_claim_resource_address), error::not_found(ERESOURCE_ESCROW_CLAIM_ACCOUNT_NOT_EXISTS)); 
        // Get the resource account signer using stored capability
        let claim_info = borrow_global_mut<UserClaimResourceInfoV2>(user_claim_resource_address);
        let user_claim_escrow_signer = account::create_signer_with_capability(&claim_info.resource_signer_cap);


        // Mint token into collection owner resource account
        let token_minted_id = token::mint_token(
            &collection_signer,
            token_data_id,
            1  // amount
        );

        if(is_distribution_upgraded(lootbox)) {
            let handlers = borrow_global_mut<LootboxDistributionHandlers>(pending_reward.creator);
            let handler = table::borrow_mut(&mut handlers.distribution_handlers, collection_name_str);
            update_distribution_handler_post_mint(handler, selected_rarity, token_index, lootbox);
        };

        // Upgrading SFT/NFT to NFT based on Random Seed
        let dynamic_seed = get_lootbox_extension_bool(lootbox.collection_resource_address, pending_reward.collection_name, string::utf8(b"dynamic_seed_enabled"));
        if (dynamic_seed == option::some(true)) {
            let property_keys = vector[
                string::utf8(b"rarity"),
                string::utf8(b"seed"),
                ];
            let property_values = vector[
                bcs::to_bytes(&selected_rarity), 
                bcs::to_bytes(&random_num),
                ];
            let property_types = vector[
                string::utf8(b"String"),
                string::utf8(b"u256")
                ];
            token_minted_id = token::mutate_one_token(
                &collection_signer,
                signer::address_of(&collection_signer),
                token_minted_id,
                property_keys,
                property_values,
                property_types,
            );
        };

        //return values are public fun get_token_id_fields(token_id: &TokenId): (address, String, String, u64) {
        let (_, _, _, minted_property_version) = token::get_token_id_fields(&token_minted_id);
        
        //Transfer to buyer if OPT IN is true
        if(token::get_direct_transfer(pending_reward.buyer)) {
            token::transfer(
                &collection_signer, 
                token_minted_id,
                pending_reward.buyer,
                1 //amount
            );
        }
        //Add to escrow
        else { 
            vector::push_back(&mut claim_info.claimable_tokens, TokenIdentifierV2 {
                creator: lootbox.collection_resource_address,
                collection: pending_reward.collection_name,
                name: selected_token,
                property_version: minted_property_version
            });

            // Transfer token to buyer escrow resource account
            token::direct_transfer(
                &collection_signer,
                &user_claim_escrow_signer,
                token_minted_id,
                1 //amount
            );
        };


        // Emit distribution event
        event::emit(
            LootboxRewardDistributedEvent {
                nonce,
                buyer: pending_reward.buyer,
                creator: pending_reward.creator,
                collection_name: pending_reward.collection_name,
                selected_token: selected_token,
                selected_rarity: selected_rarity,
                random_number: random_num,
                timestamp: timestamp::now_microseconds()
            }
        );

    }

    // Helper function to select rarity based on weights
    /*fun select_rarity(lootbox: &Lootbox, random_num: u256): String {
        let total_weight = (0 as u256);
        let rarities = &lootbox.rarities;
        
        let len = vector::length(&lootbox.rarity_keys);
        assert!(len > 0, error::invalid_state(EINVALID_VECTOR_LENGTH));
        
        // Calculate total weight
        let i = 0;
        while (i < len) {
            let rarity = vector::borrow(&lootbox.rarity_keys, i);
            let weight = *table::borrow(rarities, *rarity);
            total_weight = total_weight + (weight as u256);
            i = i + 1;
        };
        
        // Use random number to select rarity
        let roll = random_num % total_weight;
        let current_weight = (0 as u256);
        
        i = 0;
        while (i < len) {
            let rarity = vector::borrow(&lootbox.rarity_keys, i);
            let weight = *table::borrow(rarities, *rarity);
            current_weight = current_weight + (weight as u256);
            
            if (roll < current_weight) {
                return *rarity
            };
            i = i + 1;
        };

        // Fallback to last rarity
        *vector::borrow(&lootbox.rarity_keys, len - 1)
    }*/

    #[view]
    public fun view_verify_selected_rarity(
        creator: address,
        collection_name: String,
        random_num: u256
    ): String acquires Lootboxes {
        let lootboxes = borrow_global<Lootboxes>(creator);
        let lootbox = table::borrow(&lootboxes.lootbox_table, collection_name);

        let selected_rarity = select_rarity(lootbox, random_num);
        selected_rarity
    }

    #[view]
    public fun view_receivable_rarities(
        creator: address,
        collection_name: String,
    ): vector<String> acquires Lootboxes, LootboxDistributionHandlers, LootboxExtensions {
        // Check if Lootboxes exists for creator
        if (!exists<Lootboxes>(creator)) {
            return vector::empty()
        };
        
        let lootboxes = borrow_global<Lootboxes>(creator);
        
        // Check if collection exists in lootbox table
        if (!table::contains(&lootboxes.lootbox_table, collection_name)) {
            return vector::empty()
        };
        
        let lootbox = table::borrow(&lootboxes.lootbox_table, collection_name);
        let is_upgraded = is_distribution_upgraded(lootbox);
        let rarities = lootbox.rarity_keys;
        let receivable_list = vector::empty<String>();
        
        if (is_upgraded) {
            // Check if handlers exist
            if (!exists<LootboxDistributionHandlers>(creator)) {
                return vector::empty()
            };
            
            let handlers = borrow_global<LootboxDistributionHandlers>(creator);
            
            // Check if handler exists for this collection
            if (!table::contains(&handlers.distribution_handlers, collection_name)) {
                return vector::empty()
            };
            
            let handler = table::borrow(&handlers.distribution_handlers, collection_name);
            
            let i = 0;
            while (i < vector::length(&rarities)) {
                let rarity = vector::borrow(&rarities, i);
                // Check if rarity exists in handler
                if (table::contains(&handler.avail_tokens_in_rarity, *rarity)) {
                    let avail_tokens = table::borrow(&handler.avail_tokens_in_rarity, *rarity);
                    if (vector::length(avail_tokens) > 0) {
                        vector::push_back(&mut receivable_list, *rarity);
                    };
                };
                i = i + 1;
            };
        } else {
            let i = 0;
            while (i < vector::length(&rarities)) {
                let rarity = vector::borrow(&rarities, i);
                let available_tokens = get_tokens_by_rarity(lootbox, *rarity);
                if (vector::length(&available_tokens) > 0) {
                    vector::push_back(&mut receivable_list, *rarity);
                };
                i = i + 1;
            };
        };
        
        receivable_list
    }


    //UNUSED / DEPRECATED
    fun select_rarityV2(lootbox: &Lootbox, random_num: u256): String {
        let _ = lootbox;
        let _ = random_num;
        string::utf8(b"")
    }

    fun select_rarity(lootbox: &Lootbox, random_num: u256): String {
        let total_weight = (0 as u256);
        let rarities = &lootbox.rarities;
        
        let len = vector::length(&lootbox.rarity_keys);
        assert!(len > 0, error::invalid_state(EINVALID_VECTOR_LENGTH));
        
        // Calculate total weight and store sorted rarities by weight (descending)
        let i = 0;
        let sorted_rarities = vector::empty<String>();
        let sorted_weights = vector::empty<u64>();
        
        while (i < len) {
            let rarity = vector::borrow(&lootbox.rarity_keys, i);
            let weight = *table::borrow(rarities, *rarity);
            total_weight = total_weight + (weight as u256);
            
            // Insert into sorted vectors
            let j = 0;
            let inserted = false;
            while (j < vector::length(&sorted_weights)) {
                if (weight >= *vector::borrow(&sorted_weights, j)) {
                    vector::insert(&mut sorted_weights, j,weight);
                    vector::insert(&mut sorted_rarities, j, *rarity);
                    inserted = true;
                    break
                };
                j = j + 1;
            };
            if (!inserted) {
                vector::push_back(&mut sorted_weights, weight);
                vector::push_back(&mut sorted_rarities, *rarity);
            };
            
            i = i + 1;
        };
        
        // Use random number to select initial rarity
        let roll = random_num % total_weight;
        let current_weight = (0 as u256);
        
        // Find initially selected rarity
        i = 0;
        let selected_rarity = string::utf8(b""); // Initialize with empty string
        while (i < len) {
            let rarity = vector::borrow(&lootbox.rarity_keys, i);
            let weight = *table::borrow(rarities, *rarity);
            current_weight = current_weight + (weight as u256);
            
            if (roll < current_weight) {
                selected_rarity = *rarity;
                break
            };
            i = i + 1;
        };
        
        if (string::length(&selected_rarity) == 0) {
            //assert!(false, error::not_found(ENO_RARITY_SELECTED));
            return string::utf8(b"")
        };
        
        // Check if selected rarity has available tokens
        let available_tokens = get_tokens_by_rarity(lootbox, selected_rarity);
        if (vector::length(&available_tokens) > 0) {
            return selected_rarity
        };
        
        // If no tokens in selected rarity, look for tokens in more common rarities
        i = vector::length(&sorted_rarities) - 1;
        while (i >= 0) {
            let rarity = *vector::borrow(&sorted_rarities, i);
            let weight = *vector::borrow(&sorted_weights, i);
            if (weight > *table::borrow(rarities, selected_rarity)) {
                let available_tokens = get_tokens_by_rarity(lootbox, rarity);
                if (vector::length(&available_tokens) > 0) {
                    return rarity
                };
            };
            if(i > 0) {
                i = i - 1;
            }else {
                break
            };
        };
        
        // If no tokens found in any rarity, abort
        //assert!(false, error::not_found(ENO_TOKENS_AVAILABLE));
        return string::utf8(b"") // This line will never be reached due to the assert above
    }

    public entry fun set_lootbox_price<CoinType>(
        creator: &signer,
        collection_name: vector<u8>,
        new_price: u64
    ) acquires Lootboxes, FixedPriceListing {

        if(type_info::type_name<CoinType>() != string::utf8(SUPRA_COIN_TYPE)) {
            assert!(false, error::invalid_argument(EINVALID_COIN_TYPE));
        };

        // Get creator address
        let creator_addr = signer::address_of(creator);
        // Get collection name
        let collection_name_str = string::utf8(collection_name);

        // Get the lootbox
        let lootboxes = borrow_global_mut<Lootboxes>(creator_addr);
        assert!(
            table::contains(&lootboxes.lootbox_table, collection_name_str),
            error::not_found(ELOOTBOX_NOTEXISTS)
        );
        let lootbox = table::borrow_mut(&mut lootboxes.lootbox_table, collection_name_str);
        
        // Verify the signer is the creator
        assert!(lootbox.creator == creator_addr, error::permission_denied(ENOT_AUTHORIZED));

        // Get resource signer
        let resource_signer = account::create_signer_with_capability(&lootbox.collection_resource_signer_cap);

        // If price listing exists, update it, otherwise create new
        if (exists<FixedPriceListing<CoinType>>(lootbox.priceResourceAddress)) {
            let price_listing = borrow_global_mut<FixedPriceListing<CoinType>>(lootbox.priceResourceAddress);
            price_listing.price = new_price;
        } else {
            move_to(&resource_signer, FixedPriceListing<CoinType> {
                price: new_price,
            });
        };

        // Optionally emit an event
        // Add this event struct at the top with other events if you want to use it
        event::emit(
            PriceUpdatedEvent {
                creator: creator_addr,
                collection_name: collection_name_str,
                price: new_price,
                price_coinType: type_info::type_name<CoinType>(),
                timestamp: timestamp::now_microseconds()
            }
        );
    }

    // Initialize claim account function
    public entry fun initialize_claim_account(
        user: &signer
    ) {
        let user_addr = signer::address_of(user);
        let user_claim_seed = USER_CLAIM_RESOURCE_SEED;
        let user_claim_resource_address = account::create_resource_address(&user_addr, user_claim_seed);
        
        // Only create if it doesn't exist
        if (!account::exists_at(user_claim_resource_address)) {
            let (resource_account, resource_signer_cap) = account::create_resource_account(
                user,  // Using user's own signer
                user_claim_seed
            );
            
            move_to(&resource_account, UserClaimResourceInfoV2 {
                resource_signer_cap: resource_signer_cap,
                resource_signer_address: signer::address_of(&resource_account),
                claimable_tokens: vector::empty<TokenIdentifierV2>()
            });

            // Emit event
            event::emit(
                EscrowAccountCreatedEvent {
                    owner_address: user_addr,
                    escrow_address: user_claim_resource_address,
                    timestamp: timestamp::now_microseconds()
                }
            );
        };
    }


    // Friend function that can only be called by friend modules
    public fun deposit_to_escrow(
        signer: &signer,
        
        creator: address,
        collection_name: String,
        token_name: String,
        property_version: u64,

        amount: u64,
    ) acquires UserClaimResourceInfoV2 {
        let user_address = signer::address_of(signer);
        assert!(
            exists<UserClaimResourceInfoV2>(user_address),
            error::not_found(ERESOURCE_ESCROW_CLAIM_ACCOUNT_NOT_EXISTS)
        );

        let claim_info = borrow_global_mut<UserClaimResourceInfoV2>(user_address);
        let claim_signer = account::create_signer_with_capability(&claim_info.resource_signer_cap);

        let token_data_id = token::create_token_data_id(creator, collection_name, token_name);
        let token_id = token::create_token_id(token_data_id, property_version);

        let balance = token::balance_of(signer::address_of(signer), token_id);
        assert!(balance >= amount, error::invalid_argument(EINVALID_AMOUNT));

        token::direct_transfer(
            signer,
            &claim_signer,
            token_id,
            amount
        );
    }

    // View function to get the remaining claimable tokens (unique, exluding quantity of each token)
    #[view]
    public fun get_remaining_claimable_tokens(
        claimer_addr: address
    ): u64 acquires UserClaimResourceInfoV2 {
        let user_claim_resource_address = account::create_resource_address(&claimer_addr, USER_CLAIM_RESOURCE_SEED);
        if (!exists<UserClaimResourceInfoV2>(user_claim_resource_address)) {
            return 0
        };
        let claim_info = borrow_global<UserClaimResourceInfoV2>(user_claim_resource_address);
        vector::length(&claim_info.claimable_tokens)
    }

    // Claim all tokens function

    public entry fun claim_all_from_escrow(
        claimer: &signer
    ) acquires UserClaimResourceInfoV2 {
        let claimer_addr = signer::address_of(claimer);
        let user_claim_seed = USER_CLAIM_RESOURCE_SEED;
        let user_claim_resource_address = account::create_resource_address(&claimer_addr, user_claim_seed);
        
        // Check if resource account exists
        assert!(
            account::exists_at(user_claim_resource_address),
            error::not_found(ERESOURCE_ACCOUNT_NOT_EXISTS)
        );

        // Check if UserClaimResourceInfoV2 exists
        assert!(
            exists<UserClaimResourceInfoV2>(user_claim_resource_address),
            error::not_found(ERESOURCE_ACCOUNT_NOT_EXISTS)
        );
        
        // Get claim info and check if there are tokens to claim
        let claim_info = borrow_global_mut<UserClaimResourceInfoV2>(user_claim_resource_address);
        assert!(
            !vector::is_empty(&claim_info.claimable_tokens),
            error::invalid_state(ENO_TOKENS_TO_CLAIM)
        );

        let resource_signer = account::create_signer_with_capability(&claim_info.resource_signer_cap);
        let claimed_tokens = vector::empty<TokenIdentifierV2>();
        let total_claimed = 0;
        let tokens_processed = 0;
        let batch_size = 250;

        // Transfer all tokens
        while (!vector::is_empty(&claim_info.claimable_tokens)  && tokens_processed < batch_size) {
            tokens_processed = tokens_processed + 1;
            let token = vector::pop_back(&mut claim_info.claimable_tokens);
            
            // Create token data id first
            let token_data_id = token::create_token_data_id(
                token.creator,
                token.collection,
                token.name,
            );


            // Create token id with property version 0
            let token_id = token::create_token_id(token_data_id, token.property_version);
            
            // Get balance and transfer if available
            let balance = token::balance_of(claim_info.resource_signer_address, token_id);
            if (balance > 0) {
                token::direct_transfer(
                    &resource_signer,
                    claimer,
                    token_id,
                    balance
                );
                vector::push_back(&mut claimed_tokens, token);
                total_claimed = total_claimed + balance;
            };
        };

        // Emit detailed claim event
        event::emit(
            TokensClaimedEventV2 {
                claimer: claimer_addr,
                claim_resource_address: user_claim_resource_address,
                tokens_claimed: claimed_tokens,
                total_tokens: total_claimed,
                timestamp: timestamp::now_microseconds()
            }
        );
    }

    public entry fun set_lootbox_status(
        creator: &signer,
        collection_name: vector<u8>,
        is_active: bool
    ) acquires Lootboxes {
        let creator_addr = signer::address_of(creator);
        let collection_name_str = string::utf8(collection_name);

        // Get the lootbox
        let lootboxes = borrow_global_mut<Lootboxes>(creator_addr);
        assert!(
            table::contains(&lootboxes.lootbox_table, collection_name_str),
            error::not_found(ELOOTBOX_NOTEXISTS)
        );
        let lootbox = table::borrow_mut(&mut lootboxes.lootbox_table, collection_name_str);
        
        // Verify the signer is the creator
        assert!(lootbox.creator == creator_addr, error::permission_denied(ENOT_AUTHORIZED));

        // Update status
        lootbox.is_active = is_active;

        // Emit event
        event::emit(
            LootboxStatusUpdatedEvent {
                creator: creator_addr,
                collection_name: collection_name_str,
                is_active,
                is_whitelist_mode: lootbox.whitelistMode,
                auto_trigger_whitelist_time: lootbox.automatically_whitelist_mode_at_time,
                auto_trigger_active_time: lootbox.automatically_active_at_time,
                timestamp: timestamp::now_microseconds()
            }
        );
    }

    // Set whitelist status function
    public entry fun set_whitelist_status(
        creator: &signer,
        collection_name: vector<u8>,
        whitelist_mode: bool
    ) acquires Lootboxes {
        let creator_addr = signer::address_of(creator);
        let collection_name_str = string::utf8(collection_name);

        let lootboxes = borrow_global_mut<Lootboxes>(creator_addr);
        assert!(table::contains(&lootboxes.lootbox_table, collection_name_str), error::not_found(ELOOTBOX_NOTEXISTS));
        let lootbox = table::borrow_mut(&mut lootboxes.lootbox_table, collection_name_str);
        assert!(lootbox.creator == creator_addr, error::permission_denied(ENOT_AUTHORIZED));

        lootbox.whitelistMode = whitelist_mode;

        event::emit(
            LootboxStatusUpdatedEvent {
                creator: creator_addr,
                collection_name: collection_name_str,
                is_active: lootbox.is_active,
                is_whitelist_mode: whitelist_mode,
                auto_trigger_whitelist_time: lootbox.automatically_whitelist_mode_at_time,
                auto_trigger_active_time: lootbox.automatically_active_at_time,
                timestamp: timestamp::now_microseconds()
            }
        );
    }

    public entry fun set_whitelist_amounts(
        creator: &signer,
        collection_name: vector<u8>,
        addresses: vector<address>,
        amounts: vector<u64>
    ) acquires Lootboxes {
        add_addresses_to_whitelist(
            creator,
            string::utf8(collection_name),
            addresses,
            amounts,
            true
        );
    }

    // Set auto-activation time
    public entry fun set_auto_activation_time(
        creator: &signer,
        collection_name: vector<u8>,
        activation_time: u64
    ) acquires Lootboxes {
        let creator_addr = signer::address_of(creator);
        let collection_name_str = string::utf8(collection_name);

        let lootboxes = borrow_global_mut<Lootboxes>(creator_addr);
        assert!(table::contains(&lootboxes.lootbox_table, collection_name_str), error::not_found(ELOOTBOX_NOTEXISTS));
        let lootbox = table::borrow_mut(&mut lootboxes.lootbox_table, collection_name_str);
        assert!(lootbox.creator == creator_addr, error::permission_denied(ENOT_AUTHORIZED));

        lootbox.automatically_active_at_time = activation_time;

        event::emit(
            LootboxStatusUpdatedEvent {
                creator: creator_addr,
                collection_name: collection_name_str,
                is_active: lootbox.is_active,
                is_whitelist_mode: lootbox.whitelistMode,
                auto_trigger_whitelist_time: lootbox.automatically_whitelist_mode_at_time,
                auto_trigger_active_time: activation_time,
                timestamp: timestamp::now_microseconds()
            }
        );
    }

    // Set auto-whitelist time
    public entry fun set_auto_whitelist_time(
        creator: &signer,
        collection_name: vector<u8>,
        whitelist_time: u64
    ) acquires Lootboxes {
        let creator_addr = signer::address_of(creator);
        let collection_name_str = string::utf8(collection_name);

        let lootboxes = borrow_global_mut<Lootboxes>(creator_addr);
        assert!(table::contains(&lootboxes.lootbox_table, collection_name_str), error::not_found(ELOOTBOX_NOTEXISTS));
        let lootbox = table::borrow_mut(&mut lootboxes.lootbox_table, collection_name_str);
        assert!(lootbox.creator == creator_addr, error::permission_denied(ENOT_AUTHORIZED));

        lootbox.automatically_whitelist_mode_at_time = whitelist_time;

        event::emit(
            LootboxStatusUpdatedEvent {
                creator: creator_addr,
                collection_name: collection_name_str,
                is_active: lootbox.is_active,
                is_whitelist_mode: lootbox.whitelistMode,
                auto_trigger_whitelist_time: whitelist_time,
                auto_trigger_active_time: lootbox.automatically_active_at_time,
                timestamp: timestamp::now_microseconds()
            }
        );
    }

    #[view]
    public fun get_module_resource_address(): address acquires ResourceInfo {
        let module_resource_info = borrow_global<ResourceInfo>(@projectOwnerAdr);
        module_resource_info.signer_address
    }

    #[view]
    public fun get_escrow_claim_address(user_address: address): address {
        let user_claim_seed = USER_CLAIM_RESOURCE_SEED;
        account::create_resource_address(&user_address, user_claim_seed)
    }

    // ... existing code ...

    #[view]
    public fun get_lootbox_price<CoinType>(
        creator_addr: address,
        collection_name: String
    ): u64 acquires Lootboxes, FixedPriceListing {
        let lootboxes = borrow_global<Lootboxes>(creator_addr);
        let lootbox = table::borrow(&lootboxes.lootbox_table, collection_name);
        let price_listing = borrow_global<FixedPriceListing<CoinType>>(lootbox.priceResourceAddress);
        price_listing.price
    }

    #[view]
    public fun get_lootbox_status(
        creator_addr: address,
        collection_name: String
    ): (u64, u64, bool, bool) acquires Lootboxes {
        let lootboxes = borrow_global<Lootboxes>(creator_addr);
        let lootbox = table::borrow(&lootboxes.lootbox_table, collection_name);
        
        let current_time = timestamp::now_microseconds();
        let time_till_active = if (lootbox.automatically_active_at_time > current_time) {
            lootbox.automatically_active_at_time 
        } else {
            0
        };
        
        let time_till_whitelist = if (lootbox.automatically_whitelist_mode_at_time > current_time) {
            lootbox.automatically_whitelist_mode_at_time
        } else {
            0
        };

        (time_till_active, time_till_whitelist, lootbox.is_active, lootbox.whitelistMode)
    }

    #[view]
    public fun get_lootbox_rarities(
        creator_addr: address,
        collection_name: String
    ): (vector<String>, vector<u64>, vector<bool>) acquires Lootboxes {
        let lootboxes = borrow_global<Lootboxes>(creator_addr);
        let lootbox = table::borrow(&lootboxes.lootbox_table, collection_name);
        
        let rarity_names = lootbox.rarity_keys;
        let weights = vector::empty<u64>();
        let show_items = vector::empty<bool>();
        
        let i = 0;
        let len = vector::length(&rarity_names);
        while (i < len) {
            let rarity = vector::borrow(&rarity_names, i);
            vector::push_back(&mut weights, *table::borrow(&lootbox.rarities, *rarity));
            vector::push_back(&mut show_items, *table::borrow(&lootbox.rarities_showItemWhenRoll, *rarity));
            i = i + 1;
        };
        
        (rarity_names, weights, show_items)
    }

    #[view]
    public fun get_lootbox_rolled(
        creator_addr: address,
        collection_name: String
    ): u64 acquires Lootboxes {
        let lootboxes = borrow_global<Lootboxes>(creator_addr);
        let lootbox = table::borrow(&lootboxes.lootbox_table, collection_name);
        lootbox.rolled
    }

    #[view]
    public fun get_lootbox_maxsupply(
        creator_addr: address,
        collection_name: String
    ): u64 acquires Lootboxes {
        let lootboxes = borrow_global<Lootboxes>(creator_addr);
        let lootbox = table::borrow(&lootboxes.lootbox_table, collection_name);
        lootbox.maxRolls
    }

    public entry fun add_tokens_to_lootbox(
        creator: &signer,
        collection_name: vector<u8>,
        token_uris: vector<vector<u8>>,
        rarities: vector<vector<u8>>,
        max_supplies: vector<u64>
    ) acquires Lootboxes, LootboxDistributionHandlers, LootboxExtensions {
        let creator_addr = signer::address_of(creator);
        let collection_name_str = string::utf8(collection_name);

        // Verify all input vectors have the same length
        let len = vector::length(&token_uris);
        assert!(
            len == vector::length(&rarities) && 
            len == vector::length(&max_supplies),
            error::invalid_argument(EINVALID_INPUT_LENGTHS)
        );

        // Get the lootbox
        let lootboxes = borrow_global_mut<Lootboxes>(creator_addr);
        let lootbox = table::borrow_mut(&mut lootboxes.lootbox_table, collection_name_str);
        
        // Verify the signer is the creator
        assert!(lootbox.creator == creator_addr, error::permission_denied(ENOT_AUTHORIZED));

        // Check distribution upgrade status once
        let is_upgraded = is_distribution_upgraded(lootbox);

        if(is_upgraded) {
            init_distribution_handler_for_collection(
                creator,
                collection_name_str
            );
        };

        let collection_resource_address = lootbox.collection_resource_address;
        let collection_resource_signer = account::create_signer_with_capability(&lootbox.collection_resource_signer_cap);

        let i = 0;
        while (i < len) {
            // Get values for current token
            let token_uri = *vector::borrow(&token_uris, i);
            let rarity = *vector::borrow(&rarities, i);
            let max_supply = *vector::borrow(&max_supplies, i);

            // Generate token name
            let token_count = vector::length(&lootbox.tokensInLootbox);
            let token_name_str = generate_token_name(token_count + 1);

            // Check if token with this name already exists
            assert!(
                !token::check_tokendata_exists(collection_resource_address, collection_name_str, token_name_str),
                error::already_exists(ETOKEN_NAME_ALREADY_EXISTS)
            );
            
            // Verify rarity exists in lootbox configuration
            let rarity_str = string::utf8(rarity);
            assert!(
                table::contains(&lootbox.rarities, rarity_str),
                error::invalid_argument(EINVALID_RARITY)
            );

            // Set up token properties including rarity
            let property_keys = vector[string::utf8(b"rarity")];
            let property_values = vector[rarity];
            let property_types = vector[string::utf8(b"String")];

            // Token Mutability Configuration
            let mutability_settings = vector[false, true, true, true, true];
            let token_mutability_settings = token::create_token_mutability_config(&mutability_settings);

            // Create token metadata in the collection
            token::create_tokendata(
                &collection_resource_signer,
                collection_name_str,
                token_name_str,
                string::utf8(b""),
                max_supply,
                string::utf8(token_uri),
                creator_addr,
                100,
                5,
                token_mutability_settings,
                property_keys, 
                property_values,
                property_types,
            );

            // Store token data
            vector::push_back(&mut lootbox.tokensInLootbox, token_name_str);
            table::add(&mut lootbox.token_rarity_mapping, token_name_str, rarity_str);

            // If distribution is upgraded, add token to available tokens for its rarity
            if (is_upgraded) {
                let handlers = borrow_global_mut<LootboxDistributionHandlers>(creator_addr);
                let handler = table::borrow_mut(&mut handlers.distribution_handlers, collection_name_str);

                if(table::contains(&handler.avail_tokens_in_rarity, rarity_str)) {
                    let avail_tokens = table::borrow_mut(&mut handler.avail_tokens_in_rarity, rarity_str);
                    vector::push_back(avail_tokens, token_name_str);
                }
                else {
                    let avail_tokens = vector::empty<String>();
                    vector::push_back(&mut avail_tokens, token_name_str);
                    table::add(&mut handler.avail_tokens_in_rarity, rarity_str, avail_tokens);
                };
            };

            // Emit event for each token 
            event::emit(
                TokenAddedEvent {
                    creator: creator_addr,
                    collection_name: collection_name_str,
                    token_name: token_name_str,
                    token_uri: string::utf8(token_uri),
                    rarity: rarity_str,
                    max_supply,
                    timestamp: timestamp::now_microseconds()
                }
            );

            i = i + 1;
        };
    }

    public entry fun modify_lootbox_metadata(
        creator: &signer,
        collection_name: vector<u8>,
        new_description: vector<u8>,
        new_uri: vector<u8>
    ) acquires Lootboxes {
        let creator_addr = signer::address_of(creator);
        let collection_name_str = string::utf8(collection_name);

        // Check if Lootboxes exists for creator
        assert!(exists<Lootboxes>(creator_addr), error::not_found(ELOOTBOX_NOTEXISTS));

        // Get the lootbox
        let lootboxes = borrow_global_mut<Lootboxes>(creator_addr);
        assert!(
            table::contains(&lootboxes.lootbox_table, collection_name_str),
            error::not_found(ELOOTBOX_NOTEXISTS)
        );
        let lootbox = table::borrow_mut(&mut lootboxes.lootbox_table, collection_name_str);
        
        // Verify the signer is the creator
        assert!(lootbox.creator == creator_addr, error::permission_denied(ENOT_AUTHORIZED));

        // Get collection resource signer
        let collection_resource_signer = account::create_signer_with_capability(&lootbox.collection_resource_signer_cap);

        // Update collection description if provided
        if (vector::length(&new_description) > 0) {
            token::mutate_collection_description(
                &collection_resource_signer,
                collection_name_str,
                string::utf8(new_description)
            );
        };

        // Update collection URI if provided
        if (vector::length(&new_uri) > 0) {
            token::mutate_collection_uri(
                &collection_resource_signer,
                collection_name_str,
                string::utf8(new_uri)
            );
        };
    }

    //DEPRECATED
    public entry fun create_lootbox_with_rarities<CoinType>(
        source_account: &signer,
        collection_name: vector<u8>,
        description: vector<u8>,
        collection_uri: vector<u8>,
        maximum_supply: u64,
        price: u64,
        requiresKey: bool,
        keys_collection_name: vector<u8>,
        keys_collection_description: vector<u8>,
        keys_collection_url: vector<u8>,
        // Rarity parameters
        rarity_names: vector<vector<u8>>,
        rarity_weights: vector<u64>,
        show_items_on_roll: vector<bool>
    ) acquires Lootboxes { 
        // Check lootbox doesn't already exist if table exists
        let account_addr = signer::address_of(source_account);
        let fresh_account = false;

        //Check if Lootboxes Table Exists for Creator, If No, Init Table.
        if (!exists<Lootboxes>(account_addr)) {
            fresh_account = true;
        };

        let lootboxes = borrow_global_mut<Lootboxes>(account_addr);
        let lootbox = table::borrow_mut(&mut lootboxes.lootbox_table, string::utf8(collection_name));
        assert!(lootbox.creator == account_addr, error::permission_denied(ENOT_AUTHORIZED));
        
        //Unused params reduce warnings in a no-op way
        let _ = description;
        let _ = collection_uri;
        let _ = maximum_supply;
        let _ = price;
        let _ = requiresKey;
        let _ = rarity_names;
        let _ = rarity_weights;
        let _ = show_items_on_roll;
        let _ = keys_collection_name;
        let _ = keys_collection_description;
        let _ = keys_collection_url;
        let _ = fresh_account;

        assert!(false, EDEPRECATED);
    }

    public entry fun create_lootbox_with_rarities_v2<CoinType>(
        source_account: &signer,
        collection_name: vector<u8>,
        description: vector<u8>,
        collection_uri: vector<u8>,
        maximum_supply: u64,
        initial_stock: u64,
        max_stock: u64,
        price: u64,
        requiresKey: bool,
        keys_collection_name: vector<u8>,
        keys_collection_description: vector<u8>,
        keys_collection_url: vector<u8>,
        // Rarity parameters
        rarity_names: vector<vector<u8>>,
        rarity_weights: vector<u64>,
        show_items_on_roll: vector<bool>
    ) acquires Lootboxes {
        create_lootbox<CoinType>(
            source_account,
            collection_name,
            description,
            collection_uri,
            maximum_supply,
            initial_stock,
            max_stock,
            price,
            requiresKey,
            keys_collection_name,
            keys_collection_description,
            keys_collection_url
        );

        // Set rarities...
        set_rarities(
            source_account,
            collection_name,
            rarity_names,
            rarity_weights,
            show_items_on_roll
        );
    }

    //Not in use yet.
    public entry fun create_lootbox_with_rarities_and_extension<CoinType>(
        source_account: &signer,
        collection_name: vector<u8>,
        description: vector<u8>,
        collection_uri: vector<u8>,
        maximum_supply: u64,
        initial_stock: u64,
        max_stock: u64,
        price: u64,
        requiresKey: bool,
        keys_collection_name: vector<u8>,
        keys_collection_description: vector<u8>,
        keys_collection_url: vector<u8>,
        // Rarity parameters
        rarity_names: vector<vector<u8>>,
        rarity_weights: vector<u64>,
        show_items_on_roll: vector<bool>,
        // Offchain Params in extension table 
        extension_url: vector<u8>, 
        extension_rarity_colors: vector<u8>
    ) acquires Lootboxes, LootboxExtensions, LootboxDistributionHandlers {
        // Validations...

        // Call create_lootbox with all parameters
        create_lootbox<CoinType>(
            source_account,
            collection_name,
            description,
            collection_uri,
            maximum_supply,
            initial_stock,
            max_stock,
            price,
            requiresKey,
            keys_collection_name,
            keys_collection_description,
            keys_collection_url
        );

        // Set rarities...
        set_rarities(
            source_account,
            collection_name,
            rarity_names,
            rarity_weights,
            show_items_on_roll
        );

        let account_addr = signer::address_of(source_account);
        let fresh_account = false;

        //Check if Lootboxes Table Exists for Creator, If No, Init Table.
        if (!exists<Lootboxes>(account_addr)) {
            assert!(false, ELOOTBOX_NOTEXISTS);
        };
        let lootboxes = borrow_global_mut<Lootboxes>(account_addr);
        let lootbox = table::borrow_mut(&mut lootboxes.lootbox_table, string::utf8(collection_name));
        assert!(lootbox.creator == account_addr, error::permission_denied(ENOT_AUTHORIZED));

        let collection_signer = account::create_signer_with_capability(&lootbox.collection_resource_signer_cap);

        init_distribution_handler_for_collection(
            source_account,
            string::utf8(collection_name)
        );

        internal_set_lootbox_extension_bool(&collection_signer, string::utf8(collection_name), string::utf8(b"is_distribution_upgraded_by_default"), true);

        // Set extension table values
        internal_set_lootbox_extension_string(&collection_signer, string::utf8(collection_name), string::utf8(b"url"), string::utf8(extension_url));
        internal_set_lootbox_extension_string(&collection_signer, string::utf8(collection_name), string::utf8(b"rarity_colors"), string::utf8(extension_rarity_colors));

        //Unused params reduce warnings in a no-op way
        let _ = fresh_account;
    }


    /* Possibly never add this, just make the lootbox have the same stock as max supply always. Then just let them use whitelisting to control the stock.
    #[event]
    struct LootboxStockUpdatedEvent has drop, store {
        creator: address,
        collection_name: String,
        added_amount: u64,
        new_total_stock: u64,
        timestamp: u64
    }

    public entry fun add_stock_to_lootbox(
        creator: &signer,
        collection_name: vector<u8>,
        add_amount: u64
    ) acquires Lootboxes {
        let creator_addr = signer::address_of(creator);
        let collection_name_str = string::utf8(collection_name);

        // Check if Lootboxes exists for creator
        assert!(exists<Lootboxes>(creator_addr), error::not_found(ELOOTBOX_NOTEXISTS));

        // Get the lootbox
        let lootboxes = borrow_global_mut<Lootboxes>(creator_addr);
        assert!(
            table::contains(&lootboxes.lootbox_table, collection_name_str),
            error::not_found(ELOOTBOX_NOTEXISTS)
        );
        let lootbox = table::borrow_mut(&mut lootboxes.lootbox_table, collection_name_str);
        
        // Verify the signer is the creator
        assert!(lootbox.creator == creator_addr, error::permission_denied(ENOT_AUTHORIZED));

        // Check if adding stock would exceed maxRolls
        assert!(
            lootbox.rolled + add_amount <= lootbox.maxRolls,
            error::invalid_argument(EMAX_ROLLS_REACHED)
        );

        // Add stock
        lootbox.stock = lootbox.stock + add_amount;

        // Emit event for stock update
        event::emit(
            LootboxStockUpdatedEvent {
                creator: creator_addr,
                collection_name: collection_name_str,
                added_amount: add_amount,
                new_total_stock: lootbox.stock,
                timestamp: timestamp::now_microseconds()
            }
        );
    }

    */



    // Internal helper function to initialize extension table
    fun internal_init_lootbox_extension_table(
        extensions: &mut LootboxExtensions,
        creator_addr: address,
        collection_name_str: String
    ) {
        if (!table::contains(&extensions.extensions, collection_name_str)) {
            table::add(&mut extensions.extensions, collection_name_str, LootboxExtension {
                creator: creator_addr,
                collectionName: collection_name_str,
                extended_strings: table::new(),
                extended_bools: table::new(),
                extended_u64: table::new(),
                extended_u256: table::new(),
            });
        };
    }

    

    #[view]
    public fun get_lootbox_extension_string(
        creator_addr: address,
        collection_name: String,
        key: String
    ): Option<String> acquires LootboxExtensions {
        if (!exists<LootboxExtensions>(creator_addr)) {
            return option::none()
        };
        let extensions = borrow_global<LootboxExtensions>(creator_addr);
        if (table::contains(&extensions.extensions, collection_name)) {
            let extension = table::borrow(&extensions.extensions, collection_name);
            if (table::contains(&extension.extended_strings, key)) {
                option::some(*table::borrow(&extension.extended_strings, key))
            } else {
                option::none()
            }
        } else {
            option::none()
        }
    }

    #[view]
    public fun get_lootbox_extension_bool(
        creator_addr: address,
        collection_name: String,
        key: String
    ): Option<bool> acquires LootboxExtensions {
        if (!exists<LootboxExtensions>(creator_addr)) {
            return option::none()
        };
        let extensions = borrow_global<LootboxExtensions>(creator_addr);
        if (table::contains(&extensions.extensions, collection_name)) {
            let extension = table::borrow(&extensions.extensions, collection_name);
            if (table::contains(&extension.extended_bools, key)) {
                option::some(*table::borrow(&extension.extended_bools, key))
            } else {
                option::none()
            }
        } else {
            option::none()
        }
    }

    #[view]
    public fun get_lootbox_extension_u64(
        creator_addr: address,
        collection_name: String,
        key: String
    ): Option<u64> acquires LootboxExtensions {
        if (!exists<LootboxExtensions>(creator_addr)) {
            return option::none()
        };
        let extensions = borrow_global<LootboxExtensions>(creator_addr);
        if (table::contains(&extensions.extensions, collection_name)) {
            let extension = table::borrow(&extensions.extensions, collection_name);
            if (table::contains(&extension.extended_u64, key)) {
                option::some(*table::borrow(&extension.extended_u64, key))
            } else {
                option::none()
            }
        } else {
            option::none()
        }
    }

    #[view]
    public fun get_lootbox_extension_u256(
        creator_addr: address,
        collection_name: String,
        key: String
    ): Option<u256> acquires LootboxExtensions {
        if (!exists<LootboxExtensions>(creator_addr)) {
            return option::none()
        };
        let extensions = borrow_global<LootboxExtensions>(creator_addr);
        if (table::contains(&extensions.extensions, collection_name)) {
            let extension = table::borrow(&extensions.extensions, collection_name);
            if (table::contains(&extension.extended_u256, key)) {
                option::some(*table::borrow(&extension.extended_u256, key))
            } else {
                option::none()
            }
        } else {
            option::none()
        }
    }

    // Internal helper functions that don't require Lootboxes access
    fun internal_set_lootbox_extension_string(
        creator: &signer,
        collection_name_str: String,
        key_str: String,
        value_str: String

    ) acquires LootboxExtensions {
        // Initialize extensions if they don't exist
        let creator_addr = signer::address_of(creator);
        if (!exists<LootboxExtensions>(creator_addr)) {
            move_to(creator, LootboxExtensions {
                extensions: table::new()


            });
        };

        let extensions = borrow_global_mut<LootboxExtensions>(creator_addr);
        
        // Initialize extension table if needed
        internal_init_lootbox_extension_table(extensions, creator_addr, collection_name_str);
        let extension = table::borrow_mut(&mut extensions.extensions, collection_name_str);
        
        // Update string value
        if (table::contains(&extension.extended_strings, key_str)) {
            *table::borrow_mut(&mut extension.extended_strings, key_str) = value_str;
        } else {
            table::add(&mut extension.extended_strings, key_str, value_str);
        };

        // Emit event
        event::emit(
            LootboxExtensionUpdatedEventV2 {
                creator: creator_addr,
                collection_name: collection_name_str,
                updated_key: key_str,
                updated_value: value_str,
                updated_key_type: string::utf8(b"String"),
                timestamp: timestamp::now_microseconds(),
            }
        );
    }

    fun internal_set_lootbox_extension_bool(
        creator: &signer,
        collection_name_str: String,
        key_str: String,
        value: bool

    ) acquires LootboxExtensions {
        let creator_addr = signer::address_of(creator);
        if (!exists<LootboxExtensions>(creator_addr)) {
            move_to(creator, LootboxExtensions {
                extensions: table::new()

            });
        };

        let extensions = borrow_global_mut<LootboxExtensions>(creator_addr);
        
        internal_init_lootbox_extension_table(extensions, creator_addr, collection_name_str);
        let extension = table::borrow_mut(&mut extensions.extensions, collection_name_str);
        
        if (table::contains(&extension.extended_bools, key_str)) {
            *table::borrow_mut(&mut extension.extended_bools, key_str) = value;
        } else {
            table::add(&mut extension.extended_bools, key_str, value);
        };

        event::emit(
            LootboxExtensionUpdatedEventV2 {
                creator: creator_addr,
                collection_name: collection_name_str,
                updated_key: key_str,
                updated_value: string_utils::to_string(&value),
                updated_key_type: string::utf8(b"bool"),
                timestamp: timestamp::now_microseconds(),
            }
        );
    }

    fun internal_set_lootbox_extension_u64(
        creator: &signer,
        collection_name_str: String,
        key_str: String,
        value: u64

    ) acquires LootboxExtensions {
        let creator_addr = signer::address_of(creator);
        if (!exists<LootboxExtensions>(creator_addr)) {
            move_to(creator, LootboxExtensions {

                extensions: table::new()
            });
        };

        let extensions = borrow_global_mut<LootboxExtensions>(creator_addr);
        
        internal_init_lootbox_extension_table(extensions, creator_addr, collection_name_str);
        let extension = table::borrow_mut(&mut extensions.extensions, collection_name_str);
        
        if (table::contains(&extension.extended_u64, key_str)) {
            *table::borrow_mut(&mut extension.extended_u64, key_str) = value;
        } else {
            table::add(&mut extension.extended_u64, key_str, value);
        };

        let emit_event = true;

        if(string::length(&key_str) > string::length(&string::utf8(EXTENSION_MAX_MINTS_KEY))) {
            let substr = string::sub_string(&key_str,0,string::length(&string::utf8(EXTENSION_MAX_MINTS_KEY)));
            if(substr == string::utf8(EXTENSION_MAX_MINTS_KEY)) {
                emit_event = false;
            };
        };

        if(emit_event) {
            event::emit(
                LootboxExtensionUpdatedEventV2 {
                creator: creator_addr,
                collection_name: collection_name_str,
                updated_key: key_str,
                updated_value: string_utils::to_string_with_integer_types(&value),
                updated_key_type: string::utf8(b"u64"),
                    timestamp: timestamp::now_microseconds(),
                }
            );
        }
    }

    fun internal_set_lootbox_extension_u256(
        creator: &signer,
        collection_name_str: String,
        key_str: String,
        value: u256

    ) acquires LootboxExtensions {
        let creator_addr = signer::address_of(creator);
        if (!exists<LootboxExtensions>(creator_addr)) {
            move_to(creator, LootboxExtensions {

                extensions: table::new()
            });
        };

        let extensions = borrow_global_mut<LootboxExtensions>(creator_addr);
        
        internal_init_lootbox_extension_table(extensions, creator_addr, collection_name_str);
        let extension = table::borrow_mut(&mut extensions.extensions, collection_name_str);
        
        if (table::contains(&extension.extended_u256, key_str)) {
            *table::borrow_mut(&mut extension.extended_u256, key_str) = value;
        } else {
            table::add(&mut extension.extended_u256, key_str, value);
        };

        event::emit(
            LootboxExtensionUpdatedEventV2 {
                creator: creator_addr,
                collection_name: collection_name_str,
                updated_key: key_str,
                updated_value: string_utils::to_string_with_integer_types(&value),
                updated_key_type: string::utf8(b"u256"),
                timestamp: timestamp::now_microseconds(),
            }
        );
    }

    // Public entry functions that verify ownership before calling internal functions
    public entry fun set_lootbox_extension_string(
        creator: &signer,
        collection_name: vector<u8>,
        key: vector<u8>,
        value: vector<u8>
    ) acquires  Lootboxes {
        let creator_addr = signer::address_of(creator);
        let collection_name_str = string::utf8(collection_name);
        let key_str = string::utf8(key);
        let value_str = string::utf8(value);

        // Verify lootbox ownership
        let lootboxes = borrow_global<Lootboxes>(creator_addr);
        let lootbox = table::borrow(&lootboxes.lootbox_table, collection_name_str);
        assert!(lootbox.creator == creator_addr, error::permission_denied(ENOT_AUTHORIZED));

        //Unused params reduce warnings in a no-op way
        let _ = key_str;
        let _ = value_str;

        assert!(false, EFUNCTION_DISABLED);

        //internal_set_lootbox_extension_string(creator, collection_name_str, key_str, value_str);
    }

    public entry fun set_lootbox_extension_bool(
        creator: &signer,
        collection_name: vector<u8>,
        key: vector<u8>,
        value: bool
    ) acquires Lootboxes {
        let creator_addr = signer::address_of(creator);
        let collection_name_str = string::utf8(collection_name);
        let key_str = string::utf8(key);

        // Verify lootbox ownership
        let lootboxes = borrow_global<Lootboxes>(creator_addr);
        let lootbox = table::borrow(&lootboxes.lootbox_table, collection_name_str);
        assert!(lootbox.creator == creator_addr, error::permission_denied(ENOT_AUTHORIZED));

        //Unused params reduce warnings in a no-op way
        let _ = key_str;
        let _ = value;

        assert!(false, EFUNCTION_DISABLED);

        //internal_set_lootbox_extension_bool(creator, collection_name_str, key_str, value);
    }


    public entry fun set_lootbox_extension_u64(
        creator: &signer,
        collection_name: vector<u8>,
        key: vector<u8>,
        value: u64
    ) acquires Lootboxes {
        
        let creator_addr = signer::address_of(creator);
        let collection_name_str = string::utf8(collection_name);
        let key_str = string::utf8(key);

        // Verify lootbox ownership
        let lootboxes = borrow_global<Lootboxes>(creator_addr);
        let lootbox = table::borrow(&lootboxes.lootbox_table, collection_name_str);
        assert!(lootbox.creator == creator_addr, error::permission_denied(ENOT_AUTHORIZED));

        //Unused params reduce warnings in a no-op way
        let _ = key_str;
        let _ = value;

        assert!(false, EFUNCTION_DISABLED);

        //internal_set_lootbox_extension_u64(creator, collection_name_str, key_str, value);

    }

    public entry fun set_lootbox_extension_u256(
        creator: &signer,
        collection_name: vector<u8>,
        key: vector<u8>,
        value: u256
    ) acquires Lootboxes {
        
        let creator_addr = signer::address_of(creator);
        let collection_name_str = string::utf8(collection_name);
        let key_str = string::utf8(key);

        // Verify lootbox ownership
        let lootboxes = borrow_global<Lootboxes>(creator_addr);
        let lootbox = table::borrow(&lootboxes.lootbox_table, collection_name_str);
        assert!(lootbox.creator == creator_addr, error::permission_denied(ENOT_AUTHORIZED));

        //Unused params reduce warnings in a no-op way
        let _ = key_str;
        let _ = value;
        
        assert!(false, EFUNCTION_DISABLED);
        //internal_set_lootbox_extension_u256(creator, collection_name_str, key_str, value);
    }

    #[view]
    public fun get_lootbox_info_v1<CoinType>(
        creator_addr: address,
        collection_name: String
    ): (
        // Basic lootbox info
        address, // creator 0
        String,  // collection_name 1
        String,  // description 2
        String,  // collection_uri 3
        // Token collection info

        // Status info (from get_lootbox_status)
        u64,    // time_till_active 4
        u64,    // time_till_whitelist 5
        bool,   // is_active 6
        bool,   // whitelist_mode 7
        // Supply and price info
        u64,    // maxRolls (maxsupply) 8
        u64,    // rolled 9
        u64,    // stock 10
        u64,    // max_stock 11
        u64,    // price 12
        bool,   // requiresKey 13
        // Rarity info (from get_lootbox_rarities)
        vector<String>, // rarity_names 14
        vector<u64>,    // weights 15
        vector<bool>,   // show_items 16
        vector<String>, // viewReceivableRarities 17
        // Extension values
        Option<String>, // url 18
        Option<String>, // rarity_colors 19
        Option<bool>    // dynamic_seed_enabled 20
    ) acquires Lootboxes, FixedPriceListing, LootboxExtensions, LootboxDistributionHandlers {

        // Called first as they borrow Lootbox
        let price = get_lootbox_price<CoinType>(creator_addr, collection_name);
        let viewReceivableRarities = view_receivable_rarities(creator_addr, collection_name);

        // Get status
        let (time_till_active, time_till_whitelist, is_active, whitelist_mode) = 
            get_lootbox_status(creator_addr, collection_name);
        
        // Get rarity info
        let (rarity_names, weights, show_items) = 
            get_lootbox_rarities(creator_addr, collection_name);
        
        // Get supply info
        let rolled = get_lootbox_rolled(creator_addr, collection_name);
        
        // Get extension values
        let url = get_lootbox_extension_string(creator_addr, collection_name, string::utf8(b"url"));
        let rarity_colors = get_lootbox_extension_string(creator_addr, collection_name, string::utf8(b"rarity_colors"));
        let dynamic_seed_enabled = get_lootbox_extension_bool(creator_addr, collection_name, string::utf8(b"dynamic_seed_enabled"));

        assert!(exists<Lootboxes>(creator_addr), error::not_found(ELOOTBOX_NOTEXISTS));
        let lootboxes = borrow_global<Lootboxes>(creator_addr);
        let lootbox = table::borrow(&lootboxes.lootbox_table, collection_name);

        let lootbox_description = token::get_collection_description(lootbox.collection_resource_address, collection_name);
        let lootbox_uri = token::get_collection_uri(lootbox.collection_resource_address, collection_name);


        (
            // Basic lootbox info
            lootbox.creator,
            collection_name,
            lootbox_description,
            lootbox_uri,
            // Token collection info
            // Status info
            time_till_active,
            time_till_whitelist,
            is_active,
            whitelist_mode,
            // Supply and price info
            lootbox.maxRolls,
            rolled,
            lootbox.stock,
            lootbox.maxRolls,
            price,
            lootbox.requiresKey,
            // Rarity info
            rarity_names,
            weights,
            show_items,
            viewReceivableRarities,
            // Extension values
            url,
            rarity_colors,
            dynamic_seed_enabled
        )
    }

        #[view]
    public fun get_lootbox_info_v2<CoinType>(
        creator_addr: address,
        collection_name: String
    ): (
        // Basic lootbox info
        address, // creator
        String,  // collection_name
        String,  // description
        String,  // collection_uri
        // Token collection info

        // Status info (from get_lootbox_status)
        u64,    // time_till_active
        u64,    // time_till_whitelist
        bool,   // is_active
        bool,   // whitelist_mode
        // Supply and price info
        u64,    // maxRolls (maxsupply)
        u64,    // rolled
        u64,    // stock
        u64,    // max_stock
        u64,    // price
        bool,   // requiresKey
        // Rarity info (from get_lootbox_rarities)
        vector<String>, // rarity_names
        vector<u64>,    // weights
        vector<bool>,   // show_items
        vector<String>, // viewReceivableRarities
        // Extension values
        String, // url
        String, // rarity_colors
        bool    // dynamic_seed_enabled
    ) acquires Lootboxes, FixedPriceListing, LootboxExtensions, LootboxDistributionHandlers {

        // Called first as they borrow Lootbox
        let price = get_lootbox_price<CoinType>(creator_addr, collection_name);
        let viewReceivableRarities = view_receivable_rarities(creator_addr, collection_name);

        // Get status
        let (time_till_active, time_till_whitelist, is_active, whitelist_mode) = 
            get_lootbox_status(creator_addr, collection_name);
        
        // Get rarity info
        let (rarity_names, weights, show_items) = 
            get_lootbox_rarities(creator_addr, collection_name);
        
        // Get supply info
        let rolled = get_lootbox_rolled(creator_addr, collection_name);
        

        // Get extension values
        let url = {
            let lootboxes = borrow_global<Lootboxes>(creator_addr);
            let lootbox = table::borrow(&lootboxes.lootbox_table, collection_name);

            let value = option::get_with_default(
                &get_lootbox_extension_string(lootbox.collection_resource_address, collection_name, string::utf8(b"url")),
                string::utf8(b"")
            );
            value
        };
        let rarity_colors = { 
            let lootboxes = borrow_global<Lootboxes>(creator_addr);
            let lootbox = table::borrow(&lootboxes.lootbox_table, collection_name);

            let value = option::get_with_default(
                &get_lootbox_extension_string(lootbox.collection_resource_address, collection_name, string::utf8(b"rarity_colors")),
                string::utf8(b"")
            );
            value
        };
        let dynamic_seed_enabled = {
            let lootboxes = borrow_global<Lootboxes>(creator_addr);
            let lootbox = table::borrow(&lootboxes.lootbox_table, collection_name);

            let value = option::get_with_default(
                &get_lootbox_extension_bool(lootbox.collection_resource_address, collection_name, string::utf8(b"dynamic_seed_enabled")),
                false
            );
            value
        };

        assert!(exists<Lootboxes>(creator_addr), error::not_found(ELOOTBOX_NOTEXISTS));
        let lootboxes = borrow_global<Lootboxes>(creator_addr);
        let lootbox = table::borrow(&lootboxes.lootbox_table, collection_name);

        let lootbox_description = token::get_collection_description(lootbox.collection_resource_address, collection_name);
        let lootbox_uri = token::get_collection_uri(lootbox.collection_resource_address, collection_name);


        (
            // Basic lootbox info
            lootbox.creator,
            collection_name,
            lootbox_description,
            lootbox_uri,
            // Token collection info
            // Status info
            time_till_active,
            time_till_whitelist,
            is_active,
            whitelist_mode,
            // Supply and price info
            lootbox.maxRolls,
            rolled,
            lootbox.stock,
            lootbox.maxRolls,
            price,
            lootbox.requiresKey,
            // Rarity info
            rarity_names,
            weights,
            show_items,
            viewReceivableRarities,
            // Extension values
            url,
            rarity_colors,
            dynamic_seed_enabled
        )
    }

    #[view]
    public fun get_lootbox_info_v3<CoinType>(
        creator_addr: address,
        collection_name: String,
        viewer_addr_str: String
    ): (
        // Basic lootbox info
        address, // creator
        String,  // collection_name
        String,  // description
        String,  // collection_uri
        // Token collection info

        // Status info (from get_lootbox_status)
        u64,    // time_till_active
        u64,    // time_till_whitelist
        bool,   // is_active
        bool,   // whitelist_mode
        // Supply and price info
        u64,    // maxRolls (maxsupply)
        u64,    // rolled
        u64,    // stock
        u64,    // max_stock
        u64,    // price
        bool,   // requiresKey
        // Rarity info (from get_lootbox_rarities)
        vector<String>, // rarity_names
        vector<u64>,    // weights
        vector<bool>,   // show_items
        vector<String>, // viewReceivableRarities
        // Extension values
        String, // url
        String, // rarity_colors
        bool,    // dynamic_seed_enabled 
        bool,    // is max mints enabled
        u64,     // max mints globally
        u64,     // mints remaining for viewer
    ) acquires Lootboxes, FixedPriceListing, LootboxExtensions, LootboxDistributionHandlers {

        // Called first as they borrow Lootbox
        let price = get_lootbox_price<CoinType>(creator_addr, collection_name);
        let viewReceivableRarities = view_receivable_rarities(creator_addr, collection_name);

        // Get status
        let (time_till_active, time_till_whitelist, is_active, whitelist_mode) = 
            get_lootbox_status(creator_addr, collection_name);
        
        // Get rarity info
        let (rarity_names, weights, show_items) = 
            get_lootbox_rarities(creator_addr, collection_name);
        
        // Get supply info
        let rolled = get_lootbox_rolled(creator_addr, collection_name);
        

        // Get extension values
        let url = {
            let lootboxes = borrow_global<Lootboxes>(creator_addr);
            let lootbox = table::borrow(&lootboxes.lootbox_table, collection_name);

            let value = option::get_with_default(
                &get_lootbox_extension_string(lootbox.collection_resource_address, collection_name, string::utf8(b"url")),
                string::utf8(b"")
            );
            value
        };
        let rarity_colors = { 
            let lootboxes = borrow_global<Lootboxes>(creator_addr);
            let lootbox = table::borrow(&lootboxes.lootbox_table, collection_name);

            let value = option::get_with_default(
                &get_lootbox_extension_string(lootbox.collection_resource_address, collection_name, string::utf8(b"rarity_colors")),
                string::utf8(b"")
            );
            value
        };
        let dynamic_seed_enabled = {
            let lootboxes = borrow_global<Lootboxes>(creator_addr);
            let lootbox = table::borrow(&lootboxes.lootbox_table, collection_name);

            let value = option::get_with_default(
                &get_lootbox_extension_bool(lootbox.collection_resource_address, collection_name, string::utf8(b"dynamic_seed_enabled")),
                false
            );
            value
        };

        let is_max_mints_enabled = false;
        let max_mints_globally = 0;
        let mints_remaining_for_viewer = 0;

        {
            let lootboxes = borrow_global<Lootboxes>(creator_addr);
            let lootbox = table::borrow(&lootboxes.lootbox_table, collection_name);

            let val_is_max_mints_enabled = option::get_with_default(
                &get_lootbox_extension_bool(lootbox.collection_resource_address, collection_name, string::utf8(EXTENSION_MAX_MINTS_KEY)),
                false
            );
            is_max_mints_enabled = val_is_max_mints_enabled;

            let val_max_mints_globally = option::get_with_default(
                &get_lootbox_extension_u64(lootbox.collection_resource_address, collection_name, string::utf8(EXTENSION_MAX_MINTS_KEY)),
                0
            );
            max_mints_globally = val_max_mints_globally;

            let max_mints_per_current_wallet_key = string::utf8(EXTENSION_MAX_MINTS_KEY); 
            string::append(&mut max_mints_per_current_wallet_key, viewer_addr_str);
            let val_mints_by_viewer = option::get_with_default(
                &get_lootbox_extension_u64(lootbox.collection_resource_address, collection_name, max_mints_per_current_wallet_key),
                0
            );
            if(max_mints_globally >= val_mints_by_viewer) {
                mints_remaining_for_viewer = max_mints_globally - val_mints_by_viewer;
            } else {
                mints_remaining_for_viewer = 0;
            };
        };

        assert!(exists<Lootboxes>(creator_addr), error::not_found(ELOOTBOX_NOTEXISTS));
        let lootboxes = borrow_global<Lootboxes>(creator_addr);
        let lootbox = table::borrow(&lootboxes.lootbox_table, collection_name);

        let lootbox_description = token::get_collection_description(lootbox.collection_resource_address, collection_name);
        let lootbox_uri = token::get_collection_uri(lootbox.collection_resource_address, collection_name);

        (
            // Basic lootbox info
            lootbox.creator,
            collection_name,
            lootbox_description,
            lootbox_uri,
            // Token collection info
            // Status info
            time_till_active,
            time_till_whitelist,
            is_active,
            whitelist_mode,
            // Supply and price info
            lootbox.maxRolls,
            rolled,
            lootbox.stock,
            lootbox.maxRolls,
            price,
            lootbox.requiresKey,
            // Rarity info
            rarity_names,
            weights,
            show_items,
            viewReceivableRarities,
            // Extension values
            url,
            rarity_colors,
            dynamic_seed_enabled,
            is_max_mints_enabled,
            max_mints_globally,
            mints_remaining_for_viewer
        )
    }
        

    #[view]
    public fun get_whitelist_amount(
        creator_addr: address,
        collection_name: vector<u8>,
        address: address
    ): u64 acquires Lootboxes {
        let collection_name_str = string::utf8(collection_name);
        let lootboxes = borrow_global<Lootboxes>(creator_addr);
        let lootbox = table::borrow(&lootboxes.lootbox_table, collection_name_str);
        assert!(lootbox.creator == creator_addr, error::permission_denied(ENOT_AUTHORIZED));

        if(table::contains(&lootbox.allow_mintList, address)) {
            let amount = *table::borrow(&lootbox.allow_mintList, address);
            amount
        } else {
            0
        }
    }

    public entry fun add_addresses_to_whitelist(
        creator: &signer,
        collection_name: String,
        addresses: vector<address>,
        amounts: vector<u64>,
        replace_existing: bool  // true = replace amount, false = add to existing amount
    ) acquires Lootboxes {
        let creator_addr = signer::address_of(creator);
        
        // Verify vector lengths match
        let addr_len = vector::length(&addresses);
        assert!(addr_len == vector::length(&amounts), error::invalid_argument(EINVALID_VECTOR_LENGTH));
        
        // Get lootbox
        let lootboxes = borrow_global_mut<Lootboxes>(creator_addr);
        let lootbox = table::borrow_mut(&mut lootboxes.lootbox_table, collection_name);
        assert!(lootbox.creator == creator_addr, error::permission_denied(ENOT_AUTHORIZED));
        
        let i = 0;
        while (i < addr_len) {
            let addr = *vector::borrow(&addresses, i);
            let amount = *vector::borrow(&amounts, i);
            
            if (table::contains(&lootbox.allow_mintList, addr)) {
                if (replace_existing) {
                    // Replace existing amount
                    *table::borrow_mut(&mut lootbox.allow_mintList, addr) = amount;
                } else {
                    // Add to existing amount
                    let current_amount = *table::borrow(&lootbox.allow_mintList, addr);
                    *table::borrow_mut(&mut lootbox.allow_mintList, addr) = current_amount + amount;
                };
            } else {
                // New entry
                table::add(&mut lootbox.allow_mintList, addr, amount);
            };
            
            i = i + 1;
        };
        
        // Emit event
        event::emit(WhitelistUpdatedEvent {
            creator: creator_addr,
            collection_name,
            addresses,
            amounts,
            replace_existing,
            timestamp: timestamp::now_microseconds()
        });
    }

    public entry fun remove_addresses_from_whitelist(
        creator: &signer,
        collection_name: String,
        addresses: vector<address>
    ) acquires Lootboxes {
        let creator_addr = signer::address_of(creator);
        
        // Get lootbox
        let lootboxes = borrow_global_mut<Lootboxes>(creator_addr);
        let lootbox = table::borrow_mut(&mut lootboxes.lootbox_table, collection_name);
        assert!(lootbox.creator == creator_addr, error::permission_denied(ENOT_AUTHORIZED));
        
        let i = 0;
        let len = vector::length(&addresses);
        let removed_addresses = vector::empty<address>();
        
        while (i < len) {
            let addr = *vector::borrow(&addresses, i);
            if (table::contains(&lootbox.allow_mintList, addr)) {
                table::remove(&mut lootbox.allow_mintList, addr);
                vector::push_back(&mut removed_addresses, addr);
            };
            i = i + 1;
        };
        
        // Emit event only for actually removed addresses
        if (vector::length(&removed_addresses) > 0) {
            event::emit(WhitelistRemovedEvent {
                creator: creator_addr,
                collection_name,
                removed_addresses,
                timestamp: timestamp::now_microseconds()
            });
        };
    }


    public entry fun set_lootboxsocial_twitter(
        collection_owner: &signer,
        lootbox_name: vector<u8>,
        twitter_url: vector<u8>
    ) acquires Lootboxes, LootboxExtensions {
        let owner_addr = signer::address_of(collection_owner);
        let lootbox_name_str = string::utf8(lootbox_name);
        
        // Get the lootbox to access its resource account
        let lootboxes = borrow_global<Lootboxes>(owner_addr);
        assert!(table::contains(&lootboxes.lootbox_table, lootbox_name_str), error::not_found(ELOOTBOX_NOTEXISTS));
        let lootbox = table::borrow(&lootboxes.lootbox_table, lootbox_name_str);

        assert!(lootbox.creator == owner_addr, error::permission_denied(ENOT_AUTHORIZED));
        
        // Create resource signer to set extension
        let resource_signer = account::create_signer_with_capability(&lootbox.collection_resource_signer_cap);
        
        // Set the twitter URL in extensions
        internal_set_lootbox_extension_string(
            &resource_signer,
            lootbox_name_str,
            string::utf8(b"social_twitter"),
            string::utf8(twitter_url)
        );
    }

    public entry fun set_lootboxsocial_youtube(
        collection_owner: &signer,
        lootbox_name: vector<u8>,
        youtube_url: vector<u8>
    ) acquires Lootboxes, LootboxExtensions {
        let owner_addr = signer::address_of(collection_owner);
        let lootbox_name_str = string::utf8(lootbox_name);
        
        // Get the lootbox to access its resource account
        let lootboxes = borrow_global<Lootboxes>(owner_addr);
        assert!(table::contains(&lootboxes.lootbox_table, lootbox_name_str), error::not_found(ELOOTBOX_NOTEXISTS));
        let lootbox = table::borrow(&lootboxes.lootbox_table, lootbox_name_str);

        assert!(lootbox.creator == owner_addr, error::permission_denied(ENOT_AUTHORIZED));
        
        // Create resource signer to set extension
        let resource_signer = account::create_signer_with_capability(&lootbox.collection_resource_signer_cap);
        
        // Set the youtube URL in extensions
        internal_set_lootbox_extension_string(
            &resource_signer,
            lootbox_name_str,
            string::utf8(b"social_youtube"),
            string::utf8(youtube_url)
        );
    }

    public entry fun set_lootboxsocial_steam(
        collection_owner: &signer,
        lootbox_name: vector<u8>,
        steam_url: vector<u8>
    ) acquires Lootboxes, LootboxExtensions {
        let owner_addr = signer::address_of(collection_owner);
        let lootbox_name_str = string::utf8(lootbox_name);
        
        // Get the lootbox to access its resource account
        let lootboxes = borrow_global<Lootboxes>(owner_addr);
        assert!(table::contains(&lootboxes.lootbox_table, lootbox_name_str), error::not_found(ELOOTBOX_NOTEXISTS));
        let lootbox = table::borrow(&lootboxes.lootbox_table, lootbox_name_str);

        assert!(lootbox.creator == owner_addr, error::permission_denied(ENOT_AUTHORIZED));
        
        // Create resource signer to set extension
        let resource_signer = account::create_signer_with_capability(&lootbox.collection_resource_signer_cap);
        
        // Set the steam URL in extensions
        internal_set_lootbox_extension_string(
            &resource_signer,
            lootbox_name_str,
            string::utf8(b"social_steam"),
            string::utf8(steam_url)
        );
    }

    public entry fun set_lootboxsocial_epicgames(
        collection_owner: &signer,
        lootbox_name: vector<u8>,
        epicgames_url: vector<u8>
    ) acquires Lootboxes, LootboxExtensions {
        let owner_addr = signer::address_of(collection_owner);
        let lootbox_name_str = string::utf8(lootbox_name);
        
        // Get the lootbox to access its resource account
        let lootboxes = borrow_global<Lootboxes>(owner_addr);
        assert!(table::contains(&lootboxes.lootbox_table, lootbox_name_str), error::not_found(ELOOTBOX_NOTEXISTS));
        let lootbox = table::borrow(&lootboxes.lootbox_table, lootbox_name_str);

        assert!(lootbox.creator == owner_addr, error::permission_denied(ENOT_AUTHORIZED));
        
        // Create resource signer to set extension
        let resource_signer = account::create_signer_with_capability(&lootbox.collection_resource_signer_cap);
        
        // Set the epicgames URL in extensions
        internal_set_lootbox_extension_string(
            &resource_signer,
            lootbox_name_str,
            string::utf8(b"social_epicgames"),
            string::utf8(epicgames_url)
        );
    }

    public entry fun set_lootboxsocial_twitch(
        collection_owner: &signer,
        lootbox_name: vector<u8>,
        twitch_url: vector<u8>
    ) acquires Lootboxes, LootboxExtensions {
        let owner_addr = signer::address_of(collection_owner);
        let lootbox_name_str = string::utf8(lootbox_name);
        
        // Get the lootbox to access its resource account
        let lootboxes = borrow_global<Lootboxes>(owner_addr);
        assert!(table::contains(&lootboxes.lootbox_table, lootbox_name_str), error::not_found(ELOOTBOX_NOTEXISTS));
        let lootbox = table::borrow(&lootboxes.lootbox_table, lootbox_name_str);

        assert!(lootbox.creator == owner_addr, error::permission_denied(ENOT_AUTHORIZED));
        
        // Create resource signer to set extension
        let resource_signer = account::create_signer_with_capability(&lootbox.collection_resource_signer_cap);
        
        // Set the twitch URL in extensions
        internal_set_lootbox_extension_string(
            &resource_signer,
            lootbox_name_str,
            string::utf8(b"social_twitch"),
            string::utf8(twitch_url)
        );
    }

    public entry fun set_lootboxsocial_website(
        collection_owner: &signer,
        lootbox_name: vector<u8>,
        website_url: vector<u8>
    ) acquires Lootboxes, LootboxExtensions {
        let owner_addr = signer::address_of(collection_owner);
        let lootbox_name_str = string::utf8(lootbox_name);
        
        // Get the lootbox to access its resource account
        let lootboxes = borrow_global<Lootboxes>(owner_addr);
        assert!(table::contains(&lootboxes.lootbox_table, lootbox_name_str), error::not_found(ELOOTBOX_NOTEXISTS));
        let lootbox = table::borrow(&lootboxes.lootbox_table, lootbox_name_str);

        assert!(lootbox.creator == owner_addr, error::permission_denied(ENOT_AUTHORIZED));
        
        // Create resource signer to set extension
        let resource_signer = account::create_signer_with_capability(&lootbox.collection_resource_signer_cap);
        
        // Set the website URL in extensions
        internal_set_lootbox_extension_string(
            &resource_signer,
            lootbox_name_str,
            string::utf8(b"social_website"),
            string::utf8(website_url)
        );
    }


}

