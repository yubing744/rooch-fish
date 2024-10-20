module rooch_fish::rooch_fish {
    use std::vector;
    use std::u256;

    use moveos_std::object::{Self, Object};
    use moveos_std::account;
    use moveos_std::signer;
    use moveos_std::event;
    use moveos_std::table::{Self, Table};
    use moveos_std::table_vec;

    use rooch_framework::account_coin_store;
    use rooch_framework::coin_store::{Self, CoinStore};
    use rooch_framework::gas_coin::{Self, RGas};

    use rooch_fish::food;
    use rooch_fish::fish::{Self, Fish};
    use rooch_fish::pond::{Self, PondState};
    use rooch_fish::player::{Self, PlayerList};
    use rooch_fish::utils;

    const ERR_UNAUTHORIZED: u64 = 1;
    const ERR_INVALID_POND_ID: u64 = 2;
    const ERR_INSUFFICIENT_BALANCE: u64 = 3;
    const ERR_POND_FULL: u64 = 4;
    const ERR_FISH_NOT_IN_EXIT_ZONE: u64 = 5;
    const ERR_INVALID_POSITION: u64 = 6;

    struct Treasury has key, store {
        coin_store: Object<CoinStore<RGas>>
    }

    struct GameState has key {
        ponds: Table<u64, Object<PondState>>,
        player_list: PlayerList,
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

    struct PondConfig has copy, drop {
        id: u64,
        width: u64,
        height: u64,
        purchase_amount: u64,
    }

    fun init() {
        let module_signer = signer::module_signer<GameState>();

        let ponds = table::new();
        let pond_configs = vector[
            PondConfig { id: 0, width: 100, height: 100, purchase_amount: 100 },
            PondConfig { id: 1, width: 150, height: 150, purchase_amount: 200 },
            PondConfig { id: 2, width: 200, height: 200, purchase_amount: 300 },
            PondConfig { id: 3, width: 250, height: 250, purchase_amount: 400 },
            PondConfig { id: 4, width: 300, height: 300, purchase_amount: 500 },
            PondConfig { id: 5, width: 350, height: 350, purchase_amount: 600 },
            PondConfig { id: 6, width: 400, height: 400, purchase_amount: 700 },
            PondConfig { id: 7, width: 450, height: 450, purchase_amount: 800 },
        ];

        let i = 0;
        while (i < vector::length(&pond_configs)) {
            let config = vector::borrow(&pond_configs, i);
            let pond_obj = pond::create_pond(
                config.id, 
                config.width, 
                config.height, 
                (config.purchase_amount as u256), 
                100, 
                1000
            );
            table::add(&mut ponds, config.id, pond_obj);
            i = i + 1;
        };

        let player_list = player::create_player_list();

        let coin_store_obj = coin_store::create_coin_store<RGas>();
        let treasury = Treasury { coin_store: coin_store_obj };

        let game_state = GameState {
            ponds,
            player_list,
            treasury,
        };

        account::move_resource_to(&module_signer, game_state);
    }

    public entry fun purchase_fish(account: &signer, pond_id: u64) {
        let game_state = account::borrow_mut_resource<GameState>(@rooch_fish);

        let pond_obj = table::borrow_mut(&mut game_state.ponds, pond_id);
        let pond_state = object::borrow_mut(pond_obj);
        let purchase_amount = pond::get_purchase_amount(pond_state);

        // deduct user RGas coin
        let account_addr = signer::address_of(account);
        assert!(gas_coin::balance(account_addr) >= purchase_amount, ERR_INSUFFICIENT_BALANCE);
        let coin = account_coin_store::withdraw(account, purchase_amount);
        coin_store::deposit(&mut game_state.treasury.coin_store, coin);

        // Give user a fish
        let (width, height) = (pond::get_width(pond_state), pond::get_height(pond_state));
        let (x, y) = utils::random_position(width, height);
        let fish_id = pond::get_next_fish_id(pond_state);
        let fish = fish::create_fish(account_addr, fish_id, 10, x, y);
        pond::add_fish(pond_state, fish);

        event::emit(FishPurchasedEvent { pond_id, fish_id, owner: account_addr });
    }

    public entry fun move_fish(account: &signer, pond_id: u64, fish_id: u64, direction: u8) {
        let game_state = account::borrow_mut_resource<GameState>(@rooch_fish);
        let account_addr = signer::address_of(account);

        let pond_obj = table::borrow_mut(&mut game_state.ponds, pond_id);
        let pond_state = object::borrow_mut(pond_obj);

        let pond_width = pond::get_width(pond_state);
        let pond_height = pond::get_height(pond_state);

        let fish = pond::get_fish_mut(pond_state, fish_id);
        assert!(fish::get_owner(fish) == account_addr, ERR_UNAUTHORIZED);

        let (old_x, old_y) = fish::get_position(fish);
        fish::move_fish(account, fish, direction);

        let (new_x, new_y) = fish::get_position(fish);
        assert!(new_x < pond_width && new_y < pond_height, ERR_INVALID_POSITION);

        let new_x = utils::clamp(new_x, 0, pond_width);
        let new_y = utils::clamp(new_y, 0, pond_height);

        if (new_x != old_x || new_y != old_y) {
            handle_collisions(pond_state, fish_id);
        };

        event::emit(FishMovedEvent { fish_id, new_x, new_y });
    }

    public entry fun feed_food(account: &signer, pond_id: u64, amount: u64) {
        let game_state = account::borrow_mut_resource<GameState>(@rooch_fish);
        let account_addr = signer::address_of(account);
        assert!(gas_coin::balance(account_addr) >= (amount as u256), ERR_INSUFFICIENT_BALANCE);

        // deduct user RGas coin
        let coin = account_coin_store::withdraw(account, (amount as u256));
        coin_store::deposit(&mut game_state.treasury.coin_store, coin);
  
        let pond_obj = table::borrow_mut(&mut game_state.ponds, pond_id);
        let pond_state = object::borrow_mut(pond_obj);

        let food_count = amount / 10;
        let i = 0;
        while (i < food_count) {
            let (x, y) = utils::random_position(pond::get_width(pond_state), pond::get_height(pond_state));
            
            let food_id = pond::get_next_food_id(pond_state);
            let food = food::create_food(food_id, 1, x, y);
            pond::add_food(pond_state, food);
            i = i + 1;
        };

        player::add_feed(&mut game_state.player_list, account_addr, amount);
    }

    public entry fun destroy_fish(account: &signer, pond_id: u64, fish_id: u64) {
        let game_state = account::borrow_mut_resource<GameState>(@rooch_fish);
        let account_addr = signer::address_of(account);

        let pond_obj = table::borrow_mut(&mut game_state.ponds, pond_id);
        let pond_state = object::borrow_mut(pond_obj);
        
        let fish = pond::get_fish(pond_state, fish_id);
        assert!(fish::get_owner(fish) == account_addr, ERR_UNAUTHORIZED);
        assert!(pond::is_fish_in_exit_zone(pond_state, fish), ERR_FISH_NOT_IN_EXIT_ZONE);

        let removed_fish = pond::remove_fish(pond_state, fish_id);

        let reward = calculate_reward(&removed_fish, pond_state);
        let reward_coin = coin_store::withdraw(&mut game_state.treasury.coin_store, reward);
        account_coin_store::deposit(account_addr, reward_coin);

        // record player reward
        let reward_amount = u256::divide_and_round_up(reward, u256::pow(10, gas_coin::decimals()));
        player::add_reward(&mut game_state.player_list, account_addr, (reward_amount as u64));

        event::emit(FishDestroyedEvent { fish_id, reward });

        fish::drop_fish(removed_fish);
    }

    fun handle_collisions(pond_state: &mut PondState, fish_id: u64) {
        let fish = pond::get_fish(pond_state, fish_id);
        let fish_size = fish::get_size(fish);
        let (fish_x, fish_y) = fish::get_position(fish);

        handle_food_collisions(pond_state, fish_id, fish_size, fish_x, fish_y);
        handle_fish_collisions(pond_state, fish_id, fish_size, fish_x, fish_y);
    }

    fun handle_food_collisions(pond_state: &mut PondState, fish_id: u64, fish_size: u64, fish_x: u64, fish_y: u64) {
        let food_ids_to_remove = vector::empty<u64>();
        let growth_amount = 0u64;

        let foods = pond::get_all_foods(pond_state);

        let i = 0;
        while (i < table_vec::length(foods)) {
            let food = table_vec::borrow(foods, i);
            let (food_x, food_y) = food::get_position(food);
            if (utils::calculate_distance(fish_x, fish_y, food_x, food_y) <= fish_size) {
                growth_amount = growth_amount + food::get_size(food);
                vector::push_back(&mut food_ids_to_remove, food::get_id(food));
            };
            i = i + 1;
        };

        // grow fish
        let fish_mut = pond::get_fish_mut(pond_state, fish_id);
        fish::grow_fish(fish_mut, growth_amount);

        // Remove foods after the loop
        let j = 0;
        while (j < vector::length(&food_ids_to_remove)) {
            let food_id = *vector::borrow(&food_ids_to_remove, j);
            let food_obj = pond::remove_food(pond_state, food_id);
            food::drop_food(food_obj);
            j = j + 1;
        };
    }

    fun handle_fish_collisions(pond_state: &mut PondState, fish_id: u64, fish_size: u64, fish_x: u64, fish_y: u64) {
        let fish_ids_to_remove = vector::empty<u64>();
        let growth_amount = 0u64;

        let fishes = pond::get_all_fishes(pond_state);
 
        let j = 0;
        while (j < table_vec::length(fishes)) {
            let other_fish = table_vec::borrow(fishes, j);
            if (fish_id != fish::get_id(other_fish)) {
                let (other_x, other_y) = fish::get_position(other_fish);
                let other_size = fish::get_size(other_fish);
                if (utils::calculate_distance(fish_x, fish_y, other_x, other_y) <= fish_size && fish_size > other_size) {
                    growth_amount = growth_amount + (other_size / 2);
                    vector::push_back(&mut fish_ids_to_remove, fish::get_id(other_fish));
                }
            };
            j = j + 1;
        };

        let fish_mut = pond::get_fish_mut(pond_state, fish_id);

        // Apply growth and remove fishes after the loop
        fish::grow_fish(fish_mut, growth_amount);

        let k = 0;
        while (k < vector::length(&fish_ids_to_remove)) {
            let fish_id = *vector::borrow(&fish_ids_to_remove, k);
            let fish_obj = pond::remove_fish(pond_state, fish_id);
            fish::drop_fish(fish_obj);
            k = k + 1;
        };
    }

    fun calculate_reward(fish: &Object<Fish>, pond_state: &PondState): u256 {
        let base_reward = (fish::get_size(fish) as u256);
        base_reward * pond::get_purchase_amount(pond_state) / 100
    }
}
