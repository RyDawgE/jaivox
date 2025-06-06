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
    speed    : float    = 3;
    current_chunk : Vector3 = .{0, 0, 0};
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
    create_input_binding(camera,  141,   xx toggle_fast);
    create_input_binding(camera,  27,    xx close_game_binding);
    create_input_binding(camera,  130,   xx rotate_left);
    create_input_binding(camera,  131,   xx rotate_right);

}

tick_debug_camera :: (camera : *DebugCamera) {
    using camera;
    
    // Forward Backward
    if movement & .FWD_BIT {
        entity.velocity.z = 1;
    } else if movement & .BWD_BIT {
        entity.velocity.z = -1;
    } else {
        entity.velocity.z = 0;
    }
    
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
        
    rotate_from_mouse(camera);
    camera.position += ((camera.velocity.z * -get_forward_vector(camera.rotation)) + (camera.velocity.x * -get_right_vector(camera.rotation)) + (camera.velocity.y * .{0, 1, 0})) * camera.speed * game_state.delta_time;
    
    chunk_pos_x := floor((camera.position.x / VOXEL_SIZE) / CHUNK_SIZE);
    chunk_pos_y := floor((camera.position.y / VOXEL_SIZE) / CHUNK_SIZE);
    chunk_pos_z := floor((camera.position.z / VOXEL_SIZE) / CHUNK_SIZE);
    
    camera.current_chunk = .{chunk_pos_x, chunk_pos_y, chunk_pos_z};
    
    // print("Position: %\nRotation: %\n", entity.position, entity.rotation);
    // print("Forward: %\nRight: %\n", get_forward_vector(camera.rotation), get_right_vector(camera.rotation));
    // print("Chunk Position: %\n", camera.current_chunk);
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

toggle_fast :: (camera: *DebugCamera, event : *Event) {
    using camera;

    if event.key_pressed {
        speed = 50;
    } else {
        speed = 3;
    }
}

rotate_from_mouse :: (entity: *Entity) {
    using game_state.input_handle;
    
    dt : float = game_state.delta_time;
    
    entity.rotation.x += mouse_delta.x * dt * 100;
    entity.rotation.y += mouse_delta.y * dt * 100;
}

rotate_left :: (entity: *Entity, event : *Event) {
    entity.rotation.z += 1;
}

rotate_right :: (entity: *Entity, event : *Event) {
    entity.rotation.z += -1;
}

