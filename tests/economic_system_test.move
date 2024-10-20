// tests/economic_system_test.move
module rooch_fish::economic_system_test {
    use std::signer;
    use rooch_framework::genesis;
    use rooch_framework::gas_coin;
    use rooch_fish::rooch_fish;
    use rooch_fish::player;

    const POND_ID_SMALL: u64 = 0;  // Assuming pond 0 is the smallest
    const POND_ID_LARGE: u64 = 3;  // Assuming pond 3 is the largest
    const INITIAL_BALANCE: u64 = 10000000000; // 10000 RGAS

    #[test(admin = @rooch_fish, player1 = @0x42, player2 = @0x43)]
    fun test_economic_system(admin: signer, player1: signer, player2: signer) {
        // Initialize the test environment
        genesis::init_for_test();
        rooch_fish::init_world(&admin);

        let player1_addr = signer::address_of(&player1);
        let player2_addr = signer::address_of(&player2);
        gas_coin::faucet_for_test(player1_addr, INITIAL_BALANCE);
        gas_coin::faucet_for_test(player2_addr, INITIAL_BALANCE);

        // Test purchase in different ponds
        let initial_balance = gas_coin::balance(player1_addr);
        let fish1_small = rooch_fish::purchase_fish(&player1, POND_ID_SMALL);
        let cost_small = initial_balance - gas_coin::balance(player1_addr);

        let initial_balance = gas_coin::balance(player1_addr);
        let fish1_large = rooch_fish::purchase_fish(&player1, POND_ID_LARGE);
        let cost_large = initial_balance - gas_coin::balance(player1_addr);

        // Verify that larger pond costs more
        assert!(cost_large > cost_small, 1);

        // Test feeding
        let feed_amount = 1000000; // 1 RGAS
        let initial_balance = gas_coin::balance(player1_addr);
        rooch_fish::feed_food(&player1, POND_ID_SMALL, feed_amount);
        let feed_cost = initial_balance - gas_coin::balance(player1_addr);
        assert!(feed_cost == feed_amount, 2);

        // Test fish growth and reward
        rooch_fish::set_fish_position_for_test(POND_ID_SMALL, fish1_small, 25, 25);
        rooch_fish::move_fish(&player1, POND_ID_SMALL, fish1_small, 1); // Move to eat food

        rooch_fish::set_fish_position_for_test(POND_ID_SMALL, fish1_small, 50, 50); // Assuming exit zone is at center
        let initial_balance = gas_coin::balance(player1_addr);
        let reward_small = rooch_fish::destroy_fish(&player1, POND_ID_SMALL, fish1_small);
        let actual_reward_small = gas_coin::balance(player1_addr) - initial_balance;
        assert!(reward_small == actual_reward_small, 3);

        // Test reward in larger pond
        rooch_fish::set_fish_position_for_test(POND_ID_LARGE, fish1_large, 50, 50); // Assuming exit zone is at center
        let initial_balance = gas_coin::balance(player1_addr);
        let reward_large = rooch_fish::destroy_fish(&player1, POND_ID_LARGE, fish1_large);
        let actual_reward_large = gas_coin::balance(player1_addr) - initial_balance;
        assert!(reward_large == actual_reward_large, 4);
        assert!(reward_large > reward_small, 5);

        // Test feeding distribution
        let fish2_small = rooch_fish::purchase_fish(&player2, POND_ID_SMALL);
        rooch_fish::feed_food(&player1, POND_ID_SMALL, feed_amount);

        let player_list = rooch_fish::get_global_player_list();
        let player1_state = player::get_state(player_list, player1_addr);
        let player2_state = player::get_state(player_list, player2_addr);

        assert!(player1_state.feed_amount == feed_amount * 2, 6); // Player 1 fed twice
        assert!(player2_state.feed_amount == 0, 7); // Player 2 didn't feed

        // Clean up
        rooch_fish::set_fish_position_for_test(POND_ID_SMALL, fish2_small, 50, 50);
        rooch_fish::destroy_fish(&player2, POND_ID_SMALL, fish2_small);
    }
}
