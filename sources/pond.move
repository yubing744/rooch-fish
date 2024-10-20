module rooch_fish::pond {
    use std::vector;
    use std::u256;
    use moveos_std::object::{Self, Object};
    use moveos_std::signer;
    use moveos_std::table_vec::{Self, TableVec};
    use moveos_std::event;
    use rooch_framework::account_coin_store;
    use rooch_framework::coin_store::{Self, CoinStore};
    use rooch_framework::gas_coin::{Self, RGas};
    use rooch_fish::fish::{Self, Fish};
    use rooch_fish::food::{Self, Food};
    use rooch_fish::utils;
    use rooch_fish::player::{Self, PlayerList};

    friend rooch_fish::rooch_fish;

    const ERR_INSUFFICIENT_BALANCE: u64 = 1;
    const ERR_FISH_NOT_FOUND: u64 = 2;
    const ERR_FOOD_NOT_FOUND: u64 = 3;
    const ERR_MAX_FISH_COUNT_REACHED: u64 = 4;
    const ERR_MAX_FOOD_COUNT_REACHED: u64 = 5;
    const ERR_UNAUTHORIZED: u64 = 6;
    const ERR_FISH_NOT_IN_EXIT_ZONE: u64 = 7;
    const ERR_INVALID_POSITION: u64 = 8;

    struct ExitZone has store, copy, drop {
        x: u64,
        y: u64,
        radius: u64,
    }

    struct Treasury has key, store {
        coin_store: Object<CoinStore<RGas>>
    }

    struct PondState has key, store {
        id: u64,
        fishes: TableVec<Object<Fish>>,
        foods: TableVec<Object<Food>>,
        exit_zones: vector<ExitZone>,
        fish_count: u64,
        food_count: u64,
        width: u64,
        height: u64,
        purchase_amount: u256,
        next_fish_id: u64,
        next_food_id: u64,
        max_fish_count: u64,
        max_food_count: u64,
        treasury: Treasury,
        player_list: PlayerList,
    }

    struct FishPurchasedEvent has copy, drop, store {
        pond_id: u64,
        fish_id: u64,
        owner: address,
    }

    struct FishMovedEvent has copy, drop, store {
        pond_id: u64,
        fish_id: u64,
        new_x: u64,
        new_y: u64,
    }

    struct FishDestroyedEvent has copy, drop, store {
        pond_id: u64,
        fish_id: u64,
        reward: u256,
    }

    public(friend) fun create_pond(
        id: u64,
        width: u64,
        height: u64,
        purchase_amount: u256,
        max_fish_count: u64,
        max_food_count: u64
    ): Object<PondState> {
        let pond_state = PondState {
            id,
            fishes: table_vec::new(),
            foods: table_vec::new(),
            exit_zones: vector::empty(),
            fish_count: 0,
            food_count: 0,
            width,
            height,
            purchase_amount,
            next_fish_id: 1,
            next_food_id: 1,
            max_fish_count,
            max_food_count,
            treasury: Treasury { coin_store: coin_store::create_coin_store<RGas>() },
            player_list: player::create_player_list(),
        };
        object::new(pond_state)
    }

    public(friend) fun purchase_fish(pond_state: &mut PondState, account: &signer): u64 {
        let account_addr = signer::address_of(account);
        assert!(gas_coin::balance(account_addr) >= pond_state.purchase_amount, ERR_INSUFFICIENT_BALANCE);
        
        let coin = account_coin_store::withdraw(account, pond_state.purchase_amount);
        coin_store::deposit(&mut pond_state.treasury.coin_store, coin);

        let (x, y) = utils::random_position(pond_state.width, pond_state.height);
        let fish_id = pond_state.next_fish_id;
        pond_state.next_fish_id = pond_state.next_fish_id + 1;
        let fish = fish::create_fish(account_addr, fish_id, 10, x, y);
        add_fish(pond_state, fish);

        player::add_fish(&mut pond_state.player_list, account_addr);

        event::emit(FishPurchasedEvent { pond_id: pond_state.id, fish_id, owner: account_addr });

        fish_id
    }

    public(friend) fun move_fish(pond_state: &mut PondState, account: &signer, fish_id: u64, direction: u8): (u64, u64) {
        let account_addr = signer::address_of(account);

        let fish = get_fish_mut(pond_state, fish_id);
        assert!(fish::get_owner(fish) == account_addr, ERR_UNAUTHORIZED);

        let (old_x, old_y) = fish::get_position(fish);
        fish::move_fish(account, fish, direction);

        let (new_x, new_y) = fish::get_position(fish);
        assert!(new_x < pond_state.width && new_y < pond_state.height, ERR_INVALID_POSITION);

        let new_x = utils::clamp(new_x, 0, pond_state.width);
        let new_y = utils::clamp(new_y, 0, pond_state.height);

        if (new_x != old_x || new_y != old_y) {
            handle_collisions(pond_state, fish_id);
        };

        event::emit(FishMovedEvent { pond_id: pond_state.id, fish_id, new_x, new_y });

        (new_x, new_y)
    }

    #[test_only]
    public(friend) fun move_fish_to_for_test(pond_state: &mut PondState, fish_id: u64, x: u64, y: u64) {
        let fish = get_fish_mut(pond_state, fish_id);
        fish::move_fish_to_for_test(fish, x, y);
    }

    public(friend) fun feed_food(pond_state: &mut PondState, account: &signer, amount: u64) {
        let account_addr = signer::address_of(account);
        let coin = account_coin_store::withdraw(account, (amount as u256));
        coin_store::deposit(&mut pond_state.treasury.coin_store, coin);

        let food_count = amount / 10;
        let i = 0;
        while (i < food_count) {
            let (x, y) = utils::random_position(pond_state.width, pond_state.height);
            
            let food_id = pond_state.next_food_id;
            pond_state.next_food_id = pond_state.next_food_id + 1;
            let food = food::create_food(food_id, 1, x, y);
            add_food(pond_state, food);
            i = i + 1;
        };

        player::add_feed(&mut pond_state.player_list, account_addr, amount);
    }

    public(friend) fun destroy_fish(pond_state: &mut PondState, account: &signer, fish_id: u64): u256 {
        let account_addr = signer::address_of(account);
        let fish = get_fish(pond_state, fish_id);
        assert!(fish::get_owner(fish) == account_addr, ERR_UNAUTHORIZED);
        assert!(is_fish_in_exit_zone(pond_state, fish), ERR_FISH_NOT_IN_EXIT_ZONE);

        let removed_fish = remove_fish(pond_state, fish_id);
        let reward = calculate_reward(&removed_fish, pond_state);

        let reward_coin = coin_store::withdraw(&mut pond_state.treasury.coin_store, reward);
        account_coin_store::deposit(account_addr, reward_coin);

        let reward_amount = u256::divide_and_round_up(reward, u256::pow(10, gas_coin::decimals()));
        player::add_reward(&mut pond_state.player_list, account_addr, (reward_amount as u64));

        event::emit(FishDestroyedEvent { pond_id: pond_state.id, fish_id, reward });

        fish::drop_fish(removed_fish);

        reward
    }

    public fun get_fish(pond_state: &PondState, fish_id: u64): &Object<Fish> {
        let index = find_fish_index(pond_state, fish_id);
        table_vec::borrow(&pond_state.fishes, index)
    }

    fun get_fish_mut(pond_state: &mut PondState, fish_id: u64): &mut Object<Fish> {
        let index = find_fish_index(pond_state, fish_id);
        table_vec::borrow_mut(&mut pond_state.fishes, index)
    }

    fun add_fish(pond_state: &mut PondState, fish: Object<Fish>) {
        assert!(pond_state.fish_count < pond_state.max_fish_count, ERR_MAX_FISH_COUNT_REACHED);
        table_vec::push_back(&mut pond_state.fishes, fish);
        pond_state.fish_count = pond_state.fish_count + 1;
    }

    fun remove_fish(pond_state: &mut PondState, fish_id: u64): Object<Fish> {
        let index = find_fish_index(pond_state, fish_id);
        let fish = table_vec::swap_remove(&mut pond_state.fishes, index);
        pond_state.fish_count = pond_state.fish_count - 1;
        fish
    }

    fun add_food(pond_state: &mut PondState, food: Object<Food>) {
        assert!(pond_state.food_count < pond_state.max_food_count, ERR_MAX_FOOD_COUNT_REACHED);
        table_vec::push_back(&mut pond_state.foods, food);
        pond_state.food_count = pond_state.food_count + 1;
    }

    fun remove_food(pond_state: &mut PondState, food_id: u64): Object<Food> {
        let index = find_food_index(pond_state, food_id);
        let food = table_vec::swap_remove(&mut pond_state.foods, index);
        pond_state.food_count = pond_state.food_count - 1;
        food
    }

    fun find_fish_index(pond_state: &PondState, fish_id: u64): u64 {
        let i = 0;
        let len = table_vec::length(&pond_state.fishes);
        while (i < len) {
            let fish = table_vec::borrow(&pond_state.fishes, i);
            if (fish::get_id(fish) == fish_id) {
                return i
            };
            i = i + 1;
        };
        abort ERR_FISH_NOT_FOUND
    }

    fun find_food_index(pond_state: &PondState, food_id: u64): u64 {
        let i = 0;
        let len = table_vec::length(&pond_state.foods);
        while (i < len) {
            let food = table_vec::borrow(&pond_state.foods, i);
            if (food::get_id(food) == food_id) {
                return i
            };
            i = i + 1;
        };
        abort ERR_FOOD_NOT_FOUND
    }

    fun handle_collisions(pond_state: &mut PondState, fish_id: u64) {
        let fish = get_fish(pond_state, fish_id);
        let fish_size = fish::get_size(fish);
        let (fish_x, fish_y) = fish::get_position(fish);

        handle_food_collisions(pond_state, fish_id, fish_size, fish_x, fish_y);
        handle_fish_collisions(pond_state, fish_id, fish_size, fish_x, fish_y);
    }

    fun handle_food_collisions(pond_state: &mut PondState, fish_id: u64, fish_size: u64, fish_x: u64, fish_y: u64) {
        let food_ids_to_remove = vector::empty<u64>();
        let growth_amount = 0u64;

        let i = 0;
        while (i < table_vec::length(&pond_state.foods)) {
            let food = table_vec::borrow(&pond_state.foods, i);
            let (food_x, food_y) = food::get_position(food);
            if (utils::calculate_distance(fish_x, fish_y, food_x, food_y) <= fish_size) {
                growth_amount = growth_amount + food::get_size(food);
                vector::push_back(&mut food_ids_to_remove, food::get_id(food));
            };
            i = i + 1;
        };

        let fish_mut = get_fish_mut(pond_state, fish_id);
        fish::grow_fish(fish_mut, growth_amount);

        let j = 0;
        while (j < vector::length(&food_ids_to_remove)) {
            let food_id = *vector::borrow(&food_ids_to_remove, j);
            let food_obj = remove_food(pond_state, food_id);
            food::drop_food(food_obj);
            j = j + 1;
        };
    }

    fun handle_fish_collisions(pond_state: &mut PondState, fish_id: u64, fish_size: u64, fish_x: u64, fish_y: u64) {
        let fish_ids_to_remove = vector::empty<u64>();
        let growth_amount = 0u64;

        let j = 0;
        while (j < table_vec::length(&pond_state.fishes)) {
            let other_fish = table_vec::borrow(&pond_state.fishes, j);
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

        let fish_mut = get_fish_mut(pond_state, fish_id);
        fish::grow_fish(fish_mut, growth_amount);

        let k = 0;
        while (k < vector::length(&fish_ids_to_remove)) {
            let fish_id = *vector::borrow(&fish_ids_to_remove, k);
            let fish_obj = remove_fish(pond_state, fish_id);
            fish::drop_fish(fish_obj);
            k = k + 1;
        };
    }

    fun calculate_reward(fish: &Object<Fish>, pond_state: &PondState): u256 {
        let base_reward = (fish::get_size(fish) as u256);
        base_reward * pond_state.purchase_amount / 100
    }

    public(friend) fun add_exit_zone(pond_state: &mut PondState, x: u64, y: u64, radius: u64) {
        let exit_zone = ExitZone { x, y, radius };
        vector::push_back(&mut pond_state.exit_zones, exit_zone);
    }

    public(friend) fun remove_exit_zone(pond_state: &mut PondState, index: u64) {
        vector::swap_remove(&mut pond_state.exit_zones, index);
    }

    public fun is_fish_in_exit_zone(pond_state: &PondState, fish: &Object<Fish>): bool {
        let (fish_x, fish_y) = fish::get_position(fish);
        let len = vector::length(&pond_state.exit_zones);
        let i = 0;
        while (i < len) {
            let exit_zone = vector::borrow(&pond_state.exit_zones, i);
            if (is_point_in_circle(fish_x, fish_y, exit_zone.x, exit_zone.y, exit_zone.radius)) {
                return true
            };
            i = i + 1;
        };
        false
    }

    fun is_point_in_circle(px: u64, py: u64, cx: u64, cy: u64, radius: u64): bool {
        let dx = if (px > cx) { px - cx } else { cx - px };
        let dy = if (py > cy) { py - cy } else { cy - py };
        (dx * dx + dy * dy) <= (radius * radius)
    }

    public fun get_pond_id(pond_state: &PondState): u64 {
        pond_state.id
    }

    public fun get_width(pond_state: &PondState): u64 {
        pond_state.width
    }

    public fun get_height(pond_state: &PondState): u64 {
        pond_state.height
    }

    public fun get_purchase_amount(pond_state: &PondState): u256 {
        pond_state.purchase_amount
    }

    public fun get_max_fish_count(pond_state: &PondState): u64 {
        pond_state.max_fish_count
    }

    public fun get_max_food_count(pond_state: &PondState): u64 {
        pond_state.max_food_count
    }

    public fun get_fish_count(pond_state: &PondState): u64 {
        pond_state.fish_count
    }

    public fun get_food_count(pond_state: &PondState): u64 {
        pond_state.food_count
    }

    public fun get_player_list(pond_state: &PondState): &PlayerList {
        &pond_state.player_list
    }

    public fun get_player_count(pond_state: &PondState): u64 {
        player::get_player_count(&pond_state.player_list)
    }

    public fun get_total_feed(pond_state: &PondState): u64 {
        player::get_total_feed(&pond_state.player_list)
    }

    public(friend) fun drop_pond(pond: Object<PondState>) {
        let PondState { 
            id: _,
            fishes,
            foods,
            exit_zones,
            fish_count: _,
            food_count: _,
            width: _,
            height: _,
            purchase_amount: _,
            next_fish_id: _,
            next_food_id: _,
            max_fish_count: _,
            max_food_count: _,
            treasury,
            player_list
        } = object::remove(pond);

        while (!vector::is_empty(&exit_zones)) {
            vector::pop_back(&mut exit_zones);
        };
        vector::destroy_empty(exit_zones);

        while (!table_vec::is_empty(&fishes)) {
            let fish = table_vec::pop_back(&mut fishes);
            fish::drop_fish(fish);
        };
        table_vec::destroy_empty(fishes);

        while (!table_vec::is_empty(&foods)) {
            let food = table_vec::pop_back(&mut foods);
            food::drop_food(food);
        };
        table_vec::destroy_empty(foods);

        let treasury_obj = object::new_named_object(treasury);
        object::to_shared(treasury_obj);

        player::drop_player_list(player_list);
    }

    #[test_only]
    use rooch_framework::genesis;

    #[test]
    fun test_create_pond() {
        genesis::init_for_test();

        let id = 1;
        let width = 100;
        let height = 100;
        let purchase_amount = 500;
        let max_fish_count = 50;
        let max_food_count = 30;

        let pond_obj = create_pond(id, width, height, purchase_amount, max_fish_count, max_food_count);
        let pond_state = object::borrow(&pond_obj);

        assert!(get_pond_id(pond_state) == id, 1);
        assert!(get_width(pond_state) == width, 2);
        assert!(get_height(pond_state) == height, 3);
        assert!(get_purchase_amount(pond_state) == purchase_amount, 4);
        assert!(get_max_fish_count(pond_state) == max_fish_count, 5);
        assert!(get_max_food_count(pond_state) == max_food_count, 6);
        assert!(get_fish_count(pond_state) == 0, 7);
        assert!(get_food_count(pond_state) == 0, 8);
        assert!(get_player_count(pond_state) == 0, 9);
        assert!(get_total_feed(pond_state) == 0, 10);

        drop_pond(pond_obj);
    }

    #[test(account = @0x1)]
    fun test_purchase_fish(account: signer) {
        genesis::init_for_test();

        let account_addr = signer::address_of(&account);
        gas_coin::faucet_for_test(account_addr, 1000000);

        let pond_obj = create_pond(1, 100, 100, 500, 50, 30);
        let pond_state = object::borrow_mut(&mut pond_obj);

        coin_store::deposit(&mut pond_state.treasury.coin_store, account_coin_store::withdraw(&account, 1000));

        let fish_id = purchase_fish(pond_state, &account);
        assert!(get_fish_count(pond_state) == 1, 1);
        assert!(fish::get_owner(get_fish(pond_state, fish_id)) == account_addr, 2);
        //assert!(get_player_count(pond_state) == 1, 3);

        drop_pond(pond_obj);
    }

    #[test(account = @0x1)]
    fun test_move_fish(account: signer) {
        genesis::init_for_test();

        let account_addr = signer::address_of(&account);
        gas_coin::faucet_for_test(account_addr, 1000000);

        let pond_obj = create_pond(1, 100, 100, 500, 50, 30);
        let pond_state = object::borrow_mut(&mut pond_obj);

        coin_store::deposit(&mut pond_state.treasury.coin_store, account_coin_store::withdraw(&account, 1000));

        let fish_id = purchase_fish(pond_state, &account);
        move_fish_to_for_test(pond_state, fish_id, 25, 25);

        let (new_x, new_y) = move_fish(pond_state, &account, fish_id, 1);
        
        let fish = get_fish(pond_state, fish_id);
        let (fish_x, fish_y) = fish::get_position(fish);
        assert!(fish_x == new_x && fish_y == new_y, 1);

        drop_pond(pond_obj);
    }

    #[test(account = @0x1)]
    fun test_feed_food(account: signer) {
        genesis::init_for_test();

        let account_addr = signer::address_of(&account);
        gas_coin::faucet_for_test(account_addr, 1000000);

        let pond_obj = create_pond(1, 100, 100, 500, 50, 30);
        let pond_state = object::borrow_mut(&mut pond_obj);

        coin_store::deposit(&mut pond_state.treasury.coin_store, account_coin_store::withdraw(&account, 1000));

        feed_food(pond_state, &account, 100);
        assert!(get_food_count(pond_state) == 10, 1);
        assert!(get_total_feed(pond_state) == 100, 2);

        drop_pond(pond_obj);
    }

    #[test(account = @0x1)]
    fun test_destroy_fish(account: signer) {
        genesis::init_for_test();

        let account_addr = signer::address_of(&account);
        gas_coin::faucet_for_test(account_addr, 1000000);

        let pond_obj = create_pond(1, 100, 100, 500, 50, 30);
        let pond_state = object::borrow_mut(&mut pond_obj);

        coin_store::deposit(&mut pond_state.treasury.coin_store, account_coin_store::withdraw(&account, 10000));

        let fish_id = purchase_fish(pond_state, &account);
        move_fish_to_for_test(pond_state, fish_id, 25, 25);

        add_exit_zone(pond_state, 0, 0, 100);

        let reward = destroy_fish(pond_state, &account, fish_id);
        assert!(reward > 0, 1);
        assert!(get_fish_count(pond_state) == 0, 2);

        drop_pond(pond_obj);
    }

    #[test]
    fun test_exit_zones() {
        genesis::init_for_test();

        let pond_obj = create_pond(1, 100, 100, 500, 50, 30);
        let pond_state = object::borrow_mut(&mut pond_obj);

        add_exit_zone(pond_state, 10, 10, 5);
        add_exit_zone(pond_state, 90, 90, 8);

        let fish1 = fish::create_fish(@0x1, 1, 10, 12, 12);
        let fish2 = fish::create_fish(@0x2, 2, 15, 50, 50);

        assert!(is_fish_in_exit_zone(pond_state, &fish1), 1);
        assert!(!is_fish_in_exit_zone(pond_state, &fish2), 2);

        remove_exit_zone(pond_state, 0);
        assert!(!is_fish_in_exit_zone(pond_state, &fish1), 3);

        fish::drop_fish(fish1);
        fish::drop_fish(fish2);
        drop_pond(pond_obj);
    }
}
