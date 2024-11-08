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
    square_rotation -= .1;
}

rotate_right :: (entity: *Entity, event : *Event) {
    square_rotation += .1;
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


