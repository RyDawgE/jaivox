GameState :: struct {
    should_close  : bool = false;
    entity_handle : *EntityHandle;
    render_handle : *RenderHandle;
    input_handle  : *InputHandle;
}

game_state : GameState = .{};

square_rotation : float = 0;

close_game_binding :: (entity: *Entity, event : *Event) {
    if event.key_pressed == 1 {
        game_state.should_close = true;
    }
}

rotate_left :: (entity: *Entity, event : *Event) {
    entity.rotation.x += -.1;
}

rotate_right :: (entity: *Entity, event : *Event) {
    entity.rotation.x += .1;
}

//@TODO: Bad way of doing it... just make the damn hold events.
move_forward :: (entity: *Entity, event : *Event) {
    entity.movement.x = ifx event.key_pressed then 1.0 else 0.0;
}

move_backward :: (entity: *Entity, event : *Event) {
    entity.movement.x = ifx event.key_pressed then -1.0 else 0.0;
}

move_up :: (entity: *Entity, event : *Event) {
    entity.movement.z = ifx event.key_pressed then 1.0 else 0.0;
}

move_down :: (entity: *Entity, event : *Event) {
    entity.movement.z = ifx event.key_pressed then -1.0 else 0.0;
}

move_left :: (entity: *Entity, event : *Event) {
    entity.movement.y = ifx event.key_pressed then 1.0 else 0.0;
}

move_right :: (entity: *Entity, event : *Event) {
    entity.movement.y = ifx event.key_pressed then -1.0 else 0.0;
}

rotate_from_mouse :: (entity: *Entity, event : *Event) {
    using game_state.input_handle;
    
    entity.rotation.x += cos(radians(mouse_delta.x)) * cos(radians(mouse_delta.y));
    entity.rotation.y += sin(radians(mouse_delta.y));
    entity.rotation.z += sin(radians(mouse_delta.x)) * cos(radians(mouse_delta.y));
}


