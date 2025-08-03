#scope_file
BATTLE_INTRO    : TextureData;
BATTLE_IDLE     : TextureData;
BATTLE_THROW    : TextureData;
BATTLE_DAMAGE   : TextureData;
BATTLE_DEATH    : TextureData;




#scope_export

PlayerBattle :: struct @entity {
    using #as entity : Entity;

    selected_card_index    : int = -1;
    is_scoring_hand        : bool = false;
    playing_hand           : [..] *SelectableCard;
    playing_hand_total     : int;
    discard_hand           : [..] *SelectableCard;
    scroll_amt             : int = 1;
    
    health : int = 20;
    dead   : bool = false;
    vibrator : float = 0; //no im not changing it
    
    base_pos : Vector2;
}

init_player_battle :: (entity : *PlayerBattle) {
    // Create textures and buffer to GPU

    BATTLE_INTRO = create_texture_animated(TEX_KRIS_BATTLE_INTRO, 8);
    BATTLE_IDLE  = create_texture_animated(TEX_KRIS_BATTLE_IDLE, 6);
    BATTLE_THROW = create_texture_animated(TEX_KRIS_BATTLE_THROW, 11);
    BATTLE_DAMAGE = create_texture_animated(TEX_KRIS_BATTLE_DAMAGE, 1);
    BATTLE_DEATH = create_texture_animated(TEX_KRIS_BATTLE_DEATH, 1);




    // Subscriptions
    subscribe_entity_to_input(entity);
    subscribe_entity_to_tick(entity, xx tick_player_battle);
    subscribe_entity_to_render(entity);

    // Input
    create_input_binding(entity, .KEY_LEFT_CONTROL,        xx set_scroll_amt);
    create_input_binding(entity, .KEY_LEFT,     xx hover_left_card);
    create_input_binding(entity, .KEY_RIGHT,    xx hover_right_card);
    create_input_binding(entity, .KEY_Z,        xx select_current_card);
    create_input_binding(entity, .KEY_SPACE,    xx unselect_all_cards);
    create_input_binding(entity, .KEY_ENTER,    xx play_hand);
    create_input_binding(entity, .KEY_X,        xx discard);
    create_input_binding(entity, .KEY_F,        xx test);



    create_input_binding(entity,  27,    xx close_game_binding);

    // Configure sprite defaults
    entity.scale = .{2, 2};
    entity.base_pos = entity.position;
    entity.sprite = New(Sprite);
    set_sprite_texture(entity.sprite, BATTLE_IDLE);
}

tick_player_battle :: (player : *PlayerBattle) {
    using player;

    // Left Right
    entity.sprite.animation_frame = cast(s32)( (game_state.time*(6)) );
    player.vibrator = lerp(player.vibrator, 0, game_state.delta_time*3);
    player.position.x = sin(player.vibrator)*5 + player.base_pos.x;

    //print("%\n",player.selected_card_index);
    //print("Position: %\nRotation: %\n", entity.position, entity.rotation);
    //print("Forward: %\nRight: %\n", get_forward_vector(camera.rotation), get_right_vector(camera.rotation));
}

test :: (player: *PlayerBattle, event : *Event) {
    if !event.key_pressed then return;
    play_throw_anim(player);
    if !event.key_pressed then return;
    if !(game_state.hand.count > 0) then return;

    card : *SelectableCard = game_state.hand[player.selected_card_index];
    destroy_entity(card);
}


play_intro_anim :: (player: *PlayerBattle) {
    sprite : *Sprite = New(Sprite);
    set_sprite_texture(sprite, BATTLE_INTRO);
    sprite.position += .{24,2};
    play_sprite_animation(*player.entity, sprite, .5, false, true);
}

play_throw_anim :: (player: *PlayerBattle) {
    sprite : *Sprite = New(Sprite);
    set_sprite_texture(sprite, BATTLE_THROW);
    sprite.position += .{27,-4};
    play_sprite_animation(*player.entity, sprite, .65, false, true);
}

play_damage_anim :: (player: *PlayerBattle) {
    sprite : *Sprite = New(Sprite);
    set_sprite_texture(sprite, BATTLE_DAMAGE);
    sprite.position += .{27,-4};
    play_sprite_animation(*player.entity, sprite, .75, false, true);
}

play_death_anim :: (player: *PlayerBattle) {
    sprite : *Sprite = New(Sprite);
    set_sprite_texture(sprite, BATTLE_DEATH);
    sprite.position += .{27,-4};
    play_sprite_animation(*player.entity, sprite, 3, true, false);
}


// Combat
take_damage :: (player: *PlayerBattle, damage : int) {
    player.vibrator = 30;
    player.health -= damage;
    if player.health <= 0 {
        kill(player);
    } else {
        play_damage_anim(player);
    }
    play_damage_anim(player);
}

kill :: (player: *PlayerBattle) {
    player.dead = true;
    play_death_anim(player);
}

// Hand Control
set_scroll_amt :: (player: *PlayerBattle, event : *Event) {
    player.scroll_amt = ifx event.key_pressed then 2 else 1;
}

hover_left_card :: (player: *PlayerBattle, event : *Event) {
    if !event.key_pressed then return;
    if !(game_state.hand.count > 0) then return;

    player.selected_card_index =
    abs(player.selected_card_index - player.scroll_amt) % (game_state.hand.count);
    hover_card(player, player.selected_card_index);
}

hover_right_card :: (player: *PlayerBattle, event : *Event) {
    if !event.key_pressed then return;
    if !(game_state.hand.count > 0) then return;

    player.selected_card_index =
    abs(player.selected_card_index + player.scroll_amt) % (game_state.hand.count);
    hover_card(player, player.selected_card_index);
}

hover_card :: (player : *PlayerBattle, index : int) {
    if !(game_state.hand.count > 0) then return;

    for card : game_state.hand set_hovered(card, false);

    player.selected_card_index = index;
    new_card : *SelectableCard = game_state.hand[index];

    if !new_card then return;

    set_hovered(new_card, true);
}

select_current_card :: (player: *PlayerBattle, event : *Event) {
    if !event.key_pressed then return;
    if !(game_state.hand.count > 0) then return;

    card : *SelectableCard = game_state.hand[player.selected_card_index];

    num_selected : int = 0;
    for card : game_state.hand {
        num_selected += ifx card.selected then 1 else 0;
    }

    if num_selected + 1 > 5 && !card.selected then return;

    set_selected(card, !card.selected);
}

unselect_all_cards :: (player: *PlayerBattle, event : *Event) {
    if !event.key_pressed then return;
    for card : game_state.hand set_selected(card, false);
}

test_card :: (player: *PlayerBattle, event : *Event) {
    if !event.key_pressed then return;
    if !(game_state.hand.count > 0) then return;

    card : *SelectableCard = game_state.hand[player.selected_card_index];
    ping(card);
}

play_hand :: (player: *PlayerBattle, event : *Event) {
    if !event.key_pressed then return;
    if player.is_scoring_hand then return;

    played_cards : [..]*SelectableCard;

    for card : game_state.hand {
        if card.selected {
            array_add(*played_cards, card);
        } else {
            set_hovered(card, false);
            card.target_position = .{((it_index.(float) - played_cards.count) * 20) +210, 400};
        };
        set_selected(card, false);
    }

    if !(played_cards.count > 0) then return;

    player.is_scoring_hand = true;
    player.playing_hand_total = 0;

    for *card : played_cards {
        base_pos : Vector2 = player.position + .{20, -70};

        card.*.target_position = base_pos + .{(it_index.(float) * 52), 0};
        array_ordered_remove_by_value(*game_state.hand, card.*);
    }

    hover_card(player, 0);
    num_new_cards : int = game_state.hand_size - game_state.hand.count;

    for i : 1..num_new_cards {
        card, success := draw_random_card(*game_state.deck);
        if !success then break;

        entity := create_entity(SelectableCard);
        entity.target_position = .{(game_state.hand.count.(float) * 20) +210, 400};
        entity.position = .{800, 400};
        init_selectable_card(entity, card);
        array_add(*game_state.hand, entity);
    }

    score_hand(player, played_cards);
}

discard :: (player: *PlayerBattle, event : *Event) {
    if !event.key_pressed then return;
 
    played_cards : [..]*SelectableCard;

    for card : game_state.hand {
        if card.selected {
            array_add(*played_cards, card);
        } else {
            set_hovered(card, false);
            card.target_position = .{((it_index.(float) - played_cards.count) * 20) +210, 400};
        };
        set_selected(card, false);
    }
    
    for *card : played_cards {
        array_ordered_remove_by_value(*game_state.hand, card.*);
    }    
    
    hover_card(player, 0);
    discard_hand(player, played_cards);
    
    num_new_cards : int = game_state.hand_size - game_state.hand.count;
    for i : 1..num_new_cards {
        card, success := draw_random_card(*game_state.deck);
        if !success then break;

        entity := create_entity(SelectableCard);
        entity.target_position = .{(game_state.hand.count.(float) * 20) +210, 400};
        entity.position = .{800, 400};
        init_selectable_card(entity, card);
        array_add(*game_state.hand, entity);
    }

}
