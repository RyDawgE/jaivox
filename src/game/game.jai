GameState :: struct {
    should_close  : bool = false;
    entity_handle : *EntityHandle;
    render_handle : *RenderHandle;
    input_handle  : *InputHandle;
}

game_state : GameState = .{};

square_rotation : float = 0;

test_binding :: (entity: *Entity, event : *Event) {
    print("works!\n");
}

close_game_binding :: (entity: *Entity, event : *Event) {
    game_state.should_close = true;
}

rotate_left :: (entity: *Entity, event : *Event) {
    square_rotation -= .1;
}

rotate_right :: (entity: *Entity, event : *Event) {
    square_rotation += .1;
}

