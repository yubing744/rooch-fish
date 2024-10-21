// tests/multi_player_interaction_test.move
module rooch_fish::multi_player_interaction_test {
    use std::signer;
    use rooch_framework::genesis;
    use rooch_framework::gas_coin;
    use rooch_fish::rooch_fish;
    use rooch_fish::player;

    const POND_ID: u64 = 0;
    const INITIAL_BALANCE: u64 = 1000000000; // 1000 RGAS

    #[test(admin = @rooch_fish, player1 = @0x42, player2 = @0x43)]
    fun test_multi_player_interaction(admin: signer, player1: signer, player2: signer) {
        // Initialize the test environment
        genesis::init_for_test();
        rooch_fish::init_world(&admin);

        let player1_addr = signer::address_of(&player1);
        let player2_addr = signer::address_of(&player2);
        gas_coin::faucet_for_test(player1_addr, INITIAL_BALANCE);
        gas_coin::faucet_for_test(player2_addr, INITIAL_BALANCE);

        // Player 1 purchases a fish
        let fish1_id = rooch_fish::purchase_fish(&player1, POND_ID);
        assert!(rooch_fish::get_pond_player_count(POND_ID) == 1, 1);

        // Player 2 purchases a fish
        let fish2_id = rooch_fish::purchase_fish(&player2, POND_ID);
        assert!(rooch_fish::get_pond_player_count(POND_ID) == 2, 2);

        // Set fish positions for testing
        rooch_fish::set_fish_position_for_test(POND_ID, fish1_id, 25, 25);
        rooch_fish::set_fish_position_for_test(POND_ID, fish2_id, 26, 26);

        // Player 1's fish eats some food to grow
        rooch_fish::feed_food(&player1, POND_ID, 100);
        rooch_fish::move_fish(&player1, POND_ID, fish1_id, 1); // Move right to eat food

        // Player 1's fish eats Player 2's fish
        rooch_fish::move_fish(&player1, POND_ID, fish1_id, 1); // Move right to eat the other fish

        // Verify that Player 2's fish is gone
        assert!(rooch_fish::get_pond_player_count(POND_ID) == 1, 3);

        // Verify player rankings
        let player_list = rooch_fish::get_global_player_list();
        let player1_state = player::get_state(player_list, player1_addr);
        let player2_state = player::get_state(player_list, player2_addr);

        assert!(player1_state.fish_count == 1, 4);
        assert!(player2_state.fish_count == 0, 5);
        assert!(player1_state.feed_amount > player2_state.feed_amount, 6);

        // Player 1 destroys their fish
        rooch_fish::set_fish_position_for_test(POND_ID, fish1_id, 50, 50); // Assuming exit zone is at center
        let reward = rooch_fish::destroy_fish(&player1, POND_ID, fish1_id);

        // Verify final state
        assert!(rooch_fish::get_pond_player_count(POND_ID) == 0, 7);
        assert!(reward > 0, 8);

        let final_player1_state = player::get_state(player_list, player1_addr);
        assert!(final_player1_state.fish_count == 0, 9);
        assert!(final_player1_state.reward > 0, 10);
    }
}
