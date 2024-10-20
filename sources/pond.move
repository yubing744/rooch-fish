module rooch_fish::pond {
    use std::vector;
    use moveos_std::object::{Self, Object};
    use moveos_std::table_vec::{Self, TableVec};
    use rooch_fish::fish::{Self, Fish};
    use rooch_fish::food::{Self, Food};

    friend rooch_fish::rooch_fish;

    const E_FISH_NOT_FOUND: u64 = 1;
    const E_FOOD_NOT_FOUND: u64 = 2;
    const E_MAX_FISH_COUNT_REACHED: u64 = 3;
    const E_MAX_FOOD_COUNT_REACHED: u64 = 4;

    struct ExitZone has store, copy, drop {
        x: u64,
        y: u64,
        radius: u64,
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
        };
        object::new(pond_state)
    }

    public(friend) fun add_fish(pond_state: &mut PondState, fish: Object<Fish>) {
        assert!(pond_state.fish_count < pond_state.max_fish_count, E_MAX_FISH_COUNT_REACHED);
        table_vec::push_back(&mut pond_state.fishes, fish);
        pond_state.fish_count = pond_state.fish_count + 1;
    }

    public(friend) fun remove_fish(pond_state: &mut PondState, fish_id: u64): Object<Fish> {
        let index = find_fish_index(pond_state, fish_id);
        let fish = table_vec::swap_remove(&mut pond_state.fishes, index);
        pond_state.fish_count = pond_state.fish_count - 1;
        fish
    }

    public(friend) fun add_food(pond_state: &mut PondState, food: Object<Food>) {
        assert!(pond_state.food_count < pond_state.max_food_count, E_MAX_FOOD_COUNT_REACHED);
        table_vec::push_back(&mut pond_state.foods, food);
        pond_state.food_count = pond_state.food_count + 1;
    }

    public(friend) fun remove_food(pond_state: &mut PondState, food_id: u64): Object<Food> {
        let index = find_food_index(pond_state, food_id);
        let food = table_vec::swap_remove(&mut pond_state.foods, index);
        pond_state.food_count = pond_state.food_count - 1;
        food
    }

    public(friend) fun get_fish_mut(pond_state: &mut PondState, fish_id: u64): &mut Object<Fish> {
        let index = find_fish_index(pond_state, fish_id);
        table_vec::borrow_mut(&mut pond_state.fishes, index)
    }

    public fun get_fish(pond_state: &PondState, fish_id: u64): &Object<Fish> {
        let index = find_fish_index(pond_state, fish_id);
        table_vec::borrow(&pond_state.fishes, index)
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

    public(friend) fun get_next_fish_id(pond_state: &mut PondState): u64 {
        let fish_id = pond_state.next_fish_id;
        pond_state.next_fish_id = pond_state.next_fish_id + 1;
        fish_id
    }

    public(friend) fun get_next_food_id(pond_state: &mut PondState): u64 {
        let food_id = pond_state.next_food_id;
        pond_state.next_food_id = pond_state.next_food_id + 1;
        food_id
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
        abort E_FISH_NOT_FOUND
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
        abort E_FOOD_NOT_FOUND
    }

    public fun get_all_fishes(pond_state: &PondState): &TableVec<Object<Fish>> {
        &pond_state.fishes
    }

    public fun get_all_foods(pond_state: &PondState): &TableVec<Object<Food>> {
        &pond_state.foods
    }

    public fun get_fish_count(pond_state: &PondState): u64 {
        pond_state.fish_count
    }

    public fun get_food_count(pond_state: &PondState): u64 {
        pond_state.food_count
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
            max_food_count: _
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
    }

    #[test]
    fun test_create_pond() {
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

        drop_pond(pond_obj);
    }

    #[test]
    fun test_add_fish() {
        let pond_obj = create_pond(1, 100, 100, 500, 50, 30);
        let pond_state = object::borrow_mut(&mut pond_obj);

        let fish1 = fish::create_fish(@0x1, 1, 10, 5, 5);
        let fish2 = fish::create_fish(@0x2, 2, 15, 10, 10);

        add_fish(pond_state, fish1);
        assert!(get_fish_count(pond_state) == 1, 1);

        add_fish(pond_state, fish2);
        assert!(get_fish_count(pond_state) == 2, 2);

        let all_fishes = get_all_fishes(pond_state);
        assert!(table_vec::length(all_fishes) == 2, 3);

        let fish1_obj = table_vec::borrow(all_fishes, 0);
        let fish2_obj = table_vec::borrow(all_fishes, 1);

        assert!(fish::get_id(fish1_obj) == 1, 4);
        assert!(fish::get_id(fish2_obj) == 2, 5);

        drop_pond(pond_obj);
    }

    #[test]
    fun test_remove_fish() {
        let pond_obj = create_pond(1, 100, 100, 500, 50, 30);
        let pond_state = object::borrow_mut(&mut pond_obj);

        let fish1 = fish::create_fish(@0x1, 1, 10, 5, 5);
        let fish2 = fish::create_fish(@0x2, 2, 15, 10, 10);

        add_fish(pond_state, fish1);
        add_fish(pond_state, fish2);
        assert!(get_fish_count(pond_state) == 2, 1);

        let removed_fish = remove_fish(pond_state, 1);
        assert!(get_fish_count(pond_state) == 1, 2);
        assert!(fish::get_id(&removed_fish) == 1, 3);

        let all_fishes = get_all_fishes(pond_state);
        assert!(table_vec::length(all_fishes) == 1, 4);
        assert!(fish::get_id(table_vec::borrow(all_fishes, 0)) == 2, 5);

        fish::drop_fish(removed_fish);
        drop_pond(pond_obj);
    }

    #[test]
    fun test_add_food() {
        let pond_obj = create_pond(1, 100, 100, 500, 50, 30);
        let pond_state = object::borrow_mut(&mut pond_obj);

        let food1 = food::create_food(1, 5, 15, 15);
        let food2 = food::create_food(2, 8, 20, 20);

        add_food(pond_state, food1);
        assert!(get_food_count(pond_state) == 1, 1);

        add_food(pond_state, food2);
        assert!(get_food_count(pond_state) == 2, 2);

        let all_foods = get_all_foods(pond_state);
        assert!(table_vec::length(all_foods) == 2, 3);

        let food1_obj = table_vec::borrow(all_foods, 0);
        let food2_obj = table_vec::borrow(all_foods, 1);

        assert!(food::get_id(food1_obj) == 1, 4);
        assert!(food::get_id(food2_obj) == 2, 5);

        drop_pond(pond_obj);
    }

    #[test]
    fun test_remove_food() {
        let pond_obj = create_pond(1, 100, 100, 500, 50, 30);
        let pond_state = object::borrow_mut(&mut pond_obj);

        let food1 = food::create_food(1, 5, 15, 15);
        let food2 = food::create_food(2, 8, 20, 20);

        add_food(pond_state, food1);
        add_food(pond_state, food2);
        assert!(get_food_count(pond_state) == 2, 1);

        let removed_food = remove_food(pond_state, 1);
        assert!(get_food_count(pond_state) == 1, 2);
        assert!(food::get_id(&removed_food) == 1, 3);

        let all_foods = get_all_foods(pond_state);
        assert!(table_vec::length(all_foods) == 1, 4);
        assert!(food::get_id(table_vec::borrow(all_foods, 0)) == 2, 5);

        food::drop_food(removed_food);
        drop_pond(pond_obj);
    }

    #[test]
    fun test_get_next_fish_id() {
        let pond_obj = create_pond(1, 100, 100, 500, 50, 30);
        let pond_state = object::borrow_mut(&mut pond_obj);

        assert!(get_next_fish_id(pond_state) == 1, 1);
        assert!(get_next_fish_id(pond_state) == 2, 2);
        assert!(get_next_fish_id(pond_state) == 3, 3);

        drop_pond(pond_obj);
    }

    #[test]
    fun test_get_next_food_id() {
        let pond_obj = create_pond(1, 100, 100, 500, 50, 30);
        let pond_state = object::borrow_mut(&mut pond_obj);

        assert!(get_next_food_id(pond_state) == 1, 1);
        assert!(get_next_food_id(pond_state) == 2, 2);
        assert!(get_next_food_id(pond_state) == 3, 3);

        drop_pond(pond_obj);
    }

    #[test]
    fun test_exit_zones() {
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
