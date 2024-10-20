module rooch_fish::fish {
    use moveos_std::signer;
    use moveos_std::object::{Self, Object};

    friend rooch_fish::rooch_fish;
    friend rooch_fish::pond;

    /// Error codes
    const E_NOT_OWNER: u64 = 1;
    const E_INVALID_DIRECTION: u64 = 2;
    const E_UNAUTHORIZED_CREATION: u64 = 3;

    struct Fish has key, store {
        id: u64,
        owner: address,
        size: u64,
        x: u64,
        y: u64,
    }

    /// Creates a new fish object.
    /// @param owner: The address of the fish owner
    /// @param id: The unique identifier of the fish
    /// @param size: The initial size of the fish
    /// @param x: The initial x-coordinate of the fish
    /// @param y: The initial y-coordinate of the fish
    /// @return The newly created Fish object
    public(friend) fun create_fish(owner: address, id: u64, size: u64, x: u64, y: u64): Object<Fish> {
        let fish = Fish {
            id,
            owner,
            size,
            x,
            y,
        };
        object::new(fish)
    }

    /// Moves the fish in the specified direction.
    /// @param account: The signer of the transaction
    /// @param fish_obj: The fish object to move
    /// @param direction: The direction to move (0: Up, 1: Right, 2: Down, 3: Left)
    public(friend) fun move_fish(account: &signer, fish_obj: &mut Object<Fish>, direction: u8) {
        let fish = object::borrow_mut(fish_obj);
        assert!(signer::address_of(account) == fish.owner, E_NOT_OWNER);
        assert!(direction <= 3, E_INVALID_DIRECTION);

        if (direction == 0) {
            fish.y = fish.y + 1; // Up
        } else if (direction == 1) {
            fish.x = fish.x + 1; // Right
        } else if (direction == 2) {
            fish.y = fish.y - 1; // Down
        } else {
            fish.x = fish.x - 1; // Left
        }
    }

    /// Increases the size of the fish.
    /// @param fish_obj: The fish object to grow
    /// @param amount: The amount to increase the fish's size
    public(friend) fun grow_fish(fish_obj: &mut Object<Fish>, amount: u64) {
        let fish = object::borrow_mut(fish_obj);
        fish.size = fish.size + amount;
    }

    /// Destroys a fish object.
    /// @param fish_obj: The fish object to destroy
    public(friend) fun drop_fish(fish_obj: Object<Fish>) {
        let Fish { id: _, owner: _, size: _, x: _, y: _ } = object::remove(fish_obj);
    }

    /// Retrieves the fish's information.
    /// @param fish_obj: The fish object to get information from
    /// @return A tuple containing the fish's id, owner, size, x, and y
    public fun get_fish_info(fish_obj: &Object<Fish>): (u64, address, u64, u64, u64) {
        let fish = object::borrow(fish_obj);
        (fish.id, fish.owner, fish.size, fish.x, fish.y)
    }

    /// Retrieves the fish's id.
    /// @param fish_obj: The fish object to get the id from
    /// @return The id of the fish
    public fun get_id(fish_obj: &Object<Fish>): u64 {
        object::borrow(fish_obj).id
    }

    /// Retrieves the fish's owner.
    /// @param fish_obj: The fish object to get the owner from
    /// @return The address of the fish's owner
    public fun get_owner(fish_obj: &Object<Fish>): address {
        object::borrow(fish_obj).owner
    }

    /// Retrieves the fish's size.
    /// @param fish_obj: The fish object to get the size from
    /// @return The size of the fish
    public fun get_size(fish_obj: &Object<Fish>): u64 {
        object::borrow(fish_obj).size
    }

    /// Retrieves the fish's x-coordinate.
    /// @param fish_obj: The fish object to get the x-coordinate from
    /// @return The x-coordinate of the fish
    public fun get_x(fish_obj: &Object<Fish>): u64 {
        object::borrow(fish_obj).x
    }

    /// Retrieves the fish's y-coordinate.
    /// @param fish_obj: The fish object to get the y-coordinate from
    /// @return The y-coordinate of the fish
    public fun get_y(fish_obj: &Object<Fish>): u64 {
        object::borrow(fish_obj).y
    }

    /// Retrieves the fish's position (x and y coordinates).
    /// @param fish_obj: The fish object to get the position from
    /// @return A tuple containing the x and y coordinates of the fish
    public fun get_position(fish_obj: &Object<Fish>): (u64, u64) {
        let fish = object::borrow(fish_obj);
        (fish.x, fish.y)
    }

    #[test]
    fun test_create_fish() {
        let owner = @0x1;
        let id = 1;
        let size = 10;
        let x = 5;
        let y = 5;

        let fish_obj = create_fish(owner, id, size, x, y);
        let (fish_id, fish_owner, fish_size, fish_x, fish_y) = get_fish_info(&fish_obj);

        assert!(fish_id == id, 1);
        assert!(fish_owner == owner, 2);
        assert!(fish_size == size, 3);
        assert!(fish_x == x, 4);
        assert!(fish_y == y, 5);

        drop_fish(fish_obj);
    }

    #[test(owner = @0x42)]
    fun test_move_fish_up(owner: signer) {
        let owner_addr = signer::address_of(&owner);
        let id = 1;
        let size = 10;
        let x = 5;
        let y = 5;

        let fish_obj = create_fish(owner_addr, id, size, x, y);
        
        // Move fish up (direction 0)
        move_fish(&owner, &mut fish_obj, 0);

        let (_, _, _, new_x, new_y) = get_fish_info(&fish_obj);

        assert!(new_x == x, 1); // x coordinate should not change
        assert!(new_y == y + 1, 2); // y coordinate should increase by 1

        drop_fish(fish_obj);
    }

    #[test(owner = @0x42)]
    fun test_move_fish_right(owner: signer) {
        let owner_addr = signer::address_of(&owner);
        let id = 1;
        let size = 10;
        let x = 5;
        let y = 5;

        let fish_obj = create_fish(owner_addr, id, size, x, y);
        
        // Move fish right (direction 1)
        move_fish(&owner, &mut fish_obj, 1);

        let (_, _, _, new_x, new_y) = get_fish_info(&fish_obj);

        assert!(new_x == x + 1, 1); // x coordinate should increase by 1
        assert!(new_y == y, 2); // y coordinate should not change

        drop_fish(fish_obj);
    }

    #[test(owner = @0x42)]
    fun test_move_fish_down(owner: signer) {
        let owner_addr = signer::address_of(&owner);
        let id = 1;
        let size = 10;
        let x = 5;
        let y = 5;

        let fish_obj = create_fish(owner_addr, id, size, x, y);
        
        // Move fish down (direction 2)
        move_fish(&owner, &mut fish_obj, 2);

        let (_, _, _, new_x, new_y) = get_fish_info(&fish_obj);

        assert!(new_x == x, 1); // x coordinate should not change
        assert!(new_y == y - 1, 2); // y coordinate should decrease by 1

        drop_fish(fish_obj);
    }

    #[test(owner = @0x42)]
    fun test_move_fish_left(owner: signer) {
        let owner_addr = signer::address_of(&owner);
        let id = 1;
        let size = 10;
        let x = 5;
        let y = 5;

        let fish_obj = create_fish(owner_addr, id, size, x, y);
        
        // Move fish left (direction 3)
        move_fish(&owner, &mut fish_obj, 3);

        let (_, _, _, new_x, new_y) = get_fish_info(&fish_obj);

        assert!(new_x == x - 1, 1); // x coordinate should decrease by 1
        assert!(new_y == y, 2); // y coordinate should not change

        drop_fish(fish_obj);
    }

    #[test(owner = @0x42, non_owner = @0x43)]
    #[expected_failure(abort_code = E_NOT_OWNER)]
    fun test_move_fish_non_owner(owner: signer, non_owner: signer) {
        let owner_addr = signer::address_of(&owner);
        let id = 1;
        let size = 10;
        let x = 5;
        let y = 5;

        let fish_obj = create_fish(owner_addr, id, size, x, y);
        
        // Attempt to move fish with non-owner (should fail)
        move_fish(&non_owner, &mut fish_obj, 0);

        // This line should not be reached due to the expected failure
        drop_fish(fish_obj);
    }

    #[test(owner = @0x42)]
    fun test_grow_fish(owner: signer) {
        let owner_addr = signer::address_of(&owner);
        let id = 1;
        let initial_size = 10;
        let x = 5;
        let y = 5;

        let fish_obj = create_fish(owner_addr, id, initial_size, x, y);
        
        // Grow the fish
        let growth_amount = 5;
        grow_fish(&mut fish_obj, growth_amount);

        let (_, _, new_size, _, _) = get_fish_info(&fish_obj);

        assert!(new_size == initial_size + growth_amount, 1);

        drop_fish(fish_obj);
    }

    #[test(owner = @0x42)]
    fun test_get_fish_info(owner: signer) {
        let owner_addr = signer::address_of(&owner);
        let id = 1;
        let size = 10;
        let x = 5;
        let y = 5;

        let fish_obj = create_fish(owner_addr, id, size, x, y);
        
        let (retrieved_id, retrieved_owner, retrieved_size, retrieved_x, retrieved_y) = get_fish_info(&fish_obj);

        assert!(retrieved_id == id, 1);
        assert!(retrieved_owner == owner_addr, 2);
        assert!(retrieved_size == size, 3);
        assert!(retrieved_x == x, 4);
        assert!(retrieved_y == y, 5);

        drop_fish(fish_obj);
    }

    #[test(owner = @0x42)]
    fun test_get_id(owner: signer) {
        let owner_addr = signer::address_of(&owner);
        let id = 1;
        let size = 10;
        let x = 5;
        let y = 5;

        let fish_obj = create_fish(owner_addr, id, size, x, y);
        
        let retrieved_id = get_id(&fish_obj);

        assert!(retrieved_id == id, 1);

        drop_fish(fish_obj);
    }

    
    #[test(owner = @0x42)]
    #[expected_failure(abort_code = E_INVALID_DIRECTION)]
    fun test_move_fish_invalid_direction(owner: signer) {
        let owner_addr = signer::address_of(&owner);
        let id = 1;
        let size = 10;
        let x = 5;
        let y = 5;

        let fish_obj = create_fish(owner_addr, id, size, x, y);
        
        // Attempt to move fish with invalid direction (should fail)
        move_fish(&owner, &mut fish_obj, 4);

        // This line should not be reached due to the expected failure
        drop_fish(fish_obj);
    }
    
}

