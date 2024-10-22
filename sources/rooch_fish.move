module rooch_fish::rooch_fish {
    use std::vector;
    use std::u256;
    use moveos_std::object::{Self, Object};
    use moveos_std::account;
    use moveos_std::signer;
    use moveos_std::table::{Self, Table};
    use rooch_framework::gas_coin;
    use rooch_fish::pond::{Self, PondState};
    use rooch_fish::player::{Self, PlayerList};

    const ERR_INVALID_POND_ID: u64 = 1;

    struct PondConfig has copy, drop {
        id: u64,
        width: u64,
        height: u64,
        purchase_amount: u256,
        max_fish_count: u64,
        max_food_count: u64,
    }

    struct GameState has key {
        admin: address,
        ponds: Table<u64, Object<PondState>>,
        player_list: PlayerList,
    }

    public entry fun init_world(account: &signer) {
        let admin = signer::address_of(account);
        let module_signer = signer::module_signer<GameState>();

        let ponds = table::new();

        let unit = u256::pow(10, gas_coin::decimals() - 3);

        let pond_configs = vector[
            PondConfig { id: 0, width: 100, height: 100, purchase_amount: unit, max_fish_count: 100, max_food_count: 1000 },
            PondConfig { id: 1, width: 1000, height: 1000, purchase_amount: unit, max_fish_count: 1000, max_food_count: 10000 },
            PondConfig { id: 2, width: 10000, height: 10000, purchase_amount: unit, max_fish_count: 10000, max_food_count: 100000 },
            PondConfig { id: 3, width: 100000, height: 100000, purchase_amount: unit, max_fish_count: 100000, max_food_count: 1000000 },

            PondConfig { id: 4, width: 1000, height: 1000, purchase_amount: unit * 10, max_fish_count: 1000, max_food_count: 10000 },
            PondConfig { id: 5, width: 1000, height: 1000, purchase_amount: unit * 100, max_fish_count: 1000, max_food_count: 10000 },
            PondConfig { id: 6, width: 1000, height: 1000, purchase_amount: unit * 1000, max_fish_count: 1000, max_food_count: 10000 },
            PondConfig { id: 7, width: 1000, height: 1000, purchase_amount: unit * 10000, max_fish_count: 1000, max_food_count: 10000 },
        ];

        let i = 0;
        while (i < vector::length(&pond_configs)) {
            let config = vector::borrow(&pond_configs, i);
            let pond_obj = pond::create_pond(
                config.id, 
                config.width, 
                config.height, 
                (config.purchase_amount as u256), 
                config.max_fish_count, 
                config.max_food_count,
            );

            let pond_state = object::borrow_mut(&mut pond_obj);
            pond::add_exit_zone(pond_state, config.width/2, config.height/2, 10);

            table::add(&mut ponds, config.id, pond_obj);
            i = i + 1;
        };

        let player_list = player::create_player_list();

        let game_state = GameState {
            admin,
            ponds,
            player_list,
        };

        account::move_resource_to(&module_signer, game_state);
    }

    public entry fun purchase_fish(account: &signer, pond_id: u64) {
        let game_state = account::borrow_mut_resource<GameState>(@rooch_fish);
        let account_addr = signer::address_of(account);

        let pond_obj = table::borrow_mut(&mut game_state.ponds, pond_id);
        let pond_state = object::borrow_mut(pond_obj);

        let fish_id = pond::purchase_fish(pond_state, account);
        player::add_fish(&mut game_state.player_list, account_addr, fish_id);
    }

    public entry fun move_fish(account: &signer, pond_id: u64, fish_id: u64, direction: u8) {
        let game_state = account::borrow_mut_resource<GameState>(@rooch_fish);

        let pond_obj = table::borrow_mut(&mut game_state.ponds, pond_id);
        let pond_state = object::borrow_mut(pond_obj);

        pond::move_fish(pond_state, account, fish_id, direction);
    }

    public entry fun feed_food(account: &signer, pond_id: u64, amount: u256) {
        let game_state = account::borrow_mut_resource<GameState>(@rooch_fish);
        let account_addr = signer::address_of(account);

        let pond_obj = table::borrow_mut(&mut game_state.ponds, pond_id);
        let pond_state = object::borrow_mut(pond_obj);

        let actual_amount = pond::feed_food(pond_state, account, amount);
        player::add_feed(&mut game_state.player_list, account_addr, actual_amount);
    }

    public entry fun destroy_fish(account: &signer, pond_id: u64, fish_id: u64) {
        let game_state = account::borrow_mut_resource<GameState>(@rooch_fish);
        let account_addr = signer::address_of(account);

        let pond_obj = table::borrow_mut(&mut game_state.ponds, pond_id);
        let pond_state = object::borrow_mut(pond_obj);
        
        let reward = pond::destroy_fish(pond_state, account, fish_id);

        let reward_amount = u256::divide_and_round_up(reward, u256::pow(10, gas_coin::decimals()));
        player::add_reward(&mut game_state.player_list, account_addr, reward_amount);
    }

    public fun get_pond_player_list(pond_id: u64): &PlayerList {
        let game_state = account::borrow_resource<GameState>(@rooch_fish);
        let pond_obj = table::borrow(&game_state.ponds, pond_id);
        let pond_state = object::borrow(pond_obj);
        pond::get_player_list(pond_state)
    }

    public fun get_pond_player_count(pond_id: u64): u64 {
        let game_state = account::borrow_resource<GameState>(@rooch_fish);
        let pond_obj = table::borrow(&game_state.ponds, pond_id);
        let pond_state = object::borrow(pond_obj);
        pond::get_player_count(pond_state)
    }

    public fun get_pond_total_feed(pond_id: u64): u256 {
        let game_state = account::borrow_resource<GameState>(@rooch_fish);
        let pond_obj = table::borrow(&game_state.ponds, pond_id);
        let pond_state = object::borrow(pond_obj);
        pond::get_total_feed(pond_state)
    }

    public fun get_pond_player_fish_ids(pond_id: u64, owner: address): vector<u64> {
        let game_state = account::borrow_resource<GameState>(@rooch_fish);
        let pond_obj = table::borrow(&game_state.ponds, pond_id);
        let pond_state = object::borrow(pond_obj);
        pond::get_player_fish_ids(pond_state, owner)
    }

    public fun get_global_player_list(): &PlayerList {
        let game_state = account::borrow_resource<GameState>(@rooch_fish);
        &game_state.player_list
    }

    public fun get_global_player_count(): u64 {
        let game_state = account::borrow_resource<GameState>(@rooch_fish);
        player::get_player_count(&game_state.player_list)
    }

    public fun get_global_total_feed(): u256 {
        let game_state = account::borrow_resource<GameState>(@rooch_fish);
        player::get_total_feed(&game_state.player_list)
    }

    public fun get_pond_count(): u64 {
        let game_state = account::borrow_resource<GameState>(@rooch_fish);
        table::length(&game_state.ponds)
    }

    public fun get_pond_info(pond_id: u64): (u64, u64, u64, u256, u64, u64) {
        let game_state = account::borrow_resource<GameState>(@rooch_fish);
        assert!(table::contains(&game_state.ponds, pond_id), ERR_INVALID_POND_ID);
        let pond_obj = table::borrow(&game_state.ponds, pond_id);
        let pond_state = object::borrow(pond_obj);
        (
            pond::get_width(pond_state),
            pond::get_height(pond_state),
            pond::get_max_fish_count(pond_state),
            pond::get_purchase_amount(pond_state),
            pond::get_max_food_per_feed(),
            pond::get_food_value_ratio(),
        )
    }

    #[test_only]
    public fun set_fish_position_for_test(pond_id: u64, fish_id: u64, x: u64, y: u64) {
        let game_state = account::borrow_mut_resource<GameState>(@rooch_fish);
        let pond_obj = table::borrow_mut(&mut game_state.ponds, pond_id);
        let pond_state = object::borrow_mut(pond_obj);
        pond::move_fish_to_for_test(pond_state, fish_id, x, y);
    }

    #[test_only]
    public fun set_food_position_for_test(pond_id: u64, food_id: u64, x: u64, y: u64) {
        let game_state = account::borrow_mut_resource<GameState>(@rooch_fish);
        let pond_obj = table::borrow_mut(&mut game_state.ponds, pond_id);
        let pond_state = object::borrow_mut(pond_obj);
        pond::set_food_position_for_test(pond_state, food_id, x, y);
    }

    #[test_only]
    public fun get_last_food_id(pond_id: u64): u64 {
        let game_state = account::borrow_resource<GameState>(@rooch_fish);
        let pond_obj = table::borrow(&game_state.ponds, pond_id);
        let pond_state = object::borrow(pond_obj);
        pond::get_last_food_id(pond_state)
    }
}
