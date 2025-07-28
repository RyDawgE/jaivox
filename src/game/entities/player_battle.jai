#scope_file
BATTLE_INTRO    : TextureData;
BATTLE_IDLE     : TextureData;

WOBBLE_SHADER   : u32;
#scope_export

PlayerBattle :: struct @entity {
    using #as entity : Entity;

    is_wobbly   : bool = false;
}

init_player_battle :: (entity : *PlayerBattle) {
    // Create textures and buffer to GPU

    BATTLE_INTRO = create_texture_animated(TEX_KRIS_BATTLE_INTRO, 8);
    BATTLE_IDLE = create_texture_animated(TEX_KRIS_BATTLE_IDLE, 6);


    WOBBLE_SHADER = create_shader_program(
        get_shader_object("WOBBLE_SPRITE_VERT"),
        get_shader_object("RAINBOW_SPRITE_FRAG"),
    );
    
    // Subscriptions
    subscribe_entity_to_input(entity);
    subscribe_entity_to_tick(entity, xx tick_player_battle);
    subscribe_entity_to_render(entity);

    // Input
    create_input_binding(entity, .KEY_X,        xx test);


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

    //print("%\n",time_moving);
    //print("Position: %\nRotation: %\n", entity.position, entity.rotation);
    //print("Forward: %\nRight: %\n", get_forward_vector(camera.rotation), get_right_vector(camera.rotation));
}

test :: (player: *PlayerBattle, event : *Event) {
    using player;
    if !event.key_pressed then return;
    play_anim(player);

    // entity.sprite.shader_program = ifx is_wobbly then 0 else WOBBLE_SHADER;

    // is_wobbly = !is_wobbly;
}

play_anim :: (player: *PlayerBattle) {    
    sprite : *Sprite = New(Sprite);
    set_sprite_texture(sprite, BATTLE_INTRO);
    sprite.position += .{24,2};
    play_sprite_animation(*player.entity, sprite, .5, false, true);
    player.animator.sprite.shader_program = ifx !player.is_wobbly then 0 else WOBBLE_SHADER;
}
