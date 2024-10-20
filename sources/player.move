module rooch_fish::player {
    use moveos_std::table::{Self, Table};
    use std::option::{Self, Option};

    friend rooch_fish::rooch_fish;
    friend rooch_fish::pond;

    /// Error codes
    const E_OVERFLOW: u64 = 1001;
    const E_INVALID_PLAYER: u64 = 1002;

    /// Maximum value for u64
    const U64_MAX: u64 = 18446744073709551615;

    /// Represents the state of a player
    struct PlayerState has key, store, copy, drop {
        owner: address,
        feed_amount: u64,
        reward: u64,
        fish_count: u64,
    }

    /// Represents the list of all players
    struct PlayerList has key, store {
        players: Table<address, PlayerState>,
        total_feed: u64,
        player_count: u64,
    }

    /// Creates a new player list
    public(friend) fun create_player_list(): PlayerList {
        PlayerList {
            players: table::new(),
            total_feed: 0,
            player_count: 0,
        }
    }

    /// Adds a fish for a player
    /// Aborts if the addition would cause an overflow
    public(friend) fun add_fish(player_list: &mut PlayerList, owner: address) {
        let player_state = get_or_create_player_state(player_list, owner);
        assert!(player_state.fish_count < U64_MAX, E_OVERFLOW);
        player_state.fish_count = player_state.fish_count + 1;
    }

    /// Adds feed for a player
    /// Aborts if the addition would cause an overflow
    public(friend) fun add_feed(player_list: &mut PlayerList, owner: address, amount: u64) {
        assert!(player_list.total_feed <= U64_MAX - amount, E_OVERFLOW);
        let player_state = get_or_create_player_state(player_list, owner);
        assert!(player_state.feed_amount <= U64_MAX - amount, E_OVERFLOW);
        player_state.feed_amount = player_state.feed_amount + amount;
        player_list.total_feed = player_list.total_feed + amount;
    }

    /// Adds reward for a player
    /// Aborts if the addition would cause an overflow
    public(friend) fun add_reward(player_list: &mut PlayerList, owner: address, amount: u64) {
        let player_state = get_or_create_player_state(player_list, owner);
        assert!(player_state.reward <= U64_MAX - amount, E_OVERFLOW);
        player_state.reward = player_state.reward + amount;
    }

    /// Gets the state of a player
    /// Aborts if the player does not exist
    public fun get_state(player_list: &PlayerList, owner: address): PlayerState {
        assert!(player_exists(player_list, owner), E_INVALID_PLAYER);
        *table::borrow(&player_list.players, owner)
    }

    /// Safely gets the state of a player
    /// Returns None if the player does not exist
    public fun get_state_safe(player_list: &PlayerList, owner: address): Option<PlayerState> {
        if (player_exists(player_list, owner)) {
            option::some(*table::borrow(&player_list.players, owner))
        } else {
            option::none()
        }
    }

    /// Checks if a player exists
    public fun player_exists(player_list: &PlayerList, owner: address): bool {
        table::contains(&player_list.players, owner)
    }

    /// Gets or creates a player state
    fun get_or_create_player_state(player_list: &mut PlayerList, owner: address): &mut PlayerState {
        if (!table::contains(&player_list.players, owner)) {
            let new_state = create_player_state(owner);
            table::add(&mut player_list.players, owner, new_state);
            player_list.player_count = player_list.player_count + 1;
        };
        table::borrow_mut(&mut player_list.players, owner)
    }

    /// Creates a new player state
    fun create_player_state(owner: address): PlayerState {
        PlayerState {
            owner,
            feed_amount: 0,
            reward: 0,
            fish_count: 0,
        }
    }

    /// Gets the total feed amount
    public fun get_total_feed(player_list: &PlayerList): u64 {
        player_list.total_feed
    }

    /// Gets the total player count
    public fun get_player_count(player_list: &PlayerList): u64 {
        player_list.player_count
    }

    /// Drops the player list
    public fun drop_player_list(player_list: PlayerList) {
        let PlayerList { players, total_feed: _, player_count: _ } = player_list;
        table::drop(players);
    }

    #[test]
    fun test_create_player_list() {
        let player_list = create_player_list();
        assert!(table::is_empty(&player_list.players), 1);
        assert!(player_list.total_feed == 0, 2);
        assert!(player_list.player_count == 0, 3);
        
        drop_player_list(player_list);
    }

    #[test]
    fun test_add_feed() {
        let player_list = create_player_list();
        let owner = @0x1;
        
        add_feed(&mut player_list, owner, 100);
        let state = get_state(&player_list, owner);
        assert!(state.feed_amount == 100, 1);
        assert!(state.reward == 0, 2);
        assert!(get_total_feed(&player_list) == 100, 3);
        assert!(get_player_count(&player_list) == 1, 4);

        add_feed(&mut player_list, owner, 50);
        let state = get_state(&player_list, owner);
        assert!(state.feed_amount == 150, 5);
        assert!(state.reward == 0, 6);
        assert!(get_total_feed(&player_list) == 150, 7);
        assert!(get_player_count(&player_list) == 1, 8);

        let new_owner = @0x2;
        add_feed(&mut player_list, new_owner, 75);
        let state = get_state(&player_list, new_owner);
        assert!(state.feed_amount == 75, 9);
        assert!(state.reward == 0, 10);
        assert!(get_total_feed(&player_list) == 225, 11);
        assert!(get_player_count(&player_list) == 2, 12);

        drop_player_list(player_list);
    }

    #[test]
    fun test_add_reward() {
        let player_list = create_player_list();
        let owner = @0x1;
        
        add_reward(&mut player_list, owner, 50);
        let state = get_state(&player_list, owner);
        assert!(state.feed_amount == 0, 1);
        assert!(state.reward == 50, 2);
        assert!(get_player_count(&player_list) == 1, 3);

        add_reward(&mut player_list, owner, 30);
        let state = get_state(&player_list, owner);
        assert!(state.feed_amount == 0, 4);
        assert!(state.reward == 80, 5);
        assert!(get_player_count(&player_list) == 1, 6);

        let new_owner = @0x2;
        add_reward(&mut player_list, new_owner, 100);
        let state = get_state(&player_list, new_owner);
        assert!(state.feed_amount == 0, 7);
        assert!(state.reward == 100, 8);
        assert!(get_player_count(&player_list) == 2, 9);

        assert!(get_total_feed(&player_list) == 0, 10);

        drop_player_list(player_list);
    }

    #[test]
    fun test_get_state_existing_players() {
        let player_list = create_player_list();
        let owner1 = @0x1;
        let owner2 = @0x2;

        add_feed(&mut player_list, owner1, 100);
        add_reward(&mut player_list, owner1, 50);
        add_feed(&mut player_list, owner2, 200);

        let state1 = get_state(&player_list, owner1);
        assert!(state1.owner == owner1, 1);
        assert!(state1.feed_amount == 100, 2);
        assert!(state1.reward == 50, 3);

        let state2 = get_state(&player_list, owner2);
        assert!(state2.owner == owner2, 4);
        assert!(state2.feed_amount == 200, 5);
        assert!(state2.reward == 0, 6);

        assert!(get_player_count(&player_list) == 2, 7);

        drop_player_list(player_list);
    }

    #[test]
    #[expected_failure(abort_code = E_INVALID_PLAYER)]
    fun test_get_state_non_existent_player() {
        let player_list = create_player_list();
        let non_existent_owner = @0x3;

        let _ = get_state(&player_list, non_existent_owner);

        drop_player_list(player_list);
    }

    #[test]
    fun test_get_state_safe() {
        let player_list = create_player_list();
        let owner = @0x1;
        let non_existent_owner = @0x2;

        add_feed(&mut player_list, owner, 100);

        let state_option = get_state_safe(&player_list, owner);
        assert!(option::is_some(&state_option), 1);
        let state = option::extract(&mut state_option);
        assert!(state.feed_amount == 100, 2);

        let state_option = get_state_safe(&player_list, non_existent_owner);
        assert!(option::is_none(&state_option), 3);

        drop_player_list(player_list);
    }

    #[test]
    fun test_player_exists() {
        let player_list = create_player_list();
        let owner = @0x1;
        let non_existent_owner = @0x2;

        add_feed(&mut player_list, owner, 100);

        assert!(player_exists(&player_list, owner), 1);
        assert!(!player_exists(&player_list, non_existent_owner), 2);

        drop_player_list(player_list);
    }

    #[test]
    #[expected_failure(abort_code = E_OVERFLOW)]
    fun test_add_feed_overflow() {
        let player_list = create_player_list();
        let owner = @0x1;

        add_feed(&mut player_list, owner, 0xFFFFFFFFFFFFFFFF);
        add_feed(&mut player_list, owner, 1);

        drop_player_list(player_list);
    }

    #[test]
    #[expected_failure(abort_code = E_OVERFLOW)]
    fun test_add_reward_overflow() {
        let player_list = create_player_list();
        let owner = @0x1;

        add_reward(&mut player_list, owner, 0xFFFFFFFFFFFFFFFF);
        add_reward(&mut player_list, owner, 1);

        drop_player_list(player_list);
    }

    #[test]
    fun test_add_fish() {
        let player_list = create_player_list();
        let owner = @0x1;
        
        add_fish(&mut player_list, owner);
        let state = get_state(&player_list, owner);
        assert!(state.fish_count == 1, 1);
        assert!(get_player_count(&player_list) == 1, 2);

        add_fish(&mut player_list, owner);
        let state = get_state(&player_list, owner);
        assert!(state.fish_count == 2, 3);
        assert!(get_player_count(&player_list) == 1, 4);

        let new_owner = @0x2;
        add_fish(&mut player_list, new_owner);
        let state = get_state(&player_list, new_owner);
        assert!(state.fish_count == 1, 5);
        assert!(get_player_count(&player_list) == 2, 6);

        drop_player_list(player_list);
    }
}
