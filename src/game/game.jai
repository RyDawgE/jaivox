GameState :: struct {
    should_close : bool = false;   
    entity_handle : *EntityHandle;
    render_handle : *RenderHandle;
    input_handle : *InputHandle;
}

start_game :: () {
    debug_counter : int = 0;
    game_state.entity_handle = New(EntityHandle);
    game_state.render_handle = New(RenderHandle);
    game_state.input_handle = New(InputHandle);
    
    initialize_render(game_state.render_handle);
    
    entity := create_entity(Entity);
    subscribe_entity_to_input(entity, game_state.input_handle);
    create_input_binding(entity, 65, test_binding);
    
    while !should_game_close() {
        poll_events();
        render_loop();
    }
    
    cleanup();
}

should_game_close :: () -> bool {
    return game_state.should_close;
}

cleanup :: () {
    cleanup_window(game_state.render_handle.window);
}

test_binding :: (entity: *Entity, event : *Event) {
    print("works!");
}

