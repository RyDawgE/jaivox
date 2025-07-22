#scope_file
Movement :: enum_flags u8 {
    FWD_BIT  :: 0b00000001;
    BWD_BIT  :: 0b00000010;
    LFT_BIT  :: 0b00000100;
    RGT_BIT  :: 0b00001000;
    UPD_BIT  :: 0b00010000;
    DWD_BIT  :: 0b00100000;
}

WALK_UP         : TextureData;
WALK_DOWN       : TextureData;
WALK_LEFT       : TextureData;
WALK_RIGHT      : TextureData;
BATTLE_INTRO    : TextureData;
#scope_export

PlayerOverworld :: struct @entity {
    using #as entity : Entity;

    movement : Movement = 0;
    speed    : float    = 100;
    time_moving : float = 0;
}

init_player_overworld :: (entity : *PlayerOverworld) {
    // Create textures and buffer to GPU
    WALK_UP     = create_texture_animated(TEX_KRIS_UP, 4);
    WALK_DOWN   = create_texture_animated(TEX_KRIS_DOWN, 4);
    WALK_LEFT   = create_texture_animated(TEX_KRIS_LEFT, 4);
    WALK_RIGHT  = create_texture_animated(TEX_KRIS_RIGHT, 4);
    BATTLE_INTRO= create_texture_animated(TEX_KRIS_BATTLE_INTRO, 8);

    // Subscriptions
    subscribe_entity_to_input(entity);
    subscribe_entity_to_tick(entity, xx tick_player_overworld);
    subscribe_entity_to_render(entity);

    // Input
    create_input_binding(entity, .KEY_LEFT,     xx move_left);
    create_input_binding(entity, .KEY_RIGHT,    xx move_right);
    create_input_binding(entity, .KEY_UP,       xx move_up);
    create_input_binding(entity, .KEY_DOWN,     xx move_down);
    create_input_binding(entity, .KEY_Z,        xx play_anim);

    create_input_binding(entity,  141,   xx toggle_fast);
    create_input_binding(entity,  27,    xx close_game_binding);

    // Configure sprite defaults
    entity.scale = .{2, 2};
    entity.sprite = New(Sprite);
    set_sprite_texture(entity.sprite, WALK_DOWN);
}

tick_player_overworld :: (player : *PlayerOverworld) {
    using player;

    // Left Right
    if movement & .RGT_BIT {
        entity.velocity.x = 1;
        set_sprite_texture(entity.sprite, WALK_RIGHT);

    } else if movement & .LFT_BIT {
        entity.velocity.x = -1;
        set_sprite_texture(entity.sprite, WALK_LEFT);

    } else {
        entity.velocity.x = 0;
    }

    // Up Down
    if movement & .UPD_BIT {
        entity.velocity.y = 1;
        set_sprite_texture(entity.sprite, WALK_UP);

    } else if movement & .DWD_BIT {
        entity.velocity.y = -1;
        set_sprite_texture(entity.sprite, WALK_DOWN);

    } else {
        entity.velocity.y = 0;
    }

    if (movement != 0) {
        time_moving += game_state.delta_time * (speed/100);
    } else {
        time_moving = 0;
    }

    entity.position += normalize(Vector2.{entity.velocity.x, -entity.velocity.y}) * (player.speed * game_state.delta_time);

    if (!entity.sprite.animating) {
        entity.sprite.animation_frame = cast(s32)( (time_moving*(4)) ) + cast(s32) (movement != 0);
    }

    //print("%\n",time_moving);
    //print("Position: %\nRotation: %\n", entity.position, entity.rotation);
    //print("Forward: %\nRight: %\n", get_forward_vector(camera.rotation), get_right_vector(camera.rotation));
}

move_up :: (player: *PlayerOverworld, event : *Event) {
    using player;
    movement = ifx event.key_pressed then movement | .UPD_BIT else movement & ~.UPD_BIT;
}

move_down :: (player: *PlayerOverworld, event : *Event) {
    using player;
    movement = ifx event.key_pressed then movement | .DWD_BIT else movement & ~.DWD_BIT;
}

move_left :: (player: *PlayerOverworld, event : *Event) {
    using player;
    movement = ifx event.key_pressed then movement | .LFT_BIT else movement & ~.LFT_BIT;
}

move_right :: (player: *PlayerOverworld, event : *Event) {
    using player;
    movement = ifx event.key_pressed then movement | .RGT_BIT else movement & ~.RGT_BIT;
}

play_anim :: (player: *PlayerOverworld, event : *Event) {
    if !event.key_pressed then return;
    sprite : *Sprite = New(Sprite);
    set_sprite_texture(sprite, BATTLE_INTRO);
    sprite.position += .{42,0};
    play_sprite_animation(*player.entity, sprite, .5, false, true);
}

toggle_fast :: (entity: *PlayerOverworld, event : *Event) {
    if event.key_pressed {
        entity.speed = 200;
    } else {
        entity.speed = 100;
    }
}