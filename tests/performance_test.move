// tests/performance_test.move
module rooch_fish::performance_test {
    use std::signer;
    use std::vector;
    use rooch_framework::genesis;
    use rooch_framework::gas_coin;
    use rooch_fish::rooch_fish;

    const POND_ID: u64 = 0;
    const INITIAL_BALANCE: u64 = 10000000000000; // 10,000,000 RGAS
    const NUM_PLAYERS: u64 = 100;
    const OPERATIONS_PER_PLAYER: u64 = 50;

    #[test]
    fun test_large_scale_operations() {
        // Initialize the test environment
        genesis::init_for_test();
        let admin = create_signer(@rooch_fish);
        rooch_fish::init_world(&admin);

        // Create multiple players
        let players = create_players(NUM_PLAYERS);

        // Perform operations
        let fish_ids = vector::empty<u64>();
        let i = 0;
        while (i < NUM_PLAYERS) {
            let player = vector::borrow(&players, i);
            let player_addr = signer::address_of(player);
            gas_coin::faucet_for_test(player_addr, INITIAL_BALANCE);

            // Each player performs multiple operations
            let j = 0;
            while (j < OPERATIONS_PER_PLAYER) {
                if (j % 5 == 0) {
                    let fish_id = rooch_fish::purchase_fish(player, POND_ID);
                    vector::push_back(&mut fish_ids, fish_id);
                } else if (j % 5 == 1 && !vector::is_empty(&fish_ids)) {
                    let fish_id = *vector::borrow(&fish_ids, vector::length(&fish_ids) - 1);
                    rooch_fish::move_fish(player, POND_ID, fish_id, (j % 4 as u8));
                } else if (j % 5 == 2) {
                    rooch_fish::feed_food(player, POND_ID, 1000000); // 1 RGAS
                } else if (j % 5 == 3 && !vector::is_empty(&fish_ids)) {
                    let fish_id = vector::pop_back(&mut fish_ids);
                    rooch_fish::set_fish_position_for_test(POND_ID, fish_id, 50, 50); // Assuming exit zone is at center
                    rooch_fish::destroy_fish(player, POND_ID, fish_id);
                }
                j = j + 1;
            };
            i = i + 1;
        };

        // Verify final state
        let final_fish_count = rooch_fish::get_pond_player_count(POND_ID);
        let final_feed_amount = rooch_fish::get_pond_total_feed(POND_ID);
        let final_player_count = rooch_fish::get_global_player_count();

        // These assertions ensure that the operations had a significant impact
        assert!(final_fish_count > 0, 1);
        assert!(final_feed_amount > 0, 2);
        assert!(final_player_count > 0, 3);

        // Clean up remaining fish
        while (!vector::is_empty(&fish_ids)) {
            let fish_id = vector::pop_back(&mut fish_ids);
            if (fish_id < 1000000) { // Arbitrary large number to avoid potential overflow
                let player = vector::borrow(&players, (fish_id % NUM_PLAYERS as u64));
                rooch_fish::set_fish_position_for_test(POND_ID, fish_id, 50, 50);
                rooch_fish::destroy_fish(player, POND_ID, fish_id);
            };
        };

        assert!(rooch_fish::get_pond_player_count(POND_ID) == 0, 4);
    }

    // Helper function to create multiple player accounts
    fun create_players(num_players: u64): vector<signer> {
        let players = vector::empty<signer>();
        let i = 0;
        while (i < num_players) {
            let addr = @0x1 + i;
            let player = create_signer(addr);
            vector::push_back(&mut players, player);
            i = i + 1;
        };
        players
    }

    // Helper function to create a signer for testing
    // This is not a real cryptographic signer and should only be used in tests
    public fun create_signer(addr: address): signer {
        let bytes = std::bcs::to_bytes(&addr);
        std::bcs::to_bytes(&addr);
        let signer_bytes = std::vector::empty();
        let i = 0;
        while (i < 32) {
            if (i < std::vector::length(&bytes)) {
                std::vector::push_back(&mut signer_bytes, *std::vector::borrow(&bytes, i));
            } else {
                std::vector::push_back(&mut signer_bytes, 0);
            };
            i = i + 1;
        };
        std::from_bcs::deserialize(&signer_bytes)
    }
}
