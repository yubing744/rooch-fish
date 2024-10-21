// tests/error_handling_test.move
module rooch_fish::error_handling_test {
    use std::signer;
    use rooch_framework::genesis;
    use rooch_framework::gas_coin;
    use rooch_fish::rooch_fish;

    const POND_ID: u64 = 0;
    const NONEXISTENT_POND_ID: u64 = 999;
    const INITIAL_BALANCE: u64 = 1000000000; // 1000 RGAS

    #[test(admin = @rooch_fish, player1 = @0x42, player2 = @0x43)]
    #[expected_failure(abort_code = rooch_fish::pond::ERR_INSUFFICIENT_BALANCE)]
    fun test_insufficient_balance(admin: signer, player1: signer, _player2: signer) {
        genesis::init_for_test();
        rooch_fish::init_world(&admin);

        let player1_addr = signer::address_of(&player1);
        gas_coin::faucet_for_test(player1_addr, 1); // Give only 1 unit of RGAS

        rooch_fish::purchase_fish(&player1, POND_ID); // This should fail due to insufficient balance
    }

    #[test(admin = @rooch_fish, player1 = @0x42, player2 = @0x43)]
    #[expected_failure(abort_code = rooch_fish::pond::ERR_FISH_NOT_FOUND)]
    fun test_move_nonexistent_fish(admin: signer, player1: signer, _player2: signer) {
        genesis::init_for_test();
        rooch_fish::init_world(&admin);

        let player1_addr = signer::address_of(&player1);
        gas_coin::faucet_for_test(player1_addr, INITIAL_BALANCE);

        rooch_fish::move_fish(&player1, POND_ID, 9999, 1); // Try to move a non-existent fish
    }

    #[test(admin = @rooch_fish, player1 = @0x42, player2 = @0x43)]
    #[expected_failure(abort_code = rooch_fish::rooch_fish::ERR_INVALID_POND_ID)]
    fun test_operate_in_nonexistent_pond(admin: signer, player1: signer, _player2: signer) {
        genesis::init_for_test();
        rooch_fish::init_world(&admin);

        let player1_addr = signer::address_of(&player1);
        gas_coin::faucet_for_test(player1_addr, INITIAL_BALANCE);

        rooch_fish::purchase_fish(&player1, NONEXISTENT_POND_ID); // Try to purchase fish in a non-existent pond
    }

    #[test(admin = @rooch_fish, player1 = @0x42, player2 = @0x43)]
    #[expected_failure(abort_code = rooch_fish::pond::ERR_UNAUTHORIZED)]
    fun test_move_other_player_fish(admin: signer, player1: signer, player2: signer) {
        genesis::init_for_test();
        rooch_fish::init_world(&admin);

        let player1_addr = signer::address_of(&player1);
        let player2_addr = signer::address_of(&player2);
        gas_coin::faucet_for_test(player1_addr, INITIAL_BALANCE);
        gas_coin::faucet_for_test(player2_addr, INITIAL_BALANCE);

        let fish_id = rooch_fish::purchase_fish(&player1, POND_ID);
        rooch_fish::move_fish(&player2, POND_ID, fish_id, 1); // Player2 tries to move Player1's fish
    }

    #[test(admin = @rooch_fish, player1 = @0x42, player2 = @0x43)]
    #[expected_failure(abort_code = rooch_fish::pond::ERR_FISH_NOT_IN_EXIT_ZONE)]
    fun test_destroy_fish_not_in_exit_zone(admin: signer, player1: signer, _player2: signer) {
        genesis::init_for_test();
        rooch_fish::init_world(&admin);

        let player1_addr = signer::address_of(&player1);
        gas_coin::faucet_for_test(player1_addr, INITIAL_BALANCE);

        let fish_id = rooch_fish::purchase_fish(&player1, POND_ID);
        rooch_fish::set_fish_position_for_test(POND_ID, fish_id, 25, 25); // Set fish position away from exit zone
        rooch_fish::destroy_fish(&player1, POND_ID, fish_id); // Try to destroy fish not in exit zone
    }

    #[test(admin = @rooch_fish, player1 = @0x42, player2 = @0x43)]
    #[expected_failure(abort_code = rooch_fish::pond::ERR_MAX_FISH_COUNT_REACHED)]
    fun test_exceed_max_fish_count(admin: signer, player1: signer, _player2: signer) {
        genesis::init_for_test();
        rooch_fish::init_world(&admin);

        let player1_addr = signer::address_of(&player1);
        gas_coin::faucet_for_test(player1_addr, INITIAL_BALANCE);

        let max_fish_count = rooch_fish::get_max_fish_count(POND_ID);
        let i = 0;
        while (i < max_fish_count) {
            rooch_fish::purchase_fish(&player1, POND_ID);
            i = i + 1;
        };

        rooch_fish::purchase_fish(&player1, POND_ID); // Try to exceed max fish count
    }
}
