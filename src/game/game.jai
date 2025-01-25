GameState :: struct {
    should_close  : bool  = false;
    delta_time    : float = 0;
    start_time    : float = 0;
    
    entity_handle  : *EntityHandle;
    render_handle  : *RenderHandle;
    input_handle   : *InputHandle;
    physics_handle : *PhysicsHandle;
}

game_state : GameState = .{};

square_rotation : float = 0;

close_game_binding :: (entity: *Entity, event : *Event) {
    if event.key_pressed == 1 {
        game_state.should_close = true;
    }
}

update_game_state :: () {
    // Main game loop goes here, if any
}


