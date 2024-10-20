// tests/fish_lifecycle_test.move
module rooch_fish::fish_lifecycle_test {
    use std::signer;
    use rooch_framework::genesis;
    use rooch_framework::gas_coin;
    use rooch_fish::rooch_fish;

    const POND_ID: u64 = 0;
    const INITIAL_BALANCE: u256 = 1000000000; // 1000 RGAS

    #[test(admin = @rooch_fish, player = @0x42)]
    fun test_fish_lifecycle(admin: signer, player: signer) {
        // Initialize the test environment
        genesis::init_for_test();
        rooch_fish::init_world(&admin);

        let player_addr = signer::address_of(&player);
        gas_coin::faucet_for_test(player_addr, INITIAL_BALANCE);

        // Purchase a fish
        let fish_id = rooch_fish::purchase_fish(&player, POND_ID);
        
        // Verify fish count increased
        assert!(rooch_fish::get_pond_player_count(POND_ID) == 1, 1);
        
        // Set fish position for testing
        rooch_fish::set_fish_position_for_test(POND_ID, fish_id, 25, 25);
        
        // Move the fish
        let (new_x, new_y) = rooch_fish::move_fish(&player, POND_ID, fish_id, 1); // Move right
        assert!(new_x == 26 && new_y == 25, 2);
        
        // Feed the fish
        rooch_fish::feed_food(&player, POND_id, 10);
        
        // Verify total feed increased
        assert!(rooch_fish::get_pond_total_feed(POND_ID) == 10, 3);
        
        // Set fish position to exit zone for testing
        rooch_fish::set_fish_position_for_test(POND_ID, fish_id, 50, 50);
        
        // Destroy the fish
        let reward = rooch_fish::destroy_fish(&player, POND_ID, fish_id);
        
        // Verify fish count decreased
        assert!(rooch_fish::get_pond_player_count(POND_ID) == 0, 4);
        
        // Verify player received rewards
        assert!(reward > 0, 5);
    }
}
