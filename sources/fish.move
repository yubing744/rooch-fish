module rooch_fish::fish {
    use moveos_std::signer;

    friend rooch_fish::rooch_fish;
    friend rooch_fish::pond;

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

    public(friend) fun create_fish(owner: address, id: u64, size: u64, x: u64, y: u64): Fish {
        Fish {
            id,
            owner,
            size,
            x,
            y,
        }
    }

    public(friend) fun move_fish(account: &signer, fish: &mut Fish, direction: u8) {
        assert!(signer::address_of(account) == fish.owner, E_NOT_OWNER);
        assert!(direction <= 3, E_INVALID_DIRECTION);

        if (direction == 0) {
            fish.y = fish.y + 1;
        } else if (direction == 1) {
            fish.x = fish.x + 1;
        } else if (direction == 2) {
            fish.y = fish.y - 1;
        } else {
            fish.x = fish.x - 1;
        }
    }

    #[test_only]
    public(friend) fun move_fish_to_for_test(fish: &mut Fish, x: u64, y: u64) {
        fish.x = x;
        fish.y = y;
    }

    public(friend) fun grow_fish(fish: &mut Fish, amount: u64) {
        fish.size = fish.size + amount;
    }

    public(friend) fun drop_fish(fish: Fish) {
        let Fish { id: _, owner: _, size: _, x: _, y: _ } = fish;
    }

    public fun get_fish_info(fish: &Fish): (u64, address, u64, u64, u64) {
        (fish.id, fish.owner, fish.size, fish.x, fish.y)
    }

    public fun get_id(fish: &Fish): u64 {
        fish.id
    }

    public fun get_owner(fish: &Fish): address {
        fish.owner
    }

    public fun get_size(fish: &Fish): u64 {
        fish.size
    }

    public fun get_x(fish: &Fish): u64 {
        fish.x
    }

    public fun get_y(fish: &Fish): u64 {
        fish.y
    }

    public fun get_position(fish: &Fish): (u64, u64) {
        (fish.x, fish.y)
    }

    #[test]
    fun test_create_fish() {
        let owner = @0x1;
        let fish = create_fish(owner, 1, 10, 5, 5);
        let (id, fish_owner, size, x, y) = get_fish_info(&fish);

        assert!(id == 1, 1);
        assert!(fish_owner == owner, 2);
        assert!(size == 10, 3);
        assert!(x == 5, 4);
        assert!(y == 5, 5);

        drop_fish(fish);
    }

    #[test(owner = @0x42)]
    fun test_move_fish_up(owner: signer) {
        let owner_addr = signer::address_of(&owner);
        let fish = create_fish(owner_addr, 1, 10, 5, 5);
        
        move_fish(&owner, &mut fish, 0);

        let (_, _, _, new_x, new_y) = get_fish_info(&fish);
        assert!(new_x == 5, 1);
        assert!(new_y == 6, 2);

        drop_fish(fish);
    }

    #[test(owner = @0x42)]
    fun test_move_fish_right(owner: signer) {
        let owner_addr = signer::address_of(&owner);
        let fish = create_fish(owner_addr, 1, 10, 5, 5);
        
        move_fish(&owner, &mut fish, 1);

        let (_, _, _, new_x, new_y) = get_fish_info(&fish);
        assert!(new_x == 6, 1);
        assert!(new_y == 5, 2);

        drop_fish(fish);
    }

    #[test(owner = @0x42)]
    fun test_move_fish_down(owner: signer) {
        let owner_addr = signer::address_of(&owner);
        let fish = create_fish(owner_addr, 1, 10, 5, 5);
        
        move_fish(&owner, &mut fish, 2);

        let (_, _, _, new_x, new_y) = get_fish_info(&fish);
        assert!(new_x == 5, 1);
        assert!(new_y == 4, 2);

        drop_fish(fish);
    }

    #[test(owner = @0x42)]
    fun test_move_fish_left(owner: signer) {
        let owner_addr = signer::address_of(&owner);
        let fish = create_fish(owner_addr, 1, 10, 5, 5);
        
        move_fish(&owner, &mut fish, 3);

        let (_, _, _, new_x, new_y) = get_fish_info(&fish);
        assert!(new_x == 4, 1);
        assert!(new_y == 5, 2);

        drop_fish(fish);
    }

    #[test(owner = @0x42, non_owner = @0x43)]
    #[expected_failure(abort_code = E_NOT_OWNER)]
    fun test_move_fish_non_owner(owner: signer, non_owner: signer) {
        let owner_addr = signer::address_of(&owner);
        let fish = create_fish(owner_addr, 1, 10, 5, 5);
        
        move_fish(&non_owner, &mut fish, 0);

        drop_fish(fish);
    }

    #[test(owner = @0x42)]
    fun test_grow_fish(owner: signer) {
        let owner_addr = signer::address_of(&owner);
        let fish = create_fish(owner_addr, 1, 10, 5, 5);
        
        grow_fish(&mut fish, 5);

        let (_, _, new_size, _, _) = get_fish_info(&fish);
        assert!(new_size == 15, 1);

        drop_fish(fish);
    }

    #[test(owner = @0x42)]
    fun test_get_fish_info(owner: signer) {
        let owner_addr = signer::address_of(&owner);
        let fish = create_fish(owner_addr, 1, 10, 5, 5);
        
        let (id, fish_owner, size, x, y) = get_fish_info(&fish);

        assert!(id == 1, 1);
        assert!(fish_owner == owner_addr, 2);
        assert!(size == 10, 3);
        assert!(x == 5, 4);
        assert!(y == 5, 5);

        drop_fish(fish);
    }

    #[test(owner = @0x42)]
    fun test_get_id(owner: signer) {
        let owner_addr = signer::address_of(&owner);
        let fish = create_fish(owner_addr, 1, 10, 5, 5);
        
        let id = get_id(&fish);
        assert!(id == 1, 1);

        drop_fish(fish);
    }

    #[test(owner = @0x42)]
    #[expected_failure(abort_code = E_INVALID_DIRECTION)]
    fun test_move_fish_invalid_direction(owner: signer) {
        let owner_addr = signer::address_of(&owner);
        let fish = create_fish(owner_addr, 1, 10, 5, 5);
        
        move_fish(&owner, &mut fish, 4);

        drop_fish(fish);
    }
}
