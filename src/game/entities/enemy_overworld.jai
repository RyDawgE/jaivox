#scope_file
Movement :: enum_flags u8 {
    FWD_BIT  :: 0b00000001;
    BWD_BIT  :: 0b00000010;
    LFT_BIT  :: 0b00000100;
    RGT_BIT  :: 0b00001000;
    UPD_BIT  :: 0b00010000;
    DWD_BIT  :: 0b00100000;
}

IDLE         : TextureData;

WOBBLE_SHADER   : u32;
#scope_export

EnemyOverworld :: struct @entity {
    using #as entity : Entity;

    movement : Movement = 0;
    speed    : float    = 100;
    time_moving : float = 0;
    is_wobbly   : bool = false;
}

init_enemy_overworld :: (entity : *EnemyOverworld) {
    // Create textures and buffer to GPU
    IDLE      = create_texture(TEX_KNIGHT_IDLE);

    WOBBLE_SHADER = create_shader_program(
        get_shader_object("SPRITE_VERT"),
        get_shader_object("RAINBOW_SPRITE_FRAG"),
    );

    // Subscriptions
    subscribe_entity_to_tick(entity, xx tick_enemy_overworld);
    subscribe_entity_to_render(entity);

    // Configure sprite defaults
    entity.scale = .{2, 2};
    entity.sprite = New(Sprite);
    set_sprite_texture(entity.sprite, IDLE);
    entity.sprite.shader_program = WOBBLE_SHADER;
}

tick_enemy_overworld :: (enemy : *EnemyOverworld) {
    using enemy;

    // Left Right
    if movement & .RGT_BIT {
        entity.velocity.x = 1;

    } else if movement & .LFT_BIT {
        entity.velocity.x = -1;

    } else {
        entity.velocity.x = 0;
    }

    // Up Down
    if movement & .UPD_BIT {
        entity.velocity.y = 1;

    } else if movement & .DWD_BIT {
        entity.velocity.y = -1;

    } else {
        entity.velocity.y = 0;
    }

    if (movement != 0) {
        time_moving += game_state.delta_time * (speed/100);
    } else {
        time_moving = 0;
    }

    entity.velocity = .{0, sin(game_state.time*3)/1.5};
    entity.position += Vector2.{entity.velocity.x, -entity.velocity.y} * (enemy.speed * game_state.delta_time);
    //print("%\n",entity.position);
    //print("Position: %\nRotation: %\n", entity.position, entity.rotation);
    //print("Forward: %\nRight: %\n", get_forward_vector(camera.rotation), get_right_vector(camera.rotation));
}

toggle_fast :: (entity: *EnemyOverworld, event : *Event) {
    if event.key_pressed {
        entity.speed = 200;
    } else {
        entity.speed = 100;
    }
}