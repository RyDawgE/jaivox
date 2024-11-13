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
    speed : float = 3;
}

init_debug_camera :: (camera : *DebugCamera) {
    subscribe_entity_to_input(camera);
    subscribe_entity_to_tick(camera, xx tick_debug_camera);
    create_input_binding(camera, .KEY_W, xx move_forward);
    create_input_binding(camera, .KEY_A, xx move_left);
    create_input_binding(camera, .KEY_S, xx move_backward);
    create_input_binding(camera, .KEY_D, xx move_right);
    create_input_binding(camera, .KEY_E, xx move_up);
    create_input_binding(camera, .KEY_Q, xx move_down);
}

tick_debug_camera :: (camera : *DebugCamera) {
    using camera;
        
    // // Forward Backward
    // if movement & .FWD_BIT {
    //     entity.velocity = get_forward_vector(camera.rotation);
    // } else if movement & .BWD_BIT {
    //     entity.velocity = -get_forward_vector(camera.rotation);
    // } else {
    //     entity.velocity = .{0,0,0};
    // }
    
    // Forward Backward
    if movement & .FWD_BIT {
        entity.velocity.x = 1;
    } else if movement & .BWD_BIT {
        entity.velocity.x = -1;
    } else {
        entity.velocity.x = 0;
    }
    
    // Left Right
    if movement & .RGT_BIT {
        entity.velocity.y = 1;
    } else if movement & .LFT_BIT {
        entity.velocity.y = -1;
    } else {
        entity.velocity.y = 0;
    }
    
    // Up Down
    if movement & .UPD_BIT {
        entity.velocity.z = 1;
    } else if movement & .DWD_BIT {
        entity.velocity.z = -1;
    } else {
        entity.velocity.z = 0;
    }
        
    print("Position: %\nRotation: %\n", entity.position, entity.rotation);
    print("Forward: %\n", get_forward_vector(camera.rotation));
    print("Right: %\n", get_right_vector(camera.rotation));
    
    rotate_from_mouse(camera);
    camera.position += ((camera.velocity.x * get_forward_vector(camera.rotation)) + (camera.velocity.y * get_right_vector(camera.rotation)) + (camera.velocity.z * .{0, 0, 1})) * camera.speed * game_state.delta_time;
}

move_forward :: (camera: *DebugCamera, event : *Event) {
    using camera;
    
    movement = ifx event.key_pressed then movement | .FWD_BIT else movement & ~.FWD_BIT;
}

move_backward :: (camera: *DebugCamera, event : *Event) {
    using camera;
    
    movement = ifx event.key_pressed then movement | .BWD_BIT else movement & ~.BWD_BIT;
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

rotate_from_mouse :: (entity: *Entity) {
    using game_state.input_handle;
    
    dt : float = game_state.delta_time;
    
    entity.rotation.x += mouse_delta.x * dt * 100;
    entity.rotation.y += mouse_delta.y * dt * 100;
}

