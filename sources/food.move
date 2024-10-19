module rooch_fish::food {
    use moveos_std::object::{Self, Object};

    friend rooch_fish::main;
    friend rooch_fish::pond;

    struct Food has key, store {
        id: u64,
        size: u64,
        x: u64,
        y: u64,
    }

    public fun get_id(food_obj: &Object<Food>): u64 {
        object::borrow(food_obj).id
    }
}

