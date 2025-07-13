Movement :: enum_flags u8 {
    FWD_BIT  :: 0b00000001;
    BWD_BIT  :: 0b00000010;
    LFT_BIT  :: 0b00000100;
    RGT_BIT  :: 0b00001000;
    UPD_BIT  :: 0b00010000;
    DWD_BIT  :: 0b00100000;
}

DebugCamera :: struct @entity {
    using #as entity : Entity;

    movement : Movement = 0;
    speed    : float    = 100;
    current_chunk : Vector3 = .{0, 0, 0};
}

init_debug_camera :: (camera : *DebugCamera) {
    subscribe_entity_to_input(camera);
    subscribe_entity_to_tick(camera, xx tick_debug_camera);
    subscribe_entity_to_render(camera);

    create_input_binding(camera, .KEY_A, xx move_left);
    create_input_binding(camera, .KEY_D, xx move_right);
    create_input_binding(camera, .KEY_W, xx move_up);
    create_input_binding(camera, .KEY_S, xx move_down);
    create_input_binding(camera,  141,   xx toggle_fast);
    create_input_binding(camera,  27,    xx close_game_binding);

    camera.scale = .{19*2, 38*2};

    camera.sprite = New(Sprite);
    camera.sprite.texture_object = create_texture(TEX_KRIS);
}

tick_debug_camera :: (camera : *DebugCamera) {
    using camera;

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

    camera.position += normalize(Vector2.{camera.velocity.x, -camera.velocity.y}) * (camera.speed * game_state.delta_time);

    print("Position: %\nRotation: %\n", entity.position, entity.rotation);
    //print("Forward: %\nRight: %\n", get_forward_vector(camera.rotation), get_right_vector(camera.rotation));
}

move_up :: (camera: *DebugCamera, event : *Event) {
    using camera;

    movement = ifx event.key_pressed then movement | .UPD_BIT else movement & ~.UPD_BIT;}

move_down :: (camera: *DebugCamera, event : *Event) {
    using camera;

    movement = ifx event.key_pressed then movement | .DWD_BIT else movement & ~.DWD_BIT;}

move_left :: (camera: *DebugCamera, event : *Event) {
    using camera;

    movement = ifx event.key_pressed then movement | .LFT_BIT else movement & ~.LFT_BIT;
}

move_right :: (camera: *DebugCamera, event : *Event) {
    using camera;

    movement = ifx event.key_pressed then movement | .RGT_BIT else movement & ~.RGT_BIT;
}

toggle_fast :: (camera: *DebugCamera, event : *Event) {
    using camera;

    if event.key_pressed {
        speed = 200;
    } else {
        speed = 100;
    }
}