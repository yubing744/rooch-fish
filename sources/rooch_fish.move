// Copyright (c) RoochNetwork
// SPDX-License-Identifier: Apache-2.0

module rooch_fish::rooch_fish {
    use std::vector;
    use moveos_std::object::{Self, Object};
    use moveos_std::account;
    use moveos_std::signer;
    use moveos_std::event;
    use moveos_std::table::{Self, Table};
    use moveos_std::table_vec::{Self, TableVec};

    use rooch_framework::account_coin_store;
    use rooch_framework::coin_store::{Self, CoinStore};
    use rooch_framework::gas_coin::{Self, RGas};

    use rooch_fish::fish::{Self, Fish};
    use rooch_fish::food::{Self, Food};
    use rooch_fish::pond::{Self, PondState};
    use rooch_fish::player::{Self, PlayerList};
    use rooch_fish::utils;

    const ERR_UNAUTHORIZED: u64 = 1;
    const ERR_INVALID_POND_ID: u64 = 2;
    const ERR_INSUFFICIENT_BALANCE: u64 = 3;
    const ERR_POND_FULL: u64 = 4;

    struct PondInfo has key, store {
        id: u64,
        width: u64,
        height: u64,
        purchase_amount: u256,
        next_fish_id: u64,
    }

    struct Treasury has key, store {
        coin_store: Object<CoinStore<RGas>>
    }

    struct GameState has key {
        ponds: Table<u64, Object<PondState>>,
        player_list: PlayerList,
        pond_infos: vector<PondInfo>,
        treasury: Treasury,
    }

    struct FishPurchasedEvent has copy, drop, store {
        pond_id: u64,
        fish_id: u64,
        owner: address,
    }

    struct FishMovedEvent has copy, drop, store {
        fish_id: u64,
        new_x: u64,
        new_y: u64,
    }

    struct FishDestroyedEvent has copy, drop, store {
        fish_id: u64,
        reward: u256,
    }

    fun init() {
        let module_signer = signer::module_signer<GameState>();

        let pond_infos = vector::empty<PondInfo>();
        vector::push_back(&mut pond_infos, PondInfo { id: 0, width: 100, height: 100, purchase_amount: 100, next_fish_id: 1 });
        vector::push_back(&mut pond_infos, PondInfo { id: 1, width: 150, height: 150, purchase_amount: 200, next_fish_id: 1 });
        vector::push_back(&mut pond_infos, PondInfo { id: 2, width: 200, height: 200, purchase_amount: 300, next_fish_id: 1 });
        vector::push_back(&mut pond_infos, PondInfo { id: 3, width: 250, height: 250, purchase_amount: 400, next_fish_id: 1 });
        vector::push_back(&mut pond_infos, PondInfo { id: 4, width: 300, height: 300, purchase_amount: 500, next_fish_id: 1 });
        vector::push_back(&mut pond_infos, PondInfo { id: 5, width: 350, height: 350, purchase_amount: 600, next_fish_id: 1 });
        vector::push_back(&mut pond_infos, PondInfo { id: 6, width: 400, height: 400, purchase_amount: 700, next_fish_id: 1 });
        vector::push_back(&mut pond_infos, PondInfo { id: 7, width: 450, height: 450, purchase_amount: 800, next_fish_id: 1 });

        let ponds = table::new();
        let i = 0;
        while (i < vector::length(&pond_infos)) {
            let info = vector::borrow(&pond_infos, i);
            let pond_obj = pond::create_pond(info.id, info.width, info.height, 100, 1000);
            table::add(&mut ponds, info.id, pond_obj);
            i = i + 1;
        };

        let player_list = player::create_player_list();

        let coin_store_obj = coin_store::create_coin_store<RGas>();
        let treasury = Treasury { coin_store: coin_store_obj };

        let game_state = GameState {
            ponds,
            player_list,
            pond_infos,
            treasury,
        };

        account::move_resource_to(&module_signer, game_state);
    }


    public entry fun purchase_fish(account: &signer, pond_id: u64) {
        let game_state = account::borrow_mut_resource<GameState>(@rooch_fish);

        let pond_info = get_pond_info_mut(pond_id);
        let purchase_amount = pond_info.purchase_amount;

        // deduct user RGas coin
        let account_addr = signer::address_of(account);
        assert!(gas_coin::balance(account_addr) >= (purchase_amount as u256), ERR_INSUFFICIENT_BALANCE);
        let coin = account_coin_store::withdraw(account, purchase_amount);
        coin_store::deposit(&mut game_state.treasury.coin_store, coin);

        // Give user a fish
        let pond_obj = table::borrow_mut(&mut game_state.ponds, pond_id);
        let (x, y) = utils::random_position(pond_info.width, pond_info.height);
        let fish_id = pond_info.next_fish_id;
        pond_info.next_fish_id = pond_info.next_fish_id + 1;
        let fish = fish::create_fish(account_addr, fish_id, 10, x, y);
        pond::add_fish(object::borrow_mut(pond_obj), fish);

        event::emit(FishPurchasedEvent { pond_id, fish_id, owner: account_addr });
    }


    public entry fun move_fish(account: &signer, pond_id: u64, fish_id: u64, direction: u8) {
        let game_state = account::borrow_mut_resource<GameState>(@rooch_fish);
        let account_addr = signer::address_of(account);

        let fish = find_fish_mut(pond_id, fish_id);
        assert!(fish::get_owner(fish) == account_addr, ERR_UNAUTHORIZED);

        let pond_obj = table::borrow_mut(&mut game_state.ponds, pond_id);
        let pond_info = get_pond_info(pond_id);

        let (old_x, old_y) = fish::get_position(fish);
        fish::move_fish(account, fish, direction);
        let (new_x, new_y) = fish::get_position(fish);

        let new_x = utils::clamp(new_x, 0, pond_info.width);
        let new_y = utils::clamp(new_y, 0, pond_info.height);

        if (new_x != old_x || new_y != old_y) {
            handle_collisions(pond_obj, fish);
        };

        event::emit(FishMovedEvent { fish_id, new_x, new_y });
    }

    /*
    public entry fun feed_food(account: &signer, pond_id: u64, amount: u64) acquires GameState {
        let game_state = account::borrow_mut_resource<GameState>(@rooch_fish);
        let account_addr = signer::address_of(account);
        assert!(gas_coin::balance(account_addr) >= (amount as u256), ERR_INSUFFICIENT_BALANCE);

        gas_coin::deduct_gas(account_addr, (amount as u256));

        let pond_obj = table::borrow_mut(&mut game_state.ponds, pond_id);
        let pond_info = get_pond_info(pond_id);

        let food_count = amount / 10;
        let i = 0;
        while (i < food_count) {
            let (x, y) = utils::random_position(pond_info.width, pond_info.height);
            let food_id = utils::random_u64(1000000);
            let food = food::create_food(food_id, 1, x, y);
            pond::add_food(object::borrow_mut(pond_obj), food);
            i = i + 1;
        };

        player::add_feed(&mut game_state.player_list, account_addr, amount);
    }

    public entry fun destroy_fish(account: &signer, fish_id: u64) acquires GameState {
        let game_state = account::borrow_mut_resource<GameState>(@rooch_fish);
        let account_addr = signer::address_of(account);

        let (pond_id, fish) = find_fish(fish_id);
        assert!(fish::get_owner(fish) == account_addr, ERR_UNAUTHORIZED);

        let pond_obj = table::borrow_mut(&mut game_state.ponds, pond_id);
        let removed_fish = pond::remove_fish(object::borrow_mut(pond_obj), fish_id);

        let reward = calculate_reward(&removed_fish, pond_id);
        gas_coin::faucet(account_addr, reward);

        player::add_reward(&mut game_state.player_list, account_addr, reward);

        event::emit(FishDestroyedEvent { fish_id, reward });

        fish::drop_fish(removed_fish);
    }
    */

    fun handle_collisions(pond: &mut Object<PondState>, fish: &mut Object<Fish>) {
        let fish_size = fish::get_size(fish);
        let (fish_x, fish_y) = fish::get_position(fish);

        handle_food_collisions(pond, fish, fish_size, fish_x, fish_y);
        handle_fish_collisions(pond, fish, fish_size, fish_x, fish_y);
    }

    fun handle_food_collisions(pond: &mut Object<PondState>, fish: &mut Object<Fish>, fish_size: u64, fish_x: u64, fish_y: u64) {
        let foods = pond::get_all_foods(object::borrow(pond));
        let pond_mut = object::borrow_mut(pond);
        
        let i = 0;
        while (i < table_vec::length(foods)) {
            let food = table_vec::borrow(foods, i);
            let (food_x, food_y) = food::get_position(food);
            if (utils::calculate_distance(fish_x, fish_y, food_x, food_y) <= fish_size) {
                fish::grow_fish(fish, food::get_size(food));
                let food_obj = pond::remove_food(pond_mut, food::get_id(food));
                food::drop_food(food_obj);
            } else {
                i = i + 1;
            };
        };
    }

    fun handle_fish_collisions(pond: &mut Object<PondState>, fish: &mut Object<Fish>, fish_size: u64, fish_x: u64, fish_y: u64) {
        let fishes = pond::get_all_fishes(object::borrow(pond));
        let pond_mut = object::borrow_mut(pond);
        
        let j = 0;
        while (j < table_vec::length(fishes)) {
            let other_fish = table_vec::borrow(fishes, j);
            if (fish::get_id(fish) != fish::get_id(other_fish)) {
                let (other_x, other_y) = fish::get_position(other_fish);
                let other_size = fish::get_size(other_fish);
                if (utils::calculate_distance(fish_x, fish_y, other_x, other_y) <= fish_size && fish_size > other_size) {
                    fish::grow_fish(fish, other_size / 2);
                    let fish_obj = pond::remove_fish(pond_mut, fish::get_id(other_fish));
                    fish::drop_fish(fish_obj);
                } else {
                    j = j + 1;
                };
            } else {
                j = j + 1;
            };
        };
    }

    fun calculate_reward(fish: &Object<Fish>, pond_id: u64): u256 {
        let base_reward = (fish::get_size(fish) as u256);
        let pond_info = get_pond_info(pond_id);
        base_reward * (pond_info.purchase_amount as u256) / 100
    }
 
    fun find_fish_mut(pond_id: u64, fish_id: u64): &mut Object<Fish> {
        let game_state = account::borrow_mut_resource<GameState>(@rooch_fish);
        let pond_obj = table::borrow_mut(&mut game_state.ponds, pond_id);
        pond::get_fish_mut(object::borrow_mut(pond_obj), fish_id)
    }

    fun get_pond_info_mut(pond_id: u64): &mut PondInfo {
        let game_state = account::borrow_mut_resource<GameState>(@rooch_fish);
        assert!(pond_id < vector::length(&game_state.pond_infos), ERR_INVALID_POND_ID);
        vector::borrow_mut(&mut game_state.pond_infos, pond_id)
    }

    fun get_pond_info(pond_id: u64): &PondInfo {
        let game_state = account::borrow_resource<GameState>(@rooch_fish);
        assert!(pond_id < vector::length(&game_state.pond_infos), ERR_INVALID_POND_ID);
        vector::borrow(&game_state.pond_infos, pond_id)
    }
}
