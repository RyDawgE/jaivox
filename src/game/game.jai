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

