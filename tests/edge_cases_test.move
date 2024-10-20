// tests/edge_cases_test.move
module rooch_fish::edge_cases_test {
    use std::signer;
    use std::vector;
    use rooch_framework::genesis;
    use rooch_framework::gas_coin;
    use rooch_fish::rooch_fish;
    use rooch_fish::fish;

    const POND_ID: u64 = 0;
    const INITIAL_BALANCE: u64 = 1000000000000; // 1,000,000 RGAS
    const MAX_FISH_SIZE: u64 = 1000; // Assuming this is the max size, adjust if necessary

    #[test(admin = @rooch_fish, player = @0x42)]
    fun test_edge_cases(admin: signer, player: signer) {
        // Initialize the test environment
        genesis::init_for_test();
        rooch_fish::init_world(&admin);

        let player_addr = signer::address_of(&player);
        gas_coin::faucet_for_test(player_addr, INITIAL_BALANCE);

        // Test 1: Fill the pond to capacity
        let max_fish_count = rooch_fish::get_max_fish_count(POND_ID);
        let fish_ids = vector::empty<u64>();
        let i = 0;
        while (i < max_fish_count) {
            let fish_id = rooch_fish::purchase_fish(&player, POND_ID);
            vector::push_back(&mut fish_ids, fish_id);
            i = i + 1;
        };
        assert!(rooch_fish::get_pond_player_count(POND_ID) == max_fish_count, 1);

        // Attempt to purchase one more fish (should fail)
        let succeeded = false;
        if (rooch_fish::purchase_fish(&player, POND_ID) != 0) {
            succeeded = true;
        };
        assert!(!succeeded, 2);

        // Test 2: Grow a fish to maximum size
        let test_fish_id = *vector::borrow(&fish_ids, 0);
        rooch_fish::set_fish_position_for_test(POND_ID, test_fish_id, 25, 25);
        
        // Feed the fish to grow it to max size
        while (fish::get_size(rooch_fish::get_fish(POND_ID, test_fish_id)) < MAX_FISH_SIZE) {
            rooch_fish::feed_food(&player, POND_ID, 1000000); // Feed a large amount
            rooch_fish::move_fish(&player, POND_ID, test_fish_id, 1); // Move to eat food
        }

        let max_size_reached = fish::get_size(rooch_fish::get_fish(POND_ID, test_fish_id));
        assert!(max_size_reached == MAX_FISH_SIZE, 3);

        // Try to grow further (should not increase size)
        rooch_fish::feed_food(&player, POND_ID, 1000000);
        rooch_fish::move_fish(&player, POND_ID, test_fish_id, 1);
        assert!(fish::get_size(rooch_fish::get_fish(POND_ID, test_fish_id)) == max_size_reached, 4);

        // Test 3: Extreme feeding
        let extreme_feed_amount = 1000000000; // 1000 RGAS
        rooch_fish::feed_food(&player, POND_ID, extreme_feed_amount);
        assert!(rooch_fish::get_pond_total_feed(POND_ID) >= extreme_feed_amount, 5);

        // Test 4: Rapid fish movements
        let move_count = 100;
        let j = 0;
        while (j < move_count) {
            rooch_fish::move_fish(&player, POND_ID, test_fish_id, (j % 4 as u8)); // Move in all directions
            j = j + 1;
        };
        // Verify fish is still in the pond after rapid movements
        assert!(fish::get_owner(rooch_fish::get_fish(POND_ID, test_fish_id)) == player_addr, 6);

        // Clean up: Destroy all fish
        while (!vector::is_empty(&fish_ids)) {
            let fish_id = vector::pop_back(&mut fish_ids);
            rooch_fish::set_fish_position_for_test(POND_ID, fish_id, 50, 50); // Assuming exit zone is at center
            rooch_fish::destroy_fish(&player, POND_ID, fish_id);
        };
        assert!(rooch_fish::get_pond_player_count(POND_ID) == 0, 7);
    }
}
