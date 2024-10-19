module rooch_fish::pond {
    use std::vector;

    use moveos_std::object::{Self, Object};

    use rooch_fish::fish::{Self, Fish};
    use rooch_fish::food::{Self, Food};

    friend rooch_fish::main;

    struct PondState has key, store {
        id: u64,
        fishes: vector<Object<Fish>>,
        foods: vector<Object<Food>>,
        fish_count: u64,
        food_count: u64,
    }

    public(friend) fun create_pond(id: u64): Object<PondState> {
        let pond_state = PondState {
            id,
            fishes: vector::empty(),
            foods: vector::empty(),
            fish_count: 0,
            food_count: 0,
        };
        object::new(pond_state)
    }

    public(friend) fun add_fish(pond_state: &mut PondState, fish: Object<Fish>) {
        vector::push_back(&mut pond_state.fishes, fish);
        pond_state.fish_count = pond_state.fish_count + 1;
    }

    public(friend) fun remove_fish(pond_state: &mut PondState, fish_id: u64): Object<Fish> {
        let len = vector::length(&pond_state.fishes);
        let i = 0;
        while (i < len) {
            let fish = vector::borrow(&pond_state.fishes, i);
            if (fish::get_id(fish) == fish_id) {
                let removed_fish = vector::remove(&mut pond_state.fishes, i);
                pond_state.fish_count = pond_state.fish_count - 1;
                return removed_fish
            };
            i = i + 1;
        };
        abort 0 // Fish not found
    }

    public(friend) fun add_food(pond_state: &mut PondState, food: Object<Food>) {
        vector::push_back(&mut pond_state.foods, food);
        pond_state.food_count = pond_state.food_count + 1;
    }

    public(friend) fun remove_food(pond_state: &mut PondState, food_id: u64): Object<Food> {
        let len = vector::length(&pond_state.foods);
        let i = 0;
        while (i < len) {
            let food = vector::borrow(&pond_state.foods, i);
            if (food::get_id(food) == food_id) {
                let removed_food = vector::remove(&mut pond_state.foods, i);
                pond_state.food_count = pond_state.food_count - 1;
                return removed_food
            };
            i = i + 1;
        };
        abort 0 // Food not found
    }

    public fun get_fish(pond_state: &PondState, fish_id: u64): &Object<Fish> {
        let len = vector::length(&pond_state.fishes);
        let i = 0;
        while (i < len) {
            let fish = vector::borrow(&pond_state.fishes, i);
            if (fish::get_id(fish) == fish_id) {
                return fish
            };
            i = i + 1;
        };
        abort 0
    }

    public fun get_fish_mut(pond_state: &mut PondState, fish_id: u64): &mut Object<Fish> {
        let len = vector::length(&pond_state.fishes);
        let i = 0;
        while (i < len) {
            let fish = vector::borrow_mut(&mut pond_state.fishes, i);
            if (fish::get_id(fish) == fish_id) {
                return fish
            };
            i = i + 1;
        };
        abort 0
    }

    public fun get_pond_id(pond_state: &PondState): u64 {
        pond_state.id
    }
}
