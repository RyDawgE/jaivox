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
    speed : float = 0.01;
}

tick_debug_camera :: (camera : *DebugCamera) {
    using camera;
        
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
        entity.velocity.y = -1;
    } else if movement & .LFT_BIT {
        entity.velocity.y = 1;
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
        
    
    camera.position += camera.velocity * camera.speed;
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

rotate_from_mouse :: (entity: *Entity, event : *Event) {
    using game_state.input_handle;
    
    entity.rotation.x += cos(radians(mouse_delta.x)) * cos(radians(mouse_delta.y));
    entity.rotation.y += sin(radians(mouse_delta.y));
    entity.rotation.z += sin(radians(mouse_delta.x)) * cos(radians(mouse_delta.y));
}

