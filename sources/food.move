module rooch_fish::food {
    use moveos_std::object::{Self, Object};
    use std::vector;

    friend rooch_fish::rooch_fish;
    friend rooch_fish::pond;

    /// Represents a food item in the pond
    struct Food has key, store {
        id: u64,
        size: u64,
        x: u64,
        y: u64,
    }

    /// Creates a new food object with the given parameters.
    /// @param id: The unique identifier for the food
    /// @param size: The size (nutritional value) of the food
    /// @param x: The x-coordinate of the food in the pond
    /// @param y: The y-coordinate of the food in the pond
    public(friend) fun create_food(id: u64, size: u64, x: u64, y: u64): Object<Food> {
        let food = Food {
            id,
            size,
            x,
            y,
        };
        object::new(food)
    }

    /// Creates multiple food objects at once.
    /// @param ids: Vector of unique identifiers for the food items
    /// @param sizes: Vector of sizes for the food items
    /// @param xs: Vector of x-coordinates for the food items
    /// @param ys: Vector of y-coordinates for the food items
    public(friend) fun create_multiple_food(
        ids: vector<u64>, 
        sizes: vector<u64>, 
        xs: vector<u64>, 
        ys: vector<u64>
    ): vector<Object<Food>> {
        let len = vector::length(&ids);
        assert!(len == vector::length(&sizes) && len == vector::length(&xs) && len == vector::length(&ys), 0);
        
        let foods = vector::empty();
        let i = 0;
        while (i < len) {
            let food = create_food(
                *vector::borrow(&ids, i),
                *vector::borrow(&sizes, i),
                *vector::borrow(&xs, i),
                *vector::borrow(&ys, i)
            );
            vector::push_back(&mut foods, food);
            i = i + 1;
        };
        foods
    }

    /// Retrieves the ID of the food object.
    public fun get_id(food_obj: &Object<Food>): u64 {
        object::borrow(food_obj).id
    }

    /// Retrieves the size of the food object.
    public fun get_size(food_obj: &Object<Food>): u64 {
        object::borrow(food_obj).size
    }

    /// Retrieves the position of the food object.
    public fun get_position(food_obj: &Object<Food>): (u64, u64) {
        let food = object::borrow(food_obj);
        (food.x, food.y)
    }

    #[test_only]
    public fun set_position_for_test(food: &mut Object<Food>, x: u64, y: u64) {
        let food_mut = object::borrow_mut(food);
        food_mut.x = x;
        food_mut.y = y;
    }

    /// Destroys a food object.
    public(friend) fun drop_food(food_obj: Object<Food>) {
        let Food { id: _, size: _, x: _, y: _ } = object::remove(food_obj);
    }

    #[test]
    fun test_create_food() {
        let id = 1;
        let size = 5;
        let x = 10;
        let y = 20;

        let food_obj = create_food(id, size, x, y);
        
        assert!(get_id(&food_obj) == id, 1);
        assert!(get_size(&food_obj) == size, 2);
        
        let (food_x, food_y) = get_position(&food_obj);
        assert!(food_x == x, 3);
        assert!(food_y == y, 4);

        drop_food(food_obj);
    }

    #[test]
    fun test_create_multiple_food() {
        let ids = vector[1, 2, 3];
        let sizes = vector[5, 10, 15];
        let xs = vector[10, 20, 30];
        let ys = vector[40, 50, 60];

        let foods = create_multiple_food(ids, sizes, xs, ys);
        assert!(vector::length(&foods) == 3, 1);

        let food_obj = vector::pop_back(&mut foods);
        assert!(get_id(&food_obj) == 3, 2);
        assert!(get_size(&food_obj) == 15, 3);
        let (x, y) = get_position(&food_obj);
        assert!(x == 30 && y == 60, 4);

        drop_food(food_obj);
        vector::for_each(foods, |food| drop_food(food));
    }
}


