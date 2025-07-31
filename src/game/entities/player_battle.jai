#scope_file
BATTLE_INTRO    : TextureData;
BATTLE_IDLE     : TextureData;

#scope_export

PlayerBattle :: struct @entity {
    using #as entity : Entity;

    selected_card_index : int = -1;
}

init_player_battle :: (entity : *PlayerBattle) {
    // Create textures and buffer to GPU

    BATTLE_INTRO = create_texture_animated(TEX_KRIS_BATTLE_INTRO, 8);
    BATTLE_IDLE = create_texture_animated(TEX_KRIS_BATTLE_IDLE, 6);

    // Subscriptions
    subscribe_entity_to_input(entity);
    subscribe_entity_to_tick(entity, xx tick_player_battle);
    subscribe_entity_to_render(entity);

    // Input
    create_input_binding(entity, .KEY_LEFT,     xx hover_left_card);
    create_input_binding(entity, .KEY_RIGHT,    xx hover_right_card);
    create_input_binding(entity, .KEY_Z,        xx select_current_card);

    create_input_binding(entity,  27,    xx close_game_binding);

    // Configure sprite defaults
    entity.scale = .{2, 2};
    entity.sprite = New(Sprite);
    set_sprite_texture(entity.sprite, BATTLE_IDLE);

}

tick_player_battle :: (player : *PlayerBattle) {
    using player;

    // Left Right
    entity.sprite.animation_frame = cast(s32)( (game_state.time*(6)) );

    //print("%\n",player.selected_card_index);
    //print("Position: %\nRotation: %\n", entity.position, entity.rotation);
    //print("Forward: %\nRight: %\n", get_forward_vector(camera.rotation), get_right_vector(camera.rotation));
}

play_anim :: (player: *PlayerBattle) {
    sprite : *Sprite = New(Sprite);
    set_sprite_texture(sprite, BATTLE_INTRO);
    sprite.position += .{24,2};
    play_sprite_animation(*player.entity, sprite, .5, false, true);
}

hover_left_card :: (player: *PlayerBattle, event : *Event) {
    if !event.key_pressed then return;
    player.selected_card_index =
    abs(player.selected_card_index - 1) % (game_state.hand_size);
    hover_card(player, player.selected_card_index);
}

hover_right_card :: (player: *PlayerBattle, event : *Event) {
    if !event.key_pressed then return;
    player.selected_card_index =
    abs(player.selected_card_index + 1) % (game_state.hand_size);
    hover_card(player, player.selected_card_index);
}

hover_card :: (player : *PlayerBattle, index : int) {
    for card : game_state.hand set_hovered(card, false);

    player.selected_card_index = index;
    new_card : *SelectableCard = game_state.hand[index];
    set_hovered(new_card, true);
}

select_current_card :: (player: *PlayerBattle, event : *Event) {
    if !event.key_pressed then return;

    card : *SelectableCard = game_state.hand[player.selected_card_index];

    num_selected : int = 0;
    for card : game_state.hand {
        num_selected += ifx card.selected then 1 else 0;
    }

    if num_selected + 1 > 5 && !card.selected then return;

    set_selected(card, !card.selected);
}


