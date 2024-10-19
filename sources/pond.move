module rooch_fish::pond {
    use moveos_std::object::{Self, Object};
    use moveos_std::table_vec::{Self, TableVec};
    use rooch_fish::fish::{Self, Fish};
    use rooch_fish::food::{Self, Food};

    friend rooch_fish::rooch_fish;

    /// Error codes
    const E_FISH_NOT_FOUND: u64 = 1;
    const E_FOOD_NOT_FOUND: u64 = 2;
    const E_MAX_FISH_COUNT_REACHED: u64 = 3;
    const E_MAX_FOOD_COUNT_REACHED: u64 = 4;

    struct PondState has key, store {
        id: u64,
        fishes: TableVec<Object<Fish>>,
        foods: TableVec<Object<Food>>,
        fish_count: u64,
        food_count: u64,
        max_width: u64,
        max_height: u64,
        max_fish_count: u64,
        max_food_count: u64,
    }

    public(friend) fun create_pond(
        id: u64,
        max_width: u64,
        max_height: u64,
        max_fish_count: u64,
        max_food_count: u64
    ): Object<PondState> {
        let pond_state = PondState {
            id,
            fishes: table_vec::new(),
            foods: table_vec::new(),
            fish_count: 0,
            food_count: 0,
            max_width,
            max_height,
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

    public fun get_max_width(pond_state: &PondState): u64 {
        pond_state.max_width
    }

    public fun get_max_height(pond_state: &PondState): u64 {
        pond_state.max_height
    }

    public fun get_max_fish_count(pond_state: &PondState): u64 {
        pond_state.max_fish_count
    }

    public fun get_max_food_count(pond_state: &PondState): u64 {
        pond_state.max_food_count
    }

    // Helper function to find a fish's index
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

    // Helper function to find a food's index
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

    // New function to get all fishes
    public fun get_all_fishes(pond_state: &PondState): &TableVec<Object<Fish>> {
        &pond_state.fishes
    }

    // New function to get all foods
    public fun get_all_foods(pond_state: &PondState): &TableVec<Object<Food>> {
        &pond_state.foods
    }

    // New function to get fish count
    public fun get_fish_count(pond_state: &PondState): u64 {
        pond_state.fish_count
    }

    // New function to get food count
    public fun get_food_count(pond_state: &PondState): u64 {
        pond_state.food_count
    }

    public(friend) fun drop_pond(pond: Object<PondState>) {
        let PondState { 
            id: _,
            fishes,
            foods,
            fish_count: _,
            food_count: _,
            max_width: _,
            max_height: _,
            max_fish_count: _,
            max_food_count: _
        } = object::remove(pond);

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
        let max_width = 100;
        let max_height = 100;
        let max_fish_count = 50;
        let max_food_count = 30;

        let pond_obj = create_pond(id, max_width, max_height, max_fish_count, max_food_count);
        let pond_state = object::borrow(&pond_obj);

        assert!(get_pond_id(pond_state) == id, 1);
        assert!(get_max_width(pond_state) == max_width, 2);
        assert!(get_max_height(pond_state) == max_height, 3);
        assert!(get_max_fish_count(pond_state) == max_fish_count, 4);
        assert!(get_max_food_count(pond_state) == max_food_count, 5);
        assert!(get_fish_count(pond_state) == 0, 6);
        assert!(get_food_count(pond_state) == 0, 7);

        drop_pond(pond_obj);
    }

    #[test]
    fun test_add_fish() {
        let pond_obj = create_pond(1, 100, 100, 50, 30);
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
        let pond_obj = create_pond(1, 100, 100, 50, 30);
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
        let pond_obj = create_pond(1, 100, 100, 50, 30);
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
        let pond_obj = create_pond(1, 100, 100, 50, 30);
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
    fun test_pond_comprehensive() {
        // Create a pond
        let pond_obj = create_pond(1, 100, 100, 3, 2);
        let pond_state = object::borrow_mut(&mut pond_obj);

        // Test basic properties
        assert!(get_pond_id(pond_state) == 1, 1);
        assert!(get_max_width(pond_state) == 100, 2);
        assert!(get_max_height(pond_state) == 100, 3);
        assert!(get_max_fish_count(pond_state) == 3, 4);
        assert!(get_max_food_count(pond_state) == 2, 5);

        // Add fish and food
        let fish1 = fish::create_fish(@0x1, 1, 10, 5, 5);
        let fish2 = fish::create_fish(@0x2, 2, 15, 10, 10);
        let food1 = food::create_food(1, 5, 15, 15);

        add_fish(pond_state, fish1);
        add_fish(pond_state, fish2);
        add_food(pond_state, food1);

        assert!(get_fish_count(pond_state) == 2, 6);
        assert!(get_food_count(pond_state) == 1, 7);

        // Test getting fish object
        let fish_obj = get_fish(pond_state, 1);
        assert!(fish::get_id(fish_obj) == 1, 8);

        // Test getting mutable fish object and modifying it
        let fish_obj_mut = get_fish_mut(pond_state, 2);
        fish::grow_fish(fish_obj_mut, 5);
        let (_, _, size, _, _) = fish::get_fish_info(fish_obj_mut);
        assert!(size == 20, 9); // size should be 15 + 5 = 20

        // Test removing fish and food
        let removed_fish = remove_fish(pond_state, 1);
        assert!(get_fish_count(pond_state) == 1, 10);
        fish::drop_fish(removed_fish);

        let removed_food = remove_food(pond_state, 1);
        assert!(get_food_count(pond_state) == 0, 11);
        food::drop_food(removed_food);

        // Test adding up to maximum count
        let fish3 = fish::create_fish(@0x3, 3, 20, 30, 30);
        let fish4 = fish::create_fish(@0x4, 4, 25, 40, 40);
        add_fish(pond_state, fish3);
        assert!(get_fish_count(pond_state) == 2, 12);
        add_fish(pond_state, fish4);
        assert!(get_fish_count(pond_state) == 3, 13);

        let food2 = food::create_food(2, 8, 20, 20);
        let food3 = food::create_food(3, 10, 25, 25);
        add_food(pond_state, food2);
        assert!(get_food_count(pond_state) == 1, 14);
        add_food(pond_state, food3);
        assert!(get_food_count(pond_state) == 2, 15);

        // Clean up
        drop_pond(pond_obj);
    }

    #[test]
    #[expected_failure(abort_code = E_MAX_FISH_COUNT_REACHED)]
    fun test_add_fish_max_count() {
        let pond_obj = create_pond(1, 100, 100, 1, 1);
        let pond_state = object::borrow_mut(&mut pond_obj);

        let fish1 = fish::create_fish(@0x1, 1, 10, 5, 5);
        let fish2 = fish::create_fish(@0x2, 2, 15, 10, 10);

        add_fish(pond_state, fish1);
        add_fish(pond_state, fish2); // This should fail

        drop_pond(pond_obj);
    }

    #[test]
    #[expected_failure(abort_code = E_FISH_NOT_FOUND)]
    fun test_remove_nonexistent_fish() {
        let pond_obj = create_pond(1, 100, 100, 1, 1);
        let pond_state = object::borrow_mut(&mut pond_obj);

        // Add a fish first
        let fish = fish::create_fish(@0x1, 1, 10, 5, 5);
        add_fish(pond_state, fish);

        // Try to remove a non-existent fish
        let removed_fish = remove_fish(pond_state, 2); // This should fail

        // If it doesn't fail (which it should), clean up properly
        fish::drop_fish(removed_fish);

        drop_pond(pond_obj);
    }
}
