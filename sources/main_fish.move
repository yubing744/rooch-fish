// Copyright (c) RoochNetwork
// SPDX-License-Identifier: Apache-2.0

module rooch_fish::rooch_fish {
    use std::vector;
    use moveos_std::object::{Self, Object};
    use moveos_std::signer;
    use moveos_std::event;
    use moveos_std::table::{Self, Table};
    use rooch_framework::gas_coin;
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
        purchase_amount: u64,
    }

    struct GameState has key {
        ponds: Table<u64, Object<PondState>>,
        player_list: PlayerList,
        pond_infos: vector<PondInfo>,
    }

    struct FishPurchasedEvent has drop, store {
        pond_id: u64,
        fish_id: u64,
        owner: address,
    }

    struct FishMovedEvent has drop, store {
        fish_id: u64,
        new_x: u64,
        new_y: u64,
    }

    struct FishDestroyedEvent has drop, store {
        fish_id: u64,
        reward: u256,
    }

    public entry fun initialize(ctx: &mut signer) {
        assert!(signer::address_of(ctx) == @rooch_fish, ERR_UNAUTHORIZED);

        let pond_infos = vector::empty<PondInfo>();
        vector::push_back(&mut pond_infos, PondInfo { id: 0, width: 100, height: 100, purchase_amount: 100 });
        vector::push_back(&mut pond_infos, PondInfo { id: 1, width: 150, height: 150, purchase_amount: 200 });
        vector::push_back(&mut pond_infos, PondInfo { id: 2, width: 200, height: 200, purchase_amount: 300 });
        vector::push_back(&mut pond_infos, PondInfo { id: 3, width: 250, height: 250, purchase_amount: 400 });
        vector::push_back(&mut pond_infos, PondInfo { id: 4, width: 300, height: 300, purchase_amount: 500 });
        vector::push_back(&mut pond_infos, PondInfo { id: 5, width: 350, height: 350, purchase_amount: 600 });
        vector::push_back(&mut pond_infos, PondInfo { id: 6, width: 400, height: 400, purchase_amount: 700 });
        vector::push_back(&mut pond_infos, PondInfo { id: 7, width: 450, height: 450, purchase_amount: 800 });

        let ponds = table::new();
        let i = 0;
        while (i < vector::length(&pond_infos)) {
            let info = vector::borrow(&pond_infos, i);
            let pond_obj = pond::create_pond(info.id, info.width, info.height, 100, 1000);
            table::add(&mut ponds, info.id, pond_obj);
            i = i + 1;
        };

        let player_list = player::create_player_list();

        let game_state = GameState {
            ponds,
            player_list,
            pond_infos,
        };

        object::new_named_object(game_state);
    }

    public entry fun purchase_fish(account: &signer, pond_id: u64) acquires GameState {
        let game_state = object::borrow_mut_object<GameState>(@rooch_fish);
        let pond_info = get_pond_info(pond_id);
        let purchase_amount = pond_info.purchase_amount;

        let account_addr = signer::address_of(account);
        assert!(gas_coin::balance(account_addr) >= (purchase_amount as u256), ERR_INSUFFICIENT_BALANCE);

        let pond_obj = table::borrow_mut(&mut game_state.ponds, pond_id);
        assert!(pond::get_fish_count(object::borrow(pond_obj)) < 100, ERR_POND_FULL);

        gas_coin::deduct_gas(account_addr, (purchase_amount as u256));

        let (x, y) = utils::random_position(pond_info.width, pond_info.height);
        let fish_id = utils::random_u64(1000000);
        let fish = fish::create_fish(account_addr, fish_id, 10, x, y);
        pond::add_fish(object::borrow_mut(pond_obj), fish);

        event::emit(FishPurchasedEvent { pond_id, fish_id, owner: account_addr });
    }

    public entry fun move_fish(account: &signer, fish_id: u64, direction: u8) acquires GameState {
        let game_state = object::borrow_mut_object<GameState>(@rooch_fish);
        let account_addr = signer::address_of(account);

        let (pond_id, fish) = find_fish(fish_id);
        assert!(fish::get_owner(fish) == account_addr, ERR_UNAUTHORIZED);

        let pond_obj = table::borrow_mut(&mut game_state.ponds, pond_id);
        let pond_info = get_pond_info(pond_id);

        let (old_x, old_y) = fish::get_position(fish);
        fish::move_fish(account, fish, direction);
        let (new_x, new_y) = fish::get_position(fish);

        let new_x = utils::clamp(new_x, 0, pond_info.width);
        let new_y = utils::clamp(new_y, 0, pond_info.height);

        if (new_x != old_x || new_y != old_y) {
            fish::set_position(fish, new_x, new_y);
            handle_collisions(pond_obj, fish);
        };

        event::emit(FishMovedEvent { fish_id, new_x, new_y });
    }

    public entry fun feed_food(account: &signer, pond_id: u64, amount: u64) acquires GameState {
        let game_state = object::borrow_mut_object<GameState>(@rooch_fish);
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
        let game_state = object::borrow_mut_object<GameState>(@rooch_fish);
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

    fun get_pond_info(pond_id: u64): &PondInfo acquires GameState {
        let game_state = object::borrow_object<GameState>(@rooch_fish);
        assert!(pond_id < vector::length(&game_state.pond_infos), ERR_INVALID_POND_ID);
        vector::borrow(&game_state.pond_infos, pond_id)
    }

    fun find_fish(fish_id: u64): (u64, &mut Object<Fish>) acquires GameState {
        let game_state = object::borrow_mut_object<GameState>(@rooch_fish);
        let i = 0;
        while (i < 8) {
            let pond_obj = table::borrow_mut(&mut game_state.ponds, i);
            if (pond::fish_exists(object::borrow(pond_obj), fish_id)) {
                return (i, pond::get_fish_mut(object::borrow_mut(pond_obj), fish_id))
            };
            i = i + 1;
        };
        abort ERR_INVALID_POND_ID
    }

    fun handle_collisions(pond: &mut Object<PondState>, fish: &mut Object<Fish>) {
        let fish_size = fish::get_size(fish);
        let (fish_x, fish_y) = fish::get_position(fish);

        let foods = pond::get_all_foods(object::borrow(pond));
        let i = 0;
        while (i < vector::length(foods)) {
            let food = vector::borrow(foods, i);
            let (food_x, food_y) = food::get_position(food);
            if (utils::calculate_distance(fish_x, fish_y, food_x, food_y) <= fish_size) {
                fish::grow_fish(fish, food::get_size(food));
                pond::remove_food(object::borrow_mut(pond), food::get_id(food));
            };
            i = i + 1;
        };

        let fishes = pond::get_all_fishes(object::borrow(pond));
        let j = 0;
        while (j < vector::length(fishes)) {
            let other_fish = vector::borrow(fishes, j);
            if (fish::get_id(fish) != fish::get_id(other_fish)) {
                let (other_x, other_y) = fish::get_position(other_fish);
                let other_size = fish::get_size(other_fish);
                if (utils::calculate_distance(fish_x, fish_y, other_x, other_y) <= fish_size && fish_size > other_size) {
                    fish::grow_fish(fish, other_size / 2);
                    pond::remove_fish(object::borrow_mut(pond), fish::get_id(other_fish));
                };
            };
            j = j + 1;
        };
    }

    fun calculate_reward(fish: &Object<Fish>, pond_id: u64): u256 {
        let base_reward = (fish::get_size(fish) as u256);
        let pond_info = get_pond_info(pond_id);
        base_reward * (pond_info.purchase_amount as u256) / 100
    }
}
